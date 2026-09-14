"""Enregistrement / suppression des tokens FCM."""

import uuid

from fastapi import APIRouter, status
from pydantic import BaseModel
from sqlalchemy import select

from app.core.deps import CurrentUser, DbSession
from app.models.models import DeviceToken

router = APIRouter(prefix="/devices", tags=["devices"])


class TokenBody(BaseModel):
    token: str
    platform: str = "android"


@router.post("/token", status_code=status.HTTP_204_NO_CONTENT)
async def register_token(
    body: TokenBody,
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(DeviceToken).where(DeviceToken.token == body.token)
    )
    existing = result.scalar_one_or_none()
    if existing:
        # Réassigner le token au user actuel (changement de compte)
        existing.user_id = current_user.id
    else:
        db.add(
            DeviceToken(
                id=uuid.uuid4(),
                user_id=current_user.id,
                token=body.token,
                platform=body.platform,
            )
        )


@router.delete("/token", status_code=status.HTTP_204_NO_CONTENT)
async def delete_token(
    body: TokenBody,
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(DeviceToken).where(
            DeviceToken.token == body.token,
            DeviceToken.user_id == current_user.id,
        )
    )
    token = result.scalar_one_or_none()
    if token:
        await db.delete(token)
