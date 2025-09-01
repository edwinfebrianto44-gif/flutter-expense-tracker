from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import date
from fastapi import HTTPException, status
from ..crud import transaction as crud_transaction
from ..schemas.transaction import TransactionCreate, TransactionUpdate, TransactionFilter, TransactionSummary
from ..models.transaction import Transaction


class TransactionService:
    @staticmethod
    def get_transactions(
        db: Session, 
        user_id: int,
        skip: int = 0, 
        limit: int = 100,
        filters: Optional[TransactionFilter] = None
    ) -> List[Transaction]:
        return crud_transaction.get_transactions(db, user_id, skip, limit, filters)
    
    @staticmethod
    def get_transaction(db: Session, transaction_id: int, user_id: int) -> Transaction:
        transaction = crud_transaction.get_transaction(db, transaction_id)
        if not transaction or transaction.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found"
            )
        return transaction
    
    @staticmethod
    def create_transaction(db: Session, transaction_data: TransactionCreate, user_id: int) -> Transaction:
        return crud_transaction.create_transaction(db, transaction_data, user_id)
    
    @staticmethod
    def update_transaction(
        db: Session, 
        transaction_id: int, 
        transaction_data: TransactionUpdate,
        user_id: int
    ) -> Transaction:
        transaction = crud_transaction.update_transaction(db, transaction_id, transaction_data, user_id)
        if not transaction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found"
            )
        return transaction
    
    @staticmethod
    def delete_transaction(db: Session, transaction_id: int, user_id: int) -> bool:
        if not crud_transaction.delete_transaction(db, transaction_id, user_id):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found"
            )
        return True
    
    @staticmethod
    def get_summary(
        db: Session, 
        user_id: int,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None
    ) -> TransactionSummary:
        return crud_transaction.get_transaction_summary(db, user_id, start_date, end_date)
