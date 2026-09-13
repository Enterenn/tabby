"""Pending confirmation status on expenses (settlements).

Revision ID: 011
Revises: 010
Create Date: 2026-09-13
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "011"
down_revision: Union[str, None] = "010"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "expense",
        sa.Column(
            "status",
            sa.Text(),
            nullable=False,
            server_default="confirmed",
        ),
    )
    op.create_check_constraint(
        "ck_expense_status",
        "expense",
        "status IN ('confirmed', 'pending')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_expense_status", "expense", type_="check")
    op.drop_column("expense", "status")
