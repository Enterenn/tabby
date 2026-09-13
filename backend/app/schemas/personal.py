from datetime import date, datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.expense import CategoryResponse


class PersonalExpenseCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    amount: float = Field(gt=0)
    category_id: str
    expense_date: date

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        name = value.strip()
        if not name:
            raise ValueError("Name is required")
        return name


class PersonalExpenseResponse(BaseModel):
    id: str
    name: str
    amount: float
    category: CategoryResponse
    expense_date: date
    created_at: datetime

    model_config = {"from_attributes": True}
