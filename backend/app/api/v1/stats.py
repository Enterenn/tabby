"""Endpoint d'agrégation des dépenses par catégorie."""

import uuid
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.spend import (
    merge_category_amounts,
    personal_spend_by_category,
    user_share_by_category,
)
from app.models.models import Category, GroupMember, User
from app.schemas.expense import CategoryResponse

router = APIRouter(prefix="/stats", tags=["stats"])


class CategoryStat:
    def __init__(self, category: Category, amount: float, total: float):
        self.category = category
        self.amount = round(amount, 2)
        self.percent = round((amount / total * 100) if total > 0 else 0, 1)


@router.get("")
async def get_stats(
    year: int = Query(default=None),
    month: int = Query(default=None, ge=1, le=12),
    group_id: Optional[uuid.UUID] = Query(default=None),
    scope: str = Query(default="all", pattern="^(all|groups|personal)$"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Agrégation de *ta part* par catégorie (somme des ExpenseSplit).
    Filtre : mois/année courant par défaut, optionnellement un groupe.
    """
    today = date.today()
    target_year = year or today.year
    target_month = month or today.month

    # Groupes accessibles
    memberships = await db.execute(
        select(GroupMember.group_id).where(GroupMember.user_id == current_user.id)
    )
    accessible_group_ids = [row[0] for row in memberships.all()]

    if group_id is not None and group_id in accessible_group_ids:
        group_filter = [group_id]
    else:
        group_filter = accessible_group_ids

    group_rows: list[tuple[uuid.UUID, float]] = []
    if scope in ("all", "groups") and group_filter:
        group_rows = await user_share_by_category(
            db,
            user_id=current_user.id,
            group_ids=group_filter,
            year=target_year,
            month=target_month,
        )

    personal_rows: list[tuple[uuid.UUID, float]] = []
    if scope in ("all", "personal") and group_id is None:
        personal_rows = await personal_spend_by_category(
            db,
            user_id=current_user.id,
            year=target_year,
            month=target_month,
        )

    rows = merge_category_amounts(group_rows, personal_rows)

    if not rows:
        return {"year": target_year, "month": target_month, "total": 0, "categories": []}

    grand_total = float(sum(amount for _, amount in rows))

    cat_ids = [category_id for category_id, _ in rows]
    cats_result = await db.execute(
        select(Category).where(Category.id.in_(cat_ids))
    )
    cats_by_id = {c.id: c for c in cats_result.scalars().all()}

    categories = []
    for category_id, amount in rows:
        cat = cats_by_id.get(category_id)
        if cat is None:
            continue
        categories.append({
            "category": CategoryResponse(
                id=str(cat.id),
                name=cat.name,
                icon=cat.icon,
                color=cat.color,
                is_default=cat.is_default,
                sort_order=cat.sort_order,
            ).model_dump(),
            "amount": round(amount, 2),
            "percent": round(amount / grand_total * 100, 1),
        })

    return {
        "year": target_year,
        "month": target_month,
        "total": round(grand_total, 2),
        "categories": categories,
    }
