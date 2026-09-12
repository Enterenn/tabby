"""Refresh tokens table + group.owner_id (idempotent).

Revision ID: 007
Revises: 006
Create Date: 2026-09-12
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql
from sqlalchemy import inspect

revision: str = "007"
down_revision: Union[str, None] = "006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    tables = inspector.get_table_names()

    if "refresh_token" not in tables:
        op.create_table(
            "refresh_token",
            sa.Column("jti", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column(
                "user_id",
                postgresql.UUID(as_uuid=True),
                sa.ForeignKey("user.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column("expires_at", sa.TIMESTAMP(timezone=True), nullable=False),
            sa.Column("revoked_at", sa.TIMESTAMP(timezone=True), nullable=True),
            sa.Column(
                "created_at",
                sa.TIMESTAMP(timezone=True),
                server_default=sa.func.now(),
            ),
        )
        op.create_index("ix_refresh_token_user_id", "refresh_token", ["user_id"])

    group_columns = {col["name"] for col in inspector.get_columns("group")}
    if "owner_id" not in group_columns:
        op.add_column(
            "group",
            sa.Column("owner_id", postgresql.UUID(as_uuid=True), nullable=True),
        )
        op.execute(
            """
            UPDATE "group" AS g
            SET owner_id = (
                SELECT gm.user_id
                FROM group_member AS gm
                WHERE gm.group_id = g.id
                ORDER BY gm.joined_at ASC
                LIMIT 1
            )
            WHERE owner_id IS NULL
            """
        )
        op.alter_column("group", "owner_id", nullable=False)
        op.create_foreign_key(
            "fk_group_owner_id_user",
            "group",
            "user",
            ["owner_id"],
            ["id"],
            ondelete="RESTRICT",
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = inspect(bind)
    group_columns = {col["name"] for col in inspector.get_columns("group")}
    if "owner_id" in group_columns:
        op.drop_constraint("fk_group_owner_id_user", "group", type_="foreignkey")
        op.drop_column("group", "owner_id")
    if "refresh_token" in inspector.get_table_names():
        op.drop_index("ix_refresh_token_user_id", table_name="refresh_token")
        op.drop_table("refresh_token")
