from sqlalchemy import Column, Integer, String, DateTime, BigInteger, ForeignKey, Date, DECIMAL, Text
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
    type = Column(String(10), nullable=False)  # "income" or "expense"
    attachment_url = Column(String(500), nullable=True)  # URL to receipt/proof image
    attachment_filename = Column(String(255), nullable=True)  # Original filename
    attachment_size = Column(Integer, nullable=True)  # File size in bytes
    notes = Column(Text, nullable=True)  # Additional notes
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="transactions")
    category = relationship("Category", back_populates="transactions")
    
    def __repr__(self):
        return f"<Transaction(id={self.id}, amount={self.amount}, type={self.type}, user_id={self.user_id})>"
