"""SQLAlchemy ORM models — mirrors the DDL in the cahier technique."""

import uuid
from datetime import datetime

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    ForeignKey,
    Integer,
    Numeric,
    TIMESTAMP,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base


def new_uuid() -> uuid.UUID:
    return uuid.uuid4()


class User(Base):
    __tablename__ = "user"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    email: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    group_memberships: Mapped[list["GroupMember"]] = relationship(back_populates="user")
    paid_expenses: Mapped[list["Expense"]] = relationship(back_populates="paid_by_user")
    expense_splits: Mapped[list["ExpenseSplit"]] = relationship(back_populates="user")
    loyalty_cards: Mapped[list["LoyaltyCard"]] = relationship(back_populates="user", passive_deletes=True)
    recurring_expenses: Mapped[list["RecurringExpense"]] = relationship(back_populates="paid_by_user")
    personal_expenses: Mapped[list["PersonalExpense"]] = relationship(
        back_populates="user", passive_deletes=True
    )
    personal_recurrings: Mapped[list["PersonalRecurring"]] = relationship(
        back_populates="user", passive_deletes=True
    )
    personal_categories: Mapped[list["Category"]] = relationship(back_populates="user")
    budgets: Mapped[list["Budget"]] = relationship(back_populates="user", passive_deletes=True)
    device_tokens: Mapped[list["DeviceToken"]] = relationship(back_populates="user", passive_deletes=True)
    refresh_tokens: Mapped[list["RefreshToken"]] = relationship(
        back_populates="user", passive_deletes=True
    )


class DeviceToken(Base):
    __tablename__ = "device_token"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    token: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    platform: Mapped[str] = mapped_column(Text, nullable=False, default="android")
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="device_tokens")


class RefreshToken(Base):
    __tablename__ = "refresh_token"

    jti: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="refresh_tokens")


class Group(Base):
    __tablename__ = "group"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    owner_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="RESTRICT"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    members: Mapped[list["GroupMember"]] = relationship(back_populates="group", passive_deletes=True)
    categories: Mapped[list["Category"]] = relationship(back_populates="group", passive_deletes=True)
    expenses: Mapped[list["Expense"]] = relationship(back_populates="group", passive_deletes=True)
    recurring_expenses: Mapped[list["RecurringExpense"]] = relationship(back_populates="group", passive_deletes=True)
    invites: Mapped[list["GroupInvite"]] = relationship(back_populates="group", passive_deletes=True)


class GroupMember(Base):
    __tablename__ = "group_member"

    group_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("group.id", ondelete="CASCADE"), primary_key=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), primary_key=True
    )
    joined_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())
    is_pinned: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )

    group: Mapped["Group"] = relationship(back_populates="members")
    user: Mapped["User"] = relationship(back_populates="group_memberships")


class Category(Base):
    __tablename__ = "category"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    # NULL = catégorie globale par défaut (is_default) ou héritage groupe
    group_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("group.id", ondelete="CASCADE"), nullable=True
    )
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=True
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    icon: Mapped[str] = mapped_column(Text, nullable=False)
    color: Mapped[str] = mapped_column(Text, nullable=False)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    group: Mapped["Group | None"] = relationship(back_populates="categories")
    user: Mapped["User | None"] = relationship(back_populates="personal_categories")
    expenses: Mapped[list["Expense"]] = relationship(back_populates="category")
    recurring_expenses: Mapped[list["RecurringExpense"]] = relationship(back_populates="category")
    personal_expenses: Mapped[list["PersonalExpense"]] = relationship(back_populates="category")
    personal_recurrings: Mapped[list["PersonalRecurring"]] = relationship(back_populates="category")
    budgets: Mapped[list["Budget"]] = relationship(back_populates="category")


