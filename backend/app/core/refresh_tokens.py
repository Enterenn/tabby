"""Refresh-token persistence, rotation and revocation."""

import uuid
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from sqlalchemy import select, update
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
    return await _issue_token_pair(
        db,
        user_id=user_id,
        jti=jti,
        family_id=jti,
    )


async def _issue_token_pair(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    jti: uuid.UUID,
    family_id: uuid.UUID,
) -> TokenResponse:
    expires_at = _now() + timedelta(days=settings.refresh_token_expire_days)
    db.add(
        RefreshToken(
            jti=jti,
            family_id=family_id,
            user_id=user_id,
            expires_at=expires_at,
        )
    )
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
        user_id = uuid.UUID(str(payload["sub"]))
        jti = uuid.UUID(str(payload["jti"]))
    except (JWTError, ValueError, KeyError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )

    now = _now()
    replacement_jti = uuid.uuid4()
    consumed = await db.execute(
        update(RefreshToken)
        .where(
            RefreshToken.jti == jti,
            RefreshToken.user_id == user_id,
            RefreshToken.revoked_at.is_(None),
            RefreshToken.expires_at >= now,
        )
        .values(revoked_at=now, replaced_by_jti=replacement_jti)
        .returning(RefreshToken.family_id)
    )
    family_id = consumed.scalar_one_or_none()

    if family_id is None:
        token_row = await db.execute(
            select(
                RefreshToken.user_id,
                RefreshToken.family_id,
                RefreshToken.replaced_by_jti,
            ).where(RefreshToken.jti == jti)
        )
        existing = token_row.one_or_none()
        if (
            existing is not None
            and existing.user_id == user_id
            and existing.replaced_by_jti is not None
        ):
            await revoke_refresh_token_family(db, existing.family_id)
            # The response must remain unauthorized while the compromise
            # revocation survives get_db's exception rollback.
            await db.commit()
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

    return await _issue_token_pair(
        db,
        user_id=user_id,
        jti=replacement_jti,
        family_id=family_id,
    )


async def revoke_refresh_token(db: AsyncSession, refresh_token: str) -> None:
    try:
        payload = decode_token(refresh_token)
        if payload.get("type") != "refresh":
            return
        jti = uuid.UUID(str(payload["jti"]))
    except (JWTError, ValueError, KeyError):
        return
    row = await db.get(RefreshToken, jti)
    if row is not None and row.revoked_at is None:
        row.revoked_at = _now()
        await db.flush()


async def purge_expired_refresh_tokens(db: AsyncSession) -> None:
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.expires_at < _now(), RefreshToken.revoked_at.is_(None))
        .values(revoked_at=_now())
    )


async def revoke_all_refresh_tokens(db: AsyncSession, user_id: uuid.UUID) -> None:
    await db.execute(
        update(RefreshToken)
        .where(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=_now())
    )


async def revoke_refresh_token_family(
    db: AsyncSession,
    family_id: uuid.UUID,
) -> None:
    await db.execute(
        update(RefreshToken)
        .where(
            RefreshToken.family_id == family_id,
            RefreshToken.revoked_at.is_(None),
        )
        .values(revoked_at=_now())
    )
