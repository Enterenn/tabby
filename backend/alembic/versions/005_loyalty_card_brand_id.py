"""Add brand_id to loyalty_card

Revision ID: 005
Revises: 004
Create Date: 2026-09-11
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

revision: str = "005"
down_revision: Union[str, None] = "004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("loyalty_card", sa.Column("brand_id", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("loyalty_card", "brand_id")
