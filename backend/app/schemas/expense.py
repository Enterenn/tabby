from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


class CategoryResponse(BaseModel):
    id: str
    name: str
    icon: str
    color: str
    is_default: bool
    sort_order: int

    model_config = {"from_attributes": True}


class CategoryCreate(BaseModel):
    group_id: uuid.UUID | None = None
    name: str
    icon: str
    color: str  # hex sans le # ou avec


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    icon: str | None = None
    color: str | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str | None) -> str | None:
        if value is None:
            return None
        name = value.strip()
        if not name:
            raise ValueError("Name is required")
        return name


class ExpenseSplitResponse(BaseModel):
    user_id: str
    amount: float

    model_config = {"from_attributes": True}


class SplitItem(BaseModel):
    user_id: uuid.UUID
    amount: float


class ExpenseCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    amount: float = Field(gt=0)
    category_id: uuid.UUID
    paid_by: uuid.UUID
    expense_date: date
    split_type: Literal["equal", "custom"] = "equal"
    splits: list[SplitItem] | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("Name is required")
        return name

    @model_validator(mode="after")
    def validate_custom_splits(self) -> "ExpenseCreate":
        if self.split_type == "custom":
            if not self.splits:
                raise ValueError("splits required when split_type is 'custom'")
            total_splits = round(sum(s.amount for s in self.splits), 2)
            if abs(total_splits - round(self.amount, 2)) > 0.01:
                raise ValueError(
                    f"Splits sum ({total_splits}) must equal expense amount ({self.amount})"
                )
        return self


class ExpenseUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    amount: float | None = Field(default=None, gt=0)
    category_id: uuid.UUID | None = None
    paid_by: uuid.UUID | None = None
    expense_date: date | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str | None) -> str | None:
        if value is None:
            return None
        name = value.strip()
        if not name:
            raise ValueError("Name is required")
        return name


class ExpenseResponse(BaseModel):
    id: str
    name: str
    amount: float
    category: CategoryResponse
    paid_by: str
    paid_by_name: str
    expense_date: date
    created_at: datetime
    splits: list[ExpenseSplitResponse] = []

    model_config = {"from_attributes": True}
