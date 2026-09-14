from decimal import Decimal
from uuid import uuid4

import pytest
from fastapi import HTTPException

from app.models.models import Category, GroupMember
from app.services.expense_service import (
    category_is_available,
    equal_split_amounts,
    money,
)


def test_money_rounds_to_cents():
    assert money("10.005") == Decimal("10.01")


def test_default_and_group_categories_are_available():
    group_id = uuid4()
    user_id = uuid4()
    # Catégorie par défaut globale — accessible à tous
    assert category_is_available(
        Category(is_default=True, user_id=None, group_id=None), group_id, user_id
    )
    # Catégorie créée pour ce groupe
    assert category_is_available(
        Category(is_default=False, user_id=None, group_id=group_id), group_id, user_id
    )
    # Catégorie d'un autre groupe — refusée
    assert not category_is_available(
        Category(is_default=False, user_id=None, group_id=uuid4()), group_id, user_id
    )


def test_personal_category_is_available_for_its_owner():
    group_id = uuid4()
    user_id = uuid4()
    other_user = uuid4()
    # Catégorie perso créée par cet utilisateur — acceptée
    assert category_is_available(
        Category(is_default=False, user_id=user_id, group_id=None), group_id, user_id
    )
    # Catégorie perso d'un autre utilisateur — refusée
    assert not category_is_available(
        Category(is_default=False, user_id=other_user, group_id=None), group_id, user_id
    )


def test_equal_split_assigns_rounding_remainder_to_payer():
    payer = uuid4()
    other = uuid4()
    members = [
        GroupMember(user_id=payer),
        GroupMember(user_id=other),
    ]

    result = equal_split_amounts(Decimal("10.00"), members, payer)

    assert result == [(payer, Decimal("5.00")), (other, Decimal("5.00"))]


def test_equal_split_rejects_empty_group():
    with pytest.raises(HTTPException):
        equal_split_amounts(Decimal("10.00"), [], uuid4())
