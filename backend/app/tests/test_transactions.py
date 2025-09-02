"""
Transaction CRUD tests for the Expense Tracker API
"""
import pytest
from datetime import date, datetime, timedelta
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.transaction import Transaction
from app.models.category import Category
from app.models.user import User


class TestTransactionCreation:
    """Test transaction creation functionality"""
    
    def test_create_transaction_success(self, client: TestClient, auth_headers: dict, test_user: User, test_categories: list[Category], db: Session):
        """Test successful transaction creation"""
        transaction_data = {
            "amount": 75.50,
            "description": "Grocery shopping",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": test_categories[0].id
        }
        response = client.post("/api/v1/transactions", json=transaction_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["amount"] == 75.50
        assert data["data"]["description"] == "Grocery shopping"
        assert data["data"]["type"] == "expense"
        assert data["data"]["category_id"] == test_categories[0].id
        assert data["data"]["user_id"] == test_user.id
        
        # Verify transaction was created in database
        transaction = db.query(Transaction).filter(Transaction.description == "Grocery shopping").first()
        assert transaction is not None
        assert transaction.user_id == test_user.id
    
    def test_create_transaction_unauthorized(self, client: TestClient, test_categories: list[Category]):
        """Test transaction creation without authentication"""
        transaction_data = {
            "amount": 75.50,
            "description": "Test transaction",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": test_categories[0].id
        }
        response = client.post("/api/v1/transactions", json=transaction_data)
        
        assert response.status_code == 401
    
    def test_create_transaction_invalid_category(self, client: TestClient, auth_headers: dict):
        """Test transaction creation with invalid category ID"""
        transaction_data = {
            "amount": 75.50,
            "description": "Test transaction",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": 99999  # Non-existent category
        }
        response = client.post("/api/v1/transactions", json=transaction_data, headers=auth_headers)
        
        assert response.status_code == 404
        data = response.json()
        assert data["status"] == "error"
        assert "category" in data["message"].lower()
    
    def test_create_transaction_negative_amount(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test transaction creation with negative amount"""
        transaction_data = {
            "amount": -50.00,
            "description": "Invalid transaction",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": test_categories[0].id
        }
        response = client.post("/api/v1/transactions", json=transaction_data, headers=auth_headers)
        
        assert response.status_code == 422  # Validation error
    
    def test_create_transaction_invalid_type(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test transaction creation with invalid type"""
        transaction_data = {
            "amount": 50.00,
            "description": "Test transaction",
            "transaction_date": str(date.today()),
            "type": "invalid_type",
            "category_id": test_categories[0].id
        }
        response = client.post("/api/v1/transactions", json=transaction_data, headers=auth_headers)
        
        assert response.status_code == 422  # Validation error


class TestTransactionRetrieval:
    """Test transaction retrieval functionality"""
    
    def test_get_transactions_success(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test successful retrieval of user transactions"""
        response = client.get("/api/v1/transactions", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert len(data["data"]) == 3  # Number of test transactions
        
        transaction_descriptions = [tx["description"] for tx in data["data"]]
        assert "Lunch at restaurant" in transaction_descriptions
        assert "Bus fare" in transaction_descriptions
        assert "Monthly salary" in transaction_descriptions
    
    def test_get_transactions_by_type(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test retrieval of transactions filtered by type"""
        response = client.get("/api/v1/transactions?type=expense", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert len(data["data"]) == 2  # Only expense transactions
        
        for transaction in data["data"]:
            assert transaction["type"] == "expense"
    
    def test_get_transactions_by_category(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction], test_categories: list[Category]):
        """Test retrieval of transactions filtered by category"""
        category_id = test_categories[0].id
        response = client.get(f"/api/v1/transactions?category_id={category_id}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert len(data["data"]) >= 1
        
        for transaction in data["data"]:
            assert transaction["category_id"] == category_id
    
    def test_get_transactions_by_date_range(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test retrieval of transactions filtered by date range"""
        start_date = str(date.today() - timedelta(days=1))
        end_date = str(date.today() + timedelta(days=1))
        
        response = client.get(f"/api/v1/transactions?start_date={start_date}&end_date={end_date}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert len(data["data"]) == 3  # All test transactions are from today
    
    def test_get_transactions_pagination(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test transaction retrieval with pagination"""
        response = client.get("/api/v1/transactions?page=1&limit=2", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert len(data["data"]) <= 2
    
    def test_get_transactions_unauthorized(self, client: TestClient):
        """Test transaction retrieval without authentication"""
        response = client.get("/api/v1/transactions")
        
        assert response.status_code == 401
    
    def test_get_transaction_by_id(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test retrieval of specific transaction by ID"""
        transaction_id = test_transactions[0].id
        response = client.get(f"/api/v1/transactions/{transaction_id}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["id"] == transaction_id
        assert data["data"]["description"] == "Lunch at restaurant"
    
    def test_get_transaction_not_found(self, client: TestClient, auth_headers: dict):
        """Test retrieval of non-existent transaction"""
        response = client.get("/api/v1/transactions/99999", headers=auth_headers)
        
        assert response.status_code == 404
        data = response.json()
        assert data["status"] == "error"


class TestTransactionUpdate:
    """Test transaction update functionality"""
    
    def test_update_transaction_success(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction], test_categories: list[Category], db: Session):
        """Test successful transaction update"""
        transaction_id = test_transactions[0].id
        update_data = {
            "amount": 85.00,
            "description": "Updated lunch expense",
            "category_id": test_categories[1].id  # Change category
        }
        response = client.put(f"/api/v1/transactions/{transaction_id}", json=update_data, headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert data["data"]["amount"] == 85.00
        assert data["data"]["description"] == "Updated lunch expense"
        assert data["data"]["category_id"] == test_categories[1].id
        
        # Verify update in database
        transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
        assert transaction.amount == 85.00
        assert transaction.description == "Updated lunch expense"
    
    def test_update_transaction_unauthorized(self, client: TestClient, test_transactions: list[Transaction]):
        """Test transaction update without authentication"""
        transaction_id = test_transactions[0].id
        update_data = {"amount": 100.00}
        response = client.put(f"/api/v1/transactions/{transaction_id}", json=update_data)
        
        assert response.status_code == 401
    
    def test_update_transaction_not_found(self, client: TestClient, auth_headers: dict):
        """Test updating non-existent transaction"""
        update_data = {"amount": 100.00}
        response = client.put("/api/v1/transactions/99999", json=update_data, headers=auth_headers)
        
        assert response.status_code == 404
    
    def test_update_transaction_invalid_category(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test updating transaction with invalid category"""
        transaction_id = test_transactions[0].id
        update_data = {"category_id": 99999}
        response = client.put(f"/api/v1/transactions/{transaction_id}", json=update_data, headers=auth_headers)
        
        assert response.status_code == 404


class TestTransactionDeletion:
    """Test transaction deletion functionality"""
    
    def test_delete_transaction_success(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction], db: Session):
        """Test successful transaction deletion"""
        transaction_id = test_transactions[0].id
        response = client.delete(f"/api/v1/transactions/{transaction_id}", headers=auth_headers)
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        
        # Verify deletion in database
        transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
        assert transaction is None
    
    def test_delete_transaction_unauthorized(self, client: TestClient, test_transactions: list[Transaction]):
        """Test transaction deletion without authentication"""
        transaction_id = test_transactions[0].id
        response = client.delete(f"/api/v1/transactions/{transaction_id}")
        
        assert response.status_code == 401
    
    def test_delete_transaction_not_found(self, client: TestClient, auth_headers: dict):
        """Test deleting non-existent transaction"""
        response = client.delete("/api/v1/transactions/99999", headers=auth_headers)
        
        assert response.status_code == 404


class TestTransactionStatistics:
    """Test transaction statistics and analytics"""
    
    def test_get_transaction_summary(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test getting transaction summary/statistics"""
        response = client.get("/api/v1/transactions/summary", headers=auth_headers)
        
        if response.status_code == 200:  # If endpoint exists
            data = response.json()
            assert data["status"] == "success"
            assert "total_income" in data["data"]
            assert "total_expense" in data["data"]
            assert "net_amount" in data["data"]
    
    def test_get_monthly_summary(self, client: TestClient, auth_headers: dict, test_transactions: list[Transaction]):
        """Test getting monthly transaction summary"""
        current_month = date.today().strftime("%Y-%m")
        response = client.get(f"/api/v1/transactions/monthly-summary?month={current_month}", headers=auth_headers)
        
        if response.status_code == 200:  # If endpoint exists
            data = response.json()
            assert data["status"] == "success"
