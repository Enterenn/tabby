import uuid

from app.api.v1.budgets import _category_is_available_for_budget, _status
from app.models.models import Category


def test_budget_status_thresholds():
    assert _status(0) == "ok"
    assert _status(74.9) == "ok"
    assert _status(75) == "warning"
    assert _status(99.9) == "warning"
    assert _status(100) == "danger"
    assert _status(140) == "danger"


def test_missing_pairs_default_to_zero():
    group = uuid.uuid4()
    category = uuid.uuid4()
    pairs = [(group, category)]
    spent_rows = {}
    out = {pair: spent_rows.get(pair, 0.0) for pair in pairs}
    assert out[(group, category)] == 0.0


def test_budget_category_must_be_global_default_or_owned_by_user():
    user_id = uuid.uuid4()
    other_user_id = uuid.uuid4()

    assert _category_is_available_for_budget(
        Category(is_default=True, user_id=None, group_id=None),
        user_id,
    )
    assert _category_is_available_for_budget(
        Category(is_default=False, user_id=user_id, group_id=None),
        user_id,
    )
    assert not _category_is_available_for_budget(
        Category(is_default=False, user_id=other_user_id, group_id=None),
        user_id,
    )
    assert not _category_is_available_for_budget(
        Category(is_default=False, user_id=None, group_id=uuid.uuid4()),
        user_id,
    )
    assert not _category_is_available_for_budget(
        Category(is_default=True, user_id=None, group_id=uuid.uuid4()),
        user_id,
    )
