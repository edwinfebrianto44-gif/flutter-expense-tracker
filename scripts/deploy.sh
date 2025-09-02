#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo -e "${BLUE}🔧 Expense Tracker Deployment Script${NC}"
echo "======================================"

# Check if .env exists
if [ ! -f ".env" ]; then
    print_error ".env file not found! Please run setup-vps.sh first."
    exit 1
fi

# Pull latest code
print_status "Pulling latest code..."
git pull origin main

# Pull latest images
print_status "Pulling latest Docker images..."
docker-compose pull

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down

# Build and start services
print_status "Building and starting services..."
docker-compose up -d --build

# Wait for services to be healthy
print_status "Waiting for services to be ready..."
sleep 30

# Check service status
print_status "Checking service status..."
docker-compose ps

# Run database migrations
print_status "Running database migrations..."
docker-compose exec backend python -c "
import sys
sys.path.insert(0, '/app')
from alembic import command
from alembic.config import Config
config = Config('/app/alembic.ini')
try:
    command.upgrade(config, 'head')
    print('✅ Database migrations completed successfully!')
except Exception as e:
    print(f'❌ Migration error: {e}')
"

# Test API endpoint
print_status "Testing API endpoint..."
sleep 10

if curl -f -s http://localhost:8000/health > /dev/null; then
    print_status "API is responding correctly!"
else
    print_warning "API health check failed. Check logs with: docker-compose logs backend"
fi

# Show final status
echo ""
echo -e "${GREEN}🎉 Deployment completed!${NC}"
echo ""
echo -e "${BLUE}📊 Service Status:${NC}"
docker-compose ps

echo ""
echo -e "${BLUE}🔗 Access Points:${NC}"
echo "• API Documentation: https://api.expensetracker.com/docs"
echo "• API Health: https://api.expensetracker.com/health"
echo "• Database Admin: http://$(curl -s ifconfig.me):8080"

echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo "• View logs: docker-compose logs -f [service]"
echo "• Restart service: docker-compose restart [service]"
echo "• Update deployment: ./scripts/deploy.sh"
echo "• Check SSL: docker-compose exec certbot certbot certificates"
