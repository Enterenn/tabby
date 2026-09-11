"""Budget CRUD + calcul du spending mensuel en temps réel."""

import uuid
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import extract, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import get_current_user, require_group_member
from app.models.models import Budget, Category, Expense, GroupMember, User
from app.schemas.budget import BudgetCreate, BudgetResponse, BudgetUpdate
from app.schemas.expense import CategoryResponse

router = APIRouter(prefix="/groups", tags=["budgets"])

# Vue consolidée tous groupes
global_router = APIRouter(prefix="/budgets", tags=["budgets"])


def _status(percent: float) -> str:
    if percent >= 100:
        return "danger"
    if percent >= 75:
        return "warning"
    return "ok"


async def _spending_this_month(
    db: AsyncSession,
    group_id: uuid.UUID,
    category_id: uuid.UUID,
    today: date,
) -> float:
    result = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(
            Expense.group_id == group_id,
            Expense.category_id == category_id,
            extract("year", Expense.expense_date) == today.year,
            extract("month", Expense.expense_date) == today.month,
        )
    )
    return float(result.scalar_one())


def _to_response(b: Budget, spent: float) -> BudgetResponse:
    limit = float(b.limit_amount)
    percent = round((spent / limit * 100) if limit > 0 else 0, 1)
    return BudgetResponse(
        id=str(b.id),
        group_id=str(b.group_id),
        category=CategoryResponse(
            id=str(b.category.id),
            name=b.category.name,
            icon=b.category.icon,
            color=b.category.color,
            is_default=b.category.is_default,
            sort_order=b.category.sort_order,
        ),
        limit_amount=limit,
        spent_amount=round(spent, 2),
        percent=percent,
        status=_status(percent),
    )


@router.get("/{group_id}/budgets", response_model=list[BudgetResponse])
async def list_budgets(
    group_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    result = await db.execute(
        select(Budget)
        .where(Budget.group_id == group_id)
        .options(selectinload(Budget.category))
        .order_by(Budget.category_id)
    )
    budgets = result.scalars().all()
    out = []
    for b in budgets:
        spent = await _spending_this_month(db, group_id, b.category_id, today)
        out.append(_to_response(b, spent))
    return out


@router.post(
    "/{group_id}/budgets",
    response_model=BudgetResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_budget(
    group_id: uuid.UUID,
    body: BudgetCreate,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    cat_id = uuid.UUID(body.category_id)
    category = await db.get(Category, cat_id)
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")

    # Unicité group_id + category_id
    existing = await db.execute(
        select(Budget).where(
            Budget.group_id == group_id, Budget.category_id == cat_id
        )
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=409, detail="Budget already exists for this category"
        )

    budget = Budget(
        id=uuid.uuid4(),
        group_id=group_id,
        category_id=cat_id,
        limit_amount=Decimal(str(body.limit_amount)),
        period="monthly",
    )
    db.add(budget)
    await db.flush()

    # Recharger avec relation
    result = await db.execute(
        select(Budget)
        .where(Budget.id == budget.id)
        .options(selectinload(Budget.category))
    )
    budget = result.scalar_one()
    today = date.today()
    spent = await _spending_this_month(db, group_id, cat_id, today)
    return _to_response(budget, spent)


@router.put("/{group_id}/budgets/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    group_id: uuid.UUID,
    budget_id: uuid.UUID,
    body: BudgetUpdate,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Budget)
        .where(Budget.id == budget_id, Budget.group_id == group_id)
        .options(selectinload(Budget.category))
    )
    budget = result.scalar_one_or_none()
    if budget is None:
        raise HTTPException(status_code=404, detail="Budget not found")

    budget.limit_amount = Decimal(str(body.limit_amount))
    await db.flush()

    today = date.today()
    spent = await _spending_this_month(db, group_id, budget.category_id, today)
    return _to_response(budget, spent)


@router.delete(
    "/{group_id}/budgets/{budget_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_budget(
    group_id: uuid.UUID,
    budget_id: uuid.UUID,
    current_user: User = Depends(require_group_member),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Budget).where(
            Budget.id == budget_id, Budget.group_id == group_id
        )
    )
    budget = result.scalar_one_or_none()
    if budget is None:
        raise HTTPException(status_code=404, detail="Budget not found")
    await db.delete(budget)


# ── Vue globale tous groupes ──────────────────────────────────────────────────

@global_router.get("", response_model=list[BudgetResponse])
async def list_all_budgets(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    memberships = await db.execute(
        select(GroupMember.group_id).where(
            GroupMember.user_id == current_user.id
        )
    )
    group_ids = [row[0] for row in memberships.all()]
    if not group_ids:
        return []

    today = date.today()
    result = await db.execute(
        select(Budget)
        .where(Budget.group_id.in_(group_ids))
        .options(selectinload(Budget.category), selectinload(Budget.group))
        .order_by(Budget.group_id)
    )
    budgets = result.scalars().all()
    out = []
    for b in budgets:
        spent = await _spending_this_month(db, b.group_id, b.category_id, today)
        out.append(_to_response(b, spent))
    return out
