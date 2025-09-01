from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date
from ..core.database import get_db
from ..core.response import success_response
from ..core.deps import get_current_active_user
from ..schemas.transaction import Transaction, TransactionCreate, TransactionUpdate, TransactionFilter
from ..schemas.user import User
from ..schemas.openapi import *
from ..services.transaction import TransactionService

router = APIRouter()


@router.get(
    "/",
    response_model=dict,
    summary="Get user transactions",
    description="""
    Retrieve transactions for the authenticated user with optional filtering.
    
    **Query Parameters:**
    - `skip`: Number of records to skip (pagination offset)
    - `limit`: Maximum number of records to return (pagination limit)
    - `start_date`: Filter transactions from this date (YYYY-MM-DD)
    - `end_date`: Filter transactions until this date (YYYY-MM-DD)
    - `category_id`: Filter by specific category ID
    - `transaction_type`: Filter by transaction type ('expense' or 'income')
    
    **Authentication Required:** Yes (Bearer token)
    
    **Returns:** Paginated list of user's transactions with category details
    """,
    responses={
        200: {
            "description": "Transactions retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Transactions retrieved successfully",
                        "data": {
                            "transactions": [
                                {
                                    "id": 1,
                                    "amount": 25.50,
                                    "description": "Lunch at restaurant",
                                    "date": "2024-01-15",
                                    "type": "expense",
                                    "category_id": 1,
                                    "category": {
                                        "id": 1,
                                        "name": "Food",
                                        "icon": "🍔",
                                        "color": "#EF4444"
                                    },
                                    "user_id": 1
                                }
                            ],
                            "total": 1,
                            "skip": 0,
                            "limit": 100
                        }
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        422: {
            "description": "Invalid query parameters"
        }
    }
)
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


@router.get(
    "/summary",
    response_model=dict,
    summary="Get financial summary",
    description="""
    Get financial summary and analytics for the authenticated user.
    
    **Query Parameters:**
    - `start_date`: Calculate summary from this date (YYYY-MM-DD)
    - `end_date`: Calculate summary until this date (YYYY-MM-DD)
    - `period`: Predefined period ('week', 'month', 'year', 'all')
    
    **Authentication Required:** Yes (Bearer token)
    
    **Returns:** Financial summary including total income, expenses, balance, and category breakdowns
    """,
    responses={
        200: {
            "description": "Financial summary retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Summary retrieved successfully",
                        "data": {
                            "total_income": 5000.00,
                            "total_expenses": 3250.50,
                            "net_balance": 1749.50,
                            "transaction_count": 25,
                            "period": {
                                "start_date": "2024-01-01",
                                "end_date": "2024-01-31"
                            },
                            "category_breakdown": [
                                {
                                    "category_id": 1,
                                    "category_name": "Food",
                                    "category_type": "expense",
                                    "total_amount": 850.25,
                                    "transaction_count": 12,
                                    "percentage": 26.17
                                }
                            ],
                            "daily_totals": [
                                {
                                    "date": "2024-01-15",
                                    "total_income": 0.00,
                                    "total_expenses": 45.50,
                                    "net": -45.50
                                }
                            ]
                        }
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        422: {
            "description": "Invalid query parameters"
        }
    }
)
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


@router.get(
    "/{transaction_id}",
    response_model=dict,
    summary="Get transaction by ID",
    description="""
    Retrieve a specific transaction by its ID.
    
    **Path Parameters:**
    - `transaction_id`: The unique identifier of the transaction
    
    **Authentication Required:** Yes (Bearer token)
    
    **Security:** User can only access their own transactions
    """,
    responses={
        200: {
            "description": "Transaction retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Transaction retrieved successfully",
                        "data": {
                            "id": 1,
                            "amount": 75.20,
                            "description": "Weekly groceries",
                            "date": "2024-01-15",
                            "type": "expense",
                            "category_id": 1,
                            "category": {
                                "id": 1,
                                "name": "Food",
                                "icon": "🍔",
                                "color": "#EF4444"
                            },
                            "user_id": 1,
                            "created_at": "2024-01-15T10:30:00Z",
                            "updated_at": "2024-01-15T10:30:00Z"
                        }
                    }
                }
            }
        },
        404: {
            "description": "Transaction not found",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Transaction not found"
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        403: {
            "description": "Forbidden - Cannot access other user's transaction"
        }
    }
)
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


