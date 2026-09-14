"""Idempotency guarantees for recurring expense generation."""


import os

import pytest
from sqlalchemy import Table, inspect
from sqlalchemy.ext.asyncio import create_async_engine

from app.models.models import Expense, PersonalExpense


def test_recurring_unique_constraints_are_declared():
    expense_table = Expense.__table__
    personal_table = PersonalExpense.__table__
    assert isinstance(expense_table, Table)
    assert isinstance(personal_table, Table)

    expense_constraints = {
        constraint.name for constraint in expense_table.constraints if constraint.name
    }
    personal_constraints = {
        constraint.name
        for constraint in personal_table.constraints
        if constraint.name
    }

    assert "uq_expense_recurring_source_date" in expense_constraints
    assert "uq_personal_expense_recurring_source_date" in personal_constraints


@pytest.mark.asyncio
async def test_postgres_migration_is_applicable_when_database_is_available():
    database_url = os.getenv("TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("TEST_DATABASE_URL is not configured")

    engine = create_async_engine(database_url)
    try:
        async with engine.begin() as connection:
            tables = await connection.run_sync(
                lambda sync_connection: inspect(sync_connection).get_table_names()
            )
        assert "expense" in tables
        assert "personal_expense" in tables
    finally:
        await engine.dispose()