class Expense(Base):
    __tablename__ = "expense"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    group_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("group.id", ondelete="CASCADE"), nullable=False
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("category.id"), nullable=False
    )
    paid_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    expense_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(
        Text,
        CheckConstraint("status IN ('confirmed', 'pending')", name="ck_expense_status"),
        nullable=False,
        default="confirmed",
        server_default="confirmed",
    )
    recurring_source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("recurring_expense.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    group: Mapped["Group"] = relationship(back_populates="expenses")
    category: Mapped["Category"] = relationship(back_populates="expenses")
    paid_by_user: Mapped["User"] = relationship(back_populates="paid_expenses")
    splits: Mapped[list["ExpenseSplit"]] = relationship(
        back_populates="expense", cascade="all, delete-orphan"
    )
    recurring_source: Mapped["RecurringExpense | None"] = relationship(
        back_populates="generated_expenses"
    )


class ExpenseSplit(Base):
    __tablename__ = "expense_split"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    expense_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("expense.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id"), nullable=False
    )
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)

    expense: Mapped["Expense"] = relationship(back_populates="splits")
    user: Mapped["User"] = relationship(back_populates="expense_splits")


class RecurringExpense(Base):
    __tablename__ = "recurring_expense"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    group_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("group.id", ondelete="CASCADE"), nullable=False
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("category.id"), nullable=False
    )
    paid_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    frequency: Mapped[str] = mapped_column(
        Text,
        CheckConstraint("frequency IN ('monthly', 'yearly')", name="ck_recurring_frequency"),
        nullable=False,
    )
    day_of_period: Mapped[int] = mapped_column(Integer, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    group: Mapped["Group"] = relationship(back_populates="recurring_expenses")
    category: Mapped["Category"] = relationship(back_populates="recurring_expenses")
    paid_by_user: Mapped["User"] = relationship(back_populates="recurring_expenses")
    generated_expenses: Mapped[list["Expense"]] = relationship(back_populates="recurring_source")


class PersonalRecurring(Base):
    __tablename__ = "personal_recurring"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("category.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    frequency: Mapped[str] = mapped_column(
        Text,
        CheckConstraint("frequency IN ('monthly', 'yearly')", name="ck_personal_recurring_frequency"),
        nullable=False,
    )
    day_of_period: Mapped[int] = mapped_column(Integer, nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="personal_recurrings")
    category: Mapped["Category"] = relationship(back_populates="personal_recurrings")
    generated_expenses: Mapped[list["PersonalExpense"]] = relationship(
        back_populates="recurring_source"
    )


class PersonalExpense(Base):
    __tablename__ = "personal_expense"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("category.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(Text, nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    expense_date: Mapped[datetime] = mapped_column(Date, nullable=False)
    recurring_source_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("personal_recurring.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="personal_expenses")
    category: Mapped["Category"] = relationship(back_populates="personal_expenses")
    recurring_source: Mapped["PersonalRecurring | None"] = relationship(
        back_populates="generated_expenses"
    )


class Budget(Base):
    __tablename__ = "budget"

    __table_args__ = (UniqueConstraint("user_id", "category_id", name="uq_budget_user_category"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("category.id"), nullable=False
    )
    limit_amount: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    period: Mapped[str] = mapped_column(
        Text,
        CheckConstraint("period IN ('monthly')", name="ck_budget_period"),
        nullable=False,
        default="monthly",
    )

    user: Mapped["User"] = relationship(back_populates="budgets")
    category: Mapped["Category"] = relationship(back_populates="budgets")


class LoyaltyCard(Base):
    __tablename__ = "loyalty_card"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("user.id", ondelete="CASCADE"), nullable=False
    )
    brand_name: Mapped[str] = mapped_column(Text, nullable=False)
    brand_id: Mapped[str | None] = mapped_column(Text, nullable=True)
    code_type: Mapped[str] = mapped_column(
        Text,
        CheckConstraint("code_type IN ('barcode', 'qrcode')", name="ck_loyalty_code_type"),
        nullable=False,
    )
    code_value: Mapped[str] = mapped_column(Text, nullable=False)
    color: Mapped[str | None] = mapped_column(Text, nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    user: Mapped["User"] = relationship(back_populates="loyalty_cards")


class GroupInvite(Base):
    __tablename__ = "group_invite"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=new_uuid)
    group_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("group.id", ondelete="CASCADE"), nullable=False
    )
    code: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True), nullable=True)

    group: Mapped["Group"] = relationship(back_populates="invites")
