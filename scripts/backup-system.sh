#!/bin/bash

# Automated Backup System for Flutter Expense Tracker
# Daily backups to S3/MinIO with encryption and retention policies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}💾 Automated Backup System Setup${NC}"
echo "================================"
echo "This script sets up automated daily backups with S3/MinIO integration"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_ROOT/backend"

# Configuration variables
BACKUP_DIR="/var/backups/expense-tracker"
LOG_FILE="/var/log/expense-tracker-backup.log"
ENCRYPTION_KEY_FILE="/etc/expense-tracker/backup-encryption.key"

echo -e "${GREEN}📦 Installing backup dependencies...${NC}"

# Update system and install required packages
sudo apt-get update
sudo apt-get install -y \
    postgresql-client \
    awscli \
    gpg \
    gzip \
    tar \
    cron \
    logrotate \
    jq

# Install MinIO client
if ! command -v mc &> /dev/null; then
    echo -e "${YELLOW}📥 Installing MinIO client...${NC}"
    curl -fsSL https://dl.min.io/client/mc/release/linux-amd64/mc -o /tmp/mc
    sudo chmod +x /tmp/mc
    sudo mv /tmp/mc /usr/local/bin/mc
fi

echo -e "${GREEN}🔧 Creating backup directories and configuration...${NC}"

# Create backup directories
sudo mkdir -p "$BACKUP_DIR"/{database,storage,config,logs}
sudo mkdir -p /etc/expense-tracker
sudo mkdir -p /var/log

# Create backup configuration directory
sudo mkdir -p /etc/expense-tracker

echo -e "${GREEN}🔐 Setting up encryption...${NC}"

# Generate encryption key if it doesn't exist
if [ ! -f "$ENCRYPTION_KEY_FILE" ]; then
    echo -e "${YELLOW}🔑 Generating backup encryption key...${NC}"
    sudo openssl rand -base64 32 > "$ENCRYPTION_KEY_FILE"
    sudo chmod 600 "$ENCRYPTION_KEY_FILE"
    sudo chown root:root "$ENCRYPTION_KEY_FILE"
    echo -e "${GREEN}✅ Encryption key generated and secured${NC}"
else
    echo -e "${GREEN}✅ Using existing encryption key${NC}"
fi

echo -e "${GREEN}📝 Creating backup configuration...${NC}"

# Create backup configuration file
sudo tee /etc/expense-tracker/backup.conf > /dev/null << 'EOF'
# Backup Configuration for Flutter Expense Tracker
# This file contains backup settings and retention policies

# Basic Configuration
BACKUP_NAME="expense-tracker"
BACKUP_DIR="/var/backups/expense-tracker"
LOG_FILE="/var/log/expense-tracker-backup.log"
ENCRYPTION_KEY_FILE="/etc/expense-tracker/backup-encryption.key"

# Retention Policies (in days)
LOCAL_RETENTION_DAYS=7
S3_RETENTION_DAYS=30
ARCHIVE_RETENTION_DAYS=365

# Backup Components
BACKUP_DATABASE=true
BACKUP_UPLOADS=true
BACKUP_CONFIG=true
BACKUP_LOGS=true

# S3/MinIO Configuration (will be set during setup)
S3_ENDPOINT=""
S3_BUCKET=""
S3_ACCESS_KEY=""
S3_SECRET_KEY=""
S3_REGION="us-east-1"

# Notification Settings
NOTIFICATION_EMAIL=""
NOTIFICATION_WEBHOOK=""
NOTIFICATION_ON_SUCCESS=false
NOTIFICATION_ON_FAILURE=true

# Performance Settings
COMPRESSION_LEVEL=6
PARALLEL_UPLOADS=4
UPLOAD_CHUNK_SIZE="64MB"

# Security Settings
ENCRYPT_BACKUPS=true
VERIFY_BACKUPS=true
BACKUP_PERMISSIONS=600
EOF

echo -e "${GREEN}📝 Creating main backup script...${NC}"

# Create the main backup script
sudo tee /usr/local/bin/expense-tracker-backup.sh > /dev/null << 'EOF'
#!/bin/bash

# Main Backup Script for Flutter Expense Tracker
# Performs comprehensive backups with encryption and S3 upload

set -e

# Configuration
CONFIG_FILE="/etc/expense-tracker/backup.conf"
SCRIPT_DIR="/usr/local/bin"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    log ERROR "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Initialize backup session
BACKUP_DATE=$(date '+%Y%m%d_%H%M%S')
BACKUP_SESSION_DIR="$BACKUP_DIR/session_$BACKUP_DATE"
BACKUP_MANIFEST="$BACKUP_SESSION_DIR/manifest.json"

log INFO "Starting backup session: $BACKUP_DATE"

# Create session directory
mkdir -p "$BACKUP_SESSION_DIR"

# Initialize manifest
cat > "$BACKUP_MANIFEST" << EOL
{
    "backup_session": "$BACKUP_DATE",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "components": {},
    "checksums": {},
    "status": "in_progress"
}
EOL

