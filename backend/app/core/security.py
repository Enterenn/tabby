"""Password hashing and JWT utilities (PyJWT)."""

from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from jwt import InvalidTokenError as JWTError

from app.core.config import settings

PASSWORD_POLICY_ERROR = (
    "Password must be at least 8 characters and include an uppercase letter, a number and a symbol"
)


def validate_password_strength(password: str) -> str:
    has_upper = any(c.isupper() for c in password)
    has_digit = any(c.isdigit() for c in password)
    has_symbol = any(not c.isalnum() and not c.isspace() for c in password)
    if len(password) < 8 or not (has_upper and has_digit and has_symbol):
        raise ValueError(PASSWORD_POLICY_ERROR)
    return password


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


def _create_token(data: dict, expires_delta: timedelta) -> str:
    payload = data.copy()
    payload["exp"] = datetime.now(timezone.utc) + expires_delta
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def create_access_token(user_id: str) -> str:
    return _create_token(
        {"sub": user_id, "type": "access"},
        timedelta(minutes=settings.access_token_expire_minutes),
    )


def create_refresh_token(user_id: str, jti: str) -> str:
    return _create_token(
        {"sub": user_id, "type": "refresh", "jti": jti},
        timedelta(days=settings.refresh_token_expire_days),
    )


def decode_token(token: str) -> dict:
    """Raises JWTError if token is invalid or expired."""
    return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])


__all__ = [
    "JWTError",
    "PASSWORD_POLICY_ERROR",
    "create_access_token",
    "create_refresh_token",
    "decode_token",
    "hash_password",
    "validate_password_strength",
    "verify_password",
]
