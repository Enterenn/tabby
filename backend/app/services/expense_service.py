"""Reusable expense business rules and response mapping."""

from __future__ import annotations

import uuid
from decimal import Decimal, ROUND_HALF_UP

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.models import Category, Expense, GroupMember
from app.schemas.expense import CategoryResponse, ExpenseResponse, ExpenseSplitResponse, SplitItem

_CENT = Decimal("0.01")


def money(value: object) -> Decimal:
    """Convert an API/database amount to a consistently rounded Decimal."""
    return Decimal(str(value)).quantize(_CENT, rounding=ROUND_HALF_UP)


def category_is_available(category: Category, group_id: uuid.UUID) -> bool:
    """Global default or category owned by the requested group."""
    return category.is_default and category.user_id is None or category.group_id == group_id


async def require_group_category(
    db: AsyncSession,
    category_id: uuid.UUID,
    group_id: uuid.UUID,
) -> Category:
    category = await db.get(Category, category_id)
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found",
        )
    if not category_is_available(category, group_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Category not available for this group",
        )
    return category


async def require_group_member_user(
    db: AsyncSession,
    group_id: uuid.UUID,
    user_id: uuid.UUID,
    *,
    detail: str = "User is not a member of this group",
) -> GroupMember:
    member = await db.get(GroupMember, (group_id, user_id))
    if member is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)
    return member


def equal_split_amounts(
    total: Decimal,
    members: list[GroupMember],
    paid_by: uuid.UUID,
) -> list[tuple[uuid.UUID, Decimal]]:
    if not members:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Group has no members",
        )
    per_person = money(total / len(members))
    remainder = total - per_person * len(members)
    return [
        (
            member.user_id,
            per_person + (remainder if member.user_id == paid_by else Decimal("0")),
        )
        for member in members
    ]


def custom_split_amounts(splits: list[SplitItem]) -> list[tuple[uuid.UUID, Decimal]]:
    return [(item.user_id, money(item.amount)) for item in splits]


def to_expense_response(expense: Expense) -> ExpenseResponse:
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
            ExpenseSplitResponse(user_id=str(split.user_id), amount=float(split.amount))
            for split in expense.splits
        ],
    )
