"""
Test configuration and fixtures
"""
import pytest
import asyncio
from typing import Generator, AsyncGenerator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool

from app import app
from app.core.database import get_db, Base
from app.core.security import create_tokens_for_user, get_password_hash
from app.models.user import User
from app.models.category import Category
from app.models.transaction import Transaction


# Test database configuration
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={
        "check_same_thread": False,
    },
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    """Override database dependency for testing"""
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def db() -> Generator[Session, None, None]:
    """Create test database session"""
    Base.metadata.create_all(bind=engine)
    with TestingSessionLocal() as session:
        yield session
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client(db: Session) -> Generator[TestClient, None, None]:
    """Create test client"""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def test_user(db: Session) -> User:
    """Create a test user"""
    user = User(
        username="testuser",
        email="test@domain.co",
        password_hash=get_password_hash("SecureTest123!"),
        full_name="Test User"
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@pytest.fixture
def test_user_token(test_user: User) -> str:
    """Create access token for test user"""
    user_data = {
        "id": test_user.id,
        "email": test_user.email,
        "role": test_user.role,
        "username": test_user.username,
        "full_name": test_user.full_name
    }
    tokens = create_tokens_for_user(user_data)
    return tokens["access_token"]


@pytest.fixture
def auth_headers(test_user_token: str) -> dict:
    """Create authorization headers"""
    return {"Authorization": f"Bearer {test_user_token}"}


@pytest.fixture
def test_categories(db: Session, test_user: User) -> list[Category]:
    """Create test categories"""
    categories = [
        Category(
            name="Food & Dining",
            type="expense",
            color="#FF5722",
            icon="restaurant",
            user_id=test_user.id
        ),
        Category(
            name="Transportation",
            type="expense", 
            color="#2196F3",
            icon="directions_car",
            user_id=test_user.id
        ),
        Category(
            name="Salary",
            type="income",
            color="#4CAF50",
            icon="work",
            user_id=test_user.id
        )
    ]
    
    for category in categories:
        db.add(category)
    db.commit()
    
    for category in categories:
        db.refresh(category)
    
    return categories


@pytest.fixture
def test_transactions(db: Session, test_user: User, test_categories: list[Category]) -> list[Transaction]:
    """Create test transactions"""
    from datetime import datetime, date
    
    transactions = [
        Transaction(
            amount=50.00,
            description="Lunch at restaurant",
            trans_date=date.today(),
            type="expense",
            category_id=test_categories[0].id,
            user_id=test_user.id,
            created_at=datetime.utcnow()
        ),
        Transaction(
            amount=25.00,
            description="Bus fare",
            trans_date=date.today(),
            type="expense",
            category_id=test_categories[1].id,
            user_id=test_user.id,
            created_at=datetime.utcnow()
        ),
        Transaction(
            amount=3000.00,
            description="Monthly salary",
            trans_date=date.today(),
            type="income",
            category_id=test_categories[2].id,
            user_id=test_user.id,
            created_at=datetime.utcnow()
        )
    ]
    
    for transaction in transactions:
        db.add(transaction)
    db.commit()
    
    for transaction in transactions:
        db.refresh(transaction)
    
    return transactions
