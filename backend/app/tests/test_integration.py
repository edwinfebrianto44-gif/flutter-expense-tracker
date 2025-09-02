"""
Integration tests for the Expense Tracker API
Tests complete workflows and database interactions
"""
import pytest
from datetime import date, timedelta
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.category import Category
from app.models.transaction import Transaction


class TestUserWorkflow:
    """Test complete user workflow from registration to transactions"""
    
    def test_complete_user_journey(self, client: TestClient, db: Session):
        """Test complete user journey: register → login → create category → create transaction"""
        
        # Step 1: Register user
        register_data = {
            "username": "journeyuser",
            "email": "journey@example.com",
            "password": "strongpassword123",
            "full_name": "Journey User"
        }
        register_response = client.post("/api/v1/auth/register", json=register_data)
        assert register_response.status_code == 200
        
        # Step 2: Login user
        login_data = {
            "username": "journeyuser",
            "password": "strongpassword123"
        }
        login_response = client.post("/api/v1/auth/login", json=login_data)
        assert login_response.status_code == 200
        
        token = login_response.json()["data"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # Step 3: Create category
        category_data = {
            "name": "Entertainment",
            "type": "expense",
            "color": "#9C27B0",
            "icon": "movie"
        }
        category_response = client.post("/api/v1/categories", json=category_data, headers=headers)
        assert category_response.status_code == 200
        category_id = category_response.json()["data"]["id"]
        
        # Step 4: Create transaction
        transaction_data = {
            "amount": 25.99,
            "description": "Movie tickets",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": category_id
        }
        transaction_response = client.post("/api/v1/transactions", json=transaction_data, headers=headers)
        assert transaction_response.status_code == 200
        
        # Step 5: Verify transaction was created with correct relationships
        transaction_id = transaction_response.json()["data"]["id"]
        get_transaction_response = client.get(f"/api/v1/transactions/{transaction_id}", headers=headers)
        assert get_transaction_response.status_code == 200
        
        transaction_data = get_transaction_response.json()["data"]
        assert transaction_data["amount"] == 25.99
        assert transaction_data["category_id"] == category_id
        
        # Step 6: Verify data integrity in database
        user = db.query(User).filter(User.username == "journeyuser").first()
        category = db.query(Category).filter(Category.id == category_id).first()
        transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
        
        assert user is not None
        assert category is not None
        assert transaction is not None
        assert category.user_id == user.id
        assert transaction.user_id == user.id
        assert transaction.category_id == category.id


class TestDataConsistency:
    """Test data consistency across different operations"""
    
    def test_cascade_operations(self, client: TestClient, auth_headers: dict, test_user: User, db: Session):
        """Test how related data behaves during cascade operations"""
        
        # Create category
        category_data = {
            "name": "Test Category",
            "type": "expense",
            "color": "#FF5722",
            "icon": "test"
        }
        category_response = client.post("/api/v1/categories", json=category_data, headers=auth_headers)
        category_id = category_response.json()["data"]["id"]
        
        # Create transaction linked to category
        transaction_data = {
            "amount": 100.00,
            "description": "Test transaction",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": category_id
        }
        transaction_response = client.post("/api/v1/transactions", json=transaction_data, headers=auth_headers)
        transaction_id = transaction_response.json()["data"]["id"]
        
        # Verify both exist
        assert db.query(Category).filter(Category.id == category_id).first() is not None
        assert db.query(Transaction).filter(Transaction.id == transaction_id).first() is not None
        
        # Try to delete category (should handle based on business logic)
        delete_response = client.delete(f"/api/v1/categories/{category_id}", headers=auth_headers)
        
        if delete_response.status_code == 200:
            # If deletion is allowed, transaction should be handled appropriately
            transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
            # Either transaction is deleted (cascade) or category_id is set to null
            assert transaction is None or transaction.category_id is None
        elif delete_response.status_code == 400:
            # If deletion is prevented due to existing transactions
            assert "cannot delete" in delete_response.json()["message"].lower() or "has transactions" in delete_response.json()["message"].lower()
    
    def test_user_data_isolation(self, client: TestClient, db: Session):
        """Test that users can only access their own data"""
        
        # Create two users
        user1_data = {
            "username": "user1",
            "email": "user1@example.com",
            "password": "password123",
            "full_name": "User One"
        }
        user2_data = {
            "username": "user2", 
            "email": "user2@example.com",
            "password": "password123",
            "full_name": "User Two"
        }
        
        client.post("/api/v1/auth/register", json=user1_data)
        client.post("/api/v1/auth/register", json=user2_data)
        
        # Login both users
        user1_login = client.post("/api/v1/auth/login", json={"username": "user1", "password": "password123"})
        user2_login = client.post("/api/v1/auth/login", json={"username": "user2", "password": "password123"})
        
        user1_token = user1_login.json()["data"]["access_token"]
        user2_token = user2_login.json()["data"]["access_token"]
        
        user1_headers = {"Authorization": f"Bearer {user1_token}"}
        user2_headers = {"Authorization": f"Bearer {user2_token}"}
        
        # User 1 creates category and transaction
        category_data = {
            "name": "User1 Category",
            "type": "expense",
            "color": "#FF5722",
            "icon": "category1"
        }
        category_response = client.post("/api/v1/categories", json=category_data, headers=user1_headers)
        category_id = category_response.json()["data"]["id"]
        
        transaction_data = {
            "amount": 50.00,
            "description": "User1 transaction",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": category_id
        }
        transaction_response = client.post("/api/v1/transactions", json=transaction_data, headers=user1_headers)
        transaction_id = transaction_response.json()["data"]["id"]
        
        # User 2 should not see User 1's data
        user2_categories = client.get("/api/v1/categories", headers=user2_headers)
        user2_transactions = client.get("/api/v1/transactions", headers=user2_headers)
        
        assert len(user2_categories.json()["data"]) == 0
        assert len(user2_transactions.json()["data"]) == 0
        
        # User 2 should not be able to access User 1's specific resources
        user2_category_access = client.get(f"/api/v1/categories/{category_id}", headers=user2_headers)
        user2_transaction_access = client.get(f"/api/v1/transactions/{transaction_id}", headers=user2_headers)
        
        assert user2_category_access.status_code == 404
        assert user2_transaction_access.status_code == 404


class TestDatabaseTransactions:
    """Test database transaction integrity"""
    
    def test_transaction_rollback_on_error(self, client: TestClient, auth_headers: dict, db: Session):
        """Test that database transactions are rolled back on errors"""
        
        initial_category_count = db.query(Category).count()
        
        # Create valid category
        valid_category = {
            "name": "Valid Category",
            "type": "expense",
            "color": "#FF5722",
            "icon": "valid"
        }
        response = client.post("/api/v1/categories", json=valid_category, headers=auth_headers)
        assert response.status_code == 200
        
        # Attempt to create invalid transaction (should fail)
        invalid_transaction = {
            "amount": -100.00,  # Invalid negative amount
            "description": "Invalid transaction",
            "transaction_date": str(date.today()),
            "type": "expense",
            "category_id": response.json()["data"]["id"]
        }
        
        error_response = client.post("/api/v1/transactions", json=invalid_transaction, headers=auth_headers)
        assert error_response.status_code == 422
        
        # Verify category was still created (operations are independent)
        final_category_count = db.query(Category).count()
        assert final_category_count == initial_category_count + 1
    
    def test_concurrent_operations(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test handling of concurrent operations"""
        
        category_id = test_categories[0].id
        
        # Create multiple transactions concurrently (simulated)
        transaction_data_list = [
            {
                "amount": 10.00,
                "description": f"Transaction {i}",
                "transaction_date": str(date.today()),
                "type": "expense",
                "category_id": category_id
            }
            for i in range(5)
        ]
        
        responses = []
        for transaction_data in transaction_data_list:
            response = client.post("/api/v1/transactions", json=transaction_data, headers=auth_headers)
            responses.append(response)
        
        # All transactions should be created successfully
        for response in responses:
            assert response.status_code == 200
        
        # Verify all transactions exist
        get_response = client.get("/api/v1/transactions", headers=auth_headers)
        transactions = get_response.json()["data"]
        
        created_descriptions = [t["description"] for t in transactions if t["description"].startswith("Transaction")]
        assert len(created_descriptions) >= 5


class TestAPIPerformance:
    """Basic performance and load tests"""
    
    def test_bulk_operations(self, client: TestClient, auth_headers: dict, test_categories: list[Category]):
        """Test performance with bulk operations"""
        
        category_id = test_categories[0].id
        
        # Create many transactions
        for i in range(20):
            transaction_data = {
                "amount": float(10 + i),
                "description": f"Bulk transaction {i}",
                "transaction_date": str(date.today() - timedelta(days=i % 30)),
                "type": "expense",
                "category_id": category_id
            }
            response = client.post("/api/v1/transactions", json=transaction_data, headers=auth_headers)
            assert response.status_code == 200
        
        # Test retrieval performance
        response = client.get("/api/v1/transactions", headers=auth_headers)
        assert response.status_code == 200
        
        # Test filtered retrieval
        filtered_response = client.get(f"/api/v1/transactions?category_id={category_id}", headers=auth_headers)
        assert filtered_response.status_code == 200
        
        # Test pagination
        paginated_response = client.get("/api/v1/transactions?page=1&limit=10", headers=auth_headers)
        assert paginated_response.status_code == 200
        assert len(paginated_response.json()["data"]) <= 10
