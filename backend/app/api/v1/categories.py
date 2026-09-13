import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import Category, User
from app.schemas.expense import CategoryCreate, CategoryResponse, CategoryUpdate

router = APIRouter(prefix="/categories", tags=["categories"])


def _to_response(c: Category) -> CategoryResponse:
    return CategoryResponse(
        id=str(c.id),
        name=c.name,
        icon=c.icon,
        color=c.color,
        is_default=c.is_default,
        sort_order=c.sort_order,
    )


@router.get("", response_model=list[CategoryResponse])
async def list_categories(
    group_id: Optional[uuid.UUID] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Défauts globaux + tes catégories. group_id est ignoré (héritage)."""
    del group_id
    q = select(Category).where(
        or_(
            Category.is_default.is_(True) & Category.user_id.is_(None),
            Category.user_id == current_user.id,
        )
    )
    result = await db.execute(q.order_by(Category.sort_order, Category.name))
    return [_to_response(c) for c in result.scalars().all()]


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    body: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    color = body.color if body.color.startswith("#") else f"#{body.color}"
    result = await db.execute(
        select(Category).where(Category.user_id == current_user.id)
    )
    existing = result.scalars().all()
    sort_order = max((c.sort_order for c in existing), default=99) + 1

    category = Category(
        id=uuid.uuid4(),
        group_id=None,
        user_id=current_user.id,
        name=body.name.strip(),
        icon=body.icon,
        color=color,
        is_default=False,
        sort_order=sort_order,
    )
    db.add(category)
    await db.flush()
    return _to_response(category)


@router.patch("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: uuid.UUID,
    body: CategoryUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    category = await db.get(Category, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    if category.is_default or category.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot update this category",
        )
    if body.name is not None:
        category.name = body.name
    if body.icon is not None:
        category.icon = body.icon
    if body.color is not None:
        color = body.color if body.color.startswith("#") else f"#{body.color}"
        category.color = color
    await db.flush()
    return _to_response(category)


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    category = await db.get(Category, category_id)
    if category is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")
    if category.is_default or category.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete this category",
        )
    await db.delete(category)
