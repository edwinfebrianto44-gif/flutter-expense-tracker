"""
Enhanced security utilities with bcrypt password hashing,
JWT with refresh tokens, and advanced token management
"""

import bcrypt
from datetime import datetime, timedelta, timezone
from typing import Any, Union, Optional, Dict
from jose import jwt, JWTError
from passlib.context import CryptContext
from fastapi import HTTPException, status, Request
import secrets
import hashlib
from .config import get_settings

settings = get_settings()


class PasswordSecurity:
    """Enhanced password security with bcrypt"""
    
    def __init__(self):
        # Use bcrypt with cost factor 12 for good security vs performance balance
        self.pwd_context = CryptContext(
            schemes=["bcrypt"],
            deprecated="auto",
            bcrypt__rounds=12
        )
    
    def hash_password(self, password: str) -> str:
        """Hash password using bcrypt with salt"""
        return self.pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify password against hash"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def needs_update(self, hashed_password: str) -> bool:
        """Check if password hash needs updating (e.g., cost factor changed)"""
        return self.pwd_context.needs_update(hashed_password)


class JWTManager:
    """Enhanced JWT manager with refresh tokens and better security"""
    
    def __init__(self):
        self.access_token_expire_minutes = getattr(settings, 'jwt_access_token_expire_minutes', 30)
        self.refresh_token_expire_days = getattr(settings, 'jwt_refresh_token_expire_days', 7)
        self.algorithm = getattr(settings, 'jwt_algorithm', 'HS256')
        self.secret_key = getattr(settings, 'jwt_secret_key', 'your-secret-key')
        
    def create_access_token(self, data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
        """Create JWT access token"""
        to_encode = data.copy()
        
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(minutes=self.access_token_expire_minutes)
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "type": "access",
            "jti": secrets.token_urlsafe(32)  # JWT ID for token tracking
        })
        
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt
    
    def create_refresh_token(self, data: Dict[str, Any]) -> str:
        """Create JWT refresh token"""
        to_encode = data.copy()
        expire = datetime.now(timezone.utc) + timedelta(days=self.refresh_token_expire_days)
        
        to_encode.update({
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "type": "refresh",
            "jti": secrets.token_urlsafe(32)  # JWT ID for token tracking
        })
        
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt
    
    def verify_token(self, token: str, token_type: str = "access") -> Dict[str, Any]:
        """Verify and decode JWT token"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            
            # Verify token type
            if payload.get("type") != token_type:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token type"
                )
            
            return payload
            
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token expired"
            )
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials"
            )


class TokenBlacklist:
    """Simple in-memory token blacklist (in production, use Redis)"""
    
    def __init__(self):
        self._blacklisted_tokens = set()
    
    def add_token(self, jti: str):
        """Add token JTI to blacklist"""
        self._blacklisted_tokens.add(jti)
    
    def is_blacklisted(self, jti: str) -> bool:
        """Check if token JTI is blacklisted"""
        return jti in self._blacklisted_tokens


class SecurityUtils:
    """Additional security utilities"""
    
    @staticmethod
    def generate_secure_random_string(length: int = 32) -> str:
        """Generate cryptographically secure random string"""
        return secrets.token_urlsafe(length)
    
    @staticmethod
    def hash_string(string: str) -> str:
        """Hash string using SHA-256"""
        return hashlib.sha256(string.encode()).hexdigest()
    
    @staticmethod
    def get_client_ip(request: Request) -> str:
        """Get client IP address from request"""
        # Check for forwarded headers first (reverse proxy)
        forwarded_for = request.headers.get("X-Forwarded-For")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("X-Real-IP")
        if real_ip:
            return real_ip
        
        # Fallback to direct connection
        return request.client.host if request.client else "unknown"


# Global instances
password_security = PasswordSecurity()
jwt_manager = JWTManager()
token_blacklist = TokenBlacklist()

# Backward compatibility
pwd_context = password_security.pwd_context


def create_access_token(subject: Union[str, Any], expires_delta: timedelta = None):
    """Legacy function for backward compatibility"""
    data = {"sub": str(subject)}
    return jwt_manager.create_access_token(data, expires_delta)


def create_refresh_token(subject: Union[str, Any]):
    """Legacy function for backward compatibility"""
    data = {"sub": str(subject)}
    return jwt_manager.create_refresh_token(data)


def verify_password(plain_password: str, hashed_password: str):
    """Legacy function for backward compatibility"""
    return password_security.verify_password(plain_password, hashed_password)


def get_password_hash(password: str):
    """Legacy function for backward compatibility"""
    return password_security.hash_password(password)


def verify_token(token: str):
    """Legacy function for backward compatibility"""
    try:
        return jwt_manager.verify_token(token)
    except HTTPException:
        return None


def create_tokens_for_user(user_data: Dict[str, Any]) -> Dict[str, str]:
    """Create both access and refresh tokens for user"""
    # Prepare token data
    token_data = {
        "sub": user_data.get("email"),
        "email": user_data.get("email"),
        "user_id": user_data.get("id"),
        "role": user_data.get("role", "user"),
        "full_name": user_data.get("full_name")
    }
    
    # Create tokens
    access_token = jwt_manager.create_access_token(data=token_data)
    refresh_token = jwt_manager.create_refresh_token(data=token_data)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


def verify_access_token(token: str) -> Dict[str, Any]:
    """Verify access token and return payload"""
    payload = jwt_manager.verify_token(token, token_type="access")
    
    # Check if token is blacklisted
    jti = payload.get("jti")
    if jti and token_blacklist.is_blacklisted(jti):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked"
        )
    
    return payload


def revoke_token(token: str):
    """Revoke token by adding to blacklist"""
    try:
        payload = jwt_manager.verify_token(token, token_type="access")
        jti = payload.get("jti")
        if jti:
            token_blacklist.add_token(jti)
    except:
        # Token is already invalid, no need to blacklist
        pass
