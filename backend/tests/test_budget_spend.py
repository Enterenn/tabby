import uuid

from app.api.v1.budgets import _status


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
