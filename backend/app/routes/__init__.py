from fastapi import APIRouter
from . import auth, category, transaction

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(category.router, prefix="/categories", tags=["categories"])
api_router.include_router(transaction.router, prefix="/transactions", tags=["transactions"])
