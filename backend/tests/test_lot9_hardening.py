from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock
from uuid import uuid4

import pytest
from PIL import Image

from app.core.refresh_tokens import purge_expired_refresh_tokens
from app.core.uploads import process_avatar


def test_avatar_rejects_oversized_pixel_dimensions():
    image = Image.new("RGB", (5000, 5000))
    with pytest.raises(ValueError, match="too many pixels"):
        process_avatar(image)


@pytest.mark.asyncio
async def test_purge_expired_refresh_tokens_updates_expired_rows():
    db = AsyncMock()
    await purge_expired_refresh_tokens(db)
    db.execute.assert_awaited_once()
