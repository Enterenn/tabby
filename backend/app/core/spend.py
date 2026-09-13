"""Agrégation de ce qu'une dépense a vraiment coûté à un utilisateur (sa ligne de split)."""

from __future__ import annotations

import uuid

from sqlalchemy import extract, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import Expense, ExpenseSplit, GroupMember, PersonalExpense


async def user_share_by_category(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    group_ids: list[uuid.UUID],
    year: int,
    month: int,
) -> list[tuple[uuid.UUID, float]]:
    """[(category_id, share)] pour les groupes donnés, mois donné."""
    if not group_ids:
        return []
    result = await db.execute(
        select(
            Expense.category_id,
            func.coalesce(func.sum(ExpenseSplit.amount), 0).label("total_amount"),
        )
        .join(ExpenseSplit, ExpenseSplit.expense_id == Expense.id)
        .where(
            Expense.group_id.in_(group_ids),
            ExpenseSplit.user_id == user_id,
            extract("year", Expense.expense_date) == year,
            extract("month", Expense.expense_date) == month,
            Expense.status != "pending",
        )
        .group_by(Expense.category_id)
        .order_by(func.sum(ExpenseSplit.amount).desc())
    )
    return [(row[0], float(row[1])) for row in result.all()]


async def user_share_for_pairs(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    pairs: list[tuple[uuid.UUID, uuid.UUID]],
    year: int,
    month: int,
) -> dict[tuple[uuid.UUID, uuid.UUID], float]:
    """Spent = part de l'utilisateur pour chaque (group_id, category_id)."""
    out = {pair: 0.0 for pair in pairs}
    if not pairs:
        return out
    group_ids = {group_id for group_id, _ in pairs}
    category_ids = {category_id for _, category_id in pairs}
    result = await db.execute(
        select(
            Expense.group_id,
            Expense.category_id,
            func.coalesce(func.sum(ExpenseSplit.amount), 0),
        )
        .join(ExpenseSplit, ExpenseSplit.expense_id == Expense.id)
        .where(
            Expense.group_id.in_(group_ids),
            Expense.category_id.in_(category_ids),
            ExpenseSplit.user_id == user_id,
            extract("year", Expense.expense_date) == year,
            extract("month", Expense.expense_date) == month,
            Expense.status != "pending",
        )
        .group_by(Expense.group_id, Expense.category_id)
    )
    for group_id, category_id, total in result.all():
        key = (group_id, category_id)
        if key in out:
            out[key] = float(total)
    return out


async def personal_spend_by_category(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    year: int,
    month: int,
) -> list[tuple[uuid.UUID, float]]:
    result = await db.execute(
        select(
            PersonalExpense.category_id,
            func.coalesce(func.sum(PersonalExpense.amount), 0),
        )
        .where(
            PersonalExpense.user_id == user_id,
            extract("year", PersonalExpense.expense_date) == year,
            extract("month", PersonalExpense.expense_date) == month,
        )
        .group_by(PersonalExpense.category_id)
    )
    return [(row[0], float(row[1])) for row in result.all()]


def merge_category_amounts(
    *groups: list[tuple[uuid.UUID, float]],
) -> list[tuple[uuid.UUID, float]]:
    totals: dict[uuid.UUID, float] = {}
    for rows in groups:
        for category_id, amount in rows:
            totals[category_id] = totals.get(category_id, 0.0) + amount
    return sorted(totals.items(), key=lambda item: item[1], reverse=True)


async def user_spent_for_categories(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    category_ids: list[uuid.UUID],
    year: int,
    month: int,
) -> dict[uuid.UUID, float]:
    """Plafonds : part des groupes + perso, toujours en 'Tout'."""
    out = {cid: 0.0 for cid in category_ids}
    if not category_ids:
        return out

    groups = await db.execute(
        select(GroupMember.group_id).where(GroupMember.user_id == user_id)
    )
    group_ids = [row[0] for row in groups.all()]
    if group_ids:
        share_rows = await user_share_by_category(
            db, user_id=user_id, group_ids=group_ids, year=year, month=month
        )
        for category_id, amount in share_rows:
            if category_id in out:
                out[category_id] += amount

    personal_rows = await personal_spend_by_category(
        db, user_id=user_id, year=year, month=month
    )
    for category_id, amount in personal_rows:
        if category_id in out:
            out[category_id] += amount
    return out
