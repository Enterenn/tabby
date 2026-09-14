from typing import Annotated
import io
import uuid
from pathlib import Path

from fastapi import APIRouter, File, HTTPException, Request, UploadFile, status
from PIL import Image, UnidentifiedImageError
from sqlalchemy import select

from app.core.deps import CurrentUser, DbSession
from app.core.rate_limit import limiter
from app.core.refresh_tokens import (
    issue_token_pair,
    revoke_all_refresh_tokens,
    revoke_refresh_token,
    rotate_refresh_token,
)
from app.core.security import hash_password, verify_password
from app.core.uploads import (
    ALLOWED_AVATAR_SUFFIXES,
    ALLOWED_AVATAR_TYPES,
    MAX_AVATAR_BYTES,
    MIN_AVATAR_SIZE,
    apply_exif_orientation,
    avatar_public_url,
    process_avatar,
    save_avatar,
)
from app.models.models import User
from app.schemas.auth import (
    ChangePasswordRequest,
    LoginRequest,
    ProfileUpdate,
    RefreshRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])


def _user_response(user: User) -> UserResponse:
    return UserResponse(
        id=str(user.id),
        name=user.name,
        email=user.email,
        avatar_url=avatar_public_url(str(user.id)) if user.avatar_url else None,
    )


@router.get("/me", response_model=UserResponse)
async def me(current_user: CurrentUser):
    return _user_response(current_user)


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register(request: Request, body: RegisterRequest, db: DbSession):
    del request
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered")

    user = User(
        id=uuid.uuid4(),
        name=body.name,
        email=body.email,
        password_hash=hash_password(body.password),
    )
    db.add(user)
    await db.flush()
    return _user_response(user)


@router.post("/login", response_model=TokenResponse)
@limiter.limit("5/minute")
async def login(request: Request, body: LoginRequest, db: DbSession):
    del request
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    return await issue_token_pair(db, user.id)


@router.post("/refresh", response_model=TokenResponse)
@limiter.limit("10/minute")
async def refresh(request: Request, body: RefreshRequest, db: DbSession):
    del request
    return await rotate_refresh_token(db, body.refresh_token)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(body: RefreshRequest, db: DbSession):
    await revoke_refresh_token(db, body.refresh_token)


@router.patch("/me", response_model=UserResponse)
async def update_profile(
    body: ProfileUpdate,
    current_user: CurrentUser,
    db: DbSession,
):
    if body.name is not None:
        current_user.name = body.name
    if body.email is not None and body.email != current_user.email:
        existing = await db.execute(select(User).where(User.email == body.email))
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )
        current_user.email = body.email
    await db.flush()
    return _user_response(current_user)


@router.post("/change-password", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("5/minute")
async def change_password(
    request: Request,
    body: ChangePasswordRequest,
    current_user: CurrentUser,
    db: DbSession,
):
    del request
    if not verify_password(body.current_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )
    current_user.password_hash = hash_password(body.new_password)
    await revoke_all_refresh_tokens(db, current_user.id)
    await db.flush()


@router.post("/me/avatar", response_model=UserResponse)
@limiter.limit("10/minute")
async def upload_avatar(
    request: Request,
    file: Annotated[UploadFile, File()],
    current_user: CurrentUser,
    db: DbSession,
):
    del request
    content_type = (file.content_type or "").lower()
    suffix = Path(file.filename or "").suffix.lower()
    if content_type not in ALLOWED_AVATAR_TYPES and suffix not in ALLOWED_AVATAR_SUFFIXES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be JPEG, PNG or WebP",
        )

    data = await file.read()
    if len(data) > MAX_AVATAR_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File exceeds 20 MB",
        )

    try:
        image = Image.open(io.BytesIO(data))
        image.load()
        image = apply_exif_orientation(image)
    except (UnidentifiedImageError, OSError):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be JPEG, PNG or WebP",
        ) from None

    width, height = image.size
    if width < MIN_AVATAR_SIZE or height < MIN_AVATAR_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image must be at least 128x128",
        )

    try:
        processed = process_avatar(image)
    except ValueError as exc:
        image.close()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    image.close()
    save_avatar(str(current_user.id), processed)
    processed.close()

    current_user.avatar_url = f"/uploads/avatars/{current_user.id}.webp"
    await db.flush()
    return _user_response(current_user)
