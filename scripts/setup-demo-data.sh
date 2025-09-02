#!/bin/bash

# Demo Data Setup Script for Flutter Expense Tracker
# Creates demo account and seed data for portfolio demonstration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📊 Demo Data Setup for Flutter Expense Tracker${NC}"
echo "=============================================="
echo "Setting up demo account and sample data..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Load environment
if [ -f "$BACKEND_DIR/.env" ]; then
    source "$BACKEND_DIR/.env"
fi

# Demo account configuration
DEMO_EMAIL="demo@demo.com"
DEMO_PASSWORD="password123"
DEMO_NAME="Demo User"

# Function to log messages
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)
            echo -e "${RED}[$timestamp] ERROR: $message${NC}"
            ;;
        WARN)
            echo -e "${YELLOW}[$timestamp] WARN: $message${NC}"
            ;;
        INFO)
            echo -e "${GREEN}[$timestamp] INFO: $message${NC}"
            ;;
        DEBUG)
            echo -e "${BLUE}[$timestamp] DEBUG: $message${NC}"
            ;;
    esac
}

# Function to check database connection
check_database() {
    log INFO "Checking database connection..."
    
    python3 -c "
import sys
import os
sys.path.append('$BACKEND_DIR')

try:
    import psycopg2
    conn = psycopg2.connect('$DATABASE_URL')
    conn.close()
    print('Database connection successful')
except Exception as e:
    print(f'Database connection failed: {e}')
    sys.exit(1)
"
}

# Function to create demo user
create_demo_user() {
    log INFO "Creating demo user: $DEMO_EMAIL"
    
    python3 -c "
import sys
import os
sys.path.append('$BACKEND_DIR')

try:
    import psycopg2
    import bcrypt
    from datetime import datetime
    
    conn = psycopg2.connect('$DATABASE_URL')
    cursor = conn.cursor()
    
    # Hash password
    password = '$DEMO_PASSWORD'.encode('utf-8')
    salt = bcrypt.gensalt(rounds=12)
    password_hash = bcrypt.hashpw(password, salt).decode('utf-8')
    
    # Insert or update demo user
    cursor.execute('''
        INSERT INTO users (email, password_hash, full_name, is_admin, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (email) DO UPDATE SET
            password_hash = EXCLUDED.password_hash,
            full_name = EXCLUDED.full_name,
            is_active = true,
            updated_at = EXCLUDED.updated_at
        RETURNING id;
    ''', ('$DEMO_EMAIL', password_hash, '$DEMO_NAME', False, True, datetime.utcnow(), datetime.utcnow()))
    
    user_id = cursor.fetchone()[0]
    conn.commit()
    conn.close()
    
    print(f'Demo user created with ID: {user_id}')
    
except Exception as e:
    print(f'Failed to create demo user: {e}')
    sys.exit(1)
"
    
    if [ $? -eq 0 ]; then
        log INFO "Demo user created successfully"
    else
        log ERROR "Failed to create demo user"
        return 1
    fi
}

# Function to get demo user ID
get_demo_user_id() {
    python3 -c "
import sys
import os
sys.path.append('$BACKEND_DIR')

try:
    import psycopg2
    
    conn = psycopg2.connect('$DATABASE_URL')
    cursor = conn.cursor()
    
    cursor.execute('SELECT id FROM users WHERE email = %s', ('$DEMO_EMAIL',))
    result = cursor.fetchone()
    
    if result:
        print(result[0])
    else:
        print('0')
    
    conn.close()
    
except Exception as e:
    print('0')
"
}

