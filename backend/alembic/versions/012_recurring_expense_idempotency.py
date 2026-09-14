"""Protect generated recurring expenses from duplicates.

Revision ID: 012
Revises: 011
Create Date: 2026-09-14
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "012"
down_revision: Union[str, None] = "011"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index(
        "uq_expense_recurring_source_date",
        "expense",
        ["recurring_source_id", "expense_date"],
        unique=True,
        postgresql_where=sa.text("recurring_source_id IS NOT NULL"),
    )
    op.create_index(
        "ix_expense_group_date",
        "expense",
        ["group_id", "expense_date"],
    )
    op.create_index(
        "ix_expense_split_expense_id",
        "expense_split",
        ["expense_id"],
    )
    op.create_index(
        "ix_group_member_user_id",
        "group_member",
        ["user_id"],
    )
    op.create_index(
        "uq_personal_expense_recurring_source_date",
        "personal_expense",
        ["recurring_source_id", "expense_date"],
        unique=True,
        postgresql_where=sa.text("recurring_source_id IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_group_member_user_id", table_name="group_member")
    op.drop_index("ix_expense_split_expense_id", table_name="expense_split")
    op.drop_index("ix_expense_group_date", table_name="expense")
    op.drop_index(
        "uq_personal_expense_recurring_source_date",
        table_name="personal_expense",
    )
    op.drop_index("uq_expense_recurring_source_date", table_name="expense")
