"""Endpoint d'agrégation des dépenses par catégorie."""

import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from app.core.deps import CurrentUser, DbSession
from app.core.spend import (
    merge_category_amounts,
    personal_spend_by_category,
    user_share_by_category,
)
from app.models.models import Category, GroupMember
from app.schemas.expense import CategoryResponse

router = APIRouter(prefix="/stats", tags=["stats"])


def _resolve_group_filter(
    group_id: uuid.UUID | None,
    accessible_group_ids: list[uuid.UUID],
) -> list[uuid.UUID]:
    if group_id is None:
        return accessible_group_ids
    if group_id not in accessible_group_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a member of this group",
        )
    return [group_id]


class CategoryStat:
    def __init__(self, category: Category, amount: float, total: float):
        self.category = category
        self.amount = round(amount, 2)
        self.percent = round((amount / total * 100) if total > 0 else 0, 1)


@router.get("")
async def get_stats(
    current_user: CurrentUser,
    db: DbSession,
    year: Annotated[int | None, Query()] = None,
    month: Annotated[int | None, Query(ge=1, le=12)] = None,
    group_id: Annotated[uuid.UUID | None, Query()] = None,
    scope: Annotated[str, Query(pattern="^(all|groups|personal)$")] = "all",
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

    group_filter = _resolve_group_filter(group_id, accessible_group_ids)

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
