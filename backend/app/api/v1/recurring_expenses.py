"""CRUD endpoints for recurring expenses."""

import uuid
from decimal import Decimal, ROUND_HALF_UP

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, DbSession, GroupMemberUser, ensure_can_manage_paid
from app.models.models import (
    Category,
    GroupMember,
    PersonalRecurring,
    RecurringExpense,
)
from app.schemas.expense import CategoryResponse
from app.services.expense_service import require_group_category
from app.schemas.recurring import (
    PersonalRecurringCreate,
    PersonalRecurringUpdate,
    RecurringExpenseCreate,
    RecurringExpenseResponse,
    RecurringExpenseUpdate,
)

router = APIRouter(prefix="/groups", tags=["recurring-expenses"])

# Accès global (tous groupes de l'utilisateur)
global_router = APIRouter(prefix="/recurring-expenses", tags=["recurring-expenses"])


def _to_response(r: RecurringExpense) -> RecurringExpenseResponse:
    return RecurringExpenseResponse(
        id=str(r.id),
        group_id=str(r.group_id),
        group_name=r.group.name,
        name=r.name,
        amount=float(r.amount),
        category=CategoryResponse(
            id=str(r.category.id),
            name=r.category.name,
            icon=r.category.icon,
            color=r.category.color,
            is_default=r.category.is_default,
            sort_order=r.category.sort_order,
        ),
        paid_by=str(r.paid_by),
        paid_by_name=r.paid_by_user.name,
        frequency=r.frequency,
        day_of_period=r.day_of_period,
        active=r.active,
        created_at=r.created_at,
        is_personal=False,
    )


def _to_personal_response(r: PersonalRecurring) -> RecurringExpenseResponse:
    return RecurringExpenseResponse(
        id=str(r.id),
        group_id=None,
        group_name=None,
        is_personal=True,
        name=r.name,
        amount=float(r.amount),
        category=CategoryResponse(
            id=str(r.category.id),
            name=r.category.name,
            icon=r.category.icon,
            color=r.category.color,
            is_default=r.category.is_default,
            sort_order=r.category.sort_order,
        ),
        paid_by=str(r.user_id),
        paid_by_name=r.user.name,
        frequency=r.frequency,
        day_of_period=r.day_of_period,
        active=r.active,
        created_at=r.created_at,
    )


_LOAD = [
    selectinload(RecurringExpense.group),
    selectinload(RecurringExpense.category),
    selectinload(RecurringExpense.paid_by_user),
]

_PERSONAL_LOAD = [
    selectinload(PersonalRecurring.category),
    selectinload(PersonalRecurring.user),
]


@router.get("/{group_id}/recurring-expenses", response_model=list[RecurringExpenseResponse])
async def list_recurring(
    group_id: uuid.UUID,
    _current_user: GroupMemberUser,
    db: DbSession,
):
    result = await db.execute(
        select(RecurringExpense)
        .where(RecurringExpense.group_id == group_id)
        .options(*_LOAD)
        .order_by(RecurringExpense.created_at.desc())
    )
    return [_to_response(r) for r in result.scalars().all()]


