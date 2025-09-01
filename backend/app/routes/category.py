from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from ..core.database import get_db
from ..core.response import success_response
from ..core.deps import get_current_active_user
from ..schemas.category import Category, CategoryCreate, CategoryUpdate
from ..schemas.user import User
from ..services.category import CategoryService

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional
from ..core.database import get_db
from ..core.response import success_response
from ..core.deps import get_current_active_user
from ..schemas.category import Category, CategoryCreate, CategoryUpdate
from ..schemas.user import User
from ..services.category import CategoryService

router = APIRouter(tags=["Categories"])

@router.get(
    "/",
    response_model=dict,
    summary="Get all categories",
    description="""
    Retrieve all categories for the authenticated user.
    
    **Features:**
    - Pagination support with skip and limit parameters
    - Returns categories with icons and colors
    - Filtered by user ownership
    
    **Query Parameters:**
    - `skip`: Number of records to skip (for pagination)
    - `limit`: Maximum number of records to return
    
    **Authentication Required:** Yes (Bearer token)
    """,
    responses={
        200: {
            "description": "Categories retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Categories retrieved successfully",
                        "data": [
                            {
                                "id": 1,
                                "name": "Food",
                                "type": "expense",
                                "icon": "🍔",
                                "color": "#EF4444",
                                "user_id": 1
                            },
                            {
                                "id": 2,
                                "name": "Salary",
                                "type": "income",
                                "icon": "💰",
                                "color": "#10B981",
                                "user_id": 1
                            }
                        ]
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        }
    }
)
def get_categories(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get all categories"""
    categories = CategoryService.get_categories(db, skip=skip, limit=limit)
    return success_response(
        message="Categories retrieved successfully",
        data=categories
    )


@router.get(
    "/{category_id}",
    response_model=dict,
    summary="Get category by ID",
    description="""
    Retrieve a specific category by its ID.
    
    **Path Parameters:**
    - `category_id`: The unique identifier of the category
    
    **Authentication Required:** Yes (Bearer token)
    """,
    responses={
        200: {
            "description": "Category retrieved successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Category retrieved successfully",
                        "data": {
                            "id": 1,
                            "name": "Food",
                            "type": "expense",
                            "icon": "🍔",
                            "color": "#EF4444",
                            "user_id": 1
                        }
                    }
                }
            }
        },
        404: {
            "description": "Category not found",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Category not found"
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        }
    }
)
def get_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Get a specific category"""
    category = CategoryService.get_category(db, category_id)
    return success_response(
        message="Category retrieved successfully",
        data=category
    )


@router.post(
    "/",
    response_model=dict,
    status_code=201,
    summary="Create new category",
    description="""
    Create a new expense or income category for the authenticated user.
    
    **Request Body:**
    - Category information including name, type, icon, and color
    
    **Authentication Required:** Yes (Bearer token)
    
    **Business Rules:**
    - Category name must be unique per user
    - Type must be either 'expense' or 'income'
    - Color should be a valid hex color code
    """,
    responses={
        201: {
            "description": "Category created successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Category created successfully",
                        "data": {
                            "id": 5,
                            "name": "Entertainment",
                            "type": "expense",
                            "icon": "🎬",
                            "color": "#8B5CF6",
                            "user_id": 1
                        }
                    }
                }
            }
        },
        400: {
            "description": "Invalid request data",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Category with this name already exists"
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
                                "loc": ["body", "name"],
                                "msg": "field required",
                                "type": "value_error.missing"
                            }
                        ]
                    }
                }
            }
        }
    }
)
def create_category(
    category: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Create a new category"""
    db_category = CategoryService.create_category(db, category)
    return success_response(
        message="Category created successfully",
        data=db_category
    )


@router.put(
    "/{category_id}",
    response_model=dict,
    summary="Update category",
    description="""
    Update an existing category for the authenticated user.
    
    **Path Parameters:**
    - `category_id`: The unique identifier of the category to update
    
    **Request Body:**
    - Updated category information
    
    **Authentication Required:** Yes (Bearer token)
    
    **Business Rules:**
    - User can only update their own categories
    - Category name must be unique per user (excluding current category)
    - Cannot change category type if transactions exist for this category
    """,
    responses={
        200: {
            "description": "Category updated successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Category updated successfully",
                        "data": {
                            "id": 1,
                            "name": "Groceries",
                            "type": "expense",
                            "icon": "🛒",
                            "color": "#10B981",
                            "user_id": 1
                        }
                    }
                }
            }
        },
        400: {
            "description": "Invalid request or business rule violation",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Cannot change category type - transactions exist for this category"
                    }
                }
            }
        },
        404: {
            "description": "Category not found",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Category not found"
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        403: {
            "description": "Forbidden - Cannot update other user's category"
        }
    }
)
def update_category(
    category_id: int,
    category: CategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Update a category"""
    db_category = CategoryService.update_category(db, category_id, category)
    return success_response(
        message="Category updated successfully",
        data=db_category
    )


@router.delete(
    "/{category_id}",
    response_model=dict,
    summary="Delete category",
    description="""
    Delete a category for the authenticated user.
    
    **Path Parameters:**
    - `category_id`: The unique identifier of the category to delete
    
    **Authentication Required:** Yes (Bearer token)
    
    **Business Rules:**
    - User can only delete their own categories
    - Cannot delete category if it has associated transactions
    - Consider reassigning transactions to another category before deletion
    """,
    responses={
        200: {
            "description": "Category deleted successfully",
            "content": {
                "application/json": {
                    "example": {
                        "success": True,
                        "message": "Category deleted successfully"
                    }
                }
            }
        },
        400: {
            "description": "Cannot delete category with transactions",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Cannot delete category with existing transactions. Please reassign or delete transactions first."
                    }
                }
            }
        },
        404: {
            "description": "Category not found",
            "content": {
                "application/json": {
                    "example": {
                        "success": False,
                        "message": "Category not found"
                    }
                }
            }
        },
        401: {
            "description": "Unauthorized - Invalid or missing token"
        },
        403: {
            "description": "Forbidden - Cannot delete other user's category"
        }
    }
)
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """Delete a category"""
    CategoryService.delete_category(db, category_id)
    return success_response(
        message="Category deleted successfully"
    )
