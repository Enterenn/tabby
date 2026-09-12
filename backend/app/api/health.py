from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db

router = APIRouter()


@router.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    """Liveness + DB ping. Production returns a minimal payload."""
    await db.execute(text("SELECT 1"))
    if settings.debug:
        return {
            "status": "ok",
            "app": settings.app_name,
            "version": settings.version,
            "database": "connected",
        }
    return {"status": "ok"}