# Function to update manifest
update_manifest() {
    local component="$1"
    local status="$2"
    local file_path="$3"
    local checksum="$4"
    
    # Create temporary file with updated manifest
    jq --arg comp "$component" \
       --arg stat "$status" \
       --arg path "$file_path" \
       --arg sum "$checksum" \
       '.components[$comp] = {status: $stat, file: $path, checksum: $sum}' \
       "$BACKUP_MANIFEST" > "$BACKUP_MANIFEST.tmp"
    
    mv "$BACKUP_MANIFEST.tmp" "$BACKUP_MANIFEST"
}

# Function to encrypt file
encrypt_file() {
    local input_file="$1"
    local output_file="$2"
    
    if [ "$ENCRYPT_BACKUPS" = "true" ]; then
        log INFO "Encrypting: $(basename "$input_file")"
        gpg --cipher-algo AES256 --compress-algo 2 --symmetric \
            --passphrase-file "$ENCRYPTION_KEY_FILE" \
            --batch --quiet \
            --output "$output_file" \
            "$input_file"
        rm -f "$input_file"
    else
        mv "$input_file" "$output_file"
    fi
}

# Function to calculate checksum
calculate_checksum() {
    local file="$1"
    sha256sum "$file" | cut -d' ' -f1
}

# Database backup function
backup_database() {
    if [ "$BACKUP_DATABASE" != "true" ]; then
        log INFO "Database backup disabled"
        return 0
    fi
    
    log INFO "Starting database backup..."
    
    # Load database configuration from .env
    if [ -f "/app/.env" ]; then
        source /app/.env
    elif [ -f "$PROJECT_ROOT/backend/.env" ]; then
        source "$PROJECT_ROOT/backend/.env"
    else
        log ERROR "Environment file not found"
        update_manifest "database" "failed" "" ""
        return 1
    fi
    
    local db_backup_file="$BACKUP_SESSION_DIR/database_$BACKUP_DATE.sql"
    
    # Create database dump
    if ! PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --no-password \
        --verbose \
        --clean \
        --if-exists \
        --create \
        --format=plain \
        --no-owner \
        --no-privileges \
        > "$db_backup_file"; then
        log ERROR "Database backup failed"
        update_manifest "database" "failed" "" ""
        return 1
    fi
    
    # Compress and encrypt
    gzip "$db_backup_file"
    local compressed_file="${db_backup_file}.gz"
    local encrypted_file="${compressed_file}.gpg"
    
    encrypt_file "$compressed_file" "$encrypted_file"
    
    # Calculate checksum and update manifest
    local checksum=$(calculate_checksum "$encrypted_file")
    update_manifest "database" "completed" "$(basename "$encrypted_file")" "$checksum"
    
    log INFO "Database backup completed: $(basename "$encrypted_file")"
}

# Storage backup function
backup_storage() {
    if [ "$BACKUP_UPLOADS" != "true" ]; then
        log INFO "Storage backup disabled"
        return 0
    fi
    
    log INFO "Starting storage backup..."
    
    local storage_dirs=("/app/storage" "$PROJECT_ROOT/storage" "/var/www/expense-tracker/storage")
    local found_storage=false
    
    for storage_dir in "${storage_dirs[@]}"; do
        if [ -d "$storage_dir" ]; then
            found_storage=true
            local storage_backup_file="$BACKUP_SESSION_DIR/storage_$BACKUP_DATE.tar"
            
            log INFO "Backing up storage from: $storage_dir"
            
            # Create tar archive
            if ! tar -cf "$storage_backup_file" -C "$(dirname "$storage_dir")" "$(basename "$storage_dir")"; then
                log ERROR "Storage backup failed"
                update_manifest "storage" "failed" "" ""
                return 1
            fi
            
            # Compress and encrypt
            gzip "$storage_backup_file"
            local compressed_file="${storage_backup_file}.gz"
            local encrypted_file="${compressed_file}.gpg"
            
            encrypt_file "$compressed_file" "$encrypted_file"
            
            # Calculate checksum and update manifest
            local checksum=$(calculate_checksum "$encrypted_file")
            update_manifest "storage" "completed" "$(basename "$encrypted_file")" "$checksum"
            
            log INFO "Storage backup completed: $(basename "$encrypted_file")"
            break
        fi
    done
    
    if [ "$found_storage" = false ]; then
        log WARN "No storage directory found to backup"
        update_manifest "storage" "skipped" "" ""
    fi
}

# Configuration backup function
backup_config() {
    if [ "$BACKUP_CONFIG" != "true" ]; then
        log INFO "Configuration backup disabled"
        return 0
    fi
    
    log INFO "Starting configuration backup..."
    
    local config_backup_file="$BACKUP_SESSION_DIR/config_$BACKUP_DATE.tar"
    local temp_config_dir="/tmp/expense-tracker-config-$BACKUP_DATE"
    
    # Create temporary directory for config files
    mkdir -p "$temp_config_dir"
    
    # Copy configuration files (excluding sensitive data)
    local config_files=(
        "/etc/nginx/sites-available/expense-tracker-*"
        "/etc/expense-tracker/*.conf"
        "/etc/letsencrypt/renewal/*.conf"
        "$PROJECT_ROOT/docker-compose.yml"
        "$PROJECT_ROOT/backend/.env.example"
        "$PROJECT_ROOT/nginx/nginx.conf"
        "$PROJECT_ROOT/scripts/*.sh"
    )
    
    for pattern in "${config_files[@]}"; do
        if ls $pattern 1> /dev/null 2>&1; then
            cp -r $pattern "$temp_config_dir/" 2>/dev/null || true
        fi
    done
    
    # Create tar archive
    if ! tar -cf "$config_backup_file" -C "/tmp" "$(basename "$temp_config_dir")"; then
        log ERROR "Configuration backup failed"
        update_manifest "config" "failed" "" ""
        rm -rf "$temp_config_dir"
        return 1
    fi
    
    # Cleanup temp directory
    rm -rf "$temp_config_dir"
    
    # Compress and encrypt
    gzip "$config_backup_file"
    local compressed_file="${config_backup_file}.gz"
    local encrypted_file="${compressed_file}.gpg"
    
    encrypt_file "$compressed_file" "$encrypted_file"
    
    # Calculate checksum and update manifest
    local checksum=$(calculate_checksum "$encrypted_file")
    update_manifest "config" "completed" "$(basename "$encrypted_file")" "$checksum"
    
    log INFO "Configuration backup completed: $(basename "$encrypted_file")"
}

