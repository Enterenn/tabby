import uuid
from datetime import date
from decimal import Decimal, ROUND_HALF_UP

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import ensure_can_manage_paid, get_current_user, require_group_member
from app.core.fcm import send_expense_notification, send_settle_confirmed_notification
from app.models.models import Category, DeviceToken, Expense, ExpenseSplit, Group, GroupMember, User
from app.schemas.expense import ExpenseCreate, ExpenseResponse, ExpenseSplitResponse, ExpenseUpdate, CategoryResponse, SplitItem

router = APIRouter(prefix="/groups", tags=["expenses"])


def _to_response(expense: Expense) -> ExpenseResponse:
    return ExpenseResponse(
        id=str(expense.id),
        name=expense.name,
        amount=float(expense.amount),
        category=CategoryResponse(
            id=str(expense.category.id),
            name=expense.category.name,
            icon=expense.category.icon,
            color=expense.category.color,
            is_default=expense.category.is_default,
            sort_order=expense.category.sort_order,
        ),
        paid_by=str(expense.paid_by),
        paid_by_name=expense.paid_by_user.name,
        expense_date=expense.expense_date,
        created_at=expense.created_at,
        status=expense.status,
        splits=[
            ExpenseSplitResponse(user_id=str(s.user_id), amount=float(s.amount))
            for s in expense.splits
        ],
    )