@router.post(
    "/{group_id}/recurring-expenses",
    response_model=RecurringExpenseResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_recurring(
    group_id: uuid.UUID,
    body: RecurringExpenseCreate,
    current_user: GroupMemberUser,
    db: DbSession,
):
    await require_group_category(db, body.category_id, group_id, current_user.id)

    payer = await db.get(GroupMember, (group_id, body.paid_by))
    if payer is None:
        raise HTTPException(status_code=400, detail="Payer is not a member of this group")

    rec = RecurringExpense(
        id=uuid.uuid4(),
        group_id=group_id,
        category_id=body.category_id,
        paid_by=body.paid_by,
        name=body.name.strip(),
        amount=Decimal(str(body.amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP),
        frequency=body.frequency,
        day_of_period=body.day_of_period,
        active=True,
    )
    db.add(rec)
    await db.flush()

    # Recharger avec relations
    result = await db.execute(
        select(RecurringExpense)
        .where(RecurringExpense.id == rec.id)
        .options(*_LOAD)
    )
    rec = result.scalar_one()
    return _to_response(rec)


@router.patch(
    "/{group_id}/recurring-expenses/{rec_id}",
    response_model=RecurringExpenseResponse,
)
async def update_recurring(
    group_id: uuid.UUID,
    rec_id: uuid.UUID,
    body: RecurringExpenseUpdate,
    current_user: GroupMemberUser,
    db: DbSession,
):
    result = await db.execute(
        select(RecurringExpense)
        .where(RecurringExpense.id == rec_id, RecurringExpense.group_id == group_id)
        .options(*_LOAD)
    )
    rec = result.scalar_one_or_none()
    if rec is None:
        raise HTTPException(status_code=404, detail="Not found")
    await ensure_can_manage_paid(db, group_id, current_user, rec.paid_by)

    if body.name is not None:
        rec.name = body.name
    if body.amount is not None:
        rec.amount = Decimal(str(body.amount)).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
    if body.day_of_period is not None:
        rec.day_of_period = body.day_of_period
    if body.category_id is not None:
        category = await db.get(Category, body.category_id)
        if category is None:
            raise HTTPException(status_code=404, detail="Category not found")
        if category.user_id is not None or category.group_id != group_id and not category.is_default:
            raise HTTPException(status_code=403, detail="Category not available for this group")
        rec.category_id = body.category_id
    if body.paid_by is not None:
        payer = await db.get(GroupMember, (group_id, body.paid_by))
        if payer is None:
            raise HTTPException(status_code=400, detail="Payer is not a member of this group")
        rec.paid_by = body.paid_by

    await db.flush()
    result = await db.execute(
        select(RecurringExpense)
        .where(RecurringExpense.id == rec.id)
        .options(*_LOAD)
    )
    return _to_response(result.scalar_one())


@router.patch(
    "/{group_id}/recurring-expenses/{rec_id}/toggle",
    response_model=RecurringExpenseResponse,
)
async def toggle_recurring(
    group_id: uuid.UUID,
    rec_id: uuid.UUID,
    current_user: GroupMemberUser,
    db: DbSession,
):
    result = await db.execute(
        select(RecurringExpense)
        .where(RecurringExpense.id == rec_id, RecurringExpense.group_id == group_id)
        .options(*_LOAD)
    )
    rec = result.scalar_one_or_none()
    if rec is None:
        raise HTTPException(status_code=404, detail="Not found")
    await ensure_can_manage_paid(db, group_id, current_user, rec.paid_by)
    rec.active = not rec.active
    await db.flush()
    return _to_response(rec)


@router.delete(
    "/{group_id}/recurring-expenses/{rec_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_recurring(
    group_id: uuid.UUID,
    rec_id: uuid.UUID,
    current_user: GroupMemberUser,
    db: DbSession,
):
    result = await db.execute(
        select(RecurringExpense)
        .where(RecurringExpense.id == rec_id, RecurringExpense.group_id == group_id)
    )
    rec = result.scalar_one_or_none()
    if rec is None:
        raise HTTPException(status_code=404, detail="Not found")
    await ensure_can_manage_paid(db, group_id, current_user, rec.paid_by)
    await db.delete(rec)


# ── Vue globale (tous groupes) ────────────────────────────────────────────────

@global_router.get("", response_model=list[RecurringExpenseResponse])
async def list_all_recurring(
    current_user: CurrentUser,
    db: DbSession,
):
    """Toutes les récurrences actives de l'utilisateur, tous groupes confondus."""
    # Groupes de l'utilisateur
    memberships = await db.execute(
        select(GroupMember.group_id).where(GroupMember.user_id == current_user.id)
    )
    group_ids = [row[0] for row in memberships.all()]

    group_items: list[RecurringExpenseResponse] = []
    if group_ids:
        result = await db.execute(
            select(RecurringExpense)
            .where(RecurringExpense.group_id.in_(group_ids))
            .options(*_LOAD)
            .order_by(RecurringExpense.active.desc(), RecurringExpense.created_at.desc())
        )
        group_items = [_to_response(r) for r in result.scalars().all()]

    personal_result = await db.execute(
        select(PersonalRecurring)
        .where(PersonalRecurring.user_id == current_user.id)
        .options(*_PERSONAL_LOAD)
        .order_by(PersonalRecurring.active.desc(), PersonalRecurring.created_at.desc())
    )
    personal_items = [_to_personal_response(r) for r in personal_result.scalars().all()]

    return sorted(
        group_items + personal_items,
        key=lambda r: (r.active, r.created_at),
        reverse=True,
    )


@global_router.post(
    "",
    response_model=RecurringExpenseResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_personal_recurring(
    body: PersonalRecurringCreate,
    current_user: CurrentUser,
    db: DbSession,
):
    category = await db.get(Category, body.category_id)
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    if category.user_id is not None and category.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Category not available")

    rec = PersonalRecurring(
        id=uuid.uuid4(),
        user_id=current_user.id,
        category_id=category.id,
        name=body.name,
        amount=Decimal(str(body.amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP),
        frequency=body.frequency,
        day_of_period=body.day_of_period,
        active=True,
    )
    db.add(rec)
    await db.flush()
    result = await db.execute(
        select(PersonalRecurring)
        .where(PersonalRecurring.id == rec.id)
        .options(*_PERSONAL_LOAD)
    )
    return _to_personal_response(result.scalar_one())


@global_router.patch("/{rec_id}", response_model=RecurringExpenseResponse)
async def update_personal_recurring(
    rec_id: uuid.UUID,
    body: PersonalRecurringUpdate,
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(PersonalRecurring)
        .where(
            PersonalRecurring.id == rec_id,
            PersonalRecurring.user_id == current_user.id,
        )
        .options(*_PERSONAL_LOAD)
    )
    rec = result.scalar_one_or_none()
    if rec is None:
        raise HTTPException(status_code=404, detail="Not found")

    if body.name is not None:
        rec.name = body.name
    if body.amount is not None:
        rec.amount = Decimal(str(body.amount)).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
    if body.day_of_period is not None:
        rec.day_of_period = body.day_of_period
    if body.category_id is not None:
        category = await db.get(Category, body.category_id)
        if category is None:
            raise HTTPException(status_code=404, detail="Category not found")
        if category.user_id is not None and category.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Category not available")
        rec.category_id = category.id

    await db.flush()
    result = await db.execute(
        select(PersonalRecurring)
        .where(PersonalRecurring.id == rec.id)
        .options(*_PERSONAL_LOAD)
    )
    return _to_personal_response(result.scalar_one())


@global_router.patch(
    "/{rec_id}/toggle",
    response_model=RecurringExpenseResponse,
)
async def toggle_personal_recurring(
    rec_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(PersonalRecurring)
        .where(
            PersonalRecurring.id == rec_id,
            PersonalRecurring.user_id == current_user.id,
        )
        .options(*_PERSONAL_LOAD)
    )
    rec = result.scalar_one_or_none()
    if rec is None:
        raise HTTPException(status_code=404, detail="Not found")
    rec.active = not rec.active
    await db.flush()
    return _to_personal_response(rec)


@global_router.delete("/{rec_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_personal_recurring(
    rec_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(PersonalRecurring).where(
            PersonalRecurring.id == rec_id,
            PersonalRecurring.user_id == current_user.id,
        )
    )
    rec = result.scalar_one_or_none()
    if rec is None:
        raise HTTPException(status_code=404, detail="Not found")
    await db.delete(rec)
