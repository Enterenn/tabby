import time
from functools import lru_cache
from ipaddress import (
    IPv4Address,
    IPv4Network,
    IPv6Address,
    IPv6Network,
    ip_address,
    ip_network,
)
from math import ceil

from fastapi import Request
from limits import parse
from limits.storage import MemoryStorage
from limits.strategies import FixedWindowRateLimiter
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import JSONResponse, Response

from app.core.config import settings


IPAddress = IPv4Address | IPv6Address
IPNetwork = IPv4Network | IPv6Network


@lru_cache(maxsize=8)
def _trusted_proxy_networks(raw_cidrs: str) -> tuple[IPNetwork, ...]:
    return tuple(
        ip_network(cidr.strip(), strict=False)
        for cidr in raw_cidrs.split(",")
        if cidr.strip()
    )


def _parsed_ip(value: str) -> IPAddress | None:
    try:
        return ip_address(value.strip())
    except ValueError:
        return None


def _is_trusted(address: IPAddress, networks: tuple[IPNetwork, ...]) -> bool:
    return any(address in network for network in networks)


def _client_ip(request: Request) -> str:
    """Client IP for rate limits.

    Forwarding headers are accepted only from explicitly trusted proxy
    networks. The X-Forwarded-For chain is walked from right to left so a
    client cannot select its limiter key by prepending a spoofed address.
    """
    peer = get_remote_address(request)
    peer_ip = _parsed_ip(peer)
    networks = _trusted_proxy_networks(settings.trusted_proxy_cidrs)
    if peer_ip is None or not _is_trusted(peer_ip, networks):
        return peer

    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        chain = [_parsed_ip(item) for item in forwarded.split(",")]
        if not all(address is not None for address in chain):
            return peer
        valid_chain = [address for address in chain if address is not None]
        for address in reversed([*valid_chain, peer_ip]):
            if not _is_trusted(address, networks):
                return str(address)
        if valid_chain:
            return str(valid_chain[0])

    real_ip = _parsed_ip(request.headers.get("X-Real-IP", ""))
    return str(real_ip) if real_ip is not None else peer


_api_limit = parse(settings.api_rate_limit)
_api_limit_storage = MemoryStorage()
_api_limiter = FixedWindowRateLimiter(_api_limit_storage)


class ApiRateLimitMiddleware(BaseHTTPMiddleware):
    """Shared per-client ceiling across every API route."""

    async def dispatch(
        self,
        request: Request,
        call_next: RequestResponseEndpoint,
    ) -> Response:
        client_ip = _client_ip(request)
        if not _api_limiter.hit(_api_limit, client_ip):
            reset_at, _ = _api_limiter.get_window_stats(_api_limit, client_ip)
            retry_after = max(1, ceil(reset_at - time.time()))
            return JSONResponse(
                status_code=429,
                content={"detail": "Too many requests"},
                headers={"Retry-After": str(retry_after)},
            )
        return await call_next(request)


limiter = Limiter(key_func=_client_ip, default_limits=[])


def rate_limit_exceeded_handler(request: Request, exc: Exception) -> Response:
    """Starlette-compatible wrapper: ExceptionHandler is contravariant on exc."""
    if not isinstance(exc, RateLimitExceeded):
        raise exc
    return _rate_limit_exceeded_handler(request, exc)


__all__ = [
    "ApiRateLimitMiddleware",
    "limiter",
    "RateLimitExceeded",
    "rate_limit_exceeded_handler",
]
