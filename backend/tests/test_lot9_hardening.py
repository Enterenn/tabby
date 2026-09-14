from unittest.mock import AsyncMock

import pytest
from PIL import Image

from app.core.refresh_tokens import purge_expired_refresh_tokens
from app.core.uploads import (
    MAX_AVATAR_PIXELS,
    process_avatar,
    validate_avatar_dimensions,
)


def test_avatar_rejects_oversized_pixel_dimensions():
    image = Image.new("RGB", (5000, 5000))
    with pytest.raises(ValueError, match="too many pixels"):
        process_avatar(image)


def test_avatar_header_dimensions_are_checked_without_loading_pixels():
    class HeaderOnlyImage:
        size = (MAX_AVATAR_PIXELS + 1, 1)

        def load(self):
            raise AssertionError("pixel data must not be loaded before validation")

    image = HeaderOnlyImage()
    with pytest.raises(ValueError, match="too many pixels"):
        validate_avatar_dimensions(image)  # type: ignore[arg-type]


@pytest.mark.asyncio
async def test_purge_expired_refresh_tokens_updates_expired_rows():
    db = AsyncMock()
    await purge_expired_refresh_tokens(db)
    db.execute.assert_awaited_once()
