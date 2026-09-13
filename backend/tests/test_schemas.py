"""Validation Pydantic — montants et noms."""

from datetime import date
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.schemas.auth import RegisterRequest
from app.schemas.expense import ExpenseCreate
from app.schemas.group import GroupCreate, SettleRequest
from app.schemas.personal import PersonalExpenseUpdate
from app.schemas.recurring import RecurringExpenseCreate

_VALID_PASSWORD = "Abcdef1!"


def test_register_name_too_short():
    with pytest.raises(ValidationError):
        RegisterRequest(name="A", email="a@b.com", password=_VALID_PASSWORD)


def test_register_name_stripped():
    req = RegisterRequest(name="  Alice  ", email="a@b.com", password=_VALID_PASSWORD)
    assert req.name == "Alice"


def test_group_name_too_long():
    with pytest.raises(ValidationError):
        GroupCreate(name="x" * 51)


def test_expense_amount_must_be_positive():
    with pytest.raises(ValidationError):
        ExpenseCreate(
            name="Lunch",
            amount=0,
            category_id=uuid4(),
            paid_by=uuid4(),
            expense_date=date.today(),
        )


def test_settle_amount_must_be_positive():
    with pytest.raises(ValidationError):
        SettleRequest(
            from_user_id=str(uuid4()),
            to_user_id=str(uuid4()),
            amount=-1,
        )


def test_personal_expense_update_amount_must_be_positive():
    with pytest.raises(ValidationError):
        PersonalExpenseUpdate(amount=0)


def test_personal_expense_update_name_stripped():
    req = PersonalExpenseUpdate(name="  Pull  ")
    assert req.name == "Pull"


def test_recurring_amount_must_be_positive():
    with pytest.raises(ValidationError):
        RecurringExpenseCreate(
            name="Rent",
            amount=0,
            category_id=uuid4(),
            paid_by=uuid4(),
            day_of_period=1,
        )
