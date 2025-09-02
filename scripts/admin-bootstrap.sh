#!/bin/bash

# Admin Bootstrap CLI Script for Flutter Expense Tracker
# Creates initial admin user and manages administrative tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}👑 Admin Bootstrap CLI for Flutter Expense Tracker${NC}"
echo "================================================="
echo "This script manages administrative users and system setup"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Load environment if available
if [ -f "$BACKEND_DIR/.env" ]; then
    source "$BACKEND_DIR/.env"
fi

# Configuration
ADMIN_CLI_LOG="/var/log/expense-tracker-admin.log"
ADMIN_CONFIG_DIR="/etc/expense-tracker"
ADMIN_CONFIG_FILE="$ADMIN_CONFIG_DIR/admin-config.json"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)
            echo -e "${RED}[$timestamp] ERROR: $message${NC}" | tee -a "$ADMIN_CLI_LOG"
            ;;
        WARN)
            echo -e "${YELLOW}[$timestamp] WARN: $message${NC}" | tee -a "$ADMIN_CLI_LOG"
            ;;
        INFO)
            echo -e "${GREEN}[$timestamp] INFO: $message${NC}" | tee -a "$ADMIN_CLI_LOG"
            ;;
        DEBUG)
            echo -e "${BLUE}[$timestamp] DEBUG: $message${NC}" | tee -a "$ADMIN_CLI_LOG"
            ;;
    esac
}

