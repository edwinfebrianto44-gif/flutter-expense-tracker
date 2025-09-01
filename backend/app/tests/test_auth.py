import pytest
from fastapi.testclient import TestClient
from app.tests.test_main import client

def test_register_user(client):
    user_data = {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpassword123"
    }
    response = client.post("/api/v1/auth/register", json=user_data)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["data"]["username"] == "testuser"

def test_login_user(client):
    # First register a user
    user_data = {
        "username": "testuser",
        "email": "test@example.com", 
        "password": "testpassword123"
    }
    client.post("/api/v1/auth/register", json=user_data)
    
    # Then login
    login_data = {
        "username": "testuser",
        "password": "testpassword123"
    }
    response = client.post("/api/v1/auth/login", json=login_data)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert "access_token" in data["data"]
