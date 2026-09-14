"""Non-blocking notification dispatch for API mutations."""

from __future__ import annotations

import logging
from collections.abc import Callable, Sequence
from typing import Any

from fastapi import BackgroundTasks

logger = logging.getLogger(__name__)


def enqueue_notification(
    background_tasks: BackgroundTasks,
    sender: Callable[..., None],
    *,
    tokens: Sequence[str],
    **payload: Any,
) -> None:
    """Schedule an FCM send without extending the HTTP request lifetime."""
    if not tokens:
        return
    background_tasks.add_task(_send_safely, sender, tuple(tokens), payload)


def _send_safely(
    sender: Callable[..., None],
    tokens: tuple[str, ...],
    payload: dict[str, Any],
) -> None:
    try:
        sender(tokens=tokens, **payload)
    except Exception:
        logger.exception("[FCM] background notification failed")
