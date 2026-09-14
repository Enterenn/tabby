from fastapi import APIRouter
from sqlalchemy import text

from app.core.config import settings
from app.core.deps import DbSession

router = APIRouter()


@router.get("/health")
async def health_check(db: DbSession):
    """Liveness + DB ping. Production returns a minimal payload."""
    await db.execute(text("SELECT 1"))
    if settings.debug:
        return {
            "status": "ok",
            "app": settings.app_name,
            "version": settings.version,
            "database": "connected",
        }
    return {"status": "ok", "database": "connected"}
