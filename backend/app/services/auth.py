from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from ..crud import user as crud_user
from ..schemas.user import UserCreate, UserLogin
from ..core.security import create_access_token, create_refresh_token
from ..models.user import User


class AuthService:
    @staticmethod
    def register_user(db: Session, user_data: UserCreate) -> User:
        # Check if user already exists
        if crud_user.get_user_by_email(db, user_data.email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        if crud_user.get_user_by_username(db, user_data.username):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already taken"
            )
        
        return crud_user.create_user(db, user_data)
    
    @staticmethod
    def login_user(db: Session, login_data: UserLogin) -> dict:
        user = crud_user.authenticate_user(db, login_data.username, login_data.password)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect username or password"
            )
        
        access_token = create_access_token(subject=user.username)
        refresh_token = create_refresh_token(subject=user.username)
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }
