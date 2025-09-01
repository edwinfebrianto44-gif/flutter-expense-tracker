from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from ..core.database import get_db
from ..core.response import success_response
from ..core.deps import get_current_active_user
from ..schemas.category import Category, CategoryCreate, CategoryUpdate
from ..schemas.user import User
from ..services.category import CategoryService

router = APIRouter()


@router.get("/", response_model=dict)
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


@router.get("/{category_id}", response_model=dict)
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


@router.post("/", response_model=dict)
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


@router.put("/{category_id}", response_model=dict)
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


@router.delete("/{category_id}", response_model=dict)
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
