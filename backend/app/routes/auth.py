from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from ..core.database import get_db
from ..core.response import success_response, error_response
from ..core.rate_limiting import check_login_rate_limit, check_register_rate_limit
from ..core.validation import validate_request_data, InputValidator
from ..core.security import create_tokens_for_user, verify_access_token, password_security, jwt_manager
from ..core.auth_deps import get_current_user, get_current_admin_user, get_client_info
from ..schemas.user import (
    UserCreate, UserLogin, UserProfile, UserLoginResponse, 
    TokenRefresh, PasswordResetRequest, UserRoleUpdate
)
from ..crud.user import create_user, get_user_by_email, get_user_by_username, update_user_login_info
from ..models.user import User
from ..schemas.openapi import *

router = APIRouter(tags=["Authentication"])


@router.post(
    "/register",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description="""
    Register a new user account with enhanced validation and security.
    
    **Security Features:**
    - Rate limiting: 3 registration attempts per hour per IP
    - Strong password requirements
    - Email format validation
    - Input sanitization
    
    **Password Requirements:**
    - Minimum 8 characters
    - At least one uppercase letter
    - At least one lowercase letter  
    - At least one digit
    - At least one special character
    - No common weak patterns
    
    **Returns:**
    - User profile information (no sensitive data)
    
    **Example Request:**
    ```json
    {
        "username": "johndoe",
        "email": "john@example.com", 
        "password": "SecurePass123!",
        "full_name": "John Doe"
    }
    ```
    """,
    responses={
        201: {
            "description": "User successfully registered",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "User registered successfully. Please verify your email.",
                        "data": {
                            "id": 1,
                            "username": "johndoe",
                            "email": "john@example.com",
                            "full_name": "John Doe",
                            "role": "user",
                            "is_active": True,
                            "is_verified": False
                        }
                    }
                }
            }
        },
        400: {
            "description": "Registration failed - user exists or validation error",
            "content": {
                "application/json": {
                    "examples": {
                        "user_exists": {
                            "summary": "User already exists",
                            "value": {
                                "success": False,
                                "message": "User with this email already exists"
                            }
                        },
                        "validation_error": {
                            "summary": "Validation failed",
                            "value": {
                                "success": False,
                                "message": "Validation failed",
                                "errors": [
                                    "Password must contain at least one uppercase letter"
                                ]
                            }
                        }
                    }
                }
            }
        },
        429: {
            "description": "Rate limit exceeded",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Too many registration attempts. Try again in 3600 seconds.",
                        "retry_after": 3600
                    }
                }
            }
        },
        422: {
            "description": "Validation error",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "email"],
                                "msg": "field required",
                                "type": "value_error.missing"
                            }
                        ]
                    }
                }
            }
        }
    }
)
def register_user(
    request: Request,
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    """Register a new user with enhanced security validation"""
    
    # Apply rate limiting
    check_register_rate_limit(request)
    
    # Get client info for logging
    client_info = get_client_info(request)
    
    # Additional validation
    validate_request_data(user_data.dict(), "user_register")
    
    # Check if user already exists
    existing_user = get_user_by_email(db, email=user_data.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "success": False,
                "message": "User with this email already exists"
            }
        )
    
    existing_username = get_user_by_username(db, username=user_data.username)
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "success": False,
                "message": "Username already taken"
            }
        )
    
    try:
        # Create user
        user = create_user(db, user_data)
        
        # Return user profile (no sensitive data)
        user_profile = UserProfile.from_orm(user)
        
        return success_response(
            message="User registered successfully. Please verify your email.",
            data=user_profile.dict()
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "success": False,
                "message": "Registration failed. Please try again."
            }
        )
        400: {
            "description": "Email or username already registered",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Email already registered"
                    }
                }
            }
        },
        422: {
            "description": "Validation error",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "email"],
                                "msg": "field required",
                                "type": "value_error.missing"
                            }
                        ]
                    }
                }
            }
        }
    }
)
def register(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    try:
        db_user = AuthService.register_user(db, user)
        return success_response(
            message="User registered successfully",
            data={"id": db_user.id, "username": db_user.username, "email": db_user.email}
        )
    except HTTPException as e:
        return error_response(message=e.detail)


@router.post(
    "/login",
    response_model=dict,
    summary="User login with enhanced security",
    description="""
    Authenticate user with email and password with enhanced security features.
    
    **Security Features:**
    - Rate limiting: 5 login attempts per 5 minutes per IP
    - Account lockout after failed attempts
    - Secure password verification with bcrypt
    - JWT tokens with expiration
    - Client IP and user agent tracking
    
    **Authentication Flow:**
    1. Provide valid email and password
    2. Receive JWT access token and refresh token
    3. Use access token in Authorization header for protected endpoints
    4. Format: `Authorization: Bearer <access_token>`
    
    **Token Information:**
    - Access token: 30 minutes expiration
    - Refresh token: 7 days expiration
    - JWT includes user role and permissions
    
    **Account Security:**
    - Failed login attempts are tracked
    - Account temporarily locked after multiple failures
    - Login history is maintained
    
    **Example Request:**
    ```json
    {
        "email": "john@example.com",
        "password": "SecurePass123!"
    }
    ```
    """,
    responses={
        200: {
            "description": "Login successful",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Login successful",
                        "data": {
                            "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                            "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                            "token_type": "bearer",
                            "expires_in": 1800,
                            "user": {
                                "id": 1,
                                "username": "johndoe",
                                "email": "john@example.com",
                                "full_name": "John Doe",
                                "role": "user",
                                "is_verified": True
                            }
                        }
                    }
                }
            }
        },
        401: {
            "description": "Authentication failed",
            "content": {
                "application/json": {
                    "examples": {
                        "invalid_credentials": {
                            "summary": "Invalid credentials",
                            "value": {
                                "success": False,
                                "message": "Invalid email or password"
                            }
                        },
                        "account_locked": {
                            "summary": "Account locked",
                            "value": {
                                "success": False,
                                "message": "Account temporarily locked due to multiple failed login attempts"
                            }
                        },
                        "account_disabled": {
                            "summary": "Account disabled",
                            "value": {
                                "success": False,
                                "message": "Account has been deactivated"
                            }
                        }
                    }
                }
            }
        },
        429: {
            "description": "Rate limit exceeded",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Too many login attempts. Try again in 300 seconds.",
                        "retry_after": 300
                    }
                }
            }
        },
        422: {
            "description": "Validation error",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "email"],
                                "msg": "Invalid email format",
                                "type": "value_error"
                            }
                        ]
                    }
                }
            }
        }
    }
)
def login(
    request: Request,
    login_data: UserLogin, 
    db: Session = Depends(get_db)
):
    """Enhanced user login with security features"""
    
    # Apply rate limiting for login attempts
    check_login_rate_limit(request)
    
    # Get client information for security logging
    client_info = get_client_info(request)
    
    try:
        # Get user by email
        user = get_user_by_email(db, email=login_data.email)
        
        if not user:
            # Don't reveal whether user exists
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={
                    "success": False,
                    "message": "Invalid email or password"
                }
            )
        
        # Check if account is locked
        if user.locked_until and user.locked_until > datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={
                    "success": False,
                    "message": "Account temporarily locked due to multiple failed login attempts"
                }
            )
        
        # Check if account is active
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={
                    "success": False,
                    "message": "Account has been deactivated"
                }
            )
        
        # Verify password
        if not password_security.verify_password(login_data.password, user.password_hash):
            # Increment failed login attempts
            user.failed_login_attempts += 1
            
            # Lock account if too many failed attempts (5 attempts)
            if user.failed_login_attempts >= 5:
                user.locked_until = datetime.utcnow() + timedelta(minutes=30)
                user.failed_login_attempts = 0  # Reset counter
            
            db.commit()
            
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={
                    "success": False,
                    "message": "Invalid email or password"
                }
            )
        
        # Successful login - reset failed attempts and update login info
        user.failed_login_attempts = 0
        user.locked_until = None
        user.last_login = datetime.utcnow()
        db.commit()
        
        # Create tokens
        user_data = {
            "id": user.id,
            "email": user.email,
            "role": user.role,
            "username": user.username,
            "full_name": user.full_name
        }
        
        tokens = create_tokens_for_user(user_data)
        
        # Prepare response with user profile
        user_profile = UserProfile.from_orm(user)
        
        response_data = {
            **tokens,
            "expires_in": 1800,  # 30 minutes in seconds
            "user": user_profile.dict()
        }
        
        return success_response(
            message="Login successful",
            data=response_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "success": False,
                "message": "Login failed. Please try again."
            }
        )


