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

echo -e "${BLUE}🔧 Expense Tracker Backup Script${NC}"
echo "=================================="

# Create backup directory
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

print_status "Creating backup in: $BACKUP_DIR"

# Backup database
print_status "Backing up MySQL database..."
docker-compose exec -T mysql mysqldump \
    -u root \
    -p"${MYSQL_ROOT_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    expense_tracker > "$BACKUP_DIR/database.sql"

if [ $? -eq 0 ]; then
    print_status "Database backup completed"
else
    print_error "Database backup failed"
    exit 1
fi

# Backup SSL certificates
if [ -d "./certbot/conf" ]; then
    print_status "Backing up SSL certificates..."
    cp -r ./certbot/conf "$BACKUP_DIR/ssl_certificates"
    print_status "SSL certificates backup completed"
fi

# Backup configuration files
print_status "Backing up configuration files..."
cp .env "$BACKUP_DIR/" 2>/dev/null || true
cp docker-compose.yml "$BACKUP_DIR/"
cp -r nginx "$BACKUP_DIR/"

# Create backup info file
cat > "$BACKUP_DIR/backup_info.txt" << EOF
Backup Information
==================
Date: $(date)
Hostname: $(hostname)
Docker Version: $(docker --version)
Services Status:
$(docker-compose ps)

Database Size:
$(docker-compose exec -T mysql mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'Database Size (MB)' FROM information_schema.tables WHERE table_schema='expense_tracker';" 2>/dev/null || echo "Could not determine database size")
EOF

# Compress backup
print_status "Compressing backup..."
cd ./backups
tar -czf "$(basename $BACKUP_DIR).tar.gz" "$(basename $BACKUP_DIR)"
rm -rf "$(basename $BACKUP_DIR)"
cd ..

BACKUP_SIZE=$(du -h "./backups/$(basename $BACKUP_DIR).tar.gz" | cut -f1)
print_status "Backup completed: ./backups/$(basename $BACKUP_DIR).tar.gz ($BACKUP_SIZE)"

# Clean up old backups (keep last 7 days)
print_status "Cleaning up old backups..."
find ./backups -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo ""
echo -e "${GREEN}🎉 Backup process completed successfully!${NC}"
echo "Backup location: ./backups/$(basename $BACKUP_DIR).tar.gz"
