from pydantic import BaseModel, validator
from typing import Optional
from datetime import datetime, date
from decimal import Decimal
from .category import Category


class TransactionBase(BaseModel):
    category_id: int
    amount: Decimal
    description: Optional[str] = None
    trans_date: date

    @validator('amount')
    def amount_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError('Amount must be positive')
        return v


class TransactionCreate(TransactionBase):
    pass


class TransactionUpdate(BaseModel):
    category_id: Optional[int] = None
    amount: Optional[Decimal] = None
    description: Optional[str] = None
    trans_date: Optional[date] = None

    @validator('amount')
    def amount_must_be_positive(cls, v):
        if v is not None and v <= 0:
            raise ValueError('Amount must be positive')
        return v


class Transaction(TransactionBase):
    id: int
    user_id: int
    created_at: datetime
    category: Optional[Category] = None

    class Config:
        from_attributes = True


class TransactionFilter(BaseModel):
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    category_id: Optional[int] = None
    category_type: Optional[str] = None


class TransactionSummary(BaseModel):
    total_income: Decimal
    total_expense: Decimal
    balance: Decimal
    period_start: Optional[date] = None
    period_end: Optional[date] = None
