import uuid

import pytest
from fastapi import HTTPException

from app.api.v1.stats import _resolve_group_filter


def test_stats_without_group_uses_all_accessible_groups():
    groups = [uuid.uuid4(), uuid.uuid4()]

    assert _resolve_group_filter(None, groups) == groups


def test_stats_with_accessible_group_limits_the_scope():
    selected = uuid.uuid4()

    assert _resolve_group_filter(selected, [selected, uuid.uuid4()]) == [selected]


def test_stats_rejects_inaccessible_group():
    with pytest.raises(HTTPException) as exc:
        _resolve_group_filter(uuid.uuid4(), [uuid.uuid4()])

    assert exc.value.status_code == 403
