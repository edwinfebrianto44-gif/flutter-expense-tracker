from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import date
from decimal import Decimal
from ..models.transaction import Transaction
from ..models.category import Category
from ..schemas.transaction import TransactionCreate, TransactionUpdate, TransactionFilter, TransactionSummary


class TransactionCRUD:
    def get_by_id(self, db: Session, transaction_id: int) -> Optional[Transaction]:
        return db.query(Transaction).filter(Transaction.id == transaction_id).first()
    
    def update(self, db: Session, transaction_id: int, transaction_update: dict) -> Optional[Transaction]:
        db_transaction = db.query(Transaction).filter(Transaction.id == transaction_id).first()
        if db_transaction:
            for key, value in transaction_update.items():
                setattr(db_transaction, key, value)
            db.commit()
            db.refresh(db_transaction)
        return db_transaction


transaction_crud = TransactionCRUD()


def get_transaction(db: Session, transaction_id: int) -> Optional[Transaction]:
    return db.query(Transaction).filter(Transaction.id == transaction_id).first()


def get_transactions(
    db: Session, 
    user_id: int,
    skip: int = 0, 
    limit: int = 100,
    filters: Optional[TransactionFilter] = None
) -> List[Transaction]:
    query = db.query(Transaction).filter(Transaction.user_id == user_id)
    
    if filters:
        if filters.start_date:
            query = query.filter(Transaction.trans_date >= filters.start_date)
        if filters.end_date:
            query = query.filter(Transaction.trans_date <= filters.end_date)
        if filters.category_id:
            query = query.filter(Transaction.category_id == filters.category_id)
        if filters.category_type:
            query = query.join(Category).filter(Category.type == filters.category_type)
    
    return query.order_by(Transaction.trans_date.desc()).offset(skip).limit(limit).all()


def create_transaction(db: Session, transaction: TransactionCreate, user_id: int) -> Transaction:
    db_transaction = Transaction(**transaction.dict(), user_id=user_id)
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction


def update_transaction(
    db: Session, 
    transaction_id: int, 
    transaction_update: TransactionUpdate,
    user_id: int
) -> Optional[Transaction]:
    db_transaction = db.query(Transaction).filter(
        and_(Transaction.id == transaction_id, Transaction.user_id == user_id)
    ).first()
    
    if not db_transaction:
        return None
    
    update_data = transaction_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_transaction, field, value)
    
    db.commit()
    db.refresh(db_transaction)
    return db_transaction


def delete_transaction(db: Session, transaction_id: int, user_id: int) -> bool:
    db_transaction = db.query(Transaction).filter(
        and_(Transaction.id == transaction_id, Transaction.user_id == user_id)
    ).first()
    
    if not db_transaction:
        return False
    
    db.delete(db_transaction)
    db.commit()
    return True


def get_transaction_summary(
    db: Session, 
    user_id: int,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None
) -> TransactionSummary:
    query = db.query(
        func.sum(Transaction.amount).label('total_amount'),
        Category.type
    ).join(Category).filter(Transaction.user_id == user_id)
    
    if start_date:
        query = query.filter(Transaction.trans_date >= start_date)
    if end_date:
        query = query.filter(Transaction.trans_date <= end_date)
    
    results = query.group_by(Category.type).all()
    
    total_income = Decimal('0')
    total_expense = Decimal('0')
    
    for total_amount, category_type in results:
        if category_type == 'income':
            total_income = total_amount or Decimal('0')
        elif category_type == 'expense':
            total_expense = total_amount or Decimal('0')
    
    balance = total_income - total_expense
    
    return TransactionSummary(
        total_income=total_income,
        total_expense=total_expense,
        balance=balance,
        period_start=start_date,
        period_end=end_date
    )
