#!/bin/bash

# Production Environment Management Script for Flutter Expense Tracker
# Manages .env files, secrets, and environment configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Production Environment Management${NC}"
echo "===================================="
echo "This script manages production environment configuration and secrets"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Function to generate secure random string
generate_secret() {
    local length=${1:-64}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to generate JWT secret
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "\n"
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

# Function to validate domain format
validate_domain() {
    local domain="$1"
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

echo -e "${GREEN}📋 Creating production .env.example template...${NC}"

# Create comprehensive .env.example
cat > "$BACKEND_DIR/.env.example" << 'EOF'
# Production Environment Configuration for Flutter Expense Tracker
# Copy this file to .env and configure with your production values
# NEVER commit .env to version control!

# ================================
# Application Configuration
# ================================
ENVIRONMENT=production
DEBUG=false
API_VERSION=v1
APP_NAME="Expense Tracker"
APP_DESCRIPTION="Personal Finance Management System"

# ================================
# Server Configuration
# ================================
HOST=0.0.0.0
PORT=8000
WORKERS=4
WORKER_CLASS=uvicorn.workers.UvicornWorker

# ================================
# Domain Configuration
# ================================
API_DOMAIN=api.yourdomain.com
APP_DOMAIN=app.yourdomain.com
CORS_ORIGINS=https://app.yourdomain.com,https://yourdomain.com
ALLOWED_HOSTS=api.yourdomain.com,app.yourdomain.com,localhost

# ================================
# SSL/TLS Configuration
# ================================
SSL_CERT_PATH=/etc/letsencrypt/live/api.yourdomain.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/api.yourdomain.com/privkey.pem
FORCE_HTTPS=true
HSTS_MAX_AGE=31536000

# ================================
# Security Configuration
# ================================
# JWT Secret Key (generate with: openssl rand -base64 64)
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# API Key for internal services (generate with: openssl rand -hex 32)
API_SECRET_KEY=your-api-secret-key-change-this-in-production

# Session configuration
SESSION_SECRET_KEY=your-session-secret-key-change-this
SESSION_COOKIE_SECURE=true
SESSION_COOKIE_HTTPONLY=true
SESSION_COOKIE_SAMESITE=strict

# Password hashing
BCRYPT_ROUNDS=12

# ================================
# Database Configuration
# ================================
# PostgreSQL (recommended for production)
DATABASE_URL=postgresql://username:password@localhost:5432/expense_tracker
DB_HOST=localhost
DB_PORT=5432
DB_NAME=expense_tracker
DB_USER=expense_tracker_user
DB_PASSWORD=secure_database_password
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=30
DB_POOL_TIMEOUT=30
DB_POOL_RECYCLE=3600

# Database SSL (enable for remote databases)
DB_SSL_MODE=require
DB_SSL_CERT_PATH=/path/to/client-cert.pem
DB_SSL_KEY_PATH=/path/to/client-key.pem
DB_SSL_CA_PATH=/path/to/ca-cert.pem

# ================================
# Redis Configuration (for caching and sessions)
# ================================
REDIS_URL=redis://localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0
REDIS_PASSWORD=secure_redis_password
REDIS_SSL=false
REDIS_POOL_SIZE=20

# ================================
# Email Configuration
# ================================
SMTP_HOST=smtp.yourmailprovider.com
SMTP_PORT=587
SMTP_USERNAME=your-email@yourdomain.com
SMTP_PASSWORD=your-email-password
SMTP_TLS=true
SMTP_SSL=false
EMAIL_FROM=noreply@yourdomain.com
EMAIL_FROM_NAME="Expense Tracker"

# Email templates
EMAIL_TEMPLATE_DIR=/app/templates/email
ADMIN_EMAIL=admin@yourdomain.com

# ================================
# File Storage Configuration
# ================================
# Local storage
UPLOAD_DIR=/app/storage/uploads
MAX_UPLOAD_SIZE=10485760
ALLOWED_EXTENSIONS=jpg,jpeg,png,gif,pdf,csv,xlsx

# S3/MinIO Configuration (recommended for production)
USE_S3=true
AWS_ACCESS_KEY_ID=your-s3-access-key
AWS_SECRET_ACCESS_KEY=your-s3-secret-key
AWS_REGION=us-east-1
S3_BUCKET=expense-tracker-uploads
S3_ENDPOINT_URL=https://your-minio-endpoint.com
S3_SECURE=true

# CDN Configuration
CDN_BASE_URL=https://cdn.yourdomain.com
USE_CDN=true

# ================================
# Backup Configuration
# ================================
BACKUP_ENABLED=true
BACKUP_S3_BUCKET=expense-tracker-backups
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPTION_KEY=your-backup-encryption-key
BACKUP_SCHEDULE="0 2 * * *"

# ================================
# Monitoring and Logging
# ================================
LOG_LEVEL=INFO
LOG_FORMAT=json
LOG_FILE=/var/log/expense-tracker/app.log
LOG_MAX_SIZE=100MB
LOG_BACKUP_COUNT=10

# Sentry (error tracking)
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1

# Prometheus metrics
METRICS_ENABLED=true
METRICS_PORT=9090
METRICS_PATH=/metrics

# Health check configuration
HEALTH_CHECK_ENABLED=true
HEALTH_CHECK_PATH=/health

# ================================
# Rate Limiting
# ================================
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_PERIOD=3600
RATE_LIMIT_STORAGE=redis

# API rate limits (requests per minute)
API_RATE_LIMIT_AUTH=10
API_RATE_LIMIT_GENERAL=60
API_RATE_LIMIT_UPLOAD=5

# ================================
# Feature Flags
# ================================
FEATURE_REGISTRATION_ENABLED=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_TWO_FACTOR_AUTH=false
FEATURE_SOCIAL_LOGIN=false
FEATURE_ANALYTICS=true
FEATURE_EXPORT_DATA=true

# ================================
# Third-party Integrations
# ================================
# Google OAuth (if enabled)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Stripe (for payments, if needed)
STRIPE_PUBLIC_KEY=pk_live_your-stripe-public-key
STRIPE_SECRET_KEY=sk_live_your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=whsec_your-webhook-secret

# ================================
# Performance Configuration
# ================================
# Caching
CACHE_ENABLED=true
CACHE_TTL=3600
CACHE_PREFIX=expense_tracker

# Database query optimization
DB_ECHO=false
DB_QUERY_TIMEOUT=30

# Response compression
GZIP_ENABLED=true
GZIP_LEVEL=6

# ================================
# Development/Testing Overrides
# ================================
# (These should be false/disabled in production)
ALLOW_ORIGINS_ALL=false
DISABLE_AUTH=false
MOCK_EMAIL=false
SKIP_MIGRATIONS=false

# ================================
# Container Configuration
# ================================
DOCKER_HOST_UID=1000
DOCKER_HOST_GID=1000
CONTAINER_TIMEZONE=UTC

# ================================
# Maintenance Mode
# ================================
MAINTENANCE_MODE=false
MAINTENANCE_MESSAGE="System is under maintenance. Please try again later."
MAINTENANCE_ALLOWED_IPS=127.0.0.1,::1
EOF

echo -e "${GREEN}📝 Creating production environment setup script...${NC}"

# Create environment configuration script
cat > "$SCRIPT_DIR/setup-env.sh" << 'EOF'
#!/bin/bash

# Production Environment Setup Helper
# Interactive script to configure production .env file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Production Environment Configuration${NC}"
echo "======================================"
echo ""

# Check if .env already exists
if [ -f "$BACKEND_DIR/.env" ]; then
    echo -e "${YELLOW}⚠️  .env file already exists!${NC}"
    read -p "Do you want to backup and recreate it? (y/N): " recreate
    if [[ $recreate == [yY] ]]; then
        cp "$BACKEND_DIR/.env" "$BACKEND_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✅ Backup created${NC}"
    else
        echo "Exiting to avoid overwriting existing configuration."
        exit 0
    fi
fi

# Generate secrets
echo -e "${GREEN}🔐 Generating secure secrets...${NC}"
JWT_SECRET=$(openssl rand -base64 64 | tr -d "\n")
API_SECRET=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -base64 64 | tr -d "\n")
BACKUP_ENCRYPTION_KEY=$(openssl rand -base64 32 | tr -d "\n")

echo -e "${GREEN}✅ Secrets generated${NC}"
echo ""

# Collect configuration
echo -e "${YELLOW}📋 Please provide the following configuration:${NC}"
echo ""

# Domain configuration
read -p "API Domain (e.g., api.yourdomain.com): " API_DOMAIN
read -p "App Domain (e.g., app.yourdomain.com): " APP_DOMAIN

# Database configuration
echo -e "\n${YELLOW}🗃️  Database Configuration:${NC}"
read -p "Database Host (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}
read -p "Database Port (default: 5432): " DB_PORT
DB_PORT=${DB_PORT:-5432}
read -p "Database Name (default: expense_tracker): " DB_NAME
DB_NAME=${DB_NAME:-expense_tracker}
read -p "Database User: " DB_USER
read -s -p "Database Password: " DB_PASSWORD
echo ""

# Email configuration
echo -e "\n${YELLOW}📧 Email Configuration:${NC}"
read -p "SMTP Host: " SMTP_HOST
read -p "SMTP Port (default: 587): " SMTP_PORT
SMTP_PORT=${SMTP_PORT:-587}
read -p "SMTP Username: " SMTP_USERNAME
read -s -p "SMTP Password: " SMTP_PASSWORD
echo ""
read -p "From Email: " EMAIL_FROM
read -p "Admin Email: " ADMIN_EMAIL

# S3/Storage configuration
echo -e "\n${YELLOW}📁 Storage Configuration:${NC}"
read -p "Use S3/MinIO for file storage? (y/N): " USE_S3
if [[ $USE_S3 == [yY] ]]; then
    read -p "S3 Access Key ID: " AWS_ACCESS_KEY_ID
    read -s -p "S3 Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo ""
    read -p "S3 Region (default: us-east-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-us-east-1}
    read -p "S3 Bucket Name: " S3_BUCKET
    read -p "S3 Endpoint URL (leave empty for AWS): " S3_ENDPOINT_URL
    USE_S3=true
else
    USE_S3=false
fi

# Monitoring configuration
echo -e "\n${YELLOW}📊 Monitoring Configuration:${NC}"
read -p "Sentry DSN (optional): " SENTRY_DSN

echo -e "\n${GREEN}📝 Creating production .env file...${NC}"

# Create the .env file
cat > "$BACKEND_DIR/.env" << EOL
# Production Environment Configuration - Generated $(date)
# WARNING: This file contains sensitive information. Keep it secure!

# Application Configuration
ENVIRONMENT=production
DEBUG=false
API_VERSION=v1
APP_NAME="Expense Tracker"

# Server Configuration
HOST=0.0.0.0
PORT=8000
WORKERS=4

# Domain Configuration
API_DOMAIN=$API_DOMAIN
APP_DOMAIN=$APP_DOMAIN
CORS_ORIGINS=https://$APP_DOMAIN
ALLOWED_HOSTS=$API_DOMAIN,$APP_DOMAIN,localhost

# Security Configuration
JWT_SECRET_KEY=$JWT_SECRET
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7
API_SECRET_KEY=$API_SECRET
SESSION_SECRET_KEY=$SESSION_SECRET
SESSION_COOKIE_SECURE=true
SESSION_COOKIE_HTTPONLY=true
SESSION_COOKIE_SAMESITE=strict
BCRYPT_ROUNDS=12

# Database Configuration
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=30
DB_SSL_MODE=prefer

# Redis Configuration
REDIS_URL=redis://localhost:6379/0
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# Email Configuration
SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USERNAME=$SMTP_USERNAME
SMTP_PASSWORD=$SMTP_PASSWORD
SMTP_TLS=true
EMAIL_FROM=$EMAIL_FROM
ADMIN_EMAIL=$ADMIN_EMAIL

# File Storage Configuration
USE_S3=$USE_S3
EOL

if [[ $USE_S3 == true ]]; then
    cat >> "$BACKEND_DIR/.env" << EOL
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION=$AWS_REGION
S3_BUCKET=$S3_BUCKET
EOL
    if [ -n "$S3_ENDPOINT_URL" ]; then
        echo "S3_ENDPOINT_URL=$S3_ENDPOINT_URL" >> "$BACKEND_DIR/.env"
    fi
fi

cat >> "$BACKEND_DIR/.env" << EOL

# Backup Configuration
BACKUP_ENABLED=true
BACKUP_S3_BUCKET=${S3_BUCKET:-expense-tracker-backups}
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPTION_KEY=$BACKUP_ENCRYPTION_KEY

# Monitoring Configuration
LOG_LEVEL=INFO
LOG_FORMAT=json
METRICS_ENABLED=true
HEALTH_CHECK_ENABLED=true
EOL

if [ -n "$SENTRY_DSN" ]; then
    cat >> "$BACKEND_DIR/.env" << EOL
SENTRY_DSN=$SENTRY_DSN
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1
EOL
fi

cat >> "$BACKEND_DIR/.env" << EOL

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_PERIOD=3600
API_RATE_LIMIT_AUTH=10
API_RATE_LIMIT_GENERAL=60

# Feature Flags
FEATURE_REGISTRATION_ENABLED=true
FEATURE_EMAIL_VERIFICATION=true
FEATURE_ANALYTICS=true
FEATURE_EXPORT_DATA=true

# Performance Configuration
CACHE_ENABLED=true
CACHE_TTL=3600
GZIP_ENABLED=true

# Security
FORCE_HTTPS=true
HSTS_MAX_AGE=31536000

# Production Settings
MAINTENANCE_MODE=false
ALLOW_ORIGINS_ALL=false
DISABLE_AUTH=false
MOCK_EMAIL=false
EOL

# Set secure permissions
chmod 600 "$BACKEND_DIR/.env"

echo -e "${GREEN}✅ Production .env file created successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Configuration Summary:${NC}"
echo "• API Domain: $API_DOMAIN"
echo "• App Domain: $APP_DOMAIN"
echo "• Database: $DB_HOST:$DB_PORT/$DB_NAME"
echo "• Storage: $([ "$USE_S3" = "true" ] && echo "S3/MinIO" || echo "Local filesystem")"
echo "• Monitoring: $([ -n "$SENTRY_DSN" ] && echo "Sentry enabled" || echo "Local logs only")"
echo ""
echo -e "${YELLOW}🔐 Security Notes:${NC}"
echo "• JWT secrets have been automatically generated"
echo "• File permissions set to 600 (owner read/write only)"
echo "• Never commit .env to version control"
echo "• Regularly rotate secrets using the rotation script"
echo ""
echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo "1. Review the generated .env file: nano $BACKEND_DIR/.env"
echo "2. Run database migrations: cd backend && alembic upgrade head"
echo "3. Test the configuration: docker-compose up -d"
echo "4. Set up secret rotation: ./scripts/rotate-secrets.sh"
echo ""
echo -e "${GREEN}✅ Environment configuration complete!${NC}"
EOF

chmod +x "$SCRIPT_DIR/setup-env.sh"

echo -e "${GREEN}🔄 Creating JWT secret rotation script...${NC}"

# Create JWT rotation script
cat > "$SCRIPT_DIR/rotate-secrets.sh" << 'EOF'
#!/bin/bash

# JWT Secret Rotation Script for Flutter Expense Tracker
# Safely rotates JWT secrets with zero downtime

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 JWT Secret Rotation for Flutter Expense Tracker${NC}"
echo "================================================="
echo ""

# Check if .env exists
if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Run setup-env.sh first to create the production environment."
    exit 1
fi

# Load current environment
source "$BACKEND_DIR/.env"

echo -e "${YELLOW}📋 Current JWT Configuration:${NC}"
echo "• Algorithm: ${JWT_ALGORITHM:-HS256}"
echo "• Access Token Expiry: ${JWT_ACCESS_TOKEN_EXPIRE_MINUTES:-30} minutes"
echo "• Refresh Token Expiry: ${JWT_REFRESH_TOKEN_EXPIRE_DAYS:-7} days"
echo ""

read -p "Continue with JWT secret rotation? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Rotation cancelled."
    exit 0
fi

echo -e "${GREEN}🔐 Generating new JWT secret...${NC}"

# Generate new JWT secret
NEW_JWT_SECRET=$(openssl rand -base64 64 | tr -d "\n")

# Backup current .env
BACKUP_FILE="$BACKEND_DIR/.env.backup.$(date +%Y%m%d_%H%M%S)"
cp "$BACKEND_DIR/.env" "$BACKUP_FILE"
echo -e "${GREEN}✅ Backup created: $BACKUP_FILE${NC}"

# Store old secret for gradual rotation
OLD_JWT_SECRET="$JWT_SECRET_KEY"

echo -e "${YELLOW}⚙️  Implementing gradual rotation strategy...${NC}"

# Create rotation configuration
cat > "$BACKEND_DIR/.env.rotation" << EOL
# JWT Rotation Configuration
# This file supports dual JWT secrets during rotation period

# New secret (primary)
JWT_SECRET_KEY=$NEW_JWT_SECRET

# Old secret (for validation only - remove after rotation period)
JWT_SECRET_KEY_OLD=$OLD_JWT_SECRET

# Rotation timestamp
JWT_ROTATION_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Rotation strategy: gradual (accepts both old and new tokens)
JWT_ROTATION_STRATEGY=gradual
JWT_ROTATION_PERIOD_HOURS=24
EOL

# Update main .env file with new secret
sed -i "s/^JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$NEW_JWT_SECRET/" "$BACKEND_DIR/.env"

# Add rotation tracking to .env
if ! grep -q "JWT_ROTATION_DATE" "$BACKEND_DIR/.env"; then
    echo "" >> "$BACKEND_DIR/.env"
    echo "# JWT Rotation Tracking" >> "$BACKEND_DIR/.env"
    echo "JWT_ROTATION_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$BACKEND_DIR/.env"
fi

echo -e "${GREEN}📝 Creating rotation validation script...${NC}"

# Create validation script for the rotation
cat > "$SCRIPT_DIR/validate-jwt-rotation.sh" << 'EOVAL'
#!/bin/bash

# JWT Rotation Validation Script

BACKEND_DIR="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")/backend"

