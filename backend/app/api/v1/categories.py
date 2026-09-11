import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import Category, GroupMember, User
from app.schemas.expense import CategoryCreate, CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    group_id: Optional[uuid.UUID] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Catégories globales par défaut + catégories custom du groupe (si group_id fourni).
    """
    if group_id:
        q = select(Category).where(
            (Category.group_id.is_(None) & Category.is_default.is_(True))
            | (Category.group_id == group_id)
        )
    else:
        q = select(Category).where(
            Category.group_id.is_(None) & Category.is_default.is_(True)
        )

    result = await db.execute(q.order_by(Category.sort_order, Category.name))
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


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    body: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Crée une catégorie custom pour un groupe dont l'utilisateur est membre."""
    membership = await db.get(GroupMember, (body.group_id, current_user.id))
    if membership is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member of this group")

    # Normaliser la couleur (ajouter # si absent)
    color = body.color if body.color.startswith("#") else f"#{body.color}"

    # sort_order = après les catégories existantes du groupe
    result = await db.execute(
        select(Category).where(Category.group_id == body.group_id)
    )
    existing = result.scalars().all()
    sort_order = max((c.sort_order for c in existing), default=99) + 1

    category = Category(
        id=uuid.uuid4(),
        group_id=body.group_id,
        name=body.name.strip(),
        icon=body.icon,
        color=color,
        is_default=False,
        sort_order=sort_order,
    )
    db.add(category)
    await db.flush()

    return CategoryResponse(
        id=str(category.id),
        name=category.name,
        icon=category.icon,
        color=category.color,
        is_default=category.is_default,
        sort_order=category.sort_order,
    )


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Supprime une catégorie custom (impossible sur les catégories par défaut)."""
    category = await db.get(Category, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    if category.is_default or category.group_id is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot delete default categories")

    # Vérifier que l'utilisateur est membre du groupe
    membership = await db.get(GroupMember, (category.group_id, current_user.id))
    if membership is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member of this group")

    await db.delete(category)