# Function to create demo categories
create_demo_categories() {
    local user_id="$1"
    log INFO "Creating demo categories for user ID: $user_id"
    
    python3 -c "
import sys
import os
sys.path.append('$BACKEND_DIR')

try:
    import psycopg2
    from datetime import datetime
    
    conn = psycopg2.connect('$DATABASE_URL')
    cursor = conn.cursor()
    
    # Demo categories with icons and colors
    categories = [
        ('Food & Dining', '🍽️', '#FF6B6B', 'expense'),
        ('Transportation', '🚗', '#4ECDC4', 'expense'),
        ('Shopping', '🛍️', '#45B7D1', 'expense'),
        ('Entertainment', '🎬', '#96CEB4', 'expense'),
        ('Salary', '💰', '#FECA57', 'income'),
    ]
    
    category_ids = []
    
    for name, icon, color, type_cat in categories:
        cursor.execute('''
            INSERT INTO categories (name, icon, color, type, user_id, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (name, user_id) DO UPDATE SET
                icon = EXCLUDED.icon,
                color = EXCLUDED.color,
                type = EXCLUDED.type,
                updated_at = EXCLUDED.updated_at
            RETURNING id;
        ''', (name, icon, color, type_cat, $user_id, datetime.utcnow(), datetime.utcnow()))
        
        category_id = cursor.fetchone()[0]
        category_ids.append((category_id, name, type_cat))
        print(f'Created category: {name} (ID: {category_id})')
    
    conn.commit()
    conn.close()
    
    # Return category IDs for transaction creation
    for cat_id, name, cat_type in category_ids:
        print(f'{cat_id},{name},{cat_type}')
    
except Exception as e:
    print(f'Failed to create categories: {e}')
    sys.exit(1)
" | tail -5  # Get only the category ID lines
}

# Function to create demo transactions
create_demo_transactions() {
    local user_id="$1"
    local categories="$2"
    
    log INFO "Creating 30 demo transactions for user ID: $user_id"
    
    python3 -c "
import sys
import os
sys.path.append('$BACKEND_DIR')

try:
    import psycopg2
    from datetime import datetime, timedelta
    import random
    
    conn = psycopg2.connect('$DATABASE_URL')
    cursor = conn.cursor()
    
    # Parse categories
    categories = []
    for line in '''$categories'''.strip().split('\n'):
        if line:
            parts = line.split(',')
            if len(parts) >= 3:
                categories.append((int(parts[0]), parts[1], parts[2]))
    
    # Demo transaction data
    food_transactions = [
        ('Lunch at Restaurant', 25.50),
        ('Grocery Shopping', 67.80),
        ('Coffee & Pastry', 8.90),
        ('Dinner with Friends', 45.30),
        ('Fast Food', 12.75),
        ('Pizza Delivery', 18.60),
        ('Breakfast Cafe', 15.20),
        ('Ice Cream', 6.50),
    ]
    
    transport_transactions = [
        ('Gas Station', 52.00),
        ('Uber Ride', 18.50),
        ('Public Transport', 3.25),
        ('Parking Fee', 8.00),
        ('Car Wash', 15.00),
        ('Taxi to Airport', 35.75),
    ]
    
    shopping_transactions = [
        ('Clothing Store', 89.99),
        ('Electronics', 245.00),
        ('Books & Magazines', 32.50),
        ('Home Supplies', 76.30),
        ('Pharmacy', 28.90),
        ('Sports Equipment', 125.00),
    ]
    
    entertainment_transactions = [
        ('Movie Tickets', 24.00),
        ('Concert', 85.00),
        ('Streaming Service', 12.99),
        ('Video Games', 59.99),
        ('Sports Event', 95.00),
        ('Museum Visit', 18.50),
    ]
    
    salary_transactions = [
        ('Monthly Salary', 3500.00),
        ('Freelance Work', 450.00),
        ('Bonus Payment', 750.00),
    ]
    
    # Group transactions by category type
    transaction_groups = {
        'Food & Dining': food_transactions,
        'Transportation': transport_transactions,
        'Shopping': shopping_transactions,
        'Entertainment': entertainment_transactions,
        'Salary': salary_transactions,
    }
    
    # Create transactions over the last 60 days
    start_date = datetime.now() - timedelta(days=60)
    
    transaction_count = 0
    target_count = 30
    
    while transaction_count < target_count:
        for cat_id, cat_name, cat_type in categories:
            if transaction_count >= target_count:
                break
                
            if cat_name in transaction_groups:
                transactions = transaction_groups[cat_name]
                
                # Add more transactions for expense categories
                num_transactions = 8 if cat_type == 'expense' else 2
                
                for i in range(min(num_transactions, target_count - transaction_count)):
                    if transaction_count >= target_count:
                        break
                        
                    # Random transaction from the group
                    desc, amount = random.choice(transactions)
                    
                    # Random date in the last 60 days
                    random_days = random.randint(0, 60)
                    transaction_date = start_date + timedelta(days=random_days)
                    
                    # Add some variation to amounts
                    amount_variation = random.uniform(0.8, 1.2)
                    final_amount = round(amount * amount_variation, 2)
                    
                    cursor.execute('''
                        INSERT INTO transactions (description, amount, type, category_id, user_id, date, created_at, updated_at)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
                    ''', (desc, final_amount, cat_type, cat_id, $user_id, transaction_date, datetime.utcnow(), datetime.utcnow()))
                    
                    transaction_count += 1
                    print(f'Created transaction: {desc} - \${final_amount} ({cat_type})')
    
    conn.commit()
    conn.close()
    
    print(f'Successfully created {transaction_count} demo transactions')
    
except Exception as e:
    print(f'Failed to create transactions: {e}')
    sys.exit(1)
"
}

