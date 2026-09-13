import uuid

from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import extract, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import Category, PersonalExpense, User
from app.schemas.expense import CategoryResponse
from app.schemas.personal import (
    PersonalExpenseCreate,
    PersonalExpenseResponse,
    PersonalExpenseUpdate,
)

router = APIRouter(prefix="/personal-expenses", tags=["personal-expenses"])


def _to_response(expense: PersonalExpense) -> PersonalExpenseResponse:
    return PersonalExpenseResponse(
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
        expense_date=expense.expense_date,
        created_at=expense.created_at,
    )


@router.get("", response_model=list[PersonalExpenseResponse])
async def list_personal_expenses(
    year: int | None = Query(default=None),
    month: int | None = Query(default=None, ge=1, le=12),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    target_year = year or today.year
    target_month = month or today.month

    result = await db.execute(
        select(PersonalExpense)
        .where(
            PersonalExpense.user_id == current_user.id,
            extract("year", PersonalExpense.expense_date) == target_year,
            extract("month", PersonalExpense.expense_date) == target_month,
        )
        .options(selectinload(PersonalExpense.category))
        .order_by(PersonalExpense.expense_date.desc(), PersonalExpense.created_at.desc())
    )
    return [_to_response(e) for e in result.scalars().all()]


@router.post(
    "",
    response_model=PersonalExpenseResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_personal_expense(
    body: PersonalExpenseCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    category = await db.get(Category, uuid.UUID(body.category_id))
    if category is None:
        raise HTTPException(status_code=404, detail="Category not found")
    if category.user_id is not None and category.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Category not available")

    expense = PersonalExpense(
        id=uuid.uuid4(),
        user_id=current_user.id,
        category_id=category.id,
        name=body.name,
        amount=body.amount,
        expense_date=body.expense_date,
    )
    db.add(expense)
    await db.flush()
    result = await db.execute(
        select(PersonalExpense)
        .where(PersonalExpense.id == expense.id)
        .options(selectinload(PersonalExpense.category))
    )
    return _to_response(result.scalar_one())


@router.patch("/{expense_id}", response_model=PersonalExpenseResponse)
async def update_personal_expense(
    expense_id: uuid.UUID,
    body: PersonalExpenseUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PersonalExpense)
        .where(
            PersonalExpense.id == expense_id,
            PersonalExpense.user_id == current_user.id,
        )
        .options(selectinload(PersonalExpense.category))
    )
    expense = result.scalar_one_or_none()
    if expense is None:
        raise HTTPException(status_code=404, detail="Expense not found")

    if body.category_id is not None:
        category = await db.get(Category, uuid.UUID(body.category_id))
        if category is None:
            raise HTTPException(status_code=404, detail="Category not found")
        if category.user_id is not None and category.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="Category not available")
        expense.category_id = category.id

    if body.name is not None:
        expense.name = body.name
    if body.amount is not None:
        expense.amount = body.amount
    if body.expense_date is not None:
        expense.expense_date = body.expense_date

    await db.flush()
    result = await db.execute(
        select(PersonalExpense)
        .where(PersonalExpense.id == expense.id)
        .options(selectinload(PersonalExpense.category))
    )
    return _to_response(result.scalar_one())


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_personal_expense(
    expense_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PersonalExpense).where(
            PersonalExpense.id == expense_id,
            PersonalExpense.user_id == current_user.id,
        )
    )
    expense = result.scalar_one_or_none()
    if expense is None:
        raise HTTPException(status_code=404, detail="Expense not found")
    await db.delete(expense)
