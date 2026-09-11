"""Remplace les noms d'icônes Material par des emojis pour les catégories par défaut

Revision ID: 002
Revises: 001
Create Date: 2026-09-11
"""

from typing import Sequence, Union

from alembic import op

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_UPDATES = [
    ("Loyer",       "🏠"),
    ("Courses",     "🛒"),
    ("Restaurant",  "🍽️"),
    ("Transport",   "🚗"),
    ("Loisirs",     "🎮"),
    ("Abonnements", "📺"),
    ("Santé",       "🏥"),
    ("Autre",       "📦"),
]


def upgrade() -> None:
    for name, emoji in _UPDATES:
        op.execute(
            f"UPDATE category SET icon = '{emoji}' "
            f"WHERE name = '{name}' AND is_default = true"
        )


def downgrade() -> None:
    _legacy = {
        "Loyer":       "home",
        "Courses":     "shopping_cart",
        "Restaurant":  "restaurant",
        "Transport":   "directions_car",
        "Loisirs":     "sports_esports",
        "Abonnements": "subscriptions",
        "Santé":       "local_hospital",
        "Autre":       "category",
    }
    for name, icon in _legacy.items():
        op.execute(
            f"UPDATE category SET icon = '{icon}' "
            f"WHERE name = '{name}' AND is_default = true"
        )