# Function to display demo summary
show_demo_summary() {
    local user_id="$1"
    
    log INFO "Demo data summary:"
    
    python3 -c "
import sys
import os
sys.path.append('$BACKEND_DIR')

try:
    import psycopg2
    
    conn = psycopg2.connect('$DATABASE_URL')
    cursor = conn.cursor()
    
    # Get user info
    cursor.execute('SELECT email, full_name FROM users WHERE id = %s', ($user_id,))
    user_info = cursor.fetchone()
    
    # Get categories count
    cursor.execute('SELECT COUNT(*) FROM categories WHERE user_id = %s', ($user_id,))
    categories_count = cursor.fetchone()[0]
    
    # Get transactions count and totals
    cursor.execute('''
        SELECT 
            COUNT(*) as total_transactions,
            SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as total_income,
            SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as total_expenses
        FROM transactions 
        WHERE user_id = %s
    ''', ($user_id,))
    
    transaction_stats = cursor.fetchone()
    
    print(f'✅ Demo User: {user_info[1]} ({user_info[0]})')
    print(f'✅ Categories: {categories_count}')
    print(f'✅ Transactions: {transaction_stats[0]}')
    print(f'✅ Total Income: \${transaction_stats[1]:.2f}')
    print(f'✅ Total Expenses: \${transaction_stats[2]:.2f}')
    print(f'✅ Net Balance: \${transaction_stats[1] - transaction_stats[2]:.2f}')
    
    conn.close()
    
except Exception as e:
    print(f'Failed to get summary: {e}')
"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting demo data setup...${NC}"
    
    # Check database connection
    if ! check_database; then
        log ERROR "Database connection failed"
        exit 1
    fi
    
    # Create demo user
    if ! create_demo_user; then
        log ERROR "Failed to create demo user"
        exit 1
    fi
    
    # Get demo user ID
    DEMO_USER_ID=$(get_demo_user_id)
    if [ "$DEMO_USER_ID" = "0" ]; then
        log ERROR "Could not get demo user ID"
        exit 1
    fi
    
    log INFO "Demo user ID: $DEMO_USER_ID"
    
    # Create demo categories
    CATEGORIES_OUTPUT=$(create_demo_categories "$DEMO_USER_ID")
    if [ $? -ne 0 ]; then
        log ERROR "Failed to create demo categories"
        exit 1
    fi
    
    # Create demo transactions
    if ! create_demo_transactions "$DEMO_USER_ID" "$CATEGORIES_OUTPUT"; then
        log ERROR "Failed to create demo transactions"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Demo data setup completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}📊 Demo Account Details:${NC}"
    echo "• Email: $DEMO_EMAIL"
    echo "• Password: $DEMO_PASSWORD"
    echo "• Name: $DEMO_NAME"
    echo ""
    
    show_demo_summary "$DEMO_USER_ID"
    
    echo ""
    echo -e "${YELLOW}🔗 Next Steps:${NC}"
    echo "1. Test login with demo credentials"
    echo "2. Verify categories and transactions in the app"
    echo "3. Take screenshots for README"
    echo "4. Create demo GIFs/videos"
}

main "$@"
