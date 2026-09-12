from pathlib import Path

UPLOADS_DIR = Path("uploads")
AVATARS_DIR = UPLOADS_DIR / "avatars"

ALLOWED_AVATAR_TYPES = {"image/jpeg", "image/png"}
ALLOWED_AVATAR_SUFFIXES = {".jpg", ".jpeg", ".png"}
MAX_AVATAR_BYTES = 5 * 1024 * 1024
MIN_AVATAR_SIZE = 128
MAX_AVATAR_SIZE = 1024


def ensure_upload_dirs() -> None:
    AVATARS_DIR.mkdir(parents=True, exist_ok=True)


def avatar_path(user_id: str) -> Path:
    return AVATARS_DIR / f"{user_id}.jpg"


def avatar_public_url(user_id: str) -> str:
    path = avatar_path(user_id)
    version = int(path.stat().st_mtime) if path.exists() else 0
    return f"/uploads/avatars/{user_id}.jpg?v={version}"
