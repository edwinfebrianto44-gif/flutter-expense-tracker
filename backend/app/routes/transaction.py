from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date
from ..core.database import get_db
from ..core.response import success_response
from ..core.deps import get_current_active_user
from ..schemas.transaction import Transaction, TransactionCreate, TransactionUpdate, TransactionFilter
from ..schemas.user import User
from ..services.transaction import TransactionService

router = APIRouter()


@router.get("/", response_model=dict)
def get_transactions(
    skip: int = 0,
    limit: int = 100,
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    category_id: Optional[int] = Query(None),
    category_type: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get user's transactions with optional filters"""
    filters = TransactionFilter(
        start_date=start_date,
        end_date=end_date,
        category_id=category_id,
        category_type=category_type
    )
    
    transactions = TransactionService.get_transactions(
        db, current_user.id, skip, limit, filters
    )
    
    return success_response(
        message="Transactions retrieved successfully",
        data=transactions,
        meta={
            "skip": skip,
            "limit": limit,
            "filters": filters.dict(exclude_none=True)
        }
    )


@router.get("/summary", response_model=dict)
def get_transaction_summary(
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get transaction summary (income, expense, balance)"""
    summary = TransactionService.get_summary(db, current_user.id, start_date, end_date)
    return success_response(
        message="Transaction summary retrieved successfully",
        data=summary
    )


@router.get("/{transaction_id}", response_model=dict)
def get_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get a specific transaction"""
    transaction = TransactionService.get_transaction(db, transaction_id, current_user.id)
    return success_response(
        message="Transaction retrieved successfully",
        data=transaction
    )


@router.post("/", response_model=dict)
def create_transaction(
    transaction: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a new transaction"""
    db_transaction = TransactionService.create_transaction(db, transaction, current_user.id)
    return success_response(
        message="Transaction created successfully",
        data=db_transaction
    )


@router.put("/{transaction_id}", response_model=dict)
def update_transaction(
    transaction_id: int,
    transaction: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update a transaction"""
    db_transaction = TransactionService.update_transaction(
        db, transaction_id, transaction, current_user.id
    )
    return success_response(
        message="Transaction updated successfully",
        data=db_transaction
    )


@router.delete("/{transaction_id}", response_model=dict)
def delete_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Delete a transaction"""
    TransactionService.delete_transaction(db, transaction_id, current_user.id)
    return success_response(
        message="Transaction deleted successfully"
    )
