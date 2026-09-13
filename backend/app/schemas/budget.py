from __future__ import annotations

from pydantic import BaseModel, field_validator

from app.schemas.expense import CategoryResponse


class BudgetCreate(BaseModel):
    category_id: str
    limit_amount: float

    @field_validator("limit_amount")
    @classmethod
    def positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("limit_amount must be positive")
        return v


class BudgetUpdate(BaseModel):
    limit_amount: float

    @field_validator("limit_amount")
    @classmethod
    def positive(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("limit_amount must be positive")
        return v


class BudgetResponse(BaseModel):
    id: str
    group_id: str | None = None
    category: CategoryResponse
    limit_amount: float
    spent_amount: float   # dépenses du mois courant dans cette catégorie
    percent: float        # spent / limit * 100
    status: str           # "ok" | "warning" | "danger"

    model_config = {"from_attributes": True}
