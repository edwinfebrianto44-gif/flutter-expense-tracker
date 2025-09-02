from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from .core.config import get_settings
from .core.logging import configure_logging, get_logger
from .core.middleware import LoggingMiddleware
from .routes import api_router
from .routes import health

settings = get_settings()

# Configure structured logging
configure_logging(log_level=settings.log_level)
logger = get_logger("app")

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title="Expense Tracker API",
        version="1.0.0",
        description="""
## Expense Tracker API Documentation

A comprehensive RESTful API for managing personal finances built with FastAPI.

### Features

* **Authentication**: JWT-based user authentication and authorization
* **Categories**: Manage income and expense categories with icons and colors
* **Transactions**: Full CRUD operations for financial transactions
* **File Upload**: Receipt/proof attachment for transactions
* **Analytics**: Financial summaries and insights
* **Security**: Password hashing, token-based authentication, rate limiting
* **Validation**: Comprehensive input validation and error handling

### Authentication

Most endpoints require authentication using JWT Bearer tokens:

1. **Register** a new account or **Login** with existing credentials
2. Use the returned `access_token` in the Authorization header
3. Format: `Authorization: Bearer <your_token_here>`

### Base URL

```
http://localhost:8000/api/v1
```

### Response Format

All responses follow a consistent format:

**Success Response:**
```json
{
  "data": { ... },
  "message": "Success message"
}
```

**Error Response:**
```json
{
  "message": "Error description",
  "detail": "Detailed error information"
}
```

### Status Codes

* `200` - Success
* `201` - Created
* `400` - Bad Request
* `401` - Unauthorized
* `403` - Forbidden
* `404` - Not Found
* `422` - Validation Error
* `500` - Internal Server Error
        """,
        routes=app.routes,
        tags=[
            {
                "name": "Authentication",
                "description": "User registration, login, and token management"
            },
            {
                "name": "Categories",
                "description": "Manage income and expense categories"
            },
            {
                "name": "Transactions", 
                "description": "Financial transaction management"
            },
            {
                "name": "File Upload",
                "description": "Receipt and proof attachment management"
            },
            {
                "name": "Analytics",
                "description": "Financial summaries and reports"
            },
            {
                "name": "Health Check",
                "description": "API health monitoring and status endpoints"
            },
            {
                "name": "Metrics",
                "description": "Application metrics and monitoring"
            }
        ]
    )
    
    openapi_schema["info"]["x-logo"] = {
        "url": "https://fastapi.tiangolo.com/img/logo-margin/logo-teal.png"
    }
    
    # Add security scheme
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": "Enter your JWT token in the format: Bearer <token>"
        }
    }
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app = FastAPI(
    title="Expense Tracker API",
    version="1.0.0",
    description="A comprehensive API for managing personal finances",
    debug=settings.debug,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

app.openapi = custom_openapi

# Add logging middleware first
app.add_middleware(LoggingMiddleware)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files for local storage (only if using local storage)
if settings.storage_type == "local":
    # Create upload directory if it doesn't exist
    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(parents=True, exist_ok=True)
    
    # Mount static files
    app.mount("/storage", StaticFiles(directory=str(upload_dir)), name="storage")

# Include API router
app.include_router(api_router, prefix="/api/v1")

# Include health check endpoints at root level
app.include_router(health.router, tags=["Health Check"])


@app.get("/")
def read_root():
    logger.info("Root endpoint accessed")
    return {
        "message": f"Welcome to {settings.app_name}",
        "version": settings.app_version,
        "status": "running",
        "docs": "/docs",
        "health": "/health"
    }


# Remove the simple health endpoint as we have detailed ones now
