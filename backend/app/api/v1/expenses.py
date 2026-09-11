import uuid
from decimal import Decimal, ROUND_HALF_UP

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import get_current_user, require_group_member
from app.models.models import Category, Expense, ExpenseSplit, GroupMember, User
from app.schemas.expense import ExpenseCreate, ExpenseResponse, ExpenseSplitResponse, CategoryResponse, SplitItem

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
        splits=[
            ExpenseSplitResponse(user_id=str(s.user_id), amount=float(s.amount))
            for s in expense.splits
        ],
    )


@router.get("/{group_id}/expenses", response_model=list[ExpenseResponse])
async def list_expenses(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Expense)
        .where(Expense.group_id == group_id)
        .options(
            selectinload(Expense.category),
            selectinload(Expense.paid_by_user),
            selectinload(Expense.splits),
        )
        .order_by(Expense.expense_date.desc(), Expense.created_at.desc())
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
        # Répartition personnalisée — validée par le schéma Pydantic
        for item in body.splits:  # type: ignore[union-attr]
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
    expense = await db.get(Expense, expense_id)
    if expense is None or expense.group_id != group_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    await db.delete(expense)
