"""Refresh-token persistence, rotation and revocation."""

import uuid
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import (
    JWTError,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.models.models import RefreshToken, User
from app.schemas.auth import TokenResponse


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def issue_token_pair(db: AsyncSession, user_id: uuid.UUID) -> TokenResponse:
    jti = uuid.uuid4()
    expires_at = _now() + timedelta(days=settings.refresh_token_expire_days)
    db.add(RefreshToken(jti=jti, user_id=user_id, expires_at=expires_at))
    await db.flush()
    return TokenResponse(
        access_token=create_access_token(str(user_id)),
        refresh_token=create_refresh_token(str(user_id), str(jti)),
    )


async def rotate_refresh_token(db: AsyncSession, refresh_token: str) -> TokenResponse:
    try:
        payload = decode_token(refresh_token)
        if payload.get("type") != "refresh":
            raise JWTError("wrong token type")
        user_id = uuid.UUID(payload["sub"])
        jti = uuid.UUID(payload["jti"])
    except (JWTError, ValueError, KeyError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )

    row = await db.get(RefreshToken, jti)
    if (
        row is None
        or row.user_id != user_id
        or row.revoked_at is not None
        or row.expires_at < _now()
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )

    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    row.revoked_at = _now()
    await db.flush()
    return await issue_token_pair(db, user_id)


async def revoke_refresh_token(db: AsyncSession, refresh_token: str) -> None:
    try:
        payload = decode_token(refresh_token)
        if payload.get("type") != "refresh":
            return
        jti = uuid.UUID(payload["jti"])
    except (JWTError, ValueError, KeyError):
        return
    row = await db.get(RefreshToken, jti)
    if row is not None and row.revoked_at is None:
        row.revoked_at = _now()
        await db.flush()


async def purge_expired_refresh_tokens(db: AsyncSession) -> None:
    await db.execute(
        update(RefreshToken).where(RefreshToken.expires_at < _now()).values(revoked_at=_now())
    )


async def revoke_all_refresh_tokens(db: AsyncSession, user_id: uuid.UUID) -> None:
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=_now())
    )
