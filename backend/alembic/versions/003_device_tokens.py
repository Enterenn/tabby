"""Table device_token pour les notifications push FCM

Revision ID: 003
Revises: 002
Create Date: 2026-09-11
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "device_token",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("user.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("token", sa.Text, nullable=False),
        sa.Column("platform", sa.Text, nullable=False, server_default="android"),
        sa.Column(
            "created_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.func.now(),
        ),
        sa.UniqueConstraint("token", name="uq_device_token_token"),
    )
    op.create_index("ix_device_token_user_id", "device_token", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_device_token_user_id", table_name="device_token")
    op.drop_table("device_token")