# Function to validate email format
validate_email() {
    local email="$1"
    if [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate password strength
validate_password() {
    local password="$1"
    local min_length=8
    
    if [ ${#password} -lt $min_length ]; then
        echo "Password must be at least $min_length characters long"
        return 1
    fi
    
    if ! [[ $password =~ [A-Z] ]]; then
        echo "Password must contain at least one uppercase letter"
        return 1
    fi
    
    if ! [[ $password =~ [a-z] ]]; then
        echo "Password must contain at least one lowercase letter"
        return 1
    fi
    
    if ! [[ $password =~ [0-9] ]]; then
        echo "Password must contain at least one number"
        return 1
    fi
    
    if ! [[ $password =~ [^A-Za-z0-9] ]]; then
        echo "Password must contain at least one special character"
        return 1
    fi
    
    return 0
}

# Function to generate secure password
generate_password() {
    local length=${1:-16}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to check if database is accessible
check_database_connection() {
    log INFO "Checking database connection..."
    
    if [ -z "$DATABASE_URL" ]; then
        log ERROR "DATABASE_URL not configured in environment"
        return 1
    fi
    
    # Extract database connection details from DATABASE_URL
    # Format: postgresql://user:password@host:port/database
    local db_url="$DATABASE_URL"
    local db_user=$(echo "$db_url" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
    local db_pass=$(echo "$db_url" | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
    local db_host=$(echo "$db_url" | sed -n 's/.*@\([^:]*\):.*/\1/p')
    local db_port=$(echo "$db_url" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    local db_name=$(echo "$db_url" | sed -n 's/.*\/\([^?]*\).*/\1/p')
    
    # Test connection
    if PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "SELECT 1;" >/dev/null 2>&1; then
        log INFO "Database connection successful"
        return 0
    else
        log ERROR "Database connection failed"
        return 1
    fi
}

# Function to check if application is running
check_application_status() {
    log INFO "Checking application status..."
    
    # Check if the API is responding
    local api_url="http://localhost:${PORT:-8000}/health"
    
    if curl -f -s "$api_url" >/dev/null 2>&1; then
        log INFO "Application is running and responding"
        return 0
    else
        log WARN "Application may not be running or accessible"
        return 1
    fi
}

# Function to create admin user via API
create_admin_user_api() {
    local email="$1"
    local password="$2"
    local full_name="$3"
    
    log INFO "Creating admin user via API: $email"
    
    local api_url="http://localhost:${PORT:-8000}/admin/bootstrap"
    local json_payload=$(cat << EOF
{
    "email": "$email",
    "password": "$password",
    "full_name": "$full_name",
    "is_admin": true,
    "is_active": true
}
EOF
)
    
    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "X-Admin-Bootstrap-Token: ${API_SECRET_KEY:-bootstrap}" \
        -d "$json_payload" \
        "$api_url" 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "200" ]; then
        log INFO "Admin user created successfully via API"
        return 0
    else
        log ERROR "Failed to create admin user via API (HTTP $http_code)"
        log ERROR "Response: $response_body"
        return 1
    fi
}

# Function to create admin user via database
create_admin_user_db() {
    local email="$1"
    local password="$2"
    local full_name="$3"
    
    log INFO "Creating admin user via database: $email"
    
    # Generate password hash (this would normally be done by the application)
    local password_hash=$(python3 -c "
import bcrypt
import sys
password = sys.argv[1].encode('utf-8')
salt = bcrypt.gensalt(rounds=${BCRYPT_ROUNDS:-12})
hash = bcrypt.hashpw(password, salt)
print(hash.decode('utf-8'))
" "$password")
    
    # Extract database connection details
    local db_url="$DATABASE_URL"
    local db_user=$(echo "$db_url" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
    local db_pass=$(echo "$db_url" | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
    local db_host=$(echo "$db_url" | sed -n 's/.*@\([^:]*\):.*/\1/p')
    local db_port=$(echo "$db_url" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    local db_name=$(echo "$db_url" | sed -n 's/.*\/\([^?]*\).*/\1/p')
    
    # Create SQL to insert admin user
    local sql_command="
INSERT INTO users (email, password_hash, full_name, is_admin, is_active, created_at, updated_at)
VALUES ('$email', '$password_hash', '$full_name', true, true, NOW(), NOW())
ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    full_name = EXCLUDED.full_name,
    is_admin = true,
    is_active = true,
    updated_at = NOW();
"
    
    if PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" -c "$sql_command" >/dev/null 2>&1; then
        log INFO "Admin user created successfully via database"
        return 0
    else
        log ERROR "Failed to create admin user via database"
        return 1
    fi
}

# Function to create admin user
create_admin_user() {
    local email="$1"
    local password="$2"
    local full_name="$3"
    local force_db="${4:-false}"
    
    log INFO "Creating admin user: $email"
    
    # Try API first if application is running, unless forced to use database
    if [ "$force_db" = "false" ] && check_application_status; then
        if create_admin_user_api "$email" "$password" "$full_name"; then
            return 0
        else
            log WARN "API method failed, falling back to database"
        fi
    fi
    
    # Fall back to database method
    if check_database_connection; then
        if create_admin_user_db "$email" "$password" "$full_name"; then
            return 0
        else
            log ERROR "Database method also failed"
            return 1
        fi
    else
        log ERROR "Cannot create admin user: no database connection"
        return 1
    fi
}

# Function to list admin users
list_admin_users() {
    log INFO "Listing admin users..."
    
    if ! check_database_connection; then
        log ERROR "Cannot list users: no database connection"
        return 1
    fi
    
    # Extract database connection details
    local db_url="$DATABASE_URL"
    local db_user=$(echo "$db_url" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
    local db_pass=$(echo "$db_url" | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
    local db_host=$(echo "$db_url" | sed -n 's/.*@\([^:]*\):.*/\1/p')
    local db_port=$(echo "$db_url" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    local db_name=$(echo "$db_url" | sed -n 's/.*\/\([^?]*\).*/\1/p')
    
    echo -e "${YELLOW}👑 Admin Users:${NC}"
    echo "=============="
    
    PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" \
        -c "SELECT id, email, full_name, created_at, is_active FROM users WHERE is_admin = true ORDER BY created_at;" \
        -t -A -F'|' | while IFS='|' read -r id email full_name created_at is_active; do
        
        local status=$([ "$is_active" = "t" ] && echo "Active" || echo "Inactive")
        echo "• ID: $id"
        echo "  Email: $email"
        echo "  Name: $full_name"
        echo "  Status: $status"
        echo "  Created: $created_at"
        echo ""
    done
}

# Function to reset admin password
reset_admin_password() {
    local email="$1"
    local new_password="$2"
    
    log INFO "Resetting password for admin user: $email"
    
    if ! check_database_connection; then
        log ERROR "Cannot reset password: no database connection"
        return 1
    fi
    
    # Generate new password hash
    local password_hash=$(python3 -c "
import bcrypt
import sys
password = sys.argv[1].encode('utf-8')
salt = bcrypt.gensalt(rounds=${BCRYPT_ROUNDS:-12})
hash = bcrypt.hashpw(password, salt)
print(hash.decode('utf-8'))
" "$new_password")
    
    # Extract database connection details
    local db_url="$DATABASE_URL"
    local db_user=$(echo "$db_url" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
    local db_pass=$(echo "$db_url" | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
    local db_host=$(echo "$db_url" | sed -n 's/.*@\([^:]*\):.*/\1/p')
    local db_port=$(echo "$db_url" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
    local db_name=$(echo "$db_url" | sed -n 's/.*\/\([^?]*\).*/\1/p')
    
    # Update password
    local sql_command="
UPDATE users 
SET password_hash = '$password_hash', updated_at = NOW() 
WHERE email = '$email' AND is_admin = true;
"
    
    local rows_affected=$(PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" \
        -c "$sql_command" | grep "UPDATE" | awk '{print $2}')
    
    if [ "$rows_affected" = "1" ]; then
        log INFO "Password reset successfully for: $email"
        return 0
    else
        log ERROR "Failed to reset password (user not found or not admin): $email"
        return 1
    fi
}

# Function to run database migrations
run_migrations() {
    log INFO "Running database migrations..."
    
    # Check if Alembic is available
    if [ -f "$BACKEND_DIR/alembic.ini" ]; then
        cd "$BACKEND_DIR"
        
        if command -v alembic &> /dev/null; then
            log INFO "Running Alembic migrations..."
            alembic upgrade head
            log INFO "Migrations completed"
        else
            log ERROR "Alembic not found. Please install it: pip install alembic"
            return 1
        fi
    else
        log ERROR "Alembic configuration not found in $BACKEND_DIR"
        return 1
    fi
}

# Function to initialize system
initialize_system() {
    log INFO "Initializing Expense Tracker system..."
    
    # Ensure admin config directory exists
    sudo mkdir -p "$ADMIN_CONFIG_DIR"
    
    # Create admin config file if it doesn't exist
    if [ ! -f "$ADMIN_CONFIG_FILE" ]; then
        sudo tee "$ADMIN_CONFIG_FILE" > /dev/null << EOF
{
    "initialized": false,
    "initialized_at": null,
    "admin_users": [],
    "system_settings": {
        "registration_enabled": true,
        "email_verification_required": true,
        "maintenance_mode": false
    }
}
EOF
        sudo chmod 600 "$ADMIN_CONFIG_FILE"
        log INFO "Admin configuration file created"
    fi
    
    # Run migrations
    if run_migrations; then
        log INFO "Database migrations completed"
    else
        log ERROR "Migration failed"
        return 1
    fi
    
    # Mark system as initialized
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    sudo jq --arg timestamp "$timestamp" \
        '.initialized = true | .initialized_at = $timestamp' \
        "$ADMIN_CONFIG_FILE" > "/tmp/admin-config.json.tmp"
    sudo mv "/tmp/admin-config.json.tmp" "$ADMIN_CONFIG_FILE"
    
    log INFO "System initialization completed"
}

# Function to show system status
show_system_status() {
    echo -e "${BLUE}🔍 System Status${NC}"
    echo "==============="
    echo ""
    
    # Database status
    echo -e "${YELLOW}🗃️  Database:${NC}"
    if check_database_connection; then
        echo -e "${GREEN}✅ Connected and accessible${NC}"
    else
        echo -e "${RED}❌ Connection failed${NC}"
    fi
    
    # Application status
    echo -e "\n${YELLOW}🚀 Application:${NC}"
    if check_application_status; then
        echo -e "${GREEN}✅ Running and responding${NC}"
    else
        echo -e "${RED}❌ Not responding${NC}"
    fi
    
    # Admin users count
    echo -e "\n${YELLOW}👑 Admin Users:${NC}"
    if check_database_connection; then
        local db_url="$DATABASE_URL"
        local db_user=$(echo "$db_url" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
        local db_pass=$(echo "$db_url" | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
        local db_host=$(echo "$db_url" | sed -n 's/.*@\([^:]*\):.*/\1/p')
        local db_port=$(echo "$db_url" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p')
        local db_name=$(echo "$db_url" | sed -n 's/.*\/\([^?]*\).*/\1/p')
        
        local admin_count=$(PGPASSWORD="$db_pass" psql -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" \
            -t -c "SELECT COUNT(*) FROM users WHERE is_admin = true;" | xargs)
        
        echo "• Total admin users: $admin_count"
        
        if [ "$admin_count" -eq 0 ]; then
            echo -e "${RED}⚠️  No admin users found${NC}"
        else
            echo -e "${GREEN}✅ Admin users configured${NC}"
        fi
    else
        echo -e "${RED}❌ Cannot check (database unavailable)${NC}"
    fi
    
    # Configuration status
    echo -e "\n${YELLOW}⚙️  Configuration:${NC}"
    if [ -f "$ADMIN_CONFIG_FILE" ]; then
        local initialized=$(jq -r '.initialized' "$ADMIN_CONFIG_FILE" 2>/dev/null || echo "false")
        if [ "$initialized" = "true" ]; then
            echo -e "${GREEN}✅ System initialized${NC}"
        else
            echo -e "${YELLOW}⚠️  System not initialized${NC}"
        fi
    else
        echo -e "${RED}❌ Configuration file missing${NC}"
    fi
}

# Interactive admin creation
interactive_admin_creation() {
    echo -e "${YELLOW}👑 Creating Admin User${NC}"
    echo "====================="
    echo ""
    
    # Get email
    while true; do
        read -p "Admin Email: " admin_email
        if validate_email "$admin_email"; then
            break
        else
            echo -e "${RED}❌ Invalid email format${NC}"
        fi
    done
    
    # Get full name
    read -p "Full Name: " admin_name
    
    # Get password
    while true; do
        echo ""
        echo "Password requirements:"
        echo "• At least 8 characters"
        echo "• At least one uppercase letter"
        echo "• At least one lowercase letter"
        echo "• At least one number"
        echo "• At least one special character"
        echo ""
        
        read -p "Would you like to generate a secure password automatically? (y/N): " auto_generate
        
        if [[ $auto_generate == [yY] ]]; then
            admin_password=$(generate_password 16)
            echo -e "${GREEN}Generated password: $admin_password${NC}"
            echo -e "${YELLOW}⚠️  Please save this password securely!${NC}"
            break
        else
            read -s -p "Admin Password: " admin_password
            echo ""
            read -s -p "Confirm Password: " admin_password_confirm
            echo ""
            
            if [ "$admin_password" != "$admin_password_confirm" ]; then
                echo -e "${RED}❌ Passwords do not match${NC}"
                continue
            fi
            
            local validation_result=$(validate_password "$admin_password")
            if [ $? -eq 0 ]; then
                break
            else
                echo -e "${RED}❌ $validation_result${NC}"
            fi
        fi
    done
    
    # Create the admin user
    echo ""
    echo -e "${YELLOW}Creating admin user...${NC}"
    
    if create_admin_user "$admin_email" "$admin_password" "$admin_name"; then
        echo -e "${GREEN}✅ Admin user created successfully!${NC}"
        echo ""
        echo -e "${YELLOW}📋 Admin User Details:${NC}"
        echo "• Email: $admin_email"
        echo "• Name: $admin_name"
        echo "• Password: [saved securely]"
        echo ""
        echo -e "${YELLOW}🔐 Next Steps:${NC}"
        echo "1. Test login with the credentials above"
        echo "2. Change the default password if auto-generated"
        echo "3. Configure additional admin users if needed"
    else
        echo -e "${RED}❌ Failed to create admin user${NC}"
        return 1
    fi
}

# Main command handler
main() {
    local command="${1:-help}"
    
    # Ensure log file exists and is writable
    sudo touch "$ADMIN_CLI_LOG"
    sudo chmod 666 "$ADMIN_CLI_LOG"
    
    case $command in
        "init")
            initialize_system
            ;;
        "create-admin")
            if [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ]; then
                # Non-interactive mode
                local email="$2"
                local password="$3"
                local name="$4"
                
                if validate_email "$email"; then
                    create_admin_user "$email" "$password" "$name"
                else
                    log ERROR "Invalid email format: $email"
                    exit 1
                fi
            else
                # Interactive mode
                interactive_admin_creation
            fi
            ;;
        "list-admins")
            list_admin_users
            ;;
        "reset-password")
            if [ -n "$2" ]; then
                local email="$2"
                local new_password="${3:-$(generate_password 16)}"
                
                echo -e "${YELLOW}Resetting password for: $email${NC}"
                if [ -z "$3" ]; then
                    echo -e "${YELLOW}Generated new password: $new_password${NC}"
                    echo -e "${YELLOW}⚠️  Please save this password securely!${NC}"
                fi
                
                reset_admin_password "$email" "$new_password"
            else
                echo -e "${RED}❌ Email address required${NC}"
                echo "Usage: $0 reset-password <email> [new_password]"
                exit 1
            fi
            ;;
        "migrate")
            run_migrations
            ;;
        "status")
            show_system_status
            ;;
        "generate-password")
            local length="${2:-16}"
            local password=$(generate_password "$length")
            echo -e "${GREEN}Generated password: $password${NC}"
            ;;
        *)
            echo -e "${BLUE}👑 Admin Bootstrap CLI for Flutter Expense Tracker${NC}"
            echo "================================================="
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init                                  - Initialize the system"
            echo "  create-admin [email] [password] [name] - Create admin user (interactive if no args)"
            echo "  list-admins                          - List all admin users"
            echo "  reset-password <email> [password]   - Reset admin password"
            echo "  migrate                              - Run database migrations"
            echo "  status                               - Show system status"
            echo "  generate-password [length]           - Generate secure password"
            echo ""
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 create-admin"
            echo "  $0 create-admin admin@company.com SecurePass123! \"Admin User\""
            echo "  $0 list-admins"
            echo "  $0 reset-password admin@company.com"
            echo "  $0 status"
            echo ""
            echo -e "${YELLOW}💡 Tips:${NC}"
            echo "• Run 'init' first to set up the system"
            echo "• Use 'status' to check system health"
            echo "• Interactive mode provides better UX for creating users"
            echo "• Generated passwords are cryptographically secure"
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
