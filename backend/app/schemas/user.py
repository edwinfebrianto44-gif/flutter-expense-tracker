from pydantic import BaseModel, EmailStr, validator, Field
from typing import Optional, List
from datetime import datetime
from app.core.validation import InputValidator


class UserBase(BaseModel):
    username: str = Field(..., min_length=3, max_length=50, description="Username (3-50 characters)")
    email: EmailStr = Field(..., description="Valid email address")
    full_name: Optional[str] = Field(None, min_length=2, max_length=100, description="Full name (2-100 characters)")


class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=128, description="Password (8-128 characters)")
    
    @validator('email')
    def validate_email_format(cls, v):
        if not InputValidator.validate_email_format(v):
            raise ValueError('Invalid email format')
        return v
    
    @validator('password')
    def validate_password_strength(cls, v):
        is_valid, errors = InputValidator.validate_password_strength(v)
        if not is_valid:
            raise ValueError(f"Password validation failed: {'; '.join(errors)}")
        return v
    
    @validator('username')
    def validate_username(cls, v):
        if not v.replace('_', '').replace('-', '').isalnum():
            raise ValueError('Username can only contain letters, numbers, hyphens, and underscores')
        return v


class UserUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr] = None
    full_name: Optional[str] = Field(None, min_length=2, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    avatar_url: Optional[str] = Field(None, max_length=255)
    
    @validator('email')
    def validate_email_format(cls, v):
        if v and not InputValidator.validate_email_format(v):
            raise ValueError('Invalid email format')
        return v
    
    @validator('username')
    def validate_username(cls, v):
        if v and not v.replace('_', '').replace('-', '').isalnum():
            raise ValueError('Username can only contain letters, numbers, hyphens, and underscores')
        return v


class UserPasswordChange(BaseModel):
    current_password: str = Field(..., description="Current password")
    new_password: str = Field(..., min_length=8, max_length=128, description="New password (8-128 characters)")
    
    @validator('new_password')
    def validate_password_strength(cls, v):
        is_valid, errors = InputValidator.validate_password_strength(v)
        if not is_valid:
            raise ValueError(f"Password validation failed: {'; '.join(errors)}")
        return v


class UserRoleUpdate(BaseModel):
    role: str = Field(..., description="User role")
    
    @validator('role')
    def validate_role(cls, v):
        allowed_roles = ['user', 'admin']
        if v not in allowed_roles:
            raise ValueError(f'Role must be one of: {", ".join(allowed_roles)}')
        return v


class User(UserBase):
    id: int
    role: str = "user"
    is_active: bool = True
    is_verified: bool = False
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UserProfile(BaseModel):
    id: int
    username: str
    email: str
    full_name: Optional[str]
    role: str
    is_active: bool
    is_verified: bool
    phone: Optional[str]
    avatar_url: Optional[str]
    last_login: Optional[datetime]
    created_at: datetime
    
    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    email: EmailStr = Field(..., description="Email address")
    password: str = Field(..., description="Password")
    
    @validator('email')
    def validate_email_format(cls, v):
        if not InputValidator.validate_email_format(v):
            raise ValueError('Invalid email format')
        return v


class UserLoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds
    user: UserProfile


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefresh(BaseModel):
    refresh_token: str = Field(..., description="Valid refresh token")


class TokenData(BaseModel):
    email: Optional[str] = None
    user_id: Optional[int] = None
    role: Optional[str] = None


class UserListResponse(BaseModel):
    users: List[UserProfile]
    total: int
    page: int
    per_page: int
    pages: int


class PasswordResetRequest(BaseModel):
    email: EmailStr = Field(..., description="Email address for password reset")
    
    @validator('email')
    def validate_email_format(cls, v):
        if not InputValidator.validate_email_format(v):
            raise ValueError('Invalid email format')
        return v


class PasswordReset(BaseModel):
    token: str = Field(..., description="Password reset token")
    new_password: str = Field(..., min_length=8, max_length=128, description="New password")
    
    @validator('new_password')
    def validate_password_strength(cls, v):
        is_valid, errors = InputValidator.validate_password_strength(v)
        if not is_valid:
            raise ValueError(f"Password validation failed: {'; '.join(errors)}")
        return v


class EmailVerification(BaseModel):
    token: str = Field(..., description="Email verification token")