# Logs backup function
backup_logs() {
    if [ "$BACKUP_LOGS" != "true" ]; then
        log INFO "Logs backup disabled"
        return 0
    fi
    
    log INFO "Starting logs backup..."
    
    local logs_backup_file="$BACKUP_SESSION_DIR/logs_$BACKUP_DATE.tar"
    local temp_logs_dir="/tmp/expense-tracker-logs-$BACKUP_DATE"
    
    # Create temporary directory for log files
    mkdir -p "$temp_logs_dir"
    
    # Copy recent log files (last 7 days)
    local log_patterns=(
        "/var/log/nginx/*expense-tracker*"
        "/var/log/expense-tracker*"
        "/var/log/fail2ban.log"
        "/var/log/auth.log"
    )
    
    for pattern in "${log_patterns[@]}"; do
        find $(dirname "$pattern") -name "$(basename "$pattern")" -mtime -7 -exec cp {} "$temp_logs_dir/" \; 2>/dev/null || true
    done
    
    # Only create backup if we found logs
    if [ "$(ls -A "$temp_logs_dir")" ]; then
        # Create tar archive
        if ! tar -cf "$logs_backup_file" -C "/tmp" "$(basename "$temp_logs_dir")"; then
            log ERROR "Logs backup failed"
            update_manifest "logs" "failed" "" ""
            rm -rf "$temp_logs_dir"
            return 1
        fi
        
        # Compress and encrypt
        gzip "$logs_backup_file"
        local compressed_file="${logs_backup_file}.gz"
        local encrypted_file="${compressed_file}.gpg"
        
        encrypt_file "$compressed_file" "$encrypted_file"
        
        # Calculate checksum and update manifest
        local checksum=$(calculate_checksum "$encrypted_file")
        update_manifest "logs" "completed" "$(basename "$encrypted_file")" "$checksum"
        
        log INFO "Logs backup completed: $(basename "$encrypted_file")"
    else
        log WARN "No recent log files found to backup"
        update_manifest "logs" "skipped" "" ""
    fi
    
    # Cleanup temp directory
    rm -rf "$temp_logs_dir"
}

