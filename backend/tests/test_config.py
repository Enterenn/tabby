import pytest

from app.core.config import Settings

_SECRET = "unit-test-secret-key-not-for-production-use"
_SAFE_URL = "postgresql+asyncpg://tabby:strong-pass@db:5432/tabby"


def test_default_access_token_lifetime_is_fifteen_minutes():
    assert Settings.model_fields["access_token_expire_minutes"].default == 15


def test_rejects_short_secret_key():
    with pytest.raises(RuntimeError, match="SECRET_KEY"):
        Settings(secret_key="too-short", database_url=_SAFE_URL, debug=True)


def test_rejects_empty_database_url():
    with pytest.raises(RuntimeError, match="DATABASE_URL"):
        Settings(secret_key=_SECRET, database_url="", debug=True)


def test_rejects_default_postgres_password_in_production():
    with pytest.raises(RuntimeError, match="Postgres password"):
        Settings(
            secret_key=_SECRET,
            database_url="postgresql+asyncpg://tabby:tabby@db:5432/tabby",
            debug=False,
        )


def test_rejects_empty_postgres_password_in_production():
    with pytest.raises(RuntimeError, match="Postgres password"):
        Settings(
            secret_key=_SECRET,
            database_url="postgresql+asyncpg://tabby:@db:5432/tabby",
            debug=False,
        )


def test_allows_default_postgres_password_in_debug():
    settings = Settings(
        secret_key=_SECRET,
        database_url="postgresql+asyncpg://tabby:tabby@localhost:5432/tabby",
        debug=True,
    )
    assert "tabby:tabby@" in settings.database_url
