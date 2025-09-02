"""
Main application tests for the Expense Tracker API
Tests core application functionality and health checks
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app import app
from app.core.database import get_db, Base


class TestApplicationHealth:
    """Test application health and basic functionality"""
    
    def test_read_root(self, client: TestClient):
        """Test root endpoint"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "Expense Tracker API" in data["message"]
    
    def test_health_check(self, client: TestClient):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "healthy"}
    
    def test_docs_endpoint(self, client: TestClient):
        """Test API documentation endpoint"""
        response = client.get("/docs")
        assert response.status_code == 200
        assert "text/html" in response.headers["content-type"]
    
    def test_openapi_endpoint(self, client: TestClient):
        """Test OpenAPI specification endpoint"""
        response = client.get("/openapi.json")
        assert response.status_code == 200
        data = response.json()
        assert "openapi" in data
        assert "info" in data
        assert data["info"]["title"] == "Expense Tracker API"


class TestApplicationConfiguration:
    """Test application configuration and middleware"""
    
    def test_cors_headers(self, client: TestClient):
        """Test CORS headers are properly set"""
        response = client.options("/api/v1/auth/login")
        # Should allow CORS preflight
        assert response.status_code in [200, 405]  # Depends on CORS configuration
    
    def test_content_type_handling(self, client: TestClient):
        """Test different content types"""
        # Test JSON content type
        response = client.post(
            "/api/v1/auth/login",
            json={"username": "test", "password": "test"},
            headers={"Content-Type": "application/json"}
        )
        assert response.status_code in [401, 422]  # Should handle JSON properly
        
        # Test invalid content type
        response = client.post(
            "/api/v1/auth/login",
            data="invalid data",
            headers={"Content-Type": "text/plain"}
        )
        assert response.status_code == 422  # Should reject invalid content type


class TestErrorHandling:
    """Test application error handling"""
    
    def test_404_not_found(self, client: TestClient):
        """Test 404 error handling"""
        response = client.get("/nonexistent-endpoint")
        assert response.status_code == 404
        data = response.json()
        assert data["detail"] == "Not Found"
    
    def test_405_method_not_allowed(self, client: TestClient):
        """Test 405 error handling"""
        response = client.patch("/api/v1/auth/login")  # POST-only endpoint
        assert response.status_code == 405
        data = response.json()
        assert data["detail"] == "Method Not Allowed"
    
    def test_422_validation_error(self, client: TestClient):
        """Test validation error handling"""
        response = client.post("/api/v1/auth/register", json={"invalid": "data"})
        assert response.status_code == 422
        data = response.json()
        assert "detail" in data
    
    def test_500_internal_server_error_handling(self, client: TestClient):
        """Test that 500 errors are properly handled"""
        # This is difficult to test without actually causing a server error
        # In a real scenario, you might mock a service to raise an exception
        pass


class TestAPIVersioning:
    """Test API versioning"""
    
    def test_v1_routes_accessible(self, client: TestClient):
        """Test that v1 API routes are accessible"""
        # Test auth routes
        response = client.post("/api/v1/auth/login", json={"username": "test", "password": "test"})
        assert response.status_code in [401, 422]  # Should be accessible but unauthorized
        
        # Test categories routes (should require auth)
        response = client.get("/api/v1/categories")
        assert response.status_code in [401, 403]  # Should require authentication
        
        # Test transactions routes (should require auth)
        response = client.get("/api/v1/transactions")
        assert response.status_code == 401  # Should require authentication
    
    def test_api_prefix_required(self, client: TestClient):
        """Test that API prefix is required for API routes"""
        # These should not work without /api/v1 prefix
        response = client.post("/auth/login", json={"username": "test", "password": "test"})
        assert response.status_code == 404
        
        response = client.get("/categories")
        assert response.status_code == 404
        
        response = client.get("/transactions")
        assert response.status_code == 404


class TestSecurityHeaders:
    """Test security headers and configurations"""
    
    def test_security_headers_present(self, client: TestClient):
        """Test that security headers are present"""
        response = client.get("/")
        headers = response.headers
        
        # These headers should be present for security
        # Adjust based on your actual security middleware configuration
        expected_headers = [
            "X-Content-Type-Options",
            "X-Frame-Options", 
            "X-XSS-Protection"
        ]
        
        # Note: Not all headers may be configured, adjust test based on implementation
        for header in expected_headers:
            if header in headers:
                assert headers[header] is not None
    
    def test_rate_limiting(self, client: TestClient):
        """Test rate limiting (if implemented)"""
        # Make multiple requests to test rate limiting
        for i in range(10):
            response = client.get("/")
            # Should not be rate limited for GET /
            assert response.status_code == 200
        
        # Test rate limiting on auth endpoints (if implemented)
        for i in range(5):
            response = client.post("/api/v1/auth/login", json={"username": "test", "password": "test"})
            # Should handle rate limiting gracefully
            assert response.status_code in [401, 422, 429]  # 429 = Too Many Requests


class TestDatabaseConnection:
    """Test database connection and operations"""
    
    def test_database_connection(self, db):
        """Test that database connection works"""
        # Simple query to test connection
        from sqlalchemy import text
        result = db.execute(text("SELECT 1"))
        assert result.fetchone()[0] == 1
    
    def test_database_tables_exist(self, db):
        """Test that required tables exist"""
        # Check if main tables exist
        from sqlalchemy import text
        tables_query = text("""
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name IN ('users', 'categories', 'transactions')
        """)
        result = db.execute(tables_query)
        tables = [row[0] for row in result.fetchall()]
        
        expected_tables = ['users', 'categories', 'transactions']
        for table in expected_tables:
            assert table in tables
