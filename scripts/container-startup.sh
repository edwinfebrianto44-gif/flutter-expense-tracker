#!/bin/bash

# Container Startup Script with Automatic Migrations
# Handles idempotent database migrations and application startup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Container Startup - Flutter Expense Tracker${NC}"
echo "=============================================="
echo ""

# Configuration
APP_DIR="/app"
LOG_FILE="/var/log/container-startup.log"
MIGRATION_LOCK_FILE="/tmp/migration.lock"
MAX_MIGRATION_WAIT=300  # 5 minutes
HEALTH_CHECK_RETRIES=30
HEALTH_CHECK_INTERVAL=2

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        ERROR)
            echo -e "${RED}[$timestamp] ERROR: $message${NC}" | tee -a "$LOG_FILE"
            ;;
        WARN)
            echo -e "${YELLOW}[$timestamp] WARN: $message${NC}" | tee -a "$LOG_FILE"
            ;;
        INFO)
            echo -e "${GREEN}[$timestamp] INFO: $message${NC}" | tee -a "$LOG_FILE"
            ;;
        DEBUG)
            echo -e "${BLUE}[$timestamp] DEBUG: $message${NC}" | tee -a "$LOG_FILE"
            ;;
    esac
}

# Function to wait for database to be ready
wait_for_database() {
    log INFO "Waiting for database to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log DEBUG "Database connection attempt $attempt/$max_attempts"
        
        if python3 -c "
import psycopg2
import os
import sys
try:
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    conn.close()
    print('Database connection successful')
    sys.exit(0)
except Exception as e:
    print(f'Database connection failed: {e}')
    sys.exit(1)
" 2>/dev/null; then
            log INFO "Database is ready"
            return 0
        fi
        
        log DEBUG "Database not ready, waiting..."
        sleep 2
        ((attempt++))
    done
    
    log ERROR "Database did not become ready within expected time"
    return 1
}

# Function to check if another migration is running
check_migration_lock() {
    if [ -f "$MIGRATION_LOCK_FILE" ]; then
        local lock_pid=$(cat "$MIGRATION_LOCK_FILE")
        local lock_age=$(($(date +%s) - $(stat -c %Y "$MIGRATION_LOCK_FILE")))
        
        # Check if the process is still running
        if kill -0 "$lock_pid" 2>/dev/null; then
            if [ $lock_age -lt $MAX_MIGRATION_WAIT ]; then
                log INFO "Another migration process is running (PID: $lock_pid), waiting..."
                return 1
            else
                log WARN "Stale migration lock detected (age: ${lock_age}s), removing..."
                rm -f "$MIGRATION_LOCK_FILE"
                return 0
            fi
        else
            log WARN "Stale migration lock detected (process not running), removing..."
            rm -f "$MIGRATION_LOCK_FILE"
            return 0
        fi
    fi
    return 0
}

# Function to create migration lock
create_migration_lock() {
    echo $$ > "$MIGRATION_LOCK_FILE"
    log DEBUG "Created migration lock with PID: $$"
}

# Function to remove migration lock
remove_migration_lock() {
    rm -f "$MIGRATION_LOCK_FILE"
    log DEBUG "Removed migration lock"
}

# Function to get current database schema version
get_current_schema_version() {
    python3 -c "
import psycopg2
import os
import sys

try:
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    cursor = conn.cursor()
    
    # Check if alembic_version table exists
    cursor.execute(\"\"\"
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'alembic_version'
        );
    \"\"\")
    
    table_exists = cursor.fetchone()[0]
    
    if table_exists:
        cursor.execute('SELECT version_num FROM alembic_version;')
        result = cursor.fetchone()
        if result:
            print(result[0])
        else:
            print('empty')
    else:
        print('no_table')
    
    conn.close()
except Exception as e:
    print(f'error: {e}')
    sys.exit(1)
"
}

