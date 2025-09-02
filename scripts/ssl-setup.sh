#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo -e "${BLUE}🔒 SSL Certificate Setup for Expense Tracker${NC}"
echo "=============================================="

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '#' | xargs)
else
    print_error ".env file not found! Please run setup-vps.sh first."
    exit 1
fi

# Check if domain and email are set
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    print_error "DOMAIN and EMAIL must be set in .env file"
    exit 1
fi

print_status "Setting up SSL certificates for domain: $DOMAIN"

# Start nginx without SSL first
print_status "Starting nginx for domain verification..."
docker-compose up -d nginx

# Wait for nginx to start
sleep 10

# Create initial certificate
print_status "Requesting SSL certificate from Let's Encrypt..."
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d $DOMAIN

if [ $? -eq 0 ]; then
    print_status "SSL certificate obtained successfully!"
    
    # Restart nginx with SSL configuration
    print_status "Restarting nginx with SSL configuration..."
    docker-compose restart nginx
    
    print_status "SSL setup completed successfully!"
    echo ""
    echo -e "${GREEN}🎉 Your API is now accessible at: https://$DOMAIN${NC}"
    echo ""
    echo -e "${BLUE}📋 SSL Certificate Information:${NC}"
    echo "• Certificate location: ./certbot/conf/live/$DOMAIN/"
    echo "• Renewal: Automatic (certbot container handles this)"
    echo "• Expiry check: docker-compose exec certbot certbot certificates"
    echo ""
    echo -e "${BLUE}🔗 Useful URLs:${NC}"
    echo "• API Documentation: https://$DOMAIN/docs"
    echo "• API Health Check: https://$DOMAIN/health"
    echo "• Database Admin: http://$(curl -s ifconfig.me):8080"
else
    print_error "Failed to obtain SSL certificate!"
    print_warning "Please check:"
    echo "1. Domain $DOMAIN points to this server's IP address"
    echo "2. Port 80 is open and accessible"
    echo "3. No other web server is running on port 80"
    echo ""
    echo "You can check DNS with: nslookup $DOMAIN"
    echo "You can check IP with: curl ifconfig.me"
    exit 1
fi
