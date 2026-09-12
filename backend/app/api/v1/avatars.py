"""Signed avatar delivery — not a public StaticFiles mount."""

from fastapi import APIRouter, HTTPException, Query, status
from fastapi.responses import FileResponse

from app.core.uploads import AVATARS_DIR, avatar_path, verify_avatar_signature

router = APIRouter(tags=["avatars"])


@router.get("/uploads/avatars/{filename}")
async def serve_avatar(
    filename: str,
    exp: int = Query(...),
    sig: str = Query(...),
    v: int = Query(default=0),
):
    if not verify_avatar_signature(filename, exp, sig, v):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid or expired link")

    path = AVATARS_DIR / filename
    if not path.is_file() or path.resolve().parent != AVATARS_DIR.resolve():
        # Fallback jpg/webp via avatar_path if the signed name exists on disk.
        user_id = filename.rsplit(".", 1)[0]
        path = avatar_path(user_id)
    if not path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")

    media = "image/webp" if path.suffix.lower() == ".webp" else "image/jpeg"
    return FileResponse(path, media_type=media)