# Function to run database migrations
run_migrations() {
    log INFO "Running database migrations..."
    
    # Wait for any existing migrations to complete
    local wait_time=0
    while ! check_migration_lock; do
        if [ $wait_time -ge $MAX_MIGRATION_WAIT ]; then
            log ERROR "Timeout waiting for existing migration to complete"
            return 1
        fi
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    # Create lock
    create_migration_lock
    
    # Ensure we remove the lock on exit
    trap remove_migration_lock EXIT
    
    # Get current schema version
    local current_version=$(get_current_schema_version)
    log INFO "Current database schema version: $current_version"
    
    # Change to backend directory
    cd "$APP_DIR"
    
    # Check if migrations are needed
    if [ "$current_version" = "no_table" ]; then
        log INFO "No alembic_version table found, initializing database..."
        
        # Initialize Alembic
        if ! alembic stamp base; then
            log ERROR "Failed to initialize Alembic"
            return 1
        fi
        
        log INFO "Database initialized, running migrations..."
    elif [ "$current_version" = "empty" ]; then
        log INFO "Empty alembic_version table, stamping base..."
        
        if ! alembic stamp base; then
            log ERROR "Failed to stamp base version"
            return 1
        fi
    fi
    
    # Get target migration version
    local target_version=$(alembic heads | awk '{print $1}' | head -n1)
    log INFO "Target migration version: $target_version"
    
    # Check if migration is needed
    if [ "$current_version" = "$target_version" ] && [ "$current_version" != "no_table" ] && [ "$current_version" != "empty" ]; then
        log INFO "Database is already up to date"
        remove_migration_lock
        return 0
    fi
    
    # Run migrations with proper error handling
    log INFO "Applying migrations..."
    
    if alembic upgrade head; then
        local new_version=$(get_current_schema_version)
        log INFO "Migrations completed successfully, new version: $new_version"
        
        # Verify migration success
        if [ "$new_version" = "$target_version" ]; then
            log INFO "Migration verification successful"
        else
            log WARN "Migration version mismatch - target: $target_version, actual: $new_version"
        fi
        
        remove_migration_lock
        return 0
    else
        log ERROR "Migration failed"
        remove_migration_lock
        return 1
    fi
}

