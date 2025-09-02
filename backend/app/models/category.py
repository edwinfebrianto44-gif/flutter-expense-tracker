from sqlalchemy import Column, Integer, String, DateTime, Enum, ForeignKey, BigInteger
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
    icon = Column(String(10), nullable=True)  # Emoji or icon identifier
    color = Column(String(7), nullable=True)  # Hex color code
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="categories")
    transactions = relationship("Transaction", back_populates="category")
    
    def __repr__(self):
        return f"<Category(id={self.id}, name={self.name}, type={self.type}, user_id={self.user_id})>"