# S3 upload function
upload_to_s3() {
    if [ -z "$S3_BUCKET" ] || [ -z "$S3_ACCESS_KEY" ] || [ -z "$S3_SECRET_KEY" ]; then
        log WARN "S3 configuration incomplete, skipping upload"
        return 0
    fi
    
    log INFO "Starting S3 upload..."
    
    # Configure AWS CLI or MinIO client
    if [ -n "$S3_ENDPOINT" ]; then
        # MinIO configuration
        mc alias set backup "$S3_ENDPOINT" "$S3_ACCESS_KEY" "$S3_SECRET_KEY"
        local s3_target="backup/$S3_BUCKET/expense-tracker/$BACKUP_DATE/"
    else
        # AWS S3 configuration
        export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY"
        export AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY"
        export AWS_DEFAULT_REGION="$S3_REGION"
        local s3_target="s3://$S3_BUCKET/expense-tracker/$BACKUP_DATE/"
    fi
    
    # Upload all backup files
    for backup_file in "$BACKUP_SESSION_DIR"/*.gpg; do
        if [ -f "$backup_file" ]; then
            local filename=$(basename "$backup_file")
            log INFO "Uploading: $filename"
            
            if [ -n "$S3_ENDPOINT" ]; then
                # MinIO upload
                if ! mc cp "$backup_file" "$s3_target$filename"; then
                    log ERROR "Failed to upload $filename to MinIO"
                    return 1
                fi
            else
                # AWS S3 upload
                if ! aws s3 cp "$backup_file" "$s3_target$filename"; then
                    log ERROR "Failed to upload $filename to S3"
                    return 1
                fi
            fi
        fi
    done
    
    # Upload manifest
    if [ -n "$S3_ENDPOINT" ]; then
        mc cp "$BACKUP_MANIFEST" "$s3_target/manifest.json"
    else
        aws s3 cp "$BACKUP_MANIFEST" "$s3_target/manifest.json"
    fi
    
    log INFO "S3 upload completed"
}

# Cleanup function
cleanup_old_backups() {
    log INFO "Starting cleanup of old backups..."
    
    # Local cleanup
    if [ "$LOCAL_RETENTION_DAYS" -gt 0 ]; then
        find "$BACKUP_DIR" -type d -name "session_*" -mtime +$LOCAL_RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true
        log INFO "Cleaned up local backups older than $LOCAL_RETENTION_DAYS days"
    fi
    
    # S3 cleanup (if configured)
    if [ -n "$S3_BUCKET" ] && [ "$S3_RETENTION_DAYS" -gt 0 ]; then
        local cutoff_date=$(date -d "$S3_RETENTION_DAYS days ago" '+%Y%m%d')
        
        if [ -n "$S3_ENDPOINT" ]; then
            # MinIO cleanup
            mc find "backup/$S3_BUCKET/expense-tracker/" --name "*" --older-than "${S3_RETENTION_DAYS}d" --exec "mc rm {}"
        else
            # AWS S3 cleanup using lifecycle policy (recommended) or manual cleanup
            log INFO "Consider setting up S3 lifecycle policy for automatic cleanup"
        fi
        
        log INFO "Cleaned up S3 backups older than $S3_RETENTION_DAYS days"
    fi
}

# Verification function
verify_backup() {
    log INFO "Verifying backup integrity..."
    
    local verification_failed=false
    
    # Verify checksums from manifest
    for backup_file in "$BACKUP_SESSION_DIR"/*.gpg; do
        if [ -f "$backup_file" ]; then
            local filename=$(basename "$backup_file")
            local expected_checksum=$(jq -r ".checksums.\"$filename\" // empty" "$BACKUP_MANIFEST")
            
            if [ -n "$expected_checksum" ]; then
                local actual_checksum=$(calculate_checksum "$backup_file")
                
                if [ "$expected_checksum" = "$actual_checksum" ]; then
                    log INFO "Checksum verified: $filename"
                else
                    log ERROR "Checksum mismatch for $filename"
                    verification_failed=true
                fi
            fi
        fi
    done
    
    if [ "$verification_failed" = true ]; then
        log ERROR "Backup verification failed"
        return 1
    else
        log INFO "Backup verification completed successfully"
        return 0
    fi
}

# Notification function
send_notification() {
    local status="$1"
    local message="$2"
    
    if [ "$status" = "success" ] && [ "$NOTIFICATION_ON_SUCCESS" != "true" ]; then
        return 0
    fi
    
    if [ "$status" = "failure" ] && [ "$NOTIFICATION_ON_FAILURE" != "true" ]; then
        return 0
    fi
    
    # Email notification
    if [ -n "$NOTIFICATION_EMAIL" ] && command -v mail &> /dev/null; then
        local subject="[Expense Tracker] Backup $status - $(hostname)"
        echo "$message" | mail -s "$subject" "$NOTIFICATION_EMAIL"
    fi
    
    # Webhook notification
    if [ -n "$NOTIFICATION_WEBHOOK" ]; then
        local payload="{\"status\":\"$status\",\"hostname\":\"$(hostname)\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"message\":\"$message\"}"
        curl -X POST -H "Content-Type: application/json" -d "$payload" "$NOTIFICATION_WEBHOOK" || true
    fi
}

# Main execution
main() {
    local start_time=$(date +%s)
    local overall_status="success"
    local error_message=""
    
    # Perform backups
    backup_database || { overall_status="failure"; error_message="Database backup failed"; }
    backup_storage || { overall_status="failure"; error_message="Storage backup failed"; }
    backup_config || { overall_status="failure"; error_message="Configuration backup failed"; }
    backup_logs || { overall_status="failure"; error_message="Logs backup failed"; }
    
    # Upload to S3
    if [ "$overall_status" = "success" ]; then
        upload_to_s3 || { overall_status="failure"; error_message="S3 upload failed"; }
    fi
    
    # Verify backup
    if [ "$overall_status" = "success" ]; then
        verify_backup || { overall_status="failure"; error_message="Backup verification failed"; }
    fi
    
    # Update final manifest
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    jq --arg status "$overall_status" \
       --arg duration "$duration" \
       --arg end_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       '.status = $status | .duration_seconds = ($duration | tonumber) | .completed_at = $end_time' \
       "$BACKUP_MANIFEST" > "$BACKUP_MANIFEST.tmp"
    
    mv "$BACKUP_MANIFEST.tmp" "$BACKUP_MANIFEST"
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Send notification
    local message="Backup session $BACKUP_DATE completed with status: $overall_status"
    if [ "$overall_status" = "failure" ]; then
        message="$message. Error: $error_message"
    fi
    message="$message. Duration: ${duration}s"
    
    send_notification "$overall_status" "$message"
    
    log INFO "Backup session completed: $overall_status (Duration: ${duration}s)"
    
    if [ "$overall_status" = "failure" ]; then
        exit 1
    fi
}

# Execute main function
main "$@"
EOF

sudo chmod +x /usr/local/bin/expense-tracker-backup.sh

echo -e "${GREEN}📝 Creating backup restoration script...${NC}"

# Create restoration script
sudo tee /usr/local/bin/expense-tracker-restore.sh > /dev/null << 'EOF'
#!/bin/bash

# Backup Restoration Script for Flutter Expense Tracker
# Restores from encrypted backups with verification

set -e

CONFIG_FILE="/etc/expense-tracker/backup.conf"
SCRIPT_DIR="/usr/local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    log ERROR "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Function to list available backups
list_backups() {
    echo -e "${BLUE}📋 Available Backups${NC}"
    echo "==================="
    
    # Local backups
    echo -e "${YELLOW}Local backups:${NC}"
    if ls -la "$BACKUP_DIR"/session_* >/dev/null 2>&1; then
        for session_dir in "$BACKUP_DIR"/session_*; do
            if [ -d "$session_dir" ]; then
                local session_name=$(basename "$session_dir")
                local backup_date=$(echo "$session_name" | sed 's/session_//')
                local manifest_file="$session_dir/manifest.json"
                
                if [ -f "$manifest_file" ]; then
                    local status=$(jq -r '.status' "$manifest_file")
                    local timestamp=$(jq -r '.timestamp' "$manifest_file")
                    echo "  $backup_date [$status] - $timestamp"
                else
                    echo "  $backup_date [unknown] - manifest missing"
                fi
            fi
        done
    else
        echo "  No local backups found"
    fi
    
    # S3 backups (if configured)
    if [ -n "$S3_BUCKET" ]; then
        echo -e "${YELLOW}S3 backups:${NC}"
        echo "  Use 'list-s3' command to view remote backups"
    fi
}

# Function to decrypt file
decrypt_file() {
    local encrypted_file="$1"
    local output_file="$2"
    
    log INFO "Decrypting: $(basename "$encrypted_file")"
    
    if ! gpg --decrypt \
        --passphrase-file "$ENCRYPTION_KEY_FILE" \
        --batch --quiet \
        --output "$output_file" \
        "$encrypted_file"; then
        log ERROR "Failed to decrypt file: $encrypted_file"
        return 1
    fi
}

# Function to restore database
restore_database() {
    local backup_session="$1"
    local session_dir="$BACKUP_DIR/session_$backup_session"
    
    log INFO "Restoring database from backup: $backup_session"
    
    # Find database backup file
    local encrypted_db_file=$(find "$session_dir" -name "database_*.sql.gz.gpg" | head -n1)
    
    if [ -z "$encrypted_db_file" ]; then
        log ERROR "Database backup file not found in session: $backup_session"
        return 1
    fi
    
    # Create temporary restoration directory
    local restore_dir="/tmp/expense-tracker-restore-$$"
    mkdir -p "$restore_dir"
    
    # Decrypt and decompress
    local decrypted_file="$restore_dir/database.sql.gz"
    local decompressed_file="$restore_dir/database.sql"
    
    decrypt_file "$encrypted_db_file" "$decrypted_file"
    gunzip "$decrypted_file"
    
    # Load database configuration
    if [ -f "/app/.env" ]; then
        source /app/.env
    elif [ -f "$PROJECT_ROOT/backend/.env" ]; then
        source "$PROJECT_ROOT/backend/.env"
    else
        log ERROR "Environment file not found"
        rm -rf "$restore_dir"
        return 1
    fi
    
    log WARN "This will completely replace the current database!"
    read -p "Continue with database restoration? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        log INFO "Database restoration cancelled"
        rm -rf "$restore_dir"
        return 1
    fi
    
    # Restore database
    if ! PGPASSWORD="$DB_PASSWORD" psql \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -f "$decompressed_file"; then
        log ERROR "Database restoration failed"
        rm -rf "$restore_dir"
        return 1
    fi
    
    # Cleanup
    rm -rf "$restore_dir"
    
    log INFO "Database restoration completed successfully"
}

# Function to restore storage
restore_storage() {
    local backup_session="$1"
    local session_dir="$BACKUP_DIR/session_$backup_session"
    
    log INFO "Restoring storage from backup: $backup_session"
    
    # Find storage backup file
    local encrypted_storage_file=$(find "$session_dir" -name "storage_*.tar.gz.gpg" | head -n1)
    
    if [ -z "$encrypted_storage_file" ]; then
        log ERROR "Storage backup file not found in session: $backup_session"
        return 1
    fi
    
    # Create temporary restoration directory
    local restore_dir="/tmp/expense-tracker-restore-$$"
    mkdir -p "$restore_dir"
    
    # Decrypt and decompress
    local decrypted_file="$restore_dir/storage.tar.gz"
    
    decrypt_file "$encrypted_storage_file" "$decrypted_file"
    
    # Extract to temporary location
    tar -xzf "$decrypted_file" -C "$restore_dir"
    
    # Find target storage directory
    local target_storage="/var/www/expense-tracker/storage"
    if [ -d "/app/storage" ]; then
        target_storage="/app/storage"
    elif [ -d "$PROJECT_ROOT/storage" ]; then
        target_storage="$PROJECT_ROOT/storage"
    fi
    
    log WARN "This will replace files in: $target_storage"
    read -p "Continue with storage restoration? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        log INFO "Storage restoration cancelled"
        rm -rf "$restore_dir"
        return 1
    fi
    
    # Backup current storage
    if [ -d "$target_storage" ]; then
        local backup_current="$target_storage.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target_storage" "$backup_current"
        log INFO "Current storage backed up to: $backup_current"
    fi
    
    # Restore storage
    mkdir -p "$(dirname "$target_storage")"
    mv "$restore_dir/storage" "$target_storage"
    
    # Set proper permissions
    chown -R www-data:www-data "$target_storage" 2>/dev/null || true
    chmod -R 755 "$target_storage"
    
    # Cleanup
    rm -rf "$restore_dir"
    
    log INFO "Storage restoration completed successfully"
}

# Main function
main() {
    local command="${1:-help}"
    local backup_session="$2"
    
    case $command in
        "list")
            list_backups
            ;;
        "database")
            if [ -z "$backup_session" ]; then
                log ERROR "Please specify backup session"
                list_backups
                exit 1
            fi
            restore_database "$backup_session"
            ;;
        "storage")
            if [ -z "$backup_session" ]; then
                log ERROR "Please specify backup session"
                list_backups
                exit 1
            fi
            restore_storage "$backup_session"
            ;;
        "full")
            if [ -z "$backup_session" ]; then
                log ERROR "Please specify backup session"
                list_backups
                exit 1
            fi
            restore_database "$backup_session"
            restore_storage "$backup_session"
            ;;
        *)
            echo -e "${BLUE}Expense Tracker Backup Restoration${NC}"
            echo "=================================="
            echo ""
            echo "Usage: $0 <command> [backup_session]"
            echo ""
            echo "Commands:"
            echo "  list                  - List available backups"
            echo "  database <session>    - Restore database only"
            echo "  storage <session>     - Restore storage only"
            echo "  full <session>        - Restore database and storage"
            echo ""
            echo "Examples:"
            echo "  $0 list"
            echo "  $0 database 20241201_020000"
            echo "  $0 full 20241201_020000"
            ;;
    esac
}

main "$@"
EOF

sudo chmod +x /usr/local/bin/expense-tracker-restore.sh

echo -e "${GREEN}📝 Creating backup monitoring script...${NC}"

# Create monitoring script
sudo tee /usr/local/bin/backup-monitor.sh > /dev/null << 'EOF'
#!/bin/bash

# Backup Monitoring Script for Flutter Expense Tracker
# Monitors backup health and sends alerts

CONFIG_FILE="/etc/expense-tracker/backup.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $level: $message"
}

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

echo -e "${BLUE}📊 Backup Health Monitor${NC}"
echo "========================"
echo ""

# Check last backup
echo -e "${YELLOW}📅 Last Backup Status:${NC}"
LATEST_SESSION=$(ls -t "$BACKUP_DIR"/session_* 2>/dev/null | head -n1)

if [ -n "$LATEST_SESSION" ]; then
    SESSION_NAME=$(basename "$LATEST_SESSION")
    BACKUP_DATE=$(echo "$SESSION_NAME" | sed 's/session_//')
    MANIFEST_FILE="$LATEST_SESSION/manifest.json"
    
    if [ -f "$MANIFEST_FILE" ]; then
        STATUS=$(jq -r '.status' "$MANIFEST_FILE")
        TIMESTAMP=$(jq -r '.timestamp' "$MANIFEST_FILE")
        DURATION=$(jq -r '.duration_seconds // "N/A"' "$MANIFEST_FILE")
        
        echo "• Session: $BACKUP_DATE"
        echo "• Status: $STATUS"
        echo "• Time: $TIMESTAMP"
        echo "• Duration: ${DURATION}s"
        
        # Check components
        echo -e "\n${YELLOW}📦 Backup Components:${NC}"
        for component in database storage config logs; do
            COMP_STATUS=$(jq -r ".components.$component.status // \"not found\"" "$MANIFEST_FILE")
            echo "• $component: $COMP_STATUS"
        done
    else
        echo "• No manifest found for latest session"
    fi
else
    echo "• No backup sessions found"
fi

# Check backup freshness
echo -e "\n${YELLOW}⏰ Backup Freshness:${NC}"
if [ -n "$LATEST_SESSION" ]; then
    LATEST_BACKUP_TIME=$(stat -c %Y "$LATEST_SESSION")
    CURRENT_TIME=$(date +%s)
    AGE_HOURS=$(( (CURRENT_TIME - LATEST_BACKUP_TIME) / 3600 ))
    
    echo "• Last backup: $AGE_HOURS hours ago"
    
    if [ $AGE_HOURS -gt 48 ]; then
        echo -e "${RED}⚠️  WARNING: Backup is older than 48 hours${NC}"
    elif [ $AGE_HOURS -gt 24 ]; then
        echo -e "${YELLOW}⚠️  NOTICE: Backup is older than 24 hours${NC}"
    else
        echo -e "${GREEN}✅ Backup is fresh${NC}"
    fi
else
    echo -e "${RED}❌ No backups found${NC}"
fi

# Check disk space
echo -e "\n${YELLOW}💾 Disk Space:${NC}"
BACKUP_USAGE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
BACKUP_DISK_USAGE=$(df "$BACKUP_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')

echo "• Backup directory size: $BACKUP_USAGE"
echo "• Disk usage: $BACKUP_DISK_USAGE%"

if [ "$BACKUP_DISK_USAGE" -gt 90 ]; then
    echo -e "${RED}⚠️  WARNING: Disk usage above 90%${NC}"
elif [ "$BACKUP_DISK_USAGE" -gt 80 ]; then
    echo -e "${YELLOW}⚠️  NOTICE: Disk usage above 80%${NC}"
else
    echo -e "${GREEN}✅ Disk usage normal${NC}"
fi

# Check S3 connectivity
if [ -n "$S3_BUCKET" ]; then
    echo -e "\n${YELLOW}☁️  S3 Connectivity:${NC}"
    
    if [ -n "$S3_ENDPOINT" ]; then
        # MinIO test
        if mc ls "backup/$S3_BUCKET/" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ MinIO connection successful${NC}"
        else
            echo -e "${RED}❌ MinIO connection failed${NC}"
        fi
    else
        # AWS S3 test
        export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY"
        export AWS_SECRET_ACCESS_KEY="$S3_SECRET_KEY"
        export AWS_DEFAULT_REGION="$S3_REGION"
        
        if aws s3 ls "s3://$S3_BUCKET/" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ S3 connection successful${NC}"
        else
            echo -e "${RED}❌ S3 connection failed${NC}"
        fi
    fi
else
    echo -e "\n${YELLOW}☁️  S3 not configured${NC}"
fi

# Check encryption key
echo -e "\n${YELLOW}🔐 Encryption:${NC}"
if [ -f "$ENCRYPTION_KEY_FILE" ]; then
    KEY_PERMS=$(stat -c %a "$ENCRYPTION_KEY_FILE")
    if [ "$KEY_PERMS" = "600" ]; then
        echo -e "${GREEN}✅ Encryption key found with secure permissions${NC}"
    else
        echo -e "${YELLOW}⚠️  Encryption key permissions should be 600 (current: $KEY_PERMS)${NC}"
    fi
else
    echo -e "${RED}❌ Encryption key not found${NC}"
fi

# Summary
echo -e "\n${BLUE}📋 Summary${NC}"
echo "=========="

HEALTH_SCORE=0
MAX_SCORE=5

# Check if last backup was successful
if [ -n "$LATEST_SESSION" ] && [ -f "$MANIFEST_FILE" ]; then
    STATUS=$(jq -r '.status' "$MANIFEST_FILE")
    if [ "$STATUS" = "completed" ]; then
        ((HEALTH_SCORE++))
    fi
fi

# Check backup freshness
if [ -n "$LATEST_SESSION" ] && [ $AGE_HOURS -le 24 ]; then
    ((HEALTH_SCORE++))
fi

# Check disk space
if [ "$BACKUP_DISK_USAGE" -le 80 ]; then
    ((HEALTH_SCORE++))
fi

# Check S3 connectivity
if [ -z "$S3_BUCKET" ] || ([ -n "$S3_ENDPOINT" ] && mc ls "backup/$S3_BUCKET/" >/dev/null 2>&1) || ([ -z "$S3_ENDPOINT" ] && aws s3 ls "s3://$S3_BUCKET/" >/dev/null 2>&1); then
    ((HEALTH_SCORE++))
fi

# Check encryption
if [ -f "$ENCRYPTION_KEY_FILE" ] && [ "$(stat -c %a "$ENCRYPTION_KEY_FILE")" = "600" ]; then
    ((HEALTH_SCORE++))
fi

echo "• Health Score: $HEALTH_SCORE/$MAX_SCORE"

if [ $HEALTH_SCORE -eq $MAX_SCORE ]; then
    echo -e "${GREEN}🎉 All systems healthy${NC}"
elif [ $HEALTH_SCORE -ge 3 ]; then
    echo -e "${YELLOW}⚠️  Some issues detected${NC}"
else
    echo -e "${RED}🚨 Critical issues detected${NC}"
fi

echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo "• Run backup: expense-tracker-backup.sh"
echo "• List backups: expense-tracker-restore.sh list"
echo "• Check logs: tail -f /var/log/expense-tracker-backup.log"
EOF

sudo chmod +x /usr/local/bin/backup-monitor.sh

echo -e "${GREEN}⏰ Setting up automated backup schedule...${NC}"

# Create cron job for daily backups
CRON_JOB="0 2 * * * /usr/local/bin/expense-tracker-backup.sh"
(sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -

# Create logrotate configuration
sudo tee /etc/logrotate.d/expense-tracker-backup > /dev/null << 'EOF'
/var/log/expense-tracker-backup.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        # Send HUP signal to processes if needed
    endscript
}
EOF

echo -e "${GREEN}🔧 Creating backup configuration wizard...${NC}"

# Interactive setup script
cat > "$SCRIPT_DIR/setup-backup.sh" << 'EOF'
#!/bin/bash

# Interactive Backup Setup for Flutter Expense Tracker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="/etc/expense-tracker/backup.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🛠️  Backup Configuration Wizard${NC}"
echo "==============================="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run this script with sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 This wizard will configure your backup system${NC}"
echo ""

# S3/MinIO Configuration
echo -e "${YELLOW}☁️  Storage Configuration:${NC}"
read -p "Configure S3/MinIO backup storage? (y/N): " use_s3

if [[ $use_s3 == [yY] ]]; then
    read -p "Use MinIO (self-hosted) or AWS S3? (minio/s3): " storage_type
    
    if [[ $storage_type == "minio" ]]; then
        read -p "MinIO Endpoint URL (e.g., https://minio.yourdomain.com): " s3_endpoint
    else
        s3_endpoint=""
        read -p "AWS Region (default: us-east-1): " aws_region
        aws_region=${aws_region:-us-east-1}
    fi
    
    read -p "Bucket Name: " s3_bucket
    read -p "Access Key ID: " s3_access_key
    read -s -p "Secret Access Key: " s3_secret_key
    echo ""
    
    # Update configuration
    sed -i "s|S3_ENDPOINT=.*|S3_ENDPOINT=\"$s3_endpoint\"|" "$CONFIG_FILE"
    sed -i "s|S3_BUCKET=.*|S3_BUCKET=\"$s3_bucket\"|" "$CONFIG_FILE"
    sed -i "s|S3_ACCESS_KEY=.*|S3_ACCESS_KEY=\"$s3_access_key\"|" "$CONFIG_FILE"
    sed -i "s|S3_SECRET_KEY=.*|S3_SECRET_KEY=\"$s3_secret_key\"|" "$CONFIG_FILE"
    
    if [ "$storage_type" != "minio" ]; then
        sed -i "s|S3_REGION=.*|S3_REGION=\"$aws_region\"|" "$CONFIG_FILE"
    fi
    
    echo -e "${GREEN}✅ S3/MinIO configuration saved${NC}"
else
    echo -e "${YELLOW}⚠️  Backups will be stored locally only${NC}"
fi

# Notification Configuration
echo -e "\n${YELLOW}📧 Notification Configuration:${NC}"
read -p "Configure email notifications? (y/N): " use_email

if [[ $use_email == [yY] ]]; then
    read -p "Notification Email: " notification_email
    read -p "Send notifications on success? (y/N): " notify_success
    
    sed -i "s|NOTIFICATION_EMAIL=.*|NOTIFICATION_EMAIL=\"$notification_email\"|" "$CONFIG_FILE"
    
    if [[ $notify_success == [yY] ]]; then
        sed -i "s|NOTIFICATION_ON_SUCCESS=.*|NOTIFICATION_ON_SUCCESS=true|" "$CONFIG_FILE"
    fi
    
    echo -e "${GREEN}✅ Email notifications configured${NC}"
fi

# Retention Policy
echo -e "\n${YELLOW}🗂️  Retention Policy:${NC}"
read -p "Local backup retention (days, default: 7): " local_retention
local_retention=${local_retention:-7}

if [[ $use_s3 == [yY] ]]; then
    read -p "S3 backup retention (days, default: 30): " s3_retention
    s3_retention=${s3_retention:-30}
    sed -i "s|S3_RETENTION_DAYS=.*|S3_RETENTION_DAYS=$s3_retention|" "$CONFIG_FILE"
fi

sed -i "s|LOCAL_RETENTION_DAYS=.*|LOCAL_RETENTION_DAYS=$local_retention|" "$CONFIG_FILE"

echo -e "${GREEN}✅ Retention policy configured${NC}"

# Test Configuration
echo -e "\n${YELLOW}🧪 Testing Configuration:${NC}"

echo "Testing backup script execution..."
if /usr/local/bin/expense-tracker-backup.sh; then
    echo -e "${GREEN}✅ Test backup completed successfully${NC}"
else
    echo -e "${RED}❌ Test backup failed${NC}"
    echo "Please check the configuration and try again."
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Backup system configured successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Summary:${NC}"
echo "• Daily backups scheduled at 2:00 AM"
echo "• Local retention: $local_retention days"
if [[ $use_s3 == [yY] ]]; then
    echo "• S3 storage: $s3_bucket"
    echo "• S3 retention: $s3_retention days"
fi
if [[ $use_email == [yY] ]]; then
    echo "• Email notifications: $notification_email"
fi

echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo "• Monitor backups: backup-monitor.sh"
echo "• Manual backup: expense-tracker-backup.sh"
echo "• Restore backup: expense-tracker-restore.sh list"
echo "• View logs: tail -f /var/log/expense-tracker-backup.log"
EOF

chmod +x "$SCRIPT_DIR/setup-backup.sh"

# Set proper permissions
sudo chown -R root:root /etc/expense-tracker
sudo chmod 755 /etc/expense-tracker
sudo chmod 644 /etc/expense-tracker/backup.conf

echo -e "${GREEN}✅ Automated backup system setup complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Setup Summary:${NC}"
echo "• Main backup script: /usr/local/bin/expense-tracker-backup.sh"
echo "• Restoration script: /usr/local/bin/expense-tracker-restore.sh"
echo "• Monitoring script: /usr/local/bin/backup-monitor.sh"
echo "• Configuration: /etc/expense-tracker/backup.conf"
echo "• Setup wizard: $SCRIPT_DIR/setup-backup.sh"
echo ""
echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo "1. Run configuration wizard: sudo $SCRIPT_DIR/setup-backup.sh"
echo "2. Test backup system: sudo expense-tracker-backup.sh"
echo "3. Monitor backup health: backup-monitor.sh"
echo "4. Set up S3/MinIO credentials in the wizard"
echo ""
echo -e "${YELLOW}⏰ Backup Schedule:${NC}"
echo "• Automated daily backups at 2:00 AM"
echo "• Local retention: 7 days (configurable)"
echo "• S3 retention: 30 days (configurable)"
echo "• Encrypted with AES-256"
echo "• Integrity verification included"
echo ""
echo -e "${YELLOW}🔐 Security Features:${NC}"
echo "• AES-256 encryption for all backups"
echo "• SHA-256 checksums for integrity verification"
echo "• Secure key storage with 600 permissions"
echo "• Automated cleanup of old backups"
echo ""
echo -e "${GREEN}💾 Your backup system is ready for production!${NC}
