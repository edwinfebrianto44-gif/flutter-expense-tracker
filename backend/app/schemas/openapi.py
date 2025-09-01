from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# Auth Schemas
class UserLogin(BaseModel):
    email: str = Field(..., example="user@example.com", description="User email address")
    password: str = Field(..., example="password123", min_length=6, description="User password")

class UserRegister(BaseModel):
    name: str = Field(..., example="John Doe", min_length=2, description="User full name")
    email: str = Field(..., example="user@example.com", description="User email address")
    password: str = Field(..., example="password123", min_length=6, description="User password")

class Token(BaseModel):
    access_token: str = Field(..., example="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", description="JWT access token")
    token_type: str = Field(default="bearer", example="bearer", description="Token type")

class UserResponse(BaseModel):
    id: int = Field(..., example=1, description="User ID")
    name: str = Field(..., example="John Doe", description="User full name")
    email: str = Field(..., example="user@example.com", description="User email address")
    created_at: datetime = Field(..., example="2025-09-01T10:00:00Z", description="Account creation date")

class AuthResponse(BaseModel):
    access_token: str = Field(..., example="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", description="JWT access token")
    token_type: str = Field(default="bearer", example="bearer", description="Token type")
    user: UserResponse

# Category Schemas
class CategoryCreate(BaseModel):
    name: str = Field(..., example="Food", min_length=2, max_length=50, description="Category name")
    type: str = Field(..., example="expense", regex="^(income|expense)$", description="Category type: income or expense")
    icon: Optional[str] = Field("💰", example="🍔", description="Category icon emoji")
    color: Optional[str] = Field("#6366F1", example="#EF4444", description="Category color in hex format")

class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, example="Food & Dining", min_length=2, max_length=50, description="Category name")
    type: Optional[str] = Field(None, example="expense", regex="^(income|expense)$", description="Category type")
    icon: Optional[str] = Field(None, example="🍽️", description="Category icon emoji")
    color: Optional[str] = Field(None, example="#F59E0B", description="Category color in hex format")

class CategoryResponse(BaseModel):
    id: int = Field(..., example=1, description="Category ID")
    name: str = Field(..., example="Food", description="Category name")
    type: str = Field(..., example="expense", description="Category type")
    icon: str = Field(..., example="🍔", description="Category icon emoji")
    color: str = Field(..., example="#EF4444", description="Category color in hex format")
    user_id: int = Field(..., example=1, description="Owner user ID")

# Transaction Schemas
class TransactionCreate(BaseModel):
    amount: float = Field(..., example=50000.0, gt=0, description="Transaction amount in Rupiah")
    description: str = Field(..., example="Lunch at restaurant", min_length=3, max_length=200, description="Transaction description")
    type: str = Field(..., example="expense", regex="^(income|expense)$", description="Transaction type: income or expense")
    category_id: int = Field(..., example=1, description="Category ID")
    date: Optional[datetime] = Field(None, example="2025-09-01T12:00:00Z", description="Transaction date (defaults to now)")

class TransactionUpdate(BaseModel):
    amount: Optional[float] = Field(None, example=75000.0, gt=0, description="Transaction amount in Rupiah")
    description: Optional[str] = Field(None, example="Dinner at restaurant", min_length=3, max_length=200, description="Transaction description")
    type: Optional[str] = Field(None, example="expense", regex="^(income|expense)$", description="Transaction type")
    category_id: Optional[int] = Field(None, example=2, description="Category ID")
    date: Optional[datetime] = Field(None, example="2025-09-01T19:00:00Z", description="Transaction date")

class TransactionResponse(BaseModel):
    id: int = Field(..., example=1, description="Transaction ID")
    amount: float = Field(..., example=50000.0, description="Transaction amount in Rupiah")
    description: str = Field(..., example="Lunch at restaurant", description="Transaction description")
    type: str = Field(..., example="expense", description="Transaction type")
    date: datetime = Field(..., example="2025-09-01T12:00:00Z", description="Transaction date")
    category_id: int = Field(..., example=1, description="Category ID")
    user_id: int = Field(..., example=1, description="Owner user ID")
    category: Optional[CategoryResponse] = Field(None, description="Category details")

# Summary Schemas
class MonthlySummary(BaseModel):
    month: str = Field(..., example="2025-09", description="Month in YYYY-MM format")
    total_income: float = Field(..., example=5000000.0, description="Total income for the month")
    total_expense: float = Field(..., example=2500000.0, description="Total expenses for the month")
    net_amount: float = Field(..., example=2500000.0, description="Net amount (income - expenses)")
    transaction_count: int = Field(..., example=25, description="Number of transactions")

class CategorySummary(BaseModel):
    category_id: int = Field(..., example=1, description="Category ID")
    category_name: str = Field(..., example="Food", description="Category name")
    category_icon: str = Field(..., example="🍔", description="Category icon")
    category_color: str = Field(..., example="#EF4444", description="Category color")
    total_amount: float = Field(..., example=500000.0, description="Total amount for this category")
    transaction_count: int = Field(..., example=8, description="Number of transactions in this category")
    percentage: float = Field(..., example=20.0, description="Percentage of total expenses/income")

class FinancialSummary(BaseModel):
    total_income: float = Field(..., example=10000000.0, description="Total income")
    total_expense: float = Field(..., example=6500000.0, description="Total expenses")
    balance: float = Field(..., example=3500000.0, description="Current balance")
    monthly_summaries: List[MonthlySummary] = Field(..., description="Monthly breakdown")
    expense_categories: List[CategorySummary] = Field(..., description="Expense breakdown by category")
    income_categories: List[CategorySummary] = Field(..., description="Income breakdown by category")

# Error Schemas
class ErrorResponse(BaseModel):
    message: str = Field(..., example="Resource not found", description="Error message")
    detail: Optional[str] = Field(None, example="Transaction with ID 999 does not exist", description="Detailed error information")

class ValidationError(BaseModel):
    loc: List[str] = Field(..., example=["body", "amount"], description="Location of the error")
    msg: str = Field(..., example="ensure this value is greater than 0", description="Error message")
    type: str = Field(..., example="value_error.number.not_gt", description="Error type")

class ValidationErrorResponse(BaseModel):
    detail: List[ValidationError] = Field(..., description="List of validation errors")
