from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from ..models.category import CategoryType


class CategoryBase(BaseModel):
    name: str
    type: CategoryType


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[CategoryType] = None


class Category(CategoryBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True
