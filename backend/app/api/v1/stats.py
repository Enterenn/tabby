"""Endpoint d'agrégation des dépenses par catégorie."""

import uuid
from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import extract, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import Category, Expense, GroupMember, User
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
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Agrégation des dépenses par catégorie.
    Filtre : mois/année courant par défaut, optionnellement un groupe.
    Retourne uniquement les groupes dont l'utilisateur est membre.
    """
    today = date.today()
    target_year = year or today.year
    target_month = month or today.month

    # Groupes accessibles
    memberships = await db.execute(
        select(GroupMember.group_id).where(GroupMember.user_id == current_user.id)
    )
    accessible_group_ids = [row[0] for row in memberships.all()]

    if not accessible_group_ids:
        return {"year": target_year, "month": target_month, "total": 0, "categories": []}

    # Filtre groupe
    if group_id is not None and group_id in accessible_group_ids:
        group_filter = [group_id]
    else:
        group_filter = accessible_group_ids

    # Agréger montants par category_id
    result = await db.execute(
        select(
            Expense.category_id,
            func.sum(Expense.amount).label("total_amount"),
        )
        .where(
            Expense.group_id.in_(group_filter),
            extract("year", Expense.expense_date) == target_year,
            extract("month", Expense.expense_date) == target_month,
        )
        .group_by(Expense.category_id)
        .order_by(func.sum(Expense.amount).desc())
    )
    rows = result.all()

    if not rows:
        return {"year": target_year, "month": target_month, "total": 0, "categories": []}

    grand_total = float(sum(r.total_amount for r in rows))

    # Charger les catégories
    cat_ids = [r.category_id for r in rows]
    cats_result = await db.execute(
        select(Category).where(Category.id.in_(cat_ids))
    )
    cats_by_id = {c.id: c for c in cats_result.scalars().all()}

    categories = []
    for r in rows:
        cat = cats_by_id.get(r.category_id)
        if cat is None:
            continue
        amount = float(r.total_amount)
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
