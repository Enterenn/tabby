"""CRUD endpoints for recurring expenses."""

import uuid
from decimal import Decimal, ROUND_HALF_UP

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import ensure_can_manage_paid, get_current_user, require_group_member
from app.models.models import (
    Category,
    Expense,
    GroupMember,
    RecurringExpense,
    User,
)
from app.schemas.expense import CategoryResponse
from app.schemas.recurring import RecurringExpenseCreate, RecurringExpenseResponse

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
    )


_LOAD = [
    selectinload(RecurringExpense.group),
    selectinload(RecurringExpense.category),
    selectinload(RecurringExpense.paid_by_user),
]


@router.get("/{group_id}/recurring-expenses", response_model=list[RecurringExpenseResponse])
async def list_recurring(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
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
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    category = await db.get(Category, body.category_id)
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")

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
    "/{group_id}/recurring-expenses/{rec_id}/toggle",
    response_model=RecurringExpenseResponse,
)
async def toggle_recurring(
    group_id: uuid.UUID,
    rec_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
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
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
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
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Toutes les récurrences actives de l'utilisateur, tous groupes confondus."""
    # Groupes de l'utilisateur
    memberships = await db.execute(
        select(GroupMember.group_id).where(GroupMember.user_id == current_user.id)
    )
    group_ids = [row[0] for row in memberships.all()]

    if not group_ids:
        return []

    result = await db.execute(
        select(RecurringExpense)
        .where(RecurringExpense.group_id.in_(group_ids))
        .options(*_LOAD)
        .order_by(RecurringExpense.active.desc(), RecurringExpense.created_at.desc())
    )
    return [_to_response(r) for r in result.scalars().all()]
