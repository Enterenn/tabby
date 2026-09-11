from __future__ import annotations

import uuid
from datetime import date, datetime

from pydantic import BaseModel, condecimal


class CategoryResponse(BaseModel):
    id: str
    name: str
    icon: str
    color: str
    is_default: bool
    sort_order: int

    model_config = {"from_attributes": True}


class ExpenseSplitResponse(BaseModel):
    user_id: str
    amount: float

    model_config = {"from_attributes": True}


class ExpenseCreate(BaseModel):
    name: str
    amount: float
    category_id: uuid.UUID
    paid_by: uuid.UUID
    expense_date: date


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