@router.get("/{group_id}/expenses", response_model=list[ExpenseResponse])
async def list_expenses(
    group_id: uuid.UUID,
    from_date: date | None = Query(default=None),
    to_date: date | None = Query(default=None),
    category_id: uuid.UUID | None = Query(default=None),
    status_filter: str | None = Query(default=None, alias="status", pattern="^(confirmed|pending)$"),
    limit: int = Query(default=100, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    filters = [Expense.group_id == group_id]
    if from_date is not None:
        filters.append(Expense.expense_date >= from_date)
    if to_date is not None:
        filters.append(Expense.expense_date <= to_date)
    if category_id is not None:
        filters.append(Expense.category_id == category_id)
    if status_filter is not None:
        filters.append(Expense.status == status_filter)

    result = await db.execute(
        select(Expense)
        .where(*filters)
        .options(
            selectinload(Expense.category),
            selectinload(Expense.paid_by_user),
            selectinload(Expense.splits),
        )
        .order_by(Expense.expense_date.desc(), Expense.created_at.desc(), Expense.id.desc())
        .limit(limit)
        .offset(offset)
    )
    expenses = result.scalars().all()
    return [_to_response(e) for e in expenses]


@router.post(
    "/{group_id}/expenses",
    response_model=ExpenseResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_expense(
    group_id: uuid.UUID,
    body: ExpenseCreate,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    # Valider la catégorie
    category = await db.get(Category, body.category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    if category.user_id is not None or category.group_id != group_id and not category.is_default:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Category not available for this group",
        )

    # Valider le payeur (doit être membre du groupe)
    payer_member = await db.get(GroupMember, (group_id, body.paid_by))
    if payer_member is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Payer is not a member of this group")

    total = Decimal(str(body.amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    expense = Expense(
        id=uuid.uuid4(),
        group_id=group_id,
        category_id=body.category_id,
        paid_by=body.paid_by,
        name=body.name.strip(),
        amount=total,
        expense_date=body.expense_date,
    )
    db.add(expense)
    await db.flush()

    if body.split_type == "equal":
        # Répartition égale entre tous les membres
        members_result = await db.execute(
            select(GroupMember).where(GroupMember.group_id == group_id)
        )
        members = members_result.scalars().all()
        n = len(members)
        per_person = (total / n).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        remainder = total - per_person * n

        for m in members:
            split_amount = per_person + (remainder if m.user_id == body.paid_by else Decimal("0"))
            db.add(ExpenseSplit(
                id=uuid.uuid4(),
                expense_id=expense.id,
                user_id=m.user_id,
                amount=split_amount,
            ))
    else:
        # Répartition personnalisée — validée par le schéma Pydantic + membership
        for item in body.splits:  # type: ignore[union-attr]
            split_member = await db.get(GroupMember, (group_id, item.user_id))
            if split_member is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Split user is not a member of this group",
                )
            db.add(ExpenseSplit(
                id=uuid.uuid4(),
                expense_id=expense.id,
                user_id=item.user_id,
                amount=Decimal(str(item.amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP),
            ))

    await db.flush()

    # Recharger avec les relations pour la réponse
    result = await db.execute(
        select(Expense)
        .where(Expense.id == expense.id)
        .options(
            selectinload(Expense.category),
            selectinload(Expense.paid_by_user),
            selectinload(Expense.splits),
        )
    )
    expense = result.scalar_one()
    response = _to_response(expense)

    # Notifier les autres membres du groupe (fire-and-forget)
    try:
        group = await db.get(Group, group_id)
        members_result = await db.execute(
            select(GroupMember).where(GroupMember.group_id == group_id)
        )
        other_user_ids = [
            m.user_id for m in members_result.scalars().all()
            if m.user_id != current_user.id
        ]
        if other_user_ids and group:
            tokens_result = await db.execute(
                select(DeviceToken.token).where(DeviceToken.user_id.in_(other_user_ids))
            )
            tokens = [t for (t,) in tokens_result.all()]
            send_expense_notification(
                tokens=tokens,
                group_name=group.name,
                expense_name=response.name,
                amount=response.amount,
                group_id=str(group_id),
                payer_name=current_user.name,
            )
    except Exception as exc:
        import logging
        logging.getLogger(__name__).error("[FCM] notification error: %s", exc)

    return response


@router.patch(
    "/{group_id}/expenses/{expense_id}",
    response_model=ExpenseResponse,
)
async def update_expense(
    group_id: uuid.UUID,
    expense_id: uuid.UUID,
    body: ExpenseUpdate,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    expense = await db.execute(
        select(Expense)
        .where(Expense.id == expense_id, Expense.group_id == group_id)
        .options(
            selectinload(Expense.category),
            selectinload(Expense.paid_by_user),
            selectinload(Expense.splits),
        )
    )
    expense = expense.scalar_one_or_none()
    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    if expense.status == "pending":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Cannot edit a repayment waiting for confirmation",
        )
    await ensure_can_manage_paid(db, group_id, current_user, expense.paid_by)

    if body.name is not None:
        expense.name = body.name.strip()
    if body.category_id is not None:
        category = await db.get(Category, body.category_id)
        if category is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
        if category.user_id is not None or category.group_id != group_id and not category.is_default:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Category not available for this group",
            )
        expense.category_id = body.category_id
    if body.paid_by is not None:
        payer_member = await db.get(GroupMember, (group_id, body.paid_by))
        if payer_member is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Payer is not a member")
        expense.paid_by = body.paid_by
    if body.expense_date is not None:
        expense.expense_date = body.expense_date
    if body.amount is not None:
        new_amount = Decimal(str(body.amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        expense.amount = new_amount
        if body.splits is None:
            n = len(expense.splits)
            if n > 0:
                per_person = (new_amount / n).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
                remainder = new_amount - per_person * n
                for i, split in enumerate(expense.splits):
                    split.amount = per_person + (remainder if i == 0 else Decimal("0"))

    if body.splits is not None:
        effective = Decimal(str(expense.amount)).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
        total_splits = sum(
            Decimal(str(item.amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
            for item in body.splits
        )
        if abs(total_splits - effective) > Decimal("0.01"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Splits sum must equal expense amount",
            )
        expense.splits.clear()
        for item in body.splits:
            split_member = await db.get(GroupMember, (group_id, item.user_id))
            if split_member is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Split user is not a member of this group",
                )
            expense.splits.append(
                ExpenseSplit(
                    id=uuid.uuid4(),
                    expense_id=expense.id,
                    user_id=item.user_id,
                    amount=Decimal(str(item.amount)).quantize(
                        Decimal("0.01"), rounding=ROUND_HALF_UP
                    ),
                )
            )

    await db.flush()

    result = await db.execute(
        select(Expense)
        .where(Expense.id == expense_id)
        .options(
            selectinload(Expense.category),
            selectinload(Expense.paid_by_user),
            selectinload(Expense.splits),
        )
    )
    return _to_response(result.scalar_one())


@router.post(
    "/{group_id}/expenses/{expense_id}/confirm",
    response_model=ExpenseResponse,
)
async def confirm_expense(
    group_id: uuid.UUID,
    expense_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Expense)
        .where(Expense.id == expense_id, Expense.group_id == group_id)
        .options(
            selectinload(Expense.category),
            selectinload(Expense.paid_by_user),
            selectinload(Expense.splits),
        )
    )
    expense = result.scalar_one_or_none()
    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    if expense.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This expense does not wait for confirmation",
        )
    recipient_ids = {s.user_id for s in expense.splits}
    if current_user.id not in recipient_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the reimbursed member can confirm",
        )
    expense.status = "confirmed"
    await db.flush()

    try:
        group = await db.get(Group, group_id)
        tokens_result = await db.execute(
            select(DeviceToken.token).where(DeviceToken.user_id == expense.paid_by)
        )
        tokens = [t for (t,) in tokens_result.all()]
        if group and tokens:
            send_settle_confirmed_notification(
                tokens=tokens,
                group_name=group.name,
                amount=float(expense.amount),
                group_id=str(group_id),
                confirmer_name=current_user.name,
            )
    except Exception as exc:
        import logging
        logging.getLogger(__name__).error("[FCM] confirm notification error: %s", exc)

    return _to_response(expense)


@router.delete(
    "/{group_id}/expenses/{expense_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_expense(
    group_id: uuid.UUID,
    expense_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Expense)
        .where(Expense.id == expense_id, Expense.group_id == group_id)
        .options(selectinload(Expense.splits))
    )
    expense = result.scalar_one_or_none()
    if expense is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    recipient_ids = {s.user_id for s in expense.splits}
    can_reject_pending = (
        expense.status == "pending" and current_user.id in recipient_ids
    )
    if not can_reject_pending:
        await ensure_can_manage_paid(db, group_id, current_user, expense.paid_by)
    await db.delete(expense)
