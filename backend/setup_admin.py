#!/usr/bin/env python3
"""
Setup script to create initial admin user and demo data
Run this script after database migration to set up the application
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from app.core.database import SessionLocal, engine
from app.models.user import User
from app.models.category import Category, CategoryType
from app.models.transaction import Transaction
from app.core.security import password_security
from datetime import datetime, date
import json


def create_admin_user(db: Session):
    """Create initial admin user"""
    
    # Check if admin user already exists
    existing_admin = db.query(User).filter(User.role == "admin").first()
    if existing_admin:
        print("✅ Admin user already exists")
        return existing_admin
    
    # Create admin user
    admin_data = {
        "username": "admin",
        "email": "admin@expensetracker.com",
        "password": "Admin123!",  # Change this in production!
        "full_name": "System Administrator"
    }
    
    hashed_password = password_security.hash_password(admin_data["password"])
    
    admin_user = User(
        username=admin_data["username"],
        email=admin_data["email"],
        password_hash=hashed_password,
        full_name=admin_data["full_name"],
        role="admin",
        is_active=True,
        is_verified=True,
        failed_login_attempts=0
    )
    
    db.add(admin_user)
    db.commit()
    db.refresh(admin_user)
    
    print(f"✅ Admin user created:")
    print(f"   Email: {admin_data['email']}")
    print(f"   Password: {admin_data['password']}")
    print(f"   ⚠️  IMPORTANT: Change the admin password after first login!")
    
    return admin_user


def create_demo_user(db: Session):
    """Create demo user for testing"""
    
    # Check if demo user already exists
    existing_demo = db.query(User).filter(User.email == "demo@demo.com").first()
    if existing_demo:
        print("✅ Demo user already exists")
        return existing_demo
    
    demo_data = {
        "username": "demo_user",
        "email": "demo@demo.com",
        "password": "password123",
        "full_name": "Demo User"
    }
    
    hashed_password = password_security.hash_password(demo_data["password"])
    
    demo_user = User(
        username=demo_data["username"],
        email=demo_data["email"],
        password_hash=hashed_password,
        full_name=demo_data["full_name"],
        role="user",
        is_active=True,
        is_verified=True,
        failed_login_attempts=0
    )
    
    db.add(demo_user)
    db.commit()
    db.refresh(demo_user)
    
    print(f"✅ Demo user created:")
    print(f"   Email: {demo_data['email']}")
    print(f"   Password: {demo_data['password']}")
    
    return demo_user


def create_demo_categories(db: Session, user: User):
    """Create demo categories for user"""
    
    categories_data = [
        # Expense categories
        {"name": "Food & Dining", "type": "expense", "icon": "🍽️", "color": "#EF4444"},
        {"name": "Transportation", "type": "expense", "icon": "🚗", "color": "#F97316"},
        {"name": "Shopping", "type": "expense", "icon": "🛒", "color": "#EAB308"},
        {"name": "Entertainment", "type": "expense", "icon": "🎬", "color": "#8B5CF6"},
        {"name": "Bills & Utilities", "type": "expense", "icon": "⚡", "color": "#06B6D4"},
        {"name": "Healthcare", "type": "expense", "icon": "🏥", "color": "#EC4899"},
        {"name": "Education", "type": "expense", "icon": "📚", "color": "#6366F1"},
        {"name": "Travel", "type": "expense", "icon": "✈️", "color": "#14B8A6"},
        
        # Income categories
        {"name": "Salary", "type": "income", "icon": "💰", "color": "#10B981"},
        {"name": "Freelance", "type": "income", "icon": "💼", "color": "#059669"},
        {"name": "Investment", "type": "income", "icon": "📈", "color": "#065F46"},
        {"name": "Other Income", "type": "income", "icon": "💸", "color": "#047857"},
    ]
    
    created_categories = []
    
    for cat_data in categories_data:
        # Check if category already exists for this user
        existing_cat = db.query(Category).filter(
            Category.name == cat_data["name"],
            Category.user_id == user.id
        ).first()
        
        if not existing_cat:
            category = Category(
                name=cat_data["name"],
                type=CategoryType(cat_data["type"]),
                icon=cat_data["icon"],
                color=cat_data["color"],
                user_id=user.id
            )
            
            db.add(category)
            created_categories.append(category)
    
    db.commit()
    
    # Refresh all categories
    for cat in created_categories:
        db.refresh(cat)
    
    if created_categories:
        print(f"✅ Created {len(created_categories)} demo categories for {user.username}")
    else:
        print(f"✅ Demo categories already exist for {user.username}")
    
    return db.query(Category).filter(Category.user_id == user.id).all()


def create_demo_transactions(db: Session, user: User, categories: list):
    """Create demo transactions for user"""
    
    # Check if transactions already exist for this user
    existing_transactions = db.query(Transaction).filter(Transaction.user_id == user.id).count()
    if existing_transactions > 0:
        print(f"✅ Demo transactions already exist for {user.username}")
        return
    
    # Get categories by type
    expense_categories = [cat for cat in categories if cat.type == CategoryType.expense]
    income_categories = [cat for cat in categories if cat.type == CategoryType.income]
    
    transactions_data = [
        # Income transactions
        {"amount": 5000.00, "description": "Monthly Salary", "date": "2024-01-01", "category": "Salary"},
        {"amount": 1200.00, "description": "Freelance Project", "date": "2024-01-05", "category": "Freelance"},
        {"amount": 300.00, "description": "Investment Returns", "date": "2024-01-10", "category": "Investment"},
        
        # Expense transactions
        {"amount": 85.50, "description": "Grocery Shopping", "date": "2024-01-02", "category": "Food & Dining"},
        {"amount": 45.00, "description": "Gas Station", "date": "2024-01-03", "category": "Transportation"},
        {"amount": 120.00, "description": "Online Shopping", "date": "2024-01-04", "category": "Shopping"},
        {"amount": 35.00, "description": "Movie Tickets", "date": "2024-01-06", "category": "Entertainment"},
        {"amount": 250.00, "description": "Electricity Bill", "date": "2024-01-07", "category": "Bills & Utilities"},
        {"amount": 75.00, "description": "Doctor Visit", "date": "2024-01-08", "category": "Healthcare"},
        {"amount": 200.00, "description": "Online Course", "date": "2024-01-09", "category": "Education"},
        {"amount": 60.00, "description": "Restaurant Dinner", "date": "2024-01-11", "category": "Food & Dining"},
        {"amount": 30.00, "description": "Bus Pass", "date": "2024-01-12", "category": "Transportation"},
        {"amount": 150.00, "description": "Clothing Store", "date": "2024-01-13", "category": "Shopping"},
        {"amount": 25.00, "description": "Streaming Service", "date": "2024-01-14", "category": "Entertainment"},
        {"amount": 180.00, "description": "Internet Bill", "date": "2024-01-15", "category": "Bills & Utilities"},
    ]
    
    # Create category mapping
    category_map = {cat.name: cat for cat in categories}
    
    created_transactions = []
    
    for trans_data in transactions_data:
        category = category_map.get(trans_data["category"])
        if not category:
            continue
        
        transaction = Transaction(
            amount=trans_data["amount"],
            description=trans_data["description"],
            date=datetime.strptime(trans_data["date"], "%Y-%m-%d").date(),
            type=category.type.value,  # Get string value from enum
            category_id=category.id,
            user_id=user.id
        )
        
        db.add(transaction)
        created_transactions.append(transaction)
    
    db.commit()
    
    print(f"✅ Created {len(created_transactions)} demo transactions for {user.username}")


def main():
    """Main setup function"""
    print("🚀 Setting up Expense Tracker application...")
    
    # Create database session
    db = SessionLocal()
    
    try:
        # Create admin user
        print("\n📋 Creating admin user...")
        admin_user = create_admin_user(db)
        
        # Create demo user
        print("\n👤 Creating demo user...")
        demo_user = create_demo_user(db)
        
        # Create demo categories for admin
        print("\n📂 Creating demo categories for admin...")
        admin_categories = create_demo_categories(db, admin_user)
        
        # Create demo categories for demo user
        print("\n📂 Creating demo categories for demo user...")
        demo_categories = create_demo_categories(db, demo_user)
        
        # Create demo transactions for admin
        print("\n💰 Creating demo transactions for admin...")
        create_demo_transactions(db, admin_user, admin_categories)
        
        # Create demo transactions for demo user
        print("\n💰 Creating demo transactions for demo user...")
        create_demo_transactions(db, demo_user, demo_categories)
        
        print("\n✅ Setup completed successfully!")
        print("\n📊 Summary:")
        print(f"   👑 Admin users: {db.query(User).filter(User.role == 'admin').count()}")
        print(f"   👤 Regular users: {db.query(User).filter(User.role == 'user').count()}")
        print(f"   📂 Categories: {db.query(Category).count()}")
        print(f"   💰 Transactions: {db.query(Transaction).count()}")
        
        print("\n🔐 Login Credentials:")
        print("   Admin:")
        print("     Email: admin@expensetracker.com")
        print("     Password: Admin123!")
        print("   Demo User:")
        print("     Email: demo@expensetracker.com") 
        print("     Password: Demo123!")
        
        print("\n⚠️  SECURITY NOTICE:")
        print("   🔒 Change default passwords in production!")
        print("   🔑 Use strong passwords for admin accounts!")
        print("   📧 Set up email verification for new users!")
        
    except Exception as e:
        print(f"❌ Setup failed: {e}")
        db.rollback()
        return False
        
    finally:
        db.close()
    
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
