# API Documentation Generation and Usage Guide

## OpenAPI 3.0 Documentation

The Expense Tracker API now includes comprehensive OpenAPI 3.0 documentation with the following features:

### 📋 Documentation Features

✅ **Complete API Coverage**
- Authentication endpoints (login, register, refresh)
- Category management (CRUD operations)
- Transaction management (CRUD + filtering)
- Financial summary and analytics
- User profile management

✅ **Detailed Schemas**
- Request/response models with examples
- Validation rules and constraints
- Error response formats
- Authentication requirements

✅ **Interactive Documentation**
- Swagger UI available at `/docs`
- ReDoc available at `/redoc`
- Try-it-out functionality
- Authentication testing

### 🚀 Accessing the Documentation

1. **Start the FastAPI server:**
   ```bash
   cd backend
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

2. **Access Swagger UI:**
   - Open: http://localhost:8000/docs
   - Interactive API testing interface
   - Authentication support built-in

3. **Access ReDoc:**
   - Open: http://localhost:8000/redoc
   - Clean, documentation-focused interface
   - Better for API reference

### 🔧 Using the API Documentation

#### Authentication Flow
1. **Register a new user** at `/auth/register`
2. **Login** at `/auth/login` to get JWT token
3. **Use the "Authorize" button** in Swagger UI to set Bearer token
4. **Test protected endpoints** with authenticated requests

#### Example Authentication:
```json
POST /auth/login
{
  "email": "user@example.com",
  "password": "securepassword"
}

Response:
{
  "success": true,
  "message": "Login successful",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "token_type": "bearer",
    "user": {...}
  }
}
```

### 📊 API Endpoints Overview

#### Authentication (`/auth`)
- `POST /auth/register` - User registration
- `POST /auth/login` - User authentication
- `POST /auth/refresh` - Token refresh
- `GET /auth/me` - Get current user profile

#### Categories (`/categories`)
- `GET /categories` - List user categories
- `POST /categories` - Create new category
- `GET /categories/{id}` - Get specific category
- `PUT /categories/{id}` - Update category
- `DELETE /categories/{id}` - Delete category

#### Transactions (`/transactions`)
- `GET /transactions` - List transactions (with filtering)
- `POST /transactions` - Create new transaction
- `GET /transactions/summary` - Financial summary
- `GET /transactions/{id}` - Get specific transaction
- `PUT /transactions/{id}` - Update transaction
- `DELETE /transactions/{id}` - Delete transaction

### 📱 Postman Collection Export

Generate a Postman collection from the OpenAPI specification:

```bash
cd backend
python export_postman.py
```

This creates `expense_tracker_postman_collection.json` with:
- All endpoints organized by categories
- Authentication setup (Bearer token)
- Request examples and schemas
- Environment variables for easy configuration

### 🧪 Testing the API

#### Using Swagger UI:
1. Navigate to http://localhost:8000/docs
2. Click "Authorize" and enter your Bearer token
3. Expand any endpoint and click "Try it out"
4. Fill in parameters and request body
5. Click "Execute" to test

#### Using Postman:
1. Import the generated collection
2. Set environment variables:
   - `base_url`: http://localhost:8000
   - `jwt_token`: Your authentication token
3. Test endpoints with pre-configured requests

#### Using curl:
```bash
# Register user
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","full_name":"Test User"}'

# Login
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get categories (with auth)
curl -X GET "http://localhost:8000/categories" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 📈 API Response Format

All API responses follow a consistent format:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data here
  }
}
```

Error responses:
```json
{
  "success": false,
  "message": "Error description",
  "errors": {
    // Detailed error information
  }
}
```

### 🔒 Authentication & Security

- JWT Bearer token authentication
- Token includes user information and permissions
- Secure endpoints require valid authentication
- Automatic token validation on protected routes
- CORS support for frontend integration

### 📋 Schema Examples

#### User Schema:
```json
{
  "id": 1,
  "email": "user@example.com",
  "full_name": "John Doe",
  "is_active": true,
  "created_at": "2024-01-15T10:30:00Z"
}
```

#### Category Schema:
```json
{
  "id": 1,
  "name": "Food",
  "type": "expense",
  "icon": "🍔",
  "color": "#EF4444",
  "user_id": 1
}
```

#### Transaction Schema:
```json
{
  "id": 1,
  "amount": 25.50,
  "description": "Lunch at restaurant",
  "date": "2024-01-15",
  "type": "expense",
  "category_id": 1,
  "user_id": 1,
  "category": {
    "id": 1,
    "name": "Food",
    "icon": "🍔",
    "color": "#EF4444"
  }
}
```

### 🛠️ Development Notes

- OpenAPI schemas are defined in `app/schemas/openapi.py`
- Custom OpenAPI configuration in `app/__init__.py`
- Route documentation added to individual route files
- Swagger UI customized with API information and security schemes
- Export script available for Postman collection generation

### 📚 Additional Resources

- [OpenAPI 3.0 Specification](https://swagger.io/specification/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Swagger UI Documentation](https://swagger.io/tools/swagger-ui/)
- [ReDoc Documentation](https://redoc.ly/)
- [Postman Collection Format](https://schema.postman.com/)
