from unittest.mock import MagicMock

from fastapi.testclient import TestClient

from app.api.v1.auth import login
from app.api.v1.stats import get_stats
from app.core.rate_limit import (
    _api_limit_storage,
    _client_ip,
    limiter,
)
from app.main import app


def _request(client_host: str = "10.0.0.8", **headers: str) -> MagicMock:
    request = MagicMock()
    request.headers.get.side_effect = lambda key, default=None: headers.get(key, default)
    request.client.host = client_host
    return request


def test_ignores_spoofed_headers_from_untrusted_peer(monkeypatch):
    monkeypatch.setattr(
        "app.core.rate_limit.settings.trusted_proxy_cidrs",
        "",
    )
    ip = _client_ip(_request(**{"X-Forwarded-For": "1.2.3.4", "CF-Connecting-IP": "9.9.9.9"}))
    assert ip == "10.0.0.8"


def test_uses_forwarded_client_from_trusted_npm(monkeypatch):
    monkeypatch.setattr(
        "app.core.rate_limit.settings.trusted_proxy_cidrs",
        "192.168.1.20/32",
    )
    ip = _client_ip(
        _request(
            client_host="192.168.1.20",
            **{
                "X-Real-IP": "192.168.1.20",
                "X-Forwarded-For": "203.0.113.10",
            }
        )
    )
    assert ip == "203.0.113.10"


def test_walks_forwarded_chain_from_nearest_proxy(monkeypatch):
    monkeypatch.setattr(
        "app.core.rate_limit.settings.trusted_proxy_cidrs",
        "192.168.1.20/32,198.51.100.0/24",
    )
    ip = _client_ip(
        _request(
            client_host="192.168.1.20",
            **{
                "X-Forwarded-For": (
                    "1.2.3.4, 203.0.113.10, 198.51.100.8"
                ),
            },
        )
    )
    assert ip == "203.0.113.10"


def test_malformed_forwarded_chain_falls_back_to_socket_peer(monkeypatch):
    monkeypatch.setattr(
        "app.core.rate_limit.settings.trusted_proxy_cidrs",
        "192.168.1.20/32",
    )
    ip = _client_ip(
        _request(
            client_host="192.168.1.20",
            **{
                "X-Forwarded-For": "not-an-ip",
                "X-Real-IP": "203.0.113.11",
            },
        )
    )
    assert ip == "192.168.1.20"


def test_global_limit_covers_routes_without_explicit_policy():
    login_key = f"{login.__module__}.{login.__name__}"
    assert login_key in limiter._route_limits
    assert all(limit.override_defaults for limit in limiter._route_limits[login_key])

    stats_key = f"{get_stats.__module__}.{get_stats.__name__}"
    assert stats_key not in limiter._route_limits
    assert stats_key not in limiter._exempt_routes


def test_global_limit_is_shared_across_api_routes():
    _api_limit_storage.reset()
    client = TestClient(app)
    try:
        for _ in range(119):
            assert client.get("/stats").status_code != 429
        avatar_response = client.get(
            "/uploads/avatars/missing.webp?exp=0&sig=invalid"
        )
        assert avatar_response.status_code == 403

        response = client.get("/stats")
        assert response.status_code == 429
        assert int(response.headers["Retry-After"]) >= 1
    finally:
        _api_limit_storage.reset()
