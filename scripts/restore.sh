#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo -e "${BLUE}🔄 Expense Tracker Restore Script${NC}"
echo "=================================="

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    echo ""
    echo "Available backups:"
    ls -la ./backups/*.tar.gz 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    print_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

print_warning "This will restore from backup and overwrite current data!"
read -p "Are you sure you want to continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Restore cancelled"
    exit 0
fi

# Stop services
print_status "Stopping services..."
docker-compose down

# Extract backup
RESTORE_DIR="./restore_temp"
mkdir -p "$RESTORE_DIR"
print_status "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" --strip-components=1

# Restore configuration files
print_status "Restoring configuration files..."
cp "$RESTORE_DIR/.env" ./ 2>/dev/null || true
cp "$RESTORE_DIR/docker-compose.yml" ./ 2>/dev/null || true
cp -r "$RESTORE_DIR/nginx" ./ 2>/dev/null || true

# Restore SSL certificates
if [ -d "$RESTORE_DIR/ssl_certificates" ]; then
    print_status "Restoring SSL certificates..."
    mkdir -p ./certbot
    cp -r "$RESTORE_DIR/ssl_certificates" ./certbot/conf
fi

# Start MySQL service
print_status "Starting MySQL service..."
docker-compose up -d mysql

# Wait for MySQL to be ready
print_status "Waiting for MySQL to be ready..."
sleep 30

# Restore database
print_status "Restoring database..."
docker-compose exec -T mysql mysql \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    expense_tracker < "$RESTORE_DIR/database.sql"

if [ $? -eq 0 ]; then
    print_status "Database restore completed"
else
    print_error "Database restore failed"
    exit 1
fi

# Start all services
print_status "Starting all services..."
docker-compose up -d

# Clean up
rm -rf "$RESTORE_DIR"

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check services
print_status "Checking service status..."
docker-compose ps

print_status "Testing API..."
if curl -f -s http://localhost:8000/health > /dev/null; then
    print_status "API is responding correctly!"
else
    print_warning "API health check failed. Check logs with: docker-compose logs backend"
fi

echo ""
print_status "Restore completed successfully!"
echo "Backup info from restore:"
cat "$BACKUP_FILE" | tar -xzO */backup_info.txt 2>/dev/null || echo "No backup info available"