@router.post(
    "/refresh",
    response_model=dict,
    summary="Refresh access token",
    description="""
    Refresh access token using a valid refresh token.
    
    **Usage:**
    - When access token expires, use refresh token to get new access token
    - Refresh tokens have longer expiration (7 days vs 30 minutes for access tokens)
    - Send refresh token in request body
    
    **Security:**
    - Refresh tokens are single-use in production systems
    - Old refresh token becomes invalid after use
    """,
    responses={
        200: {
            "description": "Token refreshed successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Token refreshed successfully",
                        "data": {
                            "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                            "token_type": "bearer",
                            "expires_in": 1800
                        }
                    }
                }
            }
        },
        401: {
            "description": "Invalid refresh token"
        }
    }
)
def refresh_token(
    refresh_data: TokenRefresh,
    db: Session = Depends(get_db)
):
    """Refresh access token"""
    try:
        # Verify refresh token and create new access token
        new_tokens = jwt_manager.refresh_access_token(refresh_data.refresh_token)
        
        return success_response(
            message="Token refreshed successfully",
            data={
                **new_tokens,
                "expires_in": 1800
            }
        )
    except HTTPException as e:
        raise e
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "success": False,
                "message": "Invalid refresh token"
            }
        )


@router.get(
    "/me",
    response_model=dict,
    summary="Get current user profile",
    description="""
    Get the current authenticated user's profile information.
    
    **Authentication Required:** Yes (Bearer token)
    
    **Returns:** Complete user profile including role and permissions
    """,
    responses={
        200: {
            "description": "User profile retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "User profile retrieved successfully",
                        "data": {
                            "id": 1,
                            "username": "johndoe",
                            "email": "john@example.com",
                            "full_name": "John Doe",
                            "role": "user",
                            "is_active": True,
                            "is_verified": True,
                            "last_login": "2024-01-15T10:30:00Z",
                            "created_at": "2024-01-01T00:00:00Z"
                        }
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        }
    }
)
def get_current_user_profile(
    current_user: User = Depends(get_current_user)
):
    """Get current user profile"""
    user_profile = UserProfile.from_orm(current_user)
    
    return success_response(
        message="User profile retrieved successfully",
        data=user_profile.dict()
    )