# Function to create initial admin user if none exists
create_initial_admin() {
    log INFO "Checking for admin users..."
    
    local admin_count=$(python3 -c "
import psycopg2
import os
import sys

try:
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    cursor = conn.cursor()
    
    # Check if users table exists
    cursor.execute(\"\"\"
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'users'
        );
    \"\"\")
    
    table_exists = cursor.fetchone()[0]
    
    if table_exists:
        cursor.execute('SELECT COUNT(*) FROM users WHERE is_admin = true;')
        result = cursor.fetchone()
        print(result[0])
    else:
        print('0')
    
    conn.close()
except Exception as e:
    print('0')
    sys.exit(0)
")
    
    log INFO "Found $admin_count admin users"
    
    if [ "$admin_count" -eq 0 ]; then
        log INFO "No admin users found, creating initial admin..."
        
        # Get admin credentials from environment or use defaults
        local admin_email="${ADMIN_EMAIL:-admin@localhost}"
        local admin_password="${ADMIN_PASSWORD:-Admin123!}"
        local admin_name="${ADMIN_NAME:-System Administrator}"
        
        # Create admin user using the bootstrap script
        if [ -f "/usr/local/bin/admin-bootstrap.sh" ]; then
            bash /usr/local/bin/admin-bootstrap.sh create-admin "$admin_email" "$admin_password" "$admin_name"
        else
            # Fallback to direct database insertion
            python3 -c "
import psycopg2
import bcrypt
import os
import sys
from datetime import datetime

try:
    conn = psycopg2.connect(os.environ['DATABASE_URL'])
    cursor = conn.cursor()
    
    # Hash password
    password = '$admin_password'.encode('utf-8')
    salt = bcrypt.gensalt(rounds=12)
    password_hash = bcrypt.hashpw(password, salt).decode('utf-8')
    
    # Insert admin user
    cursor.execute(\"\"\"
        INSERT INTO users (email, password_hash, full_name, is_admin, is_active, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (email) DO UPDATE SET
            password_hash = EXCLUDED.password_hash,
            is_admin = true,
            is_active = true,
            updated_at = EXCLUDED.updated_at;
    \"\"\", ('$admin_email', password_hash, '$admin_name', True, True, datetime.utcnow(), datetime.utcnow()))
    
    conn.commit()
    conn.close()
    
    print('Admin user created successfully')
    sys.exit(0)
except Exception as e:
    print(f'Failed to create admin user: {e}')
    sys.exit(1)
"
        fi
        
        if [ $? -eq 0 ]; then
            log INFO "Initial admin user created successfully"
            log INFO "Email: $admin_email"
            log INFO "Password: [secured]"
        else
            log WARN "Failed to create initial admin user"
        fi
    else
        log INFO "Admin users already exist, skipping creation"
    fi
}

# Function to validate environment configuration
validate_environment() {
    log INFO "Validating environment configuration..."
    
    local errors=0
    
    # Check required environment variables
    local required_vars=(
        "DATABASE_URL"
        "JWT_SECRET_KEY"
        "API_SECRET_KEY"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log ERROR "Required environment variable not set: $var"
            ((errors++))
        else
            log DEBUG "Environment variable set: $var"
        fi
    done
    
    # Validate JWT secret length
    if [ -n "$JWT_SECRET_KEY" ] && [ ${#JWT_SECRET_KEY} -lt 32 ]; then
        log ERROR "JWT_SECRET_KEY is too short (minimum 32 characters)"
        ((errors++))
    fi
    
    # Validate API secret length
    if [ -n "$API_SECRET_KEY" ] && [ ${#API_SECRET_KEY} -lt 32 ]; then
        log ERROR "API_SECRET_KEY is too short (minimum 32 characters)"
        ((errors++))
    fi
    
    # Check database URL format
    if [ -n "$DATABASE_URL" ] && ! [[ $DATABASE_URL =~ ^postgresql:// ]]; then
        log WARN "DATABASE_URL should use PostgreSQL for production"
    fi
    
    if [ $errors -eq 0 ]; then
        log INFO "Environment validation passed"
        return 0
    else
        log ERROR "Environment validation failed with $errors errors"
        return 1
    fi
}

# Function to setup logging
setup_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Create log file with proper permissions
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    log INFO "Container startup initiated"
    log INFO "Environment: ${ENVIRONMENT:-development}"
    log INFO "Application directory: $APP_DIR"
    log INFO "Container ID: $(hostname)"
}

# Function to check application health
check_application_health() {
    local max_retries=$HEALTH_CHECK_RETRIES
    local interval=$HEALTH_CHECK_INTERVAL
    local retry=1
    
    log INFO "Checking application health..."
    
    while [ $retry -le $max_retries ]; do
        log DEBUG "Health check attempt $retry/$max_retries"
        
        # Check if the application is responding
        if curl -f -s "http://localhost:${PORT:-8000}/health" >/dev/null 2>&1; then
            log INFO "Application health check passed"
            return 0
        fi
        
        log DEBUG "Health check failed, retrying in ${interval}s..."
        sleep $interval
        ((retry++))
    done
    
    log ERROR "Application health check failed after $max_retries attempts"
    return 1
}

# Function to start the application
start_application() {
    log INFO "Starting application..."
    
    # Change to application directory
    cd "$APP_DIR"
    
    # Determine how to start the application
    if [ -n "$GUNICORN_CMD" ]; then
        log INFO "Starting with Gunicorn: $GUNICORN_CMD"
        exec $GUNICORN_CMD
    elif [ -f "main.py" ]; then
        log INFO "Starting with Uvicorn"
        exec uvicorn main:app \
            --host "${HOST:-0.0.0.0}" \
            --port "${PORT:-8000}" \
            --workers "${WORKERS:-4}" \
            --worker-class "${WORKER_CLASS:-uvicorn.workers.UvicornWorker}" \
            --access-log \
            --log-level "${LOG_LEVEL:-info}"
    else
        log ERROR "No startup method found"
        return 1
    fi
}

# Function to handle graceful shutdown
handle_shutdown() {
    log INFO "Received shutdown signal, stopping application..."
    
    # Remove migration lock if it exists
    remove_migration_lock 2>/dev/null || true
    
    # Give the application time to finish current requests
    sleep 5
    
    log INFO "Application shutdown complete"
    exit 0
}

# Function to run pre-startup checks
run_pre_startup_checks() {
    log INFO "Running pre-startup checks..."
    
    # Check if required files exist
    if [ ! -f "$APP_DIR/main.py" ]; then
        log ERROR "Application main.py not found in $APP_DIR"
        return 1
    fi
    
    if [ ! -f "$APP_DIR/alembic.ini" ]; then
        log WARN "Alembic configuration not found, migrations may not work"
    fi
    
    # Check Python dependencies
    if ! python3 -c "import fastapi, uvicorn, alembic" 2>/dev/null; then
        log ERROR "Required Python dependencies not installed"
        return 1
    fi
    
    log INFO "Pre-startup checks passed"
    return 0
}

# Main startup sequence
main() {
    # Setup logging first
    setup_logging
    
    # Setup signal handlers for graceful shutdown
    trap handle_shutdown SIGTERM SIGINT
    
    # Validate environment
    if ! validate_environment; then
        log ERROR "Environment validation failed, exiting"
        exit 1
    fi
    
    # Run pre-startup checks
    if ! run_pre_startup_checks; then
        log ERROR "Pre-startup checks failed, exiting"
        exit 1
    fi
    
    # Wait for database
    if ! wait_for_database; then
        log ERROR "Database is not available, exiting"
        exit 1
    fi
    
    # Run migrations
    if ! run_migrations; then
        log ERROR "Migration failed, exiting"
        exit 1
    fi
    
    # Create initial admin if needed
    if [ "${CREATE_ADMIN:-true}" = "true" ]; then
        create_initial_admin
    fi
    
    # Start application in background for health check
    log INFO "Starting application for health check..."
    start_application &
    APP_PID=$!
    
    # Wait a moment for the application to start
    sleep 5
    
    # Check application health
    if check_application_health; then
        log INFO "Application started successfully"
        log INFO "Container startup completed"
        
        # Wait for the application process
        wait $APP_PID
    else
        log ERROR "Application failed health check"
        kill $APP_PID 2>/dev/null || true
        exit 1
    fi
}

# Create the startup script for Docker
echo -e "${GREEN}📝 Creating Docker startup script...${NC}"

cat > "$SCRIPT_DIR/docker-startup.sh" << 'EODOCKER'
#!/bin/bash

# Docker Container Startup Script
# This script should be used as the ENTRYPOINT in your Dockerfile

# Set up environment
export PYTHONPATH="/app:$PYTHONPATH"
export PYTHONUNBUFFERED=1

# Source environment file if it exists
if [ -f "/app/.env" ]; then
    source /app/.env
fi

# Run the startup script
exec /usr/local/bin/container-startup.sh "$@"
EODOCKER

chmod +x "$SCRIPT_DIR/docker-startup.sh"

# Create the systemd service file for production deployment
echo -e "${GREEN}📝 Creating systemd service...${NC}"

cat > "$SCRIPT_DIR/expense-tracker.service" << 'EOSYSTEMD'
[Unit]
Description=Expense Tracker API Service
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=exec
User=www-data
Group=www-data
WorkingDirectory=/app
Environment=PYTHONPATH=/app
EnvironmentFile=/app/.env
ExecStart=/usr/local/bin/container-startup.sh
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=always
RestartSec=10

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/app/storage /var/log /tmp
PrivateTmp=true

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOSYSTEMD

# Create Docker health check script
echo -e "${GREEN}📝 Creating Docker health check...${NC}"

cat > "$SCRIPT_DIR/docker-healthcheck.sh" << 'EOHEALTH'
#!/bin/bash

# Docker Health Check Script
# Used in Dockerfile HEALTHCHECK instruction

set -e

# Configuration
API_URL="http://localhost:${PORT:-8000}/health"
TIMEOUT=10

# Perform health check
if curl -f -s --max-time $TIMEOUT "$API_URL" >/dev/null 2>&1; then
    echo "Health check passed"
    exit 0
else
    echo "Health check failed"
    exit 1
fi
EOHEALTH

chmod +x "$SCRIPT_DIR/docker-healthcheck.sh"

# Create the main container startup script
sudo cp - /usr/local/bin/container-startup.sh << 'EOF'
#!/bin/bash

# Container Startup Script with Automatic Migrations
# This is the actual startup script that gets installed

# All the functions and main logic from above go here
# (The script content is already defined above in the main function)

# Execute the main function if this script is run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
EOF

# The main function call for this setup script
main "$@"
