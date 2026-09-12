from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_FORBIDDEN_SECRET_KEYS = {
    "change-me-in-production",
    "change-me-in-production-use-a-long-random-string",
}


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Database
    database_url: str = "postgresql+asyncpg://tabby:tabby@localhost:5432/tabby"

    # JWT — no insecure default: startup fails closed if missing/weak.
    secret_key: str = ""
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    # App
    app_name: str = "Tabby"
    debug: bool = False
    version: str = "0.1.0"

    @model_validator(mode="after")
    def secret_key_must_be_strong(self) -> "Settings":
        key = (self.secret_key or "").strip()
        if not key or key in _FORBIDDEN_SECRET_KEYS or len(key) < 32:
            raise RuntimeError(
                "SECRET_KEY is missing, shorter than 32 characters, or set to the "
                "insecure default. Generate one with: "
                'python -c "import secrets; print(secrets.token_urlsafe(48))"'
            )
        return self


settings = Settings()
