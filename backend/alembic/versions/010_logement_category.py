"""Rename default category Loyer → Logement.

Revision ID: 010
Revises: 009
Create Date: 2026-09-13
"""

from typing import Sequence, Union

from alembic import op

revision: str = "010"
down_revision: Union[str, None] = "009"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        """
        UPDATE category
        SET name = 'Logement'
        WHERE is_default IS TRUE
          AND name = 'Loyer'
        """
    )


def downgrade() -> None:
    op.execute(
        """
        UPDATE category
        SET name = 'Loyer'
        WHERE is_default IS TRUE
          AND name = 'Logement'
        """
    )
