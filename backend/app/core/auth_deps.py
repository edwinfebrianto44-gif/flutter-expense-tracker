"""
Enhanced authentication and authorization dependencies
"""

from typing import Optional, List
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from datetime import datetime

from app.core.database import get_db
from app.core.security import verify_access_token, SecurityUtils
from app.core.rate_limiting import check_api_rate_limit
from app.models.user import User
from app.crud.user import get_user_by_id, get_user_by_email


security = HTTPBearer()


async def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """
    Get current authenticated user with rate limiting and security checks
    """
    # Apply rate limiting for API requests
    check_api_rate_limit(request)
    
    # Verify token format and extract payload
    token = credentials.credentials
    
    try:
        payload = verify_access_token(token)
        user_id = payload.get("user_id")
        email = payload.get("email")
        
        if not user_id or not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
        
        # Get user from database
        user = get_user_by_id(db, user_id=int(user_id))
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        # Check if user is active
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is deactivated"
            )
        
        # Check if user is locked due to failed login attempts
        if user.locked_until and user.locked_until > datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is temporarily locked"
            )
        
        # Update last login (optional, might be too frequent)
        # user.last_login = datetime.utcnow()
        # db.commit()
        
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )


def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Get current active user (additional check)
    """
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    return current_user


def get_current_admin_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """
    Get current user and verify admin privileges
    """
    if not current_user.is_admin():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required"
        )
    return current_user


def get_current_verified_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """
    Get current user and verify email verification
    """
    if not current_user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Email verification required"
        )
    return current_user


class PermissionChecker:
    """
    Permission checker for resource-based access control
    """
    
    def __init__(self, required_permissions: List[str] = None):
        self.required_permissions = required_permissions or []
    
    def __call__(self, current_user: User = Depends(get_current_active_user)) -> User:
        """
        Check if user has required permissions
        """
        # Admin has all permissions
        if current_user.is_admin():
            return current_user
        
        # Check specific permissions (extend this based on your permission system)
        for permission in self.required_permissions:
            if not self._user_has_permission(current_user, permission):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Missing required permission: {permission}"
                )
        
        return current_user
    
    def _user_has_permission(self, user: User, permission: str) -> bool:
        """
        Check if user has specific permission
        Extend this method based on your permission system
        """
        # Basic permission mapping for demonstration
        user_permissions = {
            "user": [
                "read_own_data",
                "write_own_data",
                "delete_own_data"
            ],
            "admin": [
                "read_all_data",
                "write_all_data", 
                "delete_all_data",
                "manage_users",
                "system_admin"
            ]
        }
        
        role_permissions = user_permissions.get(user.role, [])
        return permission in role_permissions


class ResourceOwnerChecker:
    """
    Check if user owns or can access a specific resource
    """
    
    def __init__(self, resource_user_id_field: str = "user_id"):
        self.resource_user_id_field = resource_user_id_field
    
    def __call__(
        self,
        resource_user_id: int,
        current_user: User = Depends(get_current_active_user)
    ) -> User:
        """
        Check if user can access resource
        """
        if not current_user.can_access_user_data(resource_user_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: insufficient permissions"
            )
        
        return current_user


def require_admin():
    """
    Dependency factory for admin-only endpoints
    """
    return Depends(get_current_admin_user)


def require_verified():
    """
    Dependency factory for verified-user-only endpoints
    """
    return Depends(get_current_verified_user)


def require_permissions(permissions: List[str]):
    """
    Dependency factory for permission-based access control
    """
    return Depends(PermissionChecker(permissions))


def require_resource_owner(resource_user_id_field: str = "user_id"):
    """
    Dependency factory for resource ownership checking
    """
    return Depends(ResourceOwnerChecker(resource_user_id_field))


async def get_optional_user(
    request: Request,
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: Session = Depends(get_db)
) -> Optional[User]:
    """
    Get current user if authenticated, otherwise return None
    Useful for optional authentication endpoints
    """
    if not credentials:
        return None
    
    try:
        return await get_current_user(request, credentials, db)
    except HTTPException:
        return None


def get_client_info(request: Request) -> dict:
    """
    Extract client information from request
    """
    return {
        "ip_address": SecurityUtils.get_client_ip(request),
        "user_agent": request.headers.get("User-Agent", "Unknown"),
        "referer": request.headers.get("Referer"),
        "accept_language": request.headers.get("Accept-Language"),
    }
