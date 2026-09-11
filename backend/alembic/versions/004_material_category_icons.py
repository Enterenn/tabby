"""Remet les icônes Material Symbols à la place des emojis de catégories.

Revision ID: 004
Revises: 003
Create Date: 2026-09-11
"""

from typing import Sequence, Union

from alembic import op

revision: str = "004"
down_revision: Union[str, None] = "003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_EMOJI_TO_ICON = [
    ("🏠", "home"),
    ("🛒", "shopping_cart"),
    ("🍽️", "restaurant"),
    ("🍕", "restaurant"),
    ("🍔", "restaurant"),
    ("🍜", "restaurant"),
    ("🍣", "restaurant"),
    ("☕", "local_cafe"),
    ("🍺", "liquor"),
    ("🚗", "directions_car"),
    ("✈️", "flight"),
    ("🚲", "directions_bike"),
    ("⛽", "local_gas_station"),
    ("🎮", "sports_esports"),
    ("🎬", "movie"),
    ("🎵", "music_note"),
    ("📺", "live_tv"),
    ("🏥", "local_hospital"),
    ("💊", "vaccines"),
    ("🏋️", "fitness_center"),
    ("🎓", "school"),
    ("🐾", "pets"),
    ("🐶", "pets"),
    ("🐱", "pets"),
    ("📞", "phone"),
    ("💡", "bolt"),
    ("🚿", "water_drop"),
    ("🧹", "cleaning_services"),
    ("🏨", "hotel"),
    ("🏖️", "beach_access"),
    ("🎁", "card_giftcard"),
    ("💰", "payments"),
    ("📦", "category"),
]

_DEFAULTS = [
    ("Loyer", "home"),
    ("Courses", "shopping_cart"),
    ("Restaurant", "restaurant"),
    ("Transport", "directions_car"),
    ("Loisirs", "sports_esports"),
    ("Abonnements", "subscriptions"),
    ("Santé", "local_hospital"),
    ("Autre", "category"),
]


def upgrade() -> None:
    for emoji, icon in _EMOJI_TO_ICON:
        op.execute(
            f"UPDATE category SET icon = '{icon}' WHERE icon = '{emoji}'"
        )
    for name, icon in _DEFAULTS:
        op.execute(
            f"UPDATE category SET icon = '{icon}' "
            f"WHERE name = '{name}' AND is_default = true"
        )


def downgrade() -> None:
    _legacy = {
        "Loyer": "🏠",
        "Courses": "🛒",
        "Restaurant": "🍽️",
        "Transport": "🚗",
        "Loisirs": "🎮",
        "Abonnements": "📺",
        "Santé": "🏥",
        "Autre": "📦",
    }
    for name, emoji in _legacy.items():
        op.execute(
            f"UPDATE category SET icon = '{emoji}' "
            f"WHERE name = '{name}' AND is_default = true"
        )
