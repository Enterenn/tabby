import uuid
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastapi import HTTPException

from app.core import refresh_tokens
from app.core.security import create_refresh_token, decode_token
from app.models.models import RefreshToken, User


class _ScalarResult:
    def __init__(self, value):
        self._value = value

    def scalar_one_or_none(self):
        return self._value


class _RowResult:
    def __init__(self, value):
        self._value = value

    def one_or_none(self):
        return self._value


@pytest.mark.asyncio
async def test_new_session_uses_its_first_token_as_family_id():
    db = AsyncMock()
    db.add = MagicMock()
    user_id = uuid.uuid4()

    response = await refresh_tokens.issue_token_pair(db, user_id)

    stored = db.add.call_args.args[0]
    assert isinstance(stored, RefreshToken)
    assert stored.family_id == stored.jti
    assert decode_token(response.refresh_token)["jti"] == str(stored.jti)


@pytest.mark.asyncio
async def test_rotation_atomically_consumes_token_and_keeps_family():
    db = AsyncMock()
    db.add = MagicMock()
    user_id = uuid.uuid4()
    old_jti = uuid.uuid4()
    family_id = uuid.uuid4()
    db.execute.return_value = _ScalarResult(family_id)
    db.get.return_value = SimpleNamespace(id=user_id)

    response = await refresh_tokens.rotate_refresh_token(
        db,
        create_refresh_token(str(user_id), str(old_jti)),
    )

    db.execute.assert_awaited_once()
    db.get.assert_awaited_once_with(User, user_id)
    stored = db.add.call_args.args[0]
    assert isinstance(stored, RefreshToken)
    assert stored.family_id == family_id
    assert stored.jti != old_jti
    assert decode_token(response.refresh_token)["jti"] == str(stored.jti)


@pytest.mark.asyncio
async def test_reusing_rotated_token_revokes_family_and_persists(monkeypatch):
    db = AsyncMock()
    user_id = uuid.uuid4()
    old_jti = uuid.uuid4()
    family_id = uuid.uuid4()
    replacement_jti = uuid.uuid4()
    db.execute.side_effect = [
        _ScalarResult(None),
        _RowResult(
            SimpleNamespace(
                user_id=user_id,
                family_id=family_id,
                replaced_by_jti=replacement_jti,
            )
        ),
    ]
    revoke_family = AsyncMock()
    monkeypatch.setattr(
        refresh_tokens,
        "revoke_refresh_token_family",
        revoke_family,
    )

    with pytest.raises(HTTPException) as exc:
        await refresh_tokens.rotate_refresh_token(
            db,
            create_refresh_token(str(user_id), str(old_jti)),
        )

    assert exc.value.status_code == 401
    revoke_family.assert_awaited_once_with(db, family_id)
    db.commit.assert_awaited_once()


@pytest.mark.asyncio
async def test_logged_out_token_does_not_revoke_other_sessions(monkeypatch):
    db = AsyncMock()
    user_id = uuid.uuid4()
    old_jti = uuid.uuid4()
    family_id = uuid.uuid4()
    db.execute.side_effect = [
        _ScalarResult(None),
        _RowResult(
            SimpleNamespace(
                user_id=user_id,
                family_id=family_id,
                replaced_by_jti=None,
            )
        ),
    ]
    revoke_family = AsyncMock()
    monkeypatch.setattr(
        refresh_tokens,
        "revoke_refresh_token_family",
        revoke_family,
    )

    with pytest.raises(HTTPException) as exc:
        await refresh_tokens.rotate_refresh_token(
            db,
            create_refresh_token(str(user_id), str(old_jti)),
        )

    assert exc.value.status_code == 401
    revoke_family.assert_not_awaited()
    db.commit.assert_not_awaited()
