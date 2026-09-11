from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from app.schemas.auth import UserResponse


class GroupCreate(BaseModel):
    name: str


class GroupUpdate(BaseModel):
    name: str


class MemberResponse(BaseModel):
    user: UserResponse
    joined_at: datetime

    model_config = {"from_attributes": True}


class GroupResponse(BaseModel):
    id: str
    name: str
    created_at: datetime
    members: list[MemberResponse] = []
    # Solde du groupe depuis le point de vue de l'utilisateur courant (calculé)
    balance: float = 0.0

    model_config = {"from_attributes": True}


class InviteResponse(BaseModel):
    code: str
    expires_at: datetime


class JoinRequest(BaseModel):
    code: str


class BalanceEntry(BaseModel):
    from_user_id: str
    from_user_name: str
    to_user_id: str
    to_user_name: str
    amount: float


class SettleRequest(BaseModel):
    from_user_id: str
    to_user_id: str
    amount: float
