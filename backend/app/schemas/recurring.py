from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.expense import CategoryResponse


class RecurringExpenseCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    amount: float = Field(gt=0)
    category_id: uuid.UUID
    paid_by: uuid.UUID
    day_of_period: int  # jour du mois (1-28)
    frequency: str = "monthly"

    @field_validator("day_of_period")
    @classmethod
    def validate_day(cls, v: int) -> int:
        if not 1 <= v <= 28:
            raise ValueError("day_of_period must be between 1 and 28")
        return v

    @field_validator("frequency")
    @classmethod
    def validate_frequency(cls, v: str) -> str:
        if v not in ("monthly",):
            raise ValueError("Only 'monthly' frequency is supported")
        return v


class RecurringExpenseUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    amount: float | None = Field(default=None, gt=0)
    category_id: uuid.UUID | None = None
    paid_by: uuid.UUID | None = None
    day_of_period: int | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str | None) -> str | None:
        if value is None:
            return None
        name = value.strip()
        if not name:
            raise ValueError("Name is required")
        return name

    @field_validator("day_of_period")
    @classmethod
    def validate_day(cls, v: int | None) -> int | None:
        if v is None:
            return None
        if not 1 <= v <= 28:
            raise ValueError("day_of_period must be between 1 and 28")
        return v


class RecurringExpenseResponse(BaseModel):
    id: str
    group_id: str | None = None
    group_name: str | None = None
    is_personal: bool = False
    name: str
    amount: float
    category: CategoryResponse
    paid_by: str
    paid_by_name: str
    frequency: str
    day_of_period: int
    active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class PersonalRecurringCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    amount: float = Field(gt=0)
    category_id: uuid.UUID
    day_of_period: int
    frequency: str = "monthly"

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("Name is required")
        return name

    @field_validator("day_of_period")
    @classmethod
    def validate_day(cls, v: int) -> int:
        if not 1 <= v <= 28:
            raise ValueError("day_of_period must be between 1 and 28")
        return v

    @field_validator("frequency")
    @classmethod
    def validate_frequency(cls, v: str) -> str:
        if v not in ("monthly",):
            raise ValueError("Only 'monthly' frequency is supported")
        return v


class PersonalRecurringUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    amount: float | None = Field(default=None, gt=0)
    category_id: uuid.UUID | None = None
    day_of_period: int | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str | None) -> str | None:
        if value is None:
            return None
        name = value.strip()
        if not name:
            raise ValueError("Name is required")
        return name

    @field_validator("day_of_period")
    @classmethod
    def validate_day(cls, v: int | None) -> int | None:
        if v is None:
            return None
        if not 1 <= v <= 28:
            raise ValueError("day_of_period must be between 1 and 28")
        return v

