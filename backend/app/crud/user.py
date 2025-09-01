"""
Enhanced CRUD operations for user management with role-based access
"""

from typing import Optional, List
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from datetime import datetime

from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate, UserRoleUpdate
from ..core.security import password_security, get_password_hash, verify_password
from ..core.validation import InputValidator


def get_user_by_id(db: Session, user_id: int) -> Optional[User]:
    """Get user by ID"""
    return db.query(User).filter(User.id == user_id).first()


def get_user(db: Session, user_id: int) -> Optional[User]:
    """Legacy function - get user by ID"""
    return get_user_by_id(db, user_id)


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Get user by email"""
    return db.query(User).filter(User.email == email).first()


def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """Get user by username"""
    return db.query(User).filter(User.username == username).first()


def get_users(
    db: Session, 
    skip: int = 0, 
    limit: int = 100,
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    search: Optional[str] = None
) -> List[User]:
    """
    Get users with filtering options (admin only)
    """
    query = db.query(User)
    
    # Apply filters
    if role:
        query = query.filter(User.role == role)
    
    if is_active is not None:
        query = query.filter(User.is_active == is_active)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                User.username.ilike(search_term),
                User.email.ilike(search_term),
                User.full_name.ilike(search_term)
            )
        )
    
    return query.offset(skip).limit(limit).all()


def get_users_count(
    db: Session,
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    search: Optional[str] = None
) -> int:
    """Get total count of users with filters"""
    query = db.query(User)
    
    if role:
        query = query.filter(User.role == role)
    
    if is_active is not None:
        query = query.filter(User.is_active == is_active)
    
    if search:
        search_term = f"%{search}%"
        query = query.filter(
            or_(
                User.username.ilike(search_term),
                User.email.ilike(search_term),
                User.full_name.ilike(search_term)
            )
        )
    
    return query.count()


def create_user(db: Session, user: UserCreate) -> User:
    """Create new user with enhanced security"""
    
    # Hash password using enhanced security
    hashed_password = get_password_hash(user.password)
    
    # Create user instance with new fields
    db_user = User(
        username=user.username,
        email=user.email,
        password_hash=hashed_password,
        full_name=getattr(user, 'full_name', None),
        role="user",  # Default role
        is_active=True,
        is_verified=False,  # Require email verification
        failed_login_attempts=0
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user


def update_user(db: Session, user_id: int, user_update: UserUpdate) -> Optional[User]:
    """Update user information"""
    user = get_user_by_id(db, user_id)
    if not user:
        return None
    
    # Update only provided fields
    update_data = user_update.dict(exclude_unset=True)
    
    for field, value in update_data.items():
        if hasattr(user, field):
            setattr(user, field, value)
    
    if hasattr(user, 'updated_at'):
        user.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(user)
    
    return user


def update_user_role(db: Session, user_id: int, role_update: UserRoleUpdate, current_user: User) -> Optional[User]:
    """Update user role (admin only)"""
    if not current_user.is_admin():
        raise ValueError("Admin privileges required")
    
    user = get_user_by_id(db, user_id)
    if not user:
        return None
    
    # Prevent admin from demoting themselves
    if user.id == current_user.id and role_update.role != "admin":
        raise ValueError("Cannot change your own admin role")
    
    user.role = role_update.role
    if hasattr(user, 'updated_at'):
        user.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(user)
    
    return user


def deactivate_user(db: Session, user_id: int, current_user: User) -> Optional[User]:
    """Deactivate user account (admin only)"""
    if not current_user.is_admin():
        raise ValueError("Admin privileges required")
    
    user = get_user_by_id(db, user_id)
    if not user:
        return None
    
    # Prevent admin from deactivating themselves
    if user.id == current_user.id:
        raise ValueError("Cannot deactivate your own account")
    
    user.is_active = False
    if hasattr(user, 'updated_at'):
        user.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(user)
    
    return user


def activate_user(db: Session, user_id: int, current_user: User) -> Optional[User]:
    """Activate user account (admin only)"""
    if not current_user.is_admin():
        raise ValueError("Admin privileges required")
    
    user = get_user_by_id(db, user_id)
    if not user:
        return None
    
    user.is_active = True
    if hasattr(user, 'failed_login_attempts'):
        user.failed_login_attempts = 0
    if hasattr(user, 'locked_until'):
        user.locked_until = None
    if hasattr(user, 'updated_at'):
        user.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(user)
    
    return user


def reset_user_failed_attempts(db: Session, user_id: int, current_user: User) -> Optional[User]:
    """Reset failed login attempts for user (admin only)"""
    if not current_user.is_admin():
        raise ValueError("Admin privileges required")
    
    user = get_user_by_id(db, user_id)
    if not user:
        return None
    
    if hasattr(user, 'failed_login_attempts'):
        user.failed_login_attempts = 0
    if hasattr(user, 'locked_until'):
        user.locked_until = None
    if hasattr(user, 'updated_at'):
        user.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(user)
    
    return user


def update_user_login_info(db: Session, user: User, client_info: dict = None):
    """Update user login information"""
    if hasattr(user, 'last_login'):
        user.last_login = datetime.utcnow()
    if hasattr(user, 'failed_login_attempts'):
        user.failed_login_attempts = 0
    if hasattr(user, 'locked_until'):
        user.locked_until = None
    
    db.commit()
    db.refresh(user)
    
    return user


def get_user_statistics(db: Session) -> dict:
    """Get user statistics (admin only)"""
    total_users = db.query(User).count()
    active_users = db.query(User).filter(User.is_active == True).count()
    
    # Handle cases where role column might not exist yet
    try:
        admin_users = db.query(User).filter(User.role == "admin").count()
    except:
        admin_users = 0
    
    try:
        verified_users = db.query(User).filter(User.is_verified == True).count()
    except:
        verified_users = 0
    
    try:
        locked_users = db.query(User).filter(User.locked_until.isnot(None)).count()
    except:
        locked_users = 0
    
    return {
        "total_users": total_users,
        "active_users": active_users,
        "inactive_users": total_users - active_users,
        "admin_users": admin_users,
        "regular_users": total_users - admin_users,
        "verified_users": verified_users,
        "unverified_users": total_users - verified_users,
        "locked_users": locked_users
    }


def update_user(db: Session, user_id: int, user_update: UserUpdate) -> Optional[User]:
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    
    update_data = user_update.dict(exclude_unset=True)
    if "password" in update_data:
        update_data["password_hash"] = get_password_hash(update_data.pop("password"))
    
    for field, value in update_data.items():
        setattr(db_user, field, value)
    
    db.commit()
    db.refresh(db_user)
    return db_user


def authenticate_user(db: Session, username: str, password: str) -> Optional[User]:
    user = get_user_by_username(db, username)
    if not user:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user
