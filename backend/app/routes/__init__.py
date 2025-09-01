from fastapi import APIRouter
from . import auth, category, transaction, upload, reports, notifications

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(category.router, prefix="/categories", tags=["categories"])
api_router.include_router(transaction.router, prefix="/transactions", tags=["transactions"])
api_router.include_router(upload.router, tags=["file upload"])
api_router.include_router(reports.router, prefix="/reports", tags=["reports & analytics"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["notifications"])
