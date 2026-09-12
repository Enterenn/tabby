from pathlib import Path

from PIL import Image

UPLOADS_DIR = Path("uploads")
AVATARS_DIR = UPLOADS_DIR / "avatars"

ALLOWED_AVATAR_TYPES = {"image/jpeg", "image/png", "image/webp"}
ALLOWED_AVATAR_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}
MAX_AVATAR_BYTES = 20 * 1024 * 1024
MIN_AVATAR_SIZE = 128
AVATAR_OUTPUT_SIZE = 256


def ensure_upload_dirs() -> None:
    AVATARS_DIR.mkdir(parents=True, exist_ok=True)


def avatar_path(user_id: str) -> Path:
    webp = AVATARS_DIR / f"{user_id}.webp"
    if webp.exists():
        return webp
    return AVATARS_DIR / f"{user_id}.jpg"


def avatar_public_url(user_id: str) -> str:
    path = avatar_path(user_id)
    version = int(path.stat().st_mtime) if path.exists() else 0
    return f"/uploads/avatars/{path.name}?v={version}"


def delete_avatar_files(user_id: str) -> None:
    for leftover in AVATARS_DIR.glob(f"{user_id}.*"):
        leftover.unlink(missing_ok=True)


def process_avatar(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    width, height = image.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    cropped = image.crop((left, top, left + side, top + side))
    return cropped.resize(
        (AVATAR_OUTPUT_SIZE, AVATAR_OUTPUT_SIZE),
        Image.Resampling.LANCZOS,
    )


def save_avatar(user_id: str, image: Image.Image) -> Path:
    ensure_upload_dirs()
    delete_avatar_files(user_id)
    dest = AVATARS_DIR / f"{user_id}.webp"
    image.save(dest, format="WEBP", quality=82, method=6)
    return dest
