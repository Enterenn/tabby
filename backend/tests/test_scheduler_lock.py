from unittest.mock import AsyncMock, MagicMock, patch

import pytest


@pytest.mark.asyncio
async def test_scheduler_skips_when_advisory_lock_is_taken():
    session = AsyncMock()
    lock_result = MagicMock()
    lock_result.scalar.return_value = False
    session.execute.return_value = lock_result
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session)
    factory.return_value.__aexit__ = AsyncMock(return_value=None)

    with patch("app.scheduler.async_session_factory", factory):
        from app.scheduler import generate_recurring_expenses

        assert await generate_recurring_expenses() == 0
    assert session.commit.await_count == 0
