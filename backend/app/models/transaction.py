from sqlalchemy import Column, Integer, String, DateTime, BigInteger, ForeignKey, Date, DECIMAL
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..core.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    amount = Column(DECIMAL(12, 2), nullable=False)
    description = Column(String(255), nullable=True)
    trans_date = Column(Date, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="transactions")
    category = relationship("Category", back_populates="transactions")
