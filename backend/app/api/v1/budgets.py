"""Plafonds personnels : spent = ta part des groupes + tes dépenses perso."""

import uuid
from datetime import date
from decimal import Decimal
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.deps import CurrentUser, DbSession
from app.core.spend import user_spent_for_categories
from app.models.models import Budget, Category
from app.schemas.budget import BudgetCreate, BudgetResponse, BudgetUpdate
from app.schemas.expense import CategoryResponse

router = APIRouter(prefix="/groups", tags=["budgets"])
global_router = APIRouter(prefix="/budgets", tags=["budgets"])


def _status(percent: float) -> str:
    if percent >= 100:
        return "danger"
    if percent >= 75:
        return "warning"
    return "ok"


def _target_period(year: int | None, month: int | None) -> tuple[int, int]:
    today = date.today()
    return year or today.year, month or today.month


def _to_response(b: Budget, spent: float) -> BudgetResponse:
    limit = float(b.limit_amount)
    percent = round((spent / limit * 100) if limit > 0 else 0, 1)
    return BudgetResponse(
        id=str(b.id),
        group_id=None,
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


async def _load_user_budgets(
    db: AsyncSession,
    user_id: uuid.UUID,
    year: int,
    month: int,
) -> list[BudgetResponse]:
    result = await db.execute(
        select(Budget)
        .where(Budget.user_id == user_id)
        .options(selectinload(Budget.category))
        .order_by(Budget.category_id)
    )
    budgets = result.scalars().all()
    spent = await user_spent_for_categories(
        db,
        user_id=user_id,
        category_ids=[b.category_id for b in budgets],
        year=year,
        month=month,
    )
    return [_to_response(b, spent.get(b.category_id, 0.0)) for b in budgets]


@global_router.get("", response_model=list[BudgetResponse])
async def list_all_budgets(
    current_user: CurrentUser,
    db: DbSession,
    year: Annotated[int | None, Query()] = None,
    month: Annotated[int | None, Query(ge=1, le=12)] = None,
):
    target_year, target_month = _target_period(year, month)
    return await _load_user_budgets(db, current_user.id, target_year, target_month)


@global_router.post(
    "",
    response_model=BudgetResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_budget(
    body: BudgetCreate,
    current_user: CurrentUser,
    db: DbSession,
):
    cat_id = uuid.UUID(body.category_id)
    category = await db.get(Category, cat_id)
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")

    existing = await db.execute(
        select(Budget).where(
            Budget.user_id == current_user.id, Budget.category_id == cat_id
        )
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=409, detail="Budget already exists for this category"
        )

    budget = Budget(
        id=uuid.uuid4(),
        user_id=current_user.id,
        category_id=cat_id,
        limit_amount=Decimal(str(body.limit_amount)),
        period="monthly",
    )
    db.add(budget)
    await db.flush()
    result = await db.execute(
        select(Budget)
        .where(Budget.id == budget.id)
        .options(selectinload(Budget.category))
    )
    budget = result.scalar_one()
    target_year, target_month = _target_period(None, None)
    spent = await user_spent_for_categories(
        db,
        user_id=current_user.id,
        category_ids=[cat_id],
        year=target_year,
        month=target_month,
    )
    return _to_response(budget, spent.get(cat_id, 0.0))


@global_router.put("/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    budget_id: uuid.UUID,
    body: BudgetUpdate,
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(Budget)
        .where(Budget.id == budget_id, Budget.user_id == current_user.id)
        .options(selectinload(Budget.category))
    )
    budget = result.scalar_one_or_none()
    if budget is None:
        raise HTTPException(status_code=404, detail="Budget not found")

    budget.limit_amount = Decimal(str(body.limit_amount))
    await db.flush()
    target_year, target_month = _target_period(None, None)
    spent = await user_spent_for_categories(
        db,
        user_id=current_user.id,
        category_ids=[budget.category_id],
        year=target_year,
        month=target_month,
    )
    return _to_response(budget, spent.get(budget.category_id, 0.0))


@global_router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_budget(
    budget_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(Budget).where(
            Budget.id == budget_id, Budget.user_id == current_user.id
        )
    )
    budget = result.scalar_one_or_none()
    if budget is None:
        raise HTTPException(status_code=404, detail="Budget not found")
    await db.delete(budget)


@router.get("/{group_id}/budgets", response_model=list[BudgetResponse])
async def list_group_budgets_compat(
    group_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
    year: Annotated[int | None, Query()] = None,
    month: Annotated[int | None, Query(ge=1, le=12)] = None,
):
    del group_id
    target_year, target_month = _target_period(year, month)
    return await _load_user_budgets(db, current_user.id, target_year, target_month)
