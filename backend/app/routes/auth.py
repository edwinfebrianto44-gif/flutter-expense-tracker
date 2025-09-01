from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..core.database import get_db
from ..core.response import success_response, error_response
from ..schemas.user import UserCreate, UserLogin, User, Token
from ..services.auth import AuthService

router = APIRouter()


@router.post("/register", response_model=dict)
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


@router.post("/login", response_model=dict)
def login(login_data: UserLogin, db: Session = Depends(get_db)):
    """Login user and return JWT tokens"""
    try:
        tokens = AuthService.login_user(db, login_data)
        return success_response(
            message="Login successful",
            data=tokens
        )
    except HTTPException as e:
        return error_response(message=e.detail)
