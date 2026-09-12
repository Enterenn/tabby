import hashlib
import hmac
import re
import time
from pathlib import Path

from PIL import Image, ImageOps

from app.core.config import settings

UPLOADS_DIR = Path("uploads")
AVATARS_DIR = UPLOADS_DIR / "avatars"

ALLOWED_AVATAR_TYPES = {"image/jpeg", "image/png", "image/webp"}
ALLOWED_AVATAR_SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}
MAX_AVATAR_BYTES = 20 * 1024 * 1024
MIN_AVATAR_SIZE = 128
AVATAR_OUTPUT_SIZE = 256
AVATAR_URL_TTL_SECONDS = 3600
_AVATAR_FILENAME = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(webp|jpg)$",
    re.IGNORECASE,
)


def ensure_upload_dirs() -> None:
    AVATARS_DIR.mkdir(parents=True, exist_ok=True)


def avatar_path(user_id: str) -> Path:
    webp = AVATARS_DIR / f"{user_id}.webp"
    if webp.exists():
        return webp
    return AVATARS_DIR / f"{user_id}.jpg"


def _sign(message: str) -> str:
    return hmac.new(
        settings.secret_key.encode(),
        message.encode(),
        hashlib.sha256,
    ).hexdigest()


def avatar_public_url(user_id: str) -> str:
    path = avatar_path(user_id)
    version = int(path.stat().st_mtime) if path.exists() else 0
    name = path.name
    exp = int(time.time()) + AVATAR_URL_TTL_SECONDS
    sig = _sign(f"{name}:{exp}:{version}")
    return f"/uploads/avatars/{name}?v={version}&exp={exp}&sig={sig}"


def verify_avatar_signature(filename: str, exp: int, sig: str, version: int) -> bool:
    if not _AVATAR_FILENAME.fullmatch(filename):
        return False
    if exp < int(time.time()):
        return False
    expected = _sign(f"{filename}:{exp}:{version}")
    return hmac.compare_digest(expected, sig)


def delete_avatar_files(user_id: str) -> None:
    for leftover in AVATARS_DIR.glob(f"{user_id}.*"):
        leftover.unlink(missing_ok=True)


def apply_exif_orientation(image: Image.Image) -> Image.Image:
    """Les JPEG téléphone portent souvent une rotation EXIF (90° / 270°)."""
    oriented = ImageOps.exif_transpose(image)
    return oriented if oriented is not None else image


def process_avatar(image: Image.Image) -> Image.Image:
    image = apply_exif_orientation(image).convert("RGB")
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
