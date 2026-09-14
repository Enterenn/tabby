"""Detect refresh-token reuse with token families.

Revision ID: 013
Revises: 012
Create Date: 2026-09-14
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "013"
down_revision: Union[str, None] = "012"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "refresh_token",
        sa.Column("family_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.add_column(
        "refresh_token",
        sa.Column("replaced_by_jti", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.execute("UPDATE refresh_token SET family_id = jti")
    op.alter_column("refresh_token", "family_id", nullable=False)
    op.create_index(
        "ix_refresh_token_family_id",
        "refresh_token",
        ["family_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_refresh_token_family_id", table_name="refresh_token")
    op.drop_column("refresh_token", "replaced_by_jti")
    op.drop_column("refresh_token", "family_id")
