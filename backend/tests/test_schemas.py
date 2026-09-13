"""Validation Pydantic — montants et noms."""

from datetime import date
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.schemas.auth import RegisterRequest
from app.schemas.expense import CategoryUpdate, ExpenseCreate, ExpenseUpdate, SplitItem
from app.schemas.group import GroupCreate, SettleRequest
from app.schemas.personal import PersonalExpenseUpdate
from app.schemas.recurring import PersonalRecurringCreate, RecurringExpenseCreate

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


def test_personal_recurring_amount_must_be_positive():
    with pytest.raises(ValidationError):
        PersonalRecurringCreate(
            name="Netflix",
            amount=0,
            category_id=uuid4(),
            day_of_period=5,
        )


def test_expense_update_custom_splits_must_match_amount():
    user_id = uuid4()
    with pytest.raises(ValidationError):
        ExpenseUpdate(
            amount=20,
            split_type="custom",
            splits=[SplitItem(user_id=user_id, amount=10)],
        )


def test_expense_update_custom_splits_ok():
    user_id = uuid4()
    req = ExpenseUpdate(
        amount=20,
        split_type="custom",
        splits=[SplitItem(user_id=user_id, amount=20)],
    )
    assert req.splits is not None
    assert req.splits[0].amount == 20


def test_category_update_name_stripped():
    req = CategoryUpdate(name="  Vetements  ")
    assert req.name == "Vetements"


def test_category_update_empty_name_rejected():
    with pytest.raises(ValidationError):
        CategoryUpdate(name="   ")


def test_personal_recurring_day_must_be_in_month():
    with pytest.raises(ValidationError):
        PersonalRecurringCreate(
            name="Netflix",
            amount=13,
            category_id=uuid4(),
            day_of_period=31,
        )
