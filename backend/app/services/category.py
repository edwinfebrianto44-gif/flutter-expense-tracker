from sqlalchemy.orm import Session
from typing import List, Optional
from fastapi import HTTPException, status
from ..crud import category as crud_category
from ..schemas.category import CategoryCreate, CategoryUpdate
from ..models.category import Category


class CategoryService:
    @staticmethod
    def get_categories(db: Session, skip: int = 0, limit: int = 100) -> List[Category]:
        return crud_category.get_categories(db, skip=skip, limit=limit)
    
    @staticmethod
    def get_category(db: Session, category_id: int) -> Category:
        category = crud_category.get_category(db, category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        return category
    
    @staticmethod
    def create_category(db: Session, category_data: CategoryCreate) -> Category:
        return crud_category.create_category(db, category_data)
    
    @staticmethod
    def update_category(db: Session, category_id: int, category_data: CategoryUpdate) -> Category:
        category = crud_category.update_category(db, category_id, category_data)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        return category
    
    @staticmethod
    def delete_category(db: Session, category_id: int) -> bool:
        if not crud_category.delete_category(db, category_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        return True
