from ipaddress import ip_network

from limits import parse
from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_FORBIDDEN_SECRET_KEYS = {
    "change-me-in-production",
    "change-me-in-production-use-a-long-random-string",
}


def _db_password(url: str) -> str:
    try:
        creds = url.split("://", 1)[1].split("@", 1)[0]
        if ":" not in creds:
            return ""
        return creds.split(":", 1)[1]
    except (IndexError, ValueError):
        return ""


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Database — no published default in production.
    database_url: str = ""

    # JWT — no insecure default: startup fails closed if missing/weak.
    secret_key: str = ""
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 30

    # App
    app_name: str = "Tabby"
    debug: bool = False
    version: str = "0.1.0"
    # Optional public HTTPS origin, e.g. https://tabby.example.com
    public_origin: str = ""
    # Per-client default for routes without a stricter explicit limit.
    api_rate_limit: str = "120/minute"
    # Comma-separated IPs/CIDRs allowed to supply forwarding headers.
    trusted_proxy_cidrs: str = ""

    @model_validator(mode="after")
    def secrets_must_be_strong(self) -> "Settings":
        key = (self.secret_key or "").strip()
        if not key or key in _FORBIDDEN_SECRET_KEYS or len(key) < 32:
            raise RuntimeError(
                "SECRET_KEY is missing, shorter than 32 characters, or set to the "
                "insecure default. Generate one with: "
                'python -c "import secrets; print(secrets.token_urlsafe(48))"'
            )

        url = (self.database_url or "").strip()
        if not url:
            raise RuntimeError(
                "DATABASE_URL is required. In Docker it is built from POSTGRES_PASSWORD."
            )
        if not self.debug and _db_password(url) in {"", "tabby"}:
            raise RuntimeError(
                "DATABASE_URL still uses the default or empty Postgres password. "
                "Set POSTGRES_PASSWORD to a long random value."
            )

        try:
            for cidr in self.trusted_proxy_cidrs.split(","):
                if cidr.strip():
                    ip_network(cidr.strip(), strict=False)
        except ValueError as exc:
            raise RuntimeError(
                f"TRUSTED_PROXY_CIDRS contains an invalid IP or network: {cidr.strip()}"
            ) from exc

        try:
            parse(self.api_rate_limit)
        except ValueError as exc:
            raise RuntimeError(
                "API_RATE_LIMIT must use a value such as '120/minute'"
            ) from exc
        return self


settings = Settings()
