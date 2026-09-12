from unittest.mock import MagicMock

from app.core.rate_limit import _client_ip


def _request(**headers: str) -> MagicMock:
    request = MagicMock()
    request.headers.get.side_effect = lambda key, default=None: headers.get(key, default)
    request.client.host = "10.0.0.8"
    return request


def test_ignores_spoofed_forwarded_headers_without_public_origin(monkeypatch):
    monkeypatch.setattr(
        "app.core.rate_limit.settings.public_origin",
        "",
    )
    ip = _client_ip(_request(**{"X-Forwarded-For": "1.2.3.4", "CF-Connecting-IP": "9.9.9.9"}))
    assert ip == "10.0.0.8"


def test_prefers_cloudflare_connecting_ip(monkeypatch):
    monkeypatch.setattr(
        "app.core.rate_limit.settings.public_origin",
        "https://tabby.landrodie.fr",
    )
    ip = _client_ip(
        _request(
            **{
                "CF-Connecting-IP": "203.0.113.10",
                "X-Real-IP": "10.0.0.2",
                "X-Forwarded-For": "198.51.100.1, 10.0.0.2",
            }
        )
    )
    assert ip == "203.0.113.10"
