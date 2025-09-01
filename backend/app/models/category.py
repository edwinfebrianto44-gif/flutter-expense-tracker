from sqlalchemy import Column, Integer, String, DateTime, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..core.database import Base
import enum


class CategoryType(str, enum.Enum):
    income = "income"
    expense = "expense"


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(80), nullable=False)
    type = Column(Enum(CategoryType), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    transactions = relationship("Transaction", back_populates="category")