@router.post(
    "/",
    response_model=dict,
    status_code=201,
    summary="Create new transaction",
    description="""
    Create a new income or expense transaction for the authenticated user.
    
    **Request Body:**
    - Transaction details including amount, description, date, type, and category
    
    **Authentication Required:** Yes (Bearer token)
    
    **Business Rules:**
    - Amount must be positive
    - Date cannot be in the future
    - Category must belong to the user
    - Category type must match transaction type
    """,
    responses={
        201: {
            "description": "Transaction created successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Transaction created successfully",
                        "data": {
                            "id": 15,
                            "amount": 120.00,
                            "description": "Salary bonus",
                            "date": "2024-01-15",
                            "type": "income",
                            "category_id": 6,
                            "category": {
                                "id": 6,
                                "name": "Salary",
                                "icon": "💰",
                                "color": "#10B981"
                            },
                            "user_id": 1,
                            "created_at": "2024-01-15T14:30:00Z"
                        }
                    }
                }
            }
        },
        400: {
            "description": "Invalid request data or business rule violation",
            "content": {
                "application/json": {
                    "examples": {
                        "category_mismatch": {
                            "summary": "Category type mismatch",
                            "value": {
                                "success": False,
                                "message": "Category type does not match transaction type"
                            }
                        },
                        "future_date": {
                            "summary": "Future date",
                            "value": {
                                "success": False,
                                "message": "Transaction date cannot be in the future"
                            }
                        }
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        422: {
            "description": "Validation error",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "amount"],
                                "msg": "ensure this value is greater than 0",
                                "type": "value_error.number.not_gt"
                            }
                        ]
                    }
                }
            }
        }
    }
)
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


@router.put(
    "/{transaction_id}",
    response_model=dict,
    summary="Update transaction",
    description="""
    Update an existing transaction for the authenticated user.
    
    **Path Parameters:**
    - `transaction_id`: The unique identifier of the transaction to update
    
    **Request Body:**
    - Updated transaction information
    
    **Authentication Required:** Yes (Bearer token)
    
    **Security:** User can only update their own transactions
    
    **Business Rules:**
    - Amount must be positive
    - Date cannot be in the future
    - Category must belong to the user
    - Category type must match transaction type
    """,
    responses={
        200: {
            "description": "Transaction updated successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Transaction updated successfully",
                        "data": {
                            "id": 1,
                            "amount": 85.50,
                            "description": "Updated grocery shopping",
                            "date": "2024-01-15",
                            "type": "expense",
                            "category_id": 1,
                            "category": {
                                "id": 1,
                                "name": "Food",
                                "icon": "🍔",
                                "color": "#EF4444"
                            },
                            "user_id": 1,
                            "updated_at": "2024-01-15T16:45:00Z"
                        }
                    }
                }
            }
        },
        400: {
            "description": "Invalid request data or business rule violation"
        },
        404: {
            "description": "Transaction not found",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Transaction not found"
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        403: {
            "description": "Forbidden - Cannot update other user's transaction"
        }
    }
)
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


@router.delete(
    "/{transaction_id}",
    response_model=dict,
    summary="Delete transaction",
    description="""
    Delete a transaction for the authenticated user.
    
    **Path Parameters:**
    - `transaction_id`: The unique identifier of the transaction to delete
    
    **Authentication Required:** Yes (Bearer token)
    
    **Security:** User can only delete their own transactions
    
    **Note:** This action is irreversible. Consider soft deletion for audit purposes.
    """,
    responses={
        200: {
            "description": "Transaction deleted successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Transaction deleted successfully"
                    }
                }
            }
        },
        404: {
            "description": "Transaction not found",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Transaction not found"
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        403: {
            "description": "Forbidden - Cannot delete other user's transaction"
        }
    }
)
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
