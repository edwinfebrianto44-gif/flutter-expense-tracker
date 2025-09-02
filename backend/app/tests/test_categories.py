"""
Category CRUD tests for the Expense Tracker API
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.category import Category
from app.models.user import User


class TestCategoryCreation:
    """Test category creation functionality"""
    
    def test_create_category_success(self, client: TestClient, auth_headers: dict, test_user: User, db: Session):
        """Test successful category creation"""
        category_data = {
            "name": "Groceries",
            "type": "expense",
            "color": "#FF9800",
            "icon": "shopping_cart"
        }
        response = client.post("/api/v1/categories", json=category_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["name"] == "Groceries"
        assert data["data"]["type"] == "expense"
        assert data["data"]["color"] == "#FF9800"
        assert data["data"]["icon"] == "shopping_cart"
        assert data["data"]["user_id"] == test_user.id
        
        # Verify category was created in database
        category = db.query(Category).filter(Category.name == "Groceries").first()
        assert category is not None
        assert category.user_id == test_user.id
    
    def test_create_category_unauthorized(self, client: TestClient):
        """Test category creation without authentication"""
        category_data = {
            "name": "Groceries",
            "type": "expense",
            "color": "#FF9800",
            "icon": "shopping_cart"
        }
        response = client.post("/api/v1/categories", json=category_data)
        
        assert response.status_code == 401
    
    def test_create_category_invalid_type(self, client: TestClient, auth_headers: dict):
        """Test category creation with invalid type"""
        category_data = {
            "name": "Test Category",
            "type": "invalid_type",
            "color": "#FF9800",
            "icon": "test_icon"
        }
        response = client.post("/api/v1/categories", json=category_data, headers=auth_headers)
        
        assert response.status_code == 422  # Validation error
    
    def test_create_duplicate_category_name(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test creating category with duplicate name for same user"""
        category_data = {
            "name": "Food & Dining",  # Same as existing category
            "type": "expense",
            "color": "#FF9800",
            "icon": "restaurant"
        }
        response = client.post("/api/v1/categories", json=category_data, headers=auth_headers)
        
        assert response.status_code == 400
        data = response.json()
        assert data["status"] == "error"
        assert "already exists" in data["message"].lower()


class TestCategoryRetrieval:
    """Test category retrieval functionality"""
    
    def test_get_categories_success(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test successful retrieval of user categories"""
        response = client.get("/api/v1/categories", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert len(data["data"]) == 3  # Number of test categories
        
        category_names = [cat["name"] for cat in data["data"]]
        assert "Food & Dining" in category_names
        assert "Transportation" in category_names
        assert "Salary" in category_names
    
    def test_get_categories_by_type(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test retrieval of categories filtered by type"""
        response = client.get("/api/v1/categories?type=expense", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert len(data["data"]) == 2  # Only expense categories
        
        for category in data["data"]:
            assert category["type"] == "expense"
    
    def test_get_categories_unauthorized(self, client: TestClient):
        """Test category retrieval without authentication"""
        response = client.get("/api/v1/categories")
        
        assert response.status_code == 401
    
    def test_get_category_by_id(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test retrieval of specific category by ID"""
        category_id = test_categories[0].id
        response = client.get(f"/api/v1/categories/{category_id}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["id"] == category_id
        assert data["data"]["name"] == "Food & Dining"
    
    def test_get_category_not_found(self, client: TestClient, auth_headers: dict):
        """Test retrieval of non-existent category"""
        response = client.get("/api/v1/categories/99999", headers=auth_headers)
        
        assert response.status_code == 404
        data = response.json()
        assert data["status"] == "error"


class TestCategoryUpdate:
    """Test category update functionality"""
    
    def test_update_category_success(self, client: TestClient, auth_headers: dict, test_categories: list[Category], db: Session):
        """Test successful category update"""
        category_id = test_categories[0].id
        update_data = {
            "name": "Updated Food Category",
            "color": "#E91E63",
            "icon": "fastfood"
        }
        response = client.put(f"/api/v1/categories/{category_id}", json=update_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["name"] == "Updated Food Category"
        assert data["data"]["color"] == "#E91E63"
        assert data["data"]["icon"] == "fastfood"
        
        # Verify update in database
        category = db.query(Category).filter(Category.id == category_id).first()
        assert category.name == "Updated Food Category"
        assert category.color == "#E91E63"
    
    def test_update_category_unauthorized(self, client: TestClient, test_categories: list[Category]):
        """Test category update without authentication"""
        category_id = test_categories[0].id
        update_data = {"name": "Updated Category"}
        response = client.put(f"/api/v1/categories/{category_id}", json=update_data)
        
        assert response.status_code == 401
    
    def test_update_category_not_found(self, client: TestClient, auth_headers: dict):
        """Test updating non-existent category"""
        update_data = {"name": "Updated Category"}
        response = client.put("/api/v1/categories/99999", json=update_data, headers=auth_headers)
        
        assert response.status_code == 404


class TestCategoryDeletion:
    """Test category deletion functionality"""
    
    def test_delete_category_success(self, client: TestClient, auth_headers: dict, test_categories: list[Category], db: Session):
        """Test successful category deletion"""
        category_id = test_categories[0].id
        response = client.delete(f"/api/v1/categories/{category_id}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        
        # Verify deletion in database
        category = db.query(Category).filter(Category.id == category_id).first()
        assert category is None
    
    def test_delete_category_unauthorized(self, client: TestClient, test_categories: list[Category]):
        """Test category deletion without authentication"""
        category_id = test_categories[0].id
        response = client.delete(f"/api/v1/categories/{category_id}")
        
        assert response.status_code == 401
    
    def test_delete_category_not_found(self, client: TestClient, auth_headers: dict):
        """Test deleting non-existent category"""
        response = client.delete("/api/v1/categories/99999", headers=auth_headers)
        
        assert response.status_code == 404
    
    def test_delete_category_with_transactions(self, client: TestClient, auth_headers: dict, test_categories: list[Category], test_transactions: list):
        """Test deleting category that has associated transactions"""
        # This category has transactions associated with it
        category_id = test_categories[0].id  
        response = client.delete(f"/api/v1/categories/{category_id}", headers=auth_headers)
        
        # Should either cascade delete or return error based on business logic
        # Adjust assertion based on your implementation
        assert response.status_code in [200, 400]
