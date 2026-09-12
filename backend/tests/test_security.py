import pytest
from pydantic import ValidationError

from app.core.security import (
    PASSWORD_POLICY_ERROR,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    validate_password_strength,
    verify_password,
)
from app.schemas.auth import RegisterRequest
from app.api.v1.groups import _INVITE_ALPHABET, _invite_code


def test_password_policy_rejects_weak_values():
    with pytest.raises(ValueError, match="8 characters"):
        validate_password_strength("short")


def test_register_request_uses_password_policy():
    with pytest.raises(ValidationError):
        RegisterRequest(name="Alice", email="a@b.com", password="password")
    assert PASSWORD_POLICY_ERROR


def test_password_hash_roundtrip():
    hashed = hash_password("Abcdef1!")
    assert verify_password("Abcdef1!", hashed)
    assert not verify_password("wrong-pass!", hashed)


def test_access_token_type():
    token = create_access_token("user-1")
    payload = decode_token(token)
    assert payload["sub"] == "user-1"
    assert payload["type"] == "access"


def test_refresh_token_has_jti():
    token = create_refresh_token("user-1", jti="jti-123")
    payload = decode_token(token)
    assert payload["type"] == "refresh"
    assert payload["jti"] == "jti-123"


def test_invite_code_is_eight_alphanumeric():
    code = _invite_code()
    assert len(code) == 8
    assert all(ch in _INVITE_ALPHABET for ch in code)
