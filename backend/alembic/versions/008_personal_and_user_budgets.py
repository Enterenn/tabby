"""Personal expenses, user-owned categories and ceilings.

Revision ID: 008
Revises: 007
Create Date: 2026-09-13
"""

from typing import Sequence, Union
import uuid

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from alembic import op

revision: str = "008"
down_revision: Union[str, None] = "007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "personal_expense",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("user.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "category_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("category.id"),
            nullable=False,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("amount", sa.Numeric(10, 2), nullable=False),
        sa.Column("expense_date", sa.Date(), nullable=False),
        sa.Column(
            "created_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    op.add_column(
        "category",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_category_user",
        "category",
        "user",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )

    conn = op.get_bind()
    group_cats = conn.execute(
        sa.text(
            """
            SELECT c.id, c.group_id, c.name, c.icon, c.color, c.sort_order
            FROM category c
            WHERE c.group_id IS NOT NULL AND c.is_default = false
            """
        )
    ).fetchall()

    for cat in group_cats:
        members = conn.execute(
            sa.text("SELECT user_id FROM group_member WHERE group_id = :gid"),
            {"gid": cat.group_id},
        ).fetchall()
        for member in members:
            conn.execute(
                sa.text(
                    """
                    INSERT INTO category
                        (id, group_id, user_id, name, icon, color, is_default, sort_order)
                    VALUES
                        (:id, NULL, :uid, :name, :icon, :color, false, :sort)
                    """
                ),
                {
                    "id": uuid.uuid4(),
                    "uid": member.user_id,
                    "name": cat.name,
                    "icon": cat.icon,
                    "color": cat.color,
                    "sort": cat.sort_order,
                },
            )

    op.drop_constraint("uq_budget_group_category", "budget", type_="unique")
    op.add_column(
        "budget",
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_budget_user",
        "budget",
        "user",
        ["user_id"],
        ["id"],
        ondelete="CASCADE",
    )

    old_budgets = conn.execute(
        sa.text(
            """
            SELECT b.id, b.group_id, b.category_id, b.limit_amount, b.period,
                   c.name AS cat_name, c.icon AS cat_icon
            FROM budget b
            JOIN category c ON c.id = b.category_id
            """
        )
    ).fetchall()

    for budget in old_budgets:
        members = conn.execute(
            sa.text("SELECT user_id FROM group_member WHERE group_id = :gid"),
            {"gid": budget.group_id},
        ).fetchall()
        for member in members:
            clone = conn.execute(
                sa.text(
                    """
                    SELECT id FROM category
                    WHERE user_id = :uid AND name = :name AND icon = :icon
                    LIMIT 1
                    """
                ),
                {
                    "uid": member.user_id,
                    "name": budget.cat_name,
                    "icon": budget.cat_icon,
                },
            ).fetchone()
            category_id = clone.id if clone is not None else budget.category_id
            exists = conn.execute(
                sa.text(
                    """
                    SELECT 1 FROM budget
                    WHERE user_id = :uid AND category_id = :cid
                    """
                ),
                {"uid": member.user_id, "cid": category_id},
            ).fetchone()
            if exists is not None:
                continue
            conn.execute(
                sa.text(
                    """
                    INSERT INTO budget (id, group_id, user_id, category_id, limit_amount, period)
                    VALUES (:id, :gid, :uid, :cid, :lim, :period)
                    """
                ),
                {
                    "id": uuid.uuid4(),
                    "gid": budget.group_id,
                    "uid": member.user_id,
                    "cid": category_id,
                    "lim": budget.limit_amount,
                    "period": budget.period,
                },
            )
        conn.execute(sa.text("DELETE FROM budget WHERE id = :id"), {"id": budget.id})

    op.drop_constraint("budget_group_id_fkey", "budget", type_="foreignkey")
    op.drop_column("budget", "group_id")
    op.alter_column("budget", "user_id", nullable=False)
    op.create_unique_constraint(
        "uq_budget_user_category", "budget", ["user_id", "category_id"]
    )


def downgrade() -> None:
    op.drop_constraint("uq_budget_user_category", "budget", type_="unique")
    op.add_column(
        "budget",
        sa.Column("group_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.drop_constraint("fk_budget_user", "budget", type_="foreignkey")
    op.drop_column("budget", "user_id")
    op.drop_constraint("fk_category_user", "category", type_="foreignkey")
    op.drop_column("category", "user_id")
    op.drop_table("personal_expense")
