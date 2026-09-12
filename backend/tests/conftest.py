import os

# Force a safe process env so importing Settings() does not read a production .env.
os.environ["SECRET_KEY"] = "unit-test-secret-key-not-for-production-use"
os.environ["DATABASE_URL"] = (
    "postgresql+asyncpg://tabby:unit-test-password@localhost:5432/tabby"
)
os.environ["DEBUG"] = "true"
