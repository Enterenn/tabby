"""CRUD pour les cartes de fidélité."""

import uuid

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select

from app.core.deps import CurrentUser, DbSession
from app.models.models import LoyaltyCard

router = APIRouter(prefix="/loyalty-cards", tags=["loyalty-cards"])


# ─── Schemas ──────────────────────────────────────────────────────────────────

class LoyaltyCardCreate(BaseModel):
    brand_name: str
    brand_id: str | None = None
    code_type: str  # 'barcode' | 'qrcode'
    code_value: str
    color: str | None = None


class LoyaltyCardUpdate(BaseModel):
    brand_name: str | None = None
    brand_id: str | None = None
    color: str | None = None
    code_type: str | None = None
    code_value: str | None = None


class LoyaltyCardResponse(BaseModel):
    id: str
    brand_name: str
    brand_id: str | None
    code_type: str
    code_value: str
    color: str | None
    sort_order: int

    model_config = {"from_attributes": True}


class ReorderItem(BaseModel):
    id: str
    sort_order: int


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _to_response(c: LoyaltyCard) -> LoyaltyCardResponse:
    return LoyaltyCardResponse(
        id=str(c.id),
        brand_name=c.brand_name,
        brand_id=c.brand_id,
        code_type=c.code_type,
        code_value=c.code_value,
        color=c.color,
        sort_order=c.sort_order,
    )


# ─── Endpoints ────────────────────────────────────────────────────────────────

@router.get("", response_model=list[LoyaltyCardResponse])
async def list_cards(
    current_user: CurrentUser,
    db: DbSession,
):
    result = await db.execute(
        select(LoyaltyCard)
        .where(LoyaltyCard.user_id == current_user.id)
        .order_by(LoyaltyCard.sort_order, LoyaltyCard.brand_name)
    )
    return [_to_response(c) for c in result.scalars().all()]


@router.post("", response_model=LoyaltyCardResponse, status_code=status.HTTP_201_CREATED)
async def create_card(
    body: LoyaltyCardCreate,
    current_user: CurrentUser,
    db: DbSession,
):
    if body.code_type not in ("barcode", "qrcode"):
        raise HTTPException(status_code=400, detail="code_type must be 'barcode' or 'qrcode'")

    # sort_order = dernier + 1
    result = await db.execute(
        select(LoyaltyCard)
        .where(LoyaltyCard.user_id == current_user.id)
        .order_by(LoyaltyCard.sort_order.desc())
        .limit(1)
    )
    last = result.scalar_one_or_none()
    sort_order = (last.sort_order + 1) if last else 0

    card = LoyaltyCard(
        id=uuid.uuid4(),
        user_id=current_user.id,
        brand_name=body.brand_name.strip(),
        brand_id=body.brand_id,
        code_type=body.code_type,
        # strip() retire seulement les bords — les espaces internes
        # (BK / McDo : « 8DD C9Y D9L ») font partie du code.
        code_value=body.code_value.strip(),
        color=body.color,
        sort_order=sort_order,
    )
    db.add(card)
    await db.flush()
    return _to_response(card)


@router.patch("/{card_id}", response_model=LoyaltyCardResponse)
async def update_card(
    card_id: uuid.UUID,
    body: LoyaltyCardUpdate,
    current_user: CurrentUser,
    db: DbSession,
):
    card = await db.get(LoyaltyCard, card_id)
    if card is None or card.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Card not found")
    fields = body.model_fields_set
    if "brand_name" in fields and body.brand_name is not None:
        card.brand_name = body.brand_name.strip()
    if "brand_id" in fields:
        card.brand_id = body.brand_id
    if "color" in fields:
        card.color = body.color
    if "code_type" in fields and body.code_type is not None:
        if body.code_type not in ("barcode", "qrcode"):
            raise HTTPException(
                status_code=400, detail="code_type must be 'barcode' or 'qrcode'"
            )
        card.code_type = body.code_type
    if "code_value" in fields and body.code_value is not None:
        # Espaces internes conservés (BK / McDo).
        card.code_value = body.code_value.strip()
    await db.flush()
    return _to_response(card)


@router.delete("/{card_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_card(
    card_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
):
    card = await db.get(LoyaltyCard, card_id)
    if card is None or card.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Card not found")
    await db.delete(card)


@router.put("/reorder", status_code=status.HTTP_204_NO_CONTENT)
async def reorder_cards(
    items: list[ReorderItem],
    current_user: CurrentUser,
    db: DbSession,
):
    for item in items:
        card = await db.get(LoyaltyCard, uuid.UUID(item.id))
        if card and card.user_id == current_user.id:
            card.sort_order = item.sort_order