if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo "❌ .env file not found!"
    exit 1
fi

source "$BACKEND_DIR/.env"

echo "🔍 JWT Rotation Validation"
echo "========================="
echo ""

# Check if rotation config exists
if [ -f "$BACKEND_DIR/.env.rotation" ]; then
    echo "✅ Rotation configuration found"
    source "$BACKEND_DIR/.env.rotation"
    
    # Calculate rotation age
    if [ -n "$JWT_ROTATION_DATE" ]; then
        ROTATION_TIMESTAMP=$(date -d "$JWT_ROTATION_DATE" +%s)
        CURRENT_TIMESTAMP=$(date +%s)
        ROTATION_AGE_HOURS=$(( ($CURRENT_TIMESTAMP - $ROTATION_TIMESTAMP) / 3600 ))
        
        echo "📅 Rotation performed: $JWT_ROTATION_DATE"
        echo "⏰ Rotation age: $ROTATION_AGE_HOURS hours"
        
        if [ $ROTATION_AGE_HOURS -gt 24 ]; then
            echo "⚠️  Rotation is older than 24 hours"
            echo "   Consider completing the rotation by removing old secret"
        else
            echo "✅ Rotation is within acceptable timeframe"
        fi
    fi
else
    echo "ℹ️  No active rotation configuration"
