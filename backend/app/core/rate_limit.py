from fastapi import Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from starlette.responses import Response

from app.core.config import settings


def _client_ip(request: Request) -> str:
    """Client IP for rate limits.

    Proxy headers are trusted only when PUBLIC_ORIGIN is set (public deploy
    behind Cloudflare / NPM). Direct :8000 access then uses the socket IP,
    so a forged X-Forwarded-For cannot bypass limits.
    """
    if settings.public_origin.strip():
        cf_ip = request.headers.get("CF-Connecting-IP")
        if cf_ip:
            return cf_ip.strip()
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip.strip()
        forwarded = request.headers.get("X-Forwarded-For")
        if forwarded:
            return forwarded.split(",", 1)[0].strip()
    return get_remote_address(request)


limiter = Limiter(key_func=_client_ip, default_limits=[])


def rate_limit_exceeded_handler(request: Request, exc: Exception) -> Response:
    """Starlette-compatible wrapper: ExceptionHandler is contravariant on exc."""
    if not isinstance(exc, RateLimitExceeded):
        raise exc
    return _rate_limit_exceeded_handler(request, exc)


__all__ = ["limiter", "RateLimitExceeded", "rate_limit_exceeded_handler"]
