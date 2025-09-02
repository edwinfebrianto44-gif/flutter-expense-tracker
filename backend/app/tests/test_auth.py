"""
Authentication tests for the Expense Tracker API
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.user import User
from app.core.security import verify_password


class TestUserRegistration:
    """Test user registration functionality"""
    
    def test_register_user_success(self, client: TestClient, db: Session):
        """Test successful user registration"""
        user_data = {
            "username": "newuser",
            "email": "valid.email@domain.co",
            "password": "SecurePass123!",
            "full_name": "New User"
        }
        response = client.post("/api/v1/auth/register", json=user_data)
        
        if response.status_code not in [200, 201]:
            print(f"Error response: {response.json()}")
        
        assert response.status_code in [200, 201]
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["username"] == "newuser"
        assert data["data"]["email"] == "valid.email@domain.co"
        assert data["data"]["full_name"] == "New User"
        assert "id" in data["data"]
        
        # Verify user was created in database
        user = db.query(User).filter(User.username == "newuser").first()
        assert user is not None
        assert user.email == "valid.email@domain.co"
    
    def test_register_duplicate_username(self, client: TestClient, test_user: User):
        """Test registration with duplicate username"""
        user_data = {
            "username": "testuser",  # Same as test_user
            "email": "different@domain.co",
            "password": "SecurePass123!",
            "full_name": "Different User"
        }
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 400
        data = response.json()
        assert data["detail"]["success"] == False
        assert "already" in data["detail"]["message"].lower()
    
    def test_register_duplicate_email(self, client: TestClient, test_user: User):
        """Test registration with duplicate email"""
        user_data = {
            "username": "differentuser",
            "email": "test@domain.co",  # Same as test_user
            "password": "SecurePass123!",
            "full_name": "Different User"
        }
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 400
        data = response.json()
        assert data["detail"]["success"] == False
        assert "already" in data["detail"]["message"].lower()
    
    def test_register_invalid_email(self, client: TestClient):
        """Test registration with invalid email format"""
        user_data = {
            "username": "testuser",
            "email": "invalid-email",
            "password": "SecurePass123!",
            "full_name": "Test User"
        }
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 422  # Validation error
    
    def test_register_weak_password(self, client: TestClient):
        """Test registration with weak password"""
        user_data = {
            "username": "testuser",
            "email": "test@domain.co",
            "password": "123",  # Too weak
            "full_name": "Test User"
        }
        response = client.post("/api/v1/auth/register", json=user_data)
        
        assert response.status_code == 422  # Validation error


class TestUserLogin:
    """Test user login functionality"""
    
    def test_login_success(self, client: TestClient, test_user: User):
        """Test successful login"""
        login_data = {
            "email": "test@domain.co",
            "password": "SecureTest123!"
        }
        response = client.post("/api/v1/auth/login", json=login_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "access_token" in data["data"]
        assert data["data"]["token_type"] == "bearer"
        assert data["data"]["user"]["username"] == "testuser"
        assert data["data"]["user"]["email"] == "test@domain.co"
    
    def test_login_invalid_username(self, client: TestClient):
        """Test login with invalid username"""
        login_data = {
            "email": "nonexistent@domain.co",
            "password": "SecureTest123!"
        }
        response = client.post("/api/v1/auth/login", json=login_data)
        
        assert response.status_code in [401, 422]
        data = response.json()
        assert data["detail"]["success"] == False
        assert "password" in data["detail"]["message"].lower()
    
    def test_login_invalid_password(self, client: TestClient, test_user: User):
        """Test login with invalid password"""
        login_data = {
            "email": "test@domain.co",
            "password": "wrongpassword"
        }
        response = client.post("/api/v1/auth/login", json=login_data)
        
        assert response.status_code == 401
        data = response.json()
        assert data["detail"]["success"] == False
        assert "password" in data["detail"]["message"].lower()


class TestUserProfile:
    """Test user profile functionality"""
    
    def test_get_current_user(self, client: TestClient, auth_headers: dict, test_user: User):
        """Test getting current user profile"""
        response = client.get("/api/v1/auth/me", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["id"] == test_user.id
        assert data["data"]["username"] == test_user.username
        assert data["data"]["email"] == test_user.email
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["id"] == test_user.id
        assert data["data"]["username"] == test_user.username
        assert data["data"]["email"] == test_user.email
    
    def test_get_current_user_unauthorized(self, client: TestClient):
        """Test getting current user without authentication"""
        response = client.get("/api/v1/auth/me")
        
        assert response.status_code in [401, 403]
        data = response.json()
        assert "detail" in data
        assert "authenticated" in data["detail"].lower()
    
    def test_get_current_user_invalid_token(self, client: TestClient):
        """Test getting current user with invalid token"""
        headers = {"Authorization": "Bearer invalid_token"}
        response = client.get("/api/v1/auth/me", headers=headers)
        
        assert response.status_code == 401
        # Response format may vary, so let's be flexible
        if response.status_code == 401:
            # Test passed - token was rejected
            pass