fi

echo ""
echo "🔑 Current JWT Configuration:"
echo "• Secret length: $(echo -n "$JWT_SECRET_KEY" | wc -c) characters"
echo "• Algorithm: ${JWT_ALGORITHM:-HS256}"
echo "• Access token expiry: ${JWT_ACCESS_TOKEN_EXPIRE_MINUTES:-30} minutes"
echo "• Refresh token expiry: ${JWT_REFRESH_TOKEN_EXPIRE_DAYS:-7} days"

# Test JWT secret format
if [[ ${#JWT_SECRET_KEY} -lt 32 ]]; then
    echo "⚠️  WARNING: JWT secret appears to be too short (< 32 characters)"
else
    echo "✅ JWT secret length is adequate"
fi

echo ""
echo "🔧 Management Commands:"
echo "• Complete rotation: ./scripts/complete-jwt-rotation.sh"
echo "• Rollback rotation: ./scripts/rollback-jwt-rotation.sh"
echo "• Generate new secret: ./scripts/rotate-secrets.sh"
EOVAL

chmod +x "$SCRIPT_DIR/validate-jwt-rotation.sh"

echo -e "${GREEN}📝 Creating rotation completion script...${NC}"

# Create completion script
cat > "$SCRIPT_DIR/complete-jwt-rotation.sh" << 'EOCOMP'
#!/bin/bash

# Complete JWT Rotation Script
# Removes old JWT secret after rotation period

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")/backend"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Completing JWT Secret Rotation${NC}"
echo "================================"
echo ""

if [ ! -f "$BACKEND_DIR/.env.rotation" ]; then
    echo -e "${RED}❌ No active rotation found!${NC}"
    exit 1
fi

source "$BACKEND_DIR/.env.rotation"

# Check rotation age
if [ -n "$JWT_ROTATION_DATE" ]; then
    ROTATION_TIMESTAMP=$(date -d "$JWT_ROTATION_DATE" +%s)
    CURRENT_TIMESTAMP=$(date +%s)
    ROTATION_AGE_HOURS=$(( ($CURRENT_TIMESTAMP - $ROTATION_TIMESTAMP) / 3600 ))
    
    echo -e "${YELLOW}📅 Rotation started: $JWT_ROTATION_DATE${NC}"
    echo -e "${YELLOW}⏰ Rotation age: $ROTATION_AGE_HOURS hours${NC}"
    
    if [ $ROTATION_AGE_HOURS -lt 2 ]; then
        echo -e "${YELLOW}⚠️  WARNING: Rotation is very recent (< 2 hours)${NC}"
        echo "   Some tokens may still be using the old secret."
        read -p "Continue anyway? (y/N): " force_complete
        if [[ $force_complete != [yY] ]]; then
            echo "Completion cancelled."
            exit 0
        fi
    fi
fi

echo -e "${GREEN}🧹 Cleaning up rotation configuration...${NC}"

# Remove rotation configuration
rm -f "$BACKEND_DIR/.env.rotation"

# Remove old secret references from .env if they exist
sed -i '/JWT_SECRET_KEY_OLD/d' "$BACKEND_DIR/.env"
sed -i '/JWT_ROTATION_STRATEGY/d' "$BACKEND_DIR/.env"
sed -i '/JWT_ROTATION_PERIOD_HOURS/d' "$BACKEND_DIR/.env"

echo -e "${GREEN}✅ JWT rotation completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo "• Old JWT secret removed"
echo "• Rotation configuration cleaned up"
echo "• All active tokens now use the new secret"
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Monitor application logs for any JWT validation errors"
echo "2. Verify user sessions are working correctly"
echo "3. Consider setting up automated rotation schedule"
EOCOMP

chmod +x "$SCRIPT_DIR/complete-jwt-rotation.sh"

echo -e "${GREEN}📝 Creating rollback script...${NC}"

# Create rollback script
cat > "$SCRIPT_DIR/rollback-jwt-rotation.sh" << 'EOROLL'
#!/bin/bash

# JWT Rotation Rollback Script
# Rolls back to previous JWT secret in case of issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")/backend"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}🔄 JWT Secret Rotation Rollback${NC}"
echo "==============================="
echo ""

# Find the most recent backup
LATEST_BACKUP=$(ls -t "$BACKEND_DIR"/.env.backup.* 2>/dev/null | head -n1)

if [ -z "$LATEST_BACKUP" ]; then
    echo -e "${RED}❌ No backup files found!${NC}"
    echo "Cannot rollback without a backup."
    exit 1
fi

echo -e "${YELLOW}📁 Latest backup found: $(basename "$LATEST_BACKUP")${NC}"

# Show backup timestamp
BACKUP_DATE=$(echo "$LATEST_BACKUP" | grep -o '[0-9]\{8\}_[0-9]\{6\}' | sed 's/_/ /')
echo -e "${YELLOW}📅 Backup date: $BACKUP_DATE${NC}"

echo ""
echo -e "${RED}⚠️  WARNING: This will rollback to the previous JWT secret!${NC}"
echo "All tokens issued with the new secret will become invalid."
echo "Users will need to re-authenticate."

read -p "Continue with rollback? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Rollback cancelled."
    exit 0
fi

echo -e "${YELLOW}🔄 Rolling back JWT configuration...${NC}"

# Create a backup of current state before rollback
ROLLBACK_BACKUP="$BACKEND_DIR/.env.before_rollback.$(date +%Y%m%d_%H%M%S)"
cp "$BACKEND_DIR/.env" "$ROLLBACK_BACKUP"

# Restore from backup
cp "$LATEST_BACKUP" "$BACKEND_DIR/.env"

# Remove rotation configuration if it exists
rm -f "$BACKEND_DIR/.env.rotation"

echo -e "${GREEN}✅ JWT rollback completed!${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo "• Restored from backup: $(basename "$LATEST_BACKUP")"
echo "• Current state backed up to: $(basename "$ROLLBACK_BACKUP")"
echo "• All users will need to re-authenticate"
echo ""
echo -e "${YELLOW}🔧 Recommended Actions:${NC}"
echo "1. Restart the application to load the old secret"
echo "2. Monitor for any authentication issues"
echo "3. Investigate the cause of the rotation problem"
echo "4. Plan a new rotation when the issue is resolved"
EOROLL

chmod +x "$SCRIPT_DIR/rollback-jwt-rotation.sh"

# Generate API secret as well
echo -e "${GREEN}🔐 Generating new API secret...${NC}"
NEW_API_SECRET=$(openssl rand -hex 32)
sed -i "s/^API_SECRET_KEY=.*/API_SECRET_KEY=$NEW_API_SECRET/" "$BACKEND_DIR/.env" 2>/dev/null || echo "API_SECRET_KEY=$NEW_API_SECRET" >> "$BACKEND_DIR/.env"

echo -e "${GREEN}🔐 Generating new session secret...${NC}"
NEW_SESSION_SECRET=$(openssl rand -base64 64 | tr -d "\n")
sed -i "s/^SESSION_SECRET_KEY=.*/SESSION_SECRET_KEY=$NEW_SESSION_SECRET/" "$BACKEND_DIR/.env" 2>/dev/null || echo "SESSION_SECRET_KEY=$NEW_SESSION_SECRET" >> "$BACKEND_DIR/.env"

echo -e "${GREEN}✅ Secret rotation completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Rotation Summary:${NC}"
echo "• JWT Secret: ✅ Rotated (gradual strategy)"
echo "• API Secret: ✅ Rotated (immediate)"
echo "• Session Secret: ✅ Rotated (immediate)"
echo ""
echo -e "${YELLOW}⚠️  Important Notes:${NC}"
echo "1. JWT rotation uses gradual strategy (accepts old tokens for 24h)"
echo "2. API and session secrets are immediately active"
echo "3. Users may need to re-authenticate for some operations"
echo "4. Monitor logs for any authentication issues"
echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo "• Validate rotation: ./scripts/validate-jwt-rotation.sh"
echo "• Complete rotation: ./scripts/complete-jwt-rotation.sh"
echo "• Rollback if needed: ./scripts/rollback-jwt-rotation.sh"
echo ""
echo -e "${GREEN}🔒 Secrets have been rotated successfully!${NC}"
echo -e "${YELLOW}📅 Next rotation recommended in: 90 days${NC}"
EOF

chmod +x "$SCRIPT_DIR/rotate-secrets.sh"

echo -e "${GREEN}📋 Creating environment validation script...${NC}"

# Create environment validation script
cat > "$SCRIPT_DIR/validate-env.sh" << 'EOF'
#!/bin/bash

# Environment Validation Script for Flutter Expense Tracker
# Validates production environment configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Environment Validation for Flutter Expense Tracker${NC}"
echo "==================================================="
echo ""

# Check if .env exists
if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Run setup-env.sh to create the production environment."
    exit 1
fi

# Load environment
source "$BACKEND_DIR/.env"

ERRORS=0
WARNINGS=0

# Function to report error
report_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    ((ERRORS++))
}

# Function to report warning
report_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    ((WARNINGS++))
}

# Function to report success
report_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo -e "${YELLOW}🔧 Validating core configuration...${NC}"

# Environment check
if [ "$ENVIRONMENT" = "production" ]; then
    report_success "Environment set to production"
else
    report_warning "Environment is not set to 'production' (current: ${ENVIRONMENT:-not set})"
fi

# Debug mode check
if [ "$DEBUG" = "false" ]; then
    report_success "Debug mode disabled"
else
    report_error "Debug mode should be disabled in production (current: ${DEBUG:-not set})"
fi

# Domain validation
if [ -n "$API_DOMAIN" ]; then
    if [[ $API_DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        report_success "API domain format valid: $API_DOMAIN"
    else
        report_error "Invalid API domain format: $API_DOMAIN"
    fi
else
    report_error "API_DOMAIN not set"
fi

if [ -n "$APP_DOMAIN" ]; then
    if [[ $APP_DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        report_success "App domain format valid: $APP_DOMAIN"
    else
        report_error "Invalid app domain format: $APP_DOMAIN"
    fi
else
    report_error "APP_DOMAIN not set"
fi

echo ""
echo -e "${YELLOW}🔐 Validating security configuration...${NC}"

# JWT secret validation
if [ -n "$JWT_SECRET_KEY" ]; then
    if [ ${#JWT_SECRET_KEY} -ge 32 ]; then
        report_success "JWT secret length adequate (${#JWT_SECRET_KEY} characters)"
    else
        report_error "JWT secret too short (${#JWT_SECRET_KEY} characters, minimum 32 required)"
    fi
else
    report_error "JWT_SECRET_KEY not set"
fi

# API secret validation
if [ -n "$API_SECRET_KEY" ]; then
    if [ ${#API_SECRET_KEY} -ge 32 ]; then
        report_success "API secret length adequate (${#API_SECRET_KEY} characters)"
    else
        report_error "API secret too short (${#API_SECRET_KEY} characters, minimum 32 required)"
    fi
else
    report_error "API_SECRET_KEY not set"
fi

# Session security
if [ "$SESSION_COOKIE_SECURE" = "true" ]; then
    report_success "Session cookies set to secure"
else
    report_error "Session cookies should be secure in production"
fi

if [ "$SESSION_COOKIE_HTTPONLY" = "true" ]; then
    report_success "Session cookies set to HTTP-only"
else
    report_error "Session cookies should be HTTP-only in production"
fi

# HTTPS enforcement
if [ "$FORCE_HTTPS" = "true" ]; then
    report_success "HTTPS enforcement enabled"
else
    report_warning "HTTPS enforcement not enabled"
fi

echo ""
echo -e "${YELLOW}🗃️  Validating database configuration...${NC}"

# Database URL
if [ -n "$DATABASE_URL" ]; then
    if [[ $DATABASE_URL =~ ^postgresql:// ]]; then
        report_success "Database URL format valid (PostgreSQL)"
    else
        report_warning "Database URL should use PostgreSQL for production"
    fi
else
    report_error "DATABASE_URL not set"
fi

# Database connection parameters
[ -n "$DB_HOST" ] && report_success "Database host set: $DB_HOST" || report_error "DB_HOST not set"
[ -n "$DB_NAME" ] && report_success "Database name set: $DB_NAME" || report_error "DB_NAME not set"
[ -n "$DB_USER" ] && report_success "Database user set: $DB_USER" || report_error "DB_USER not set"
[ -n "$DB_PASSWORD" ] && report_success "Database password set" || report_error "DB_PASSWORD not set"

echo ""
echo -e "${YELLOW}📧 Validating email configuration...${NC}"

# Email configuration
[ -n "$SMTP_HOST" ] && report_success "SMTP host set: $SMTP_HOST" || report_warning "SMTP_HOST not set"
[ -n "$SMTP_USERNAME" ] && report_success "SMTP username set" || report_warning "SMTP_USERNAME not set"
[ -n "$SMTP_PASSWORD" ] && report_success "SMTP password set" || report_warning "SMTP_PASSWORD not set"

if [ -n "$EMAIL_FROM" ]; then
    if [[ $EMAIL_FROM =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        report_success "From email format valid: $EMAIL_FROM"
    else
        report_error "Invalid from email format: $EMAIL_FROM"
    fi
else
    report_warning "EMAIL_FROM not set"
fi

echo ""
echo -e "${YELLOW}📁 Validating storage configuration...${NC}"

if [ "$USE_S3" = "true" ]; then
    report_success "S3 storage enabled"
    [ -n "$AWS_ACCESS_KEY_ID" ] && report_success "S3 access key set" || report_error "AWS_ACCESS_KEY_ID not set"
    [ -n "$AWS_SECRET_ACCESS_KEY" ] && report_success "S3 secret key set" || report_error "AWS_SECRET_ACCESS_KEY not set"
    [ -n "$S3_BUCKET" ] && report_success "S3 bucket set: $S3_BUCKET" || report_error "S3_BUCKET not set"
else
    report_warning "S3 storage not enabled (using local storage)"
fi

echo ""
echo -e "${YELLOW}⚡ Validating performance configuration...${NC}"

# Redis configuration
if [ -n "$REDIS_URL" ]; then
    report_success "Redis URL configured"
else
    report_warning "Redis not configured (caching and sessions will use memory)"
fi

# Rate limiting
if [ "$RATE_LIMIT_ENABLED" = "true" ]; then
    report_success "Rate limiting enabled"
else
    report_warning "Rate limiting not enabled"
fi

# Compression
if [ "$GZIP_ENABLED" = "true" ]; then
    report_success "Gzip compression enabled"
else
    report_warning "Gzip compression not enabled"
fi

echo ""
echo -e "${YELLOW}📊 Validating monitoring configuration...${NC}"

# Logging
if [ "$LOG_LEVEL" = "INFO" ] || [ "$LOG_LEVEL" = "WARNING" ] || [ "$LOG_LEVEL" = "ERROR" ]; then
    report_success "Log level appropriate for production: $LOG_LEVEL"
else
    report_warning "Log level may be too verbose for production: ${LOG_LEVEL:-not set}"
fi

# Metrics
if [ "$METRICS_ENABLED" = "true" ]; then
    report_success "Metrics collection enabled"
else
    report_warning "Metrics collection not enabled"
fi

# Health checks
if [ "$HEALTH_CHECK_ENABLED" = "true" ]; then
    report_success "Health checks enabled"
else
    report_warning "Health checks not enabled"
fi

# Sentry
if [ -n "$SENTRY_DSN" ]; then
    report_success "Sentry error tracking configured"
else
    report_warning "Sentry error tracking not configured"
fi

echo ""
echo -e "${YELLOW}🔒 Validating production security settings...${NC}"

# Development settings that should be disabled
if [ "$ALLOW_ORIGINS_ALL" = "false" ]; then
    report_success "CORS not set to allow all origins"
else
    report_error "CORS should not allow all origins in production"
fi

if [ "$DISABLE_AUTH" = "false" ]; then
    report_success "Authentication not disabled"
else
    report_error "Authentication should not be disabled in production"
fi

if [ "$MOCK_EMAIL" = "false" ]; then
    report_success "Email mocking disabled"
else
    report_warning "Email mocking should be disabled in production"
fi

echo ""
echo -e "${BLUE}📋 Validation Summary${NC}"
echo "===================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 Perfect! No issues found in environment configuration.${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}✅ Configuration is valid with $WARNINGS warning(s).${NC}"
    echo -e "${YELLOW}⚠️  Consider addressing warnings for optimal production setup.${NC}"
else
    echo -e "${RED}❌ Configuration has $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo -e "${RED}🚨 Please fix all errors before deploying to production!${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo "• Fix configuration: nano $BACKEND_DIR/.env"
echo "• Generate new secrets: ./scripts/rotate-secrets.sh"
echo "• Test configuration: docker-compose config"
echo "• View example config: cat $BACKEND_DIR/.env.example"

exit $ERRORS
EOF

chmod +x "$SCRIPT_DIR/validate-env.sh"

# Set secure permissions on .env.example
chmod 644 "$BACKEND_DIR/.env.example"

echo -e "${GREEN}✅ Production environment management setup complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Created Files:${NC}"
echo "• $BACKEND_DIR/.env.example - Production environment template"
echo "• $SCRIPT_DIR/setup-env.sh - Interactive environment setup"
echo "• $SCRIPT_DIR/rotate-secrets.sh - JWT/API secret rotation"
echo "• $SCRIPT_DIR/validate-env.sh - Environment validation"
echo "• $SCRIPT_DIR/validate-jwt-rotation.sh - JWT rotation validation"
echo "• $SCRIPT_DIR/complete-jwt-rotation.sh - Complete JWT rotation"
echo "• $SCRIPT_DIR/rollback-jwt-rotation.sh - Rollback JWT rotation"
echo ""
echo -e "${YELLOW}🚀 Quick Start:${NC}"
echo "1. Create production .env: ./scripts/setup-env.sh"
echo "2. Validate configuration: ./scripts/validate-env.sh"
echo "3. Rotate secrets regularly: ./scripts/rotate-secrets.sh"
echo ""
echo -e "${YELLOW}🔐 Security Features:${NC}"
echo "• Automatic secret generation with cryptographically secure randomness"
echo "• Gradual JWT rotation with 24-hour overlap period"
echo "• Environment validation with security best practices"
echo "• Secure file permissions (600 for .env files)"
echo "• Backup and rollback capabilities"
echo ""
echo -e "${GREEN}🔒 Environment management system ready for production!${NC}
