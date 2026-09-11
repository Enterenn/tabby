from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, field_validator

from app.schemas.expense import CategoryResponse


class RecurringExpenseCreate(BaseModel):
    name: str
    amount: float
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


class RecurringExpenseResponse(BaseModel):
    id: str
    group_id: str
    group_name: str
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
