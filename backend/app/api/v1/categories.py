import uuid
from typing import Optional

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import Category, GroupMember, User
from app.schemas.expense import CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    group_id: Optional[uuid.UUID] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Retourne les catégories disponibles :
    - catégories globales par défaut (group_id IS NULL, is_default = true)
    - si group_id fourni : + catégories spécifiques à ce groupe
    """
    q = select(Category).where(
        (Category.group_id.is_(None)) & (Category.is_default.is_(True))
    )
    if group_id:
        q = select(Category).where(
            (Category.group_id.is_(None) & Category.is_default.is_(True))
            | (Category.group_id == group_id)
        )

    result = await db.execute(q.order_by(Category.sort_order))
    categories = result.scalars().all()
    return [
        CategoryResponse(
            id=str(c.id),
            name=c.name,
            icon=c.icon,
            color=c.color,
            is_default=c.is_default,
            sort_order=c.sort_order,
        )
        for c in categories
    ]
