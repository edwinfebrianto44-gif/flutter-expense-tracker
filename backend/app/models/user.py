from sqlalchemy import Column, Integer, String, DateTime, BigInteger
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from ..core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, index=True, autoincrement=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    password_hash = Column(String(100), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