# Admin-only endpoints
@router.get(
    "/admin/users",
    response_model=dict,
    summary="Get all users (Admin only)",
    description="""
    Get list of all users with filtering and pagination options.
    
    **Admin privileges required**
    
    **Query Parameters:**
    - `page`: Page number (default: 1)
    - `per_page`: Items per page (default: 20, max: 100)
    - `role`: Filter by user role ('user', 'admin')
    - `is_active`: Filter by active status (true/false)
    - `search`: Search in username, email, or full name
    
    **Returns:** Paginated list of users with metadata
    """,
    responses={
        200: {
            "description": "Users retrieved successfully"
        },
        403: {
            "description": "Forbidden - Admin privileges required"
        }
    }
)
def get_all_users(
    page: int = 1,
    per_page: int = 20,
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Get all users with filtering (admin only)"""
    
    # Validate pagination
    if page < 1:
        page = 1
    if per_page < 1 or per_page > 100:
        per_page = 20
    
    skip = (page - 1) * per_page
    
    # Get users and total count
    users = get_users(
        db=db,
        skip=skip,
        limit=per_page,
        role=role,
        is_active=is_active,
        search=search
    )
    
    total = get_users_count(
        db=db,
        role=role,
        is_active=is_active,
        search=search
    )
    
    pages = (total + per_page - 1) // per_page
    
    # Convert to profile format
    users_data = [UserProfile.from_orm(user).dict() for user in users]
    
    return success_response(
        message="Users retrieved successfully",
        data={
            "users": users_data,
            "total": total,
            "page": page,
            "per_page": per_page,
            "pages": pages
        }
    )


@router.put(
    "/admin/users/{user_id}/role",
    response_model=dict,
    summary="Update user role (Admin only)",
    description="""
    Update a user's role.
    
    **Admin privileges required**
    
    **Available Roles:**
    - `user`: Regular user (default)
    - `admin`: Administrator with full access
    
    **Business Rules:**
    - Admin cannot change their own role to non-admin
    - Role changes take effect immediately
    """,
    responses={
        200: {
            "description": "User role updated successfully"
        },
        403: {
            "description": "Forbidden - Admin privileges required"
        },
        404: {
            "description": "User not found"
        }
    }
)
def update_user_role_endpoint(
    user_id: int,
    role_update: UserRoleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_admin_user)
):
    """Update user role (admin only)"""
    try:
        user = update_user_role(db, user_id, role_update, current_user)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={
                    "success": False,
                    "message": "User not found"
                }
            )
        
        user_profile = UserProfile.from_orm(user)
        
        return success_response(
            message=f"User role updated to {role_update.role}",
            data=user_profile.dict()
        )
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "success": False,
                "message": str(e)
            }
        )
