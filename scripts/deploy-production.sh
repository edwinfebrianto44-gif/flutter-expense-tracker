#!/bin/bash

# Production Deployment Script for Expense Tracker
# Deploys backend to api.expensetracker.com and frontend to app.expensetracker.com

set -e

echo "🚀 Starting Production Deployment..."

# Configuration
BACKEND_DOMAIN="api.expensetracker.com"
FRONTEND_DOMAIN="app.expensetracker.com"
PROJECT_ROOT="/workspaces/flutter-expense-tracker"
WEB_ROOT="/var/www"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root for some operations
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root user"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed"
        exit 1
    fi
    
    # Check Nginx
    if ! command -v nginx &> /dev/null; then
        log_warning "Nginx is not installed - will attempt to install"
    fi
    
    log_success "Prerequisites check completed"
}

# Setup environment
setup_environment() {
    log_info "Setting up production environment..."
    
    cd "$PROJECT_ROOT"
    
    # Copy production environment file
    if [ ! -f "backend/.env.prod" ]; then
        log_info "Creating production environment file..."
        cat > backend/.env.prod << EOF
# Production Environment Configuration
DEBUG=false
ENVIRONMENT=production

# Database
DATABASE_URL=postgresql://expense_user:your_secure_password@localhost:5432/expense_tracker_prod

# Security
JWT_SECRET_KEY=$(openssl rand -hex 32)
API_SECRET_KEY=$(openssl rand -hex 32)

# CORS
ALLOWED_ORIGINS=https://${FRONTEND_DOMAIN},https://${BACKEND_DOMAIN}

# SSL
USE_SSL=true

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password

# Features
FEATURE_REGISTRATION_ENABLED=true
FEATURE_EMAIL_VERIFICATION=true

# File Storage
USE_S3=false
UPLOAD_PATH=/app/storage/uploads

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=3600

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
EOF
        log_warning "Please edit backend/.env.prod with your actual values"
        log_warning "Especially DATABASE_URL, SMTP credentials, etc."
    fi
    
    log_success "Environment setup completed"
}

# Deploy backend
deploy_backend() {
    log_info "Deploying backend to ${BACKEND_DOMAIN}..."
    
    cd "$PROJECT_ROOT"
    
    # Build backend Docker image
    log_info "Building backend Docker image..."
    docker build -t expense-tracker-backend:prod -f backend/Dockerfile backend/
    
    # Stop existing backend container
    log_info "Stopping existing backend container..."
    docker-compose -f docker-compose.prod.yml down backend || true
    
    # Start backend with production configuration
    log_info "Starting backend container..."
    docker-compose -f docker-compose.prod.yml up -d backend
    
    # Wait for backend to be ready
    log_info "Waiting for backend to be ready..."
    sleep 10
    
    # Health check
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        log_success "Backend health check passed"
    else
        log_error "Backend health check failed"
        return 1
    fi
    
    log_success "Backend deployment completed"
}

# Deploy frontend
deploy_frontend() {
    log_info "Deploying frontend to ${FRONTEND_DOMAIN}..."
    
    cd "$PROJECT_ROOT/mobile-app"
    
    # Update API endpoint configuration
    log_info "Updating API configuration for production..."
    cat > lib/core/config/app_config.dart << EOF
class AppConfig {
  static const String baseUrl = 'https://${BACKEND_DOMAIN}';
  static const String apiVersion = 'v1';
  static const String environment = 'production';
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshEndpoint = '/auth/refresh';
  static const String transactionsEndpoint = '/transactions';
  static const String categoriesEndpoint = '/categories';
  static const String analyticsEndpoint = '/analytics';
  static const String uploadEndpoint = '/upload';
  
  // App Settings
  static const bool enableDebugMode = false;
  static const bool enableAnalytics = true;
  static const int requestTimeoutSeconds = 30;
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableBiometricAuth = true;
  static const bool enablePushNotifications = true;
}
EOF
    
    # Install dependencies
    log_info "Installing Flutter dependencies..."
    flutter clean
    flutter pub get
    
    # Generate code
    log_info "Generating code..."
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    # Build web version
    log_info "Building Flutter web app..."
    flutter build web --release --web-renderer html
    
    # Create web directory
    sudo mkdir -p "${WEB_ROOT}/${FRONTEND_DOMAIN}"
    
    # Copy built files
    log_info "Copying built files to web server..."
    sudo cp -r build/web/* "${WEB_ROOT}/${FRONTEND_DOMAIN}/"
    
    # Set proper permissions
    sudo chown -R www-data:www-data "${WEB_ROOT}/${FRONTEND_DOMAIN}"
    sudo chmod -R 755 "${WEB_ROOT}/${FRONTEND_DOMAIN}"
    
    log_success "Frontend deployment completed"
}

# Configure Nginx
configure_nginx() {
    log_info "Configuring Nginx..."
    
    # Backend configuration
    sudo tee /etc/nginx/sites-available/${BACKEND_DOMAIN} > /dev/null << EOF
server {
    listen 80;
    server_name ${BACKEND_DOMAIN};
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${BACKEND_DOMAIN};
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${BACKEND_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${BACKEND_DOMAIN}/privkey.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Proxy to FastAPI
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    # File upload size
    client_max_body_size 50M;
}
EOF
    
    # Frontend configuration
    sudo tee /etc/nginx/sites-available/${FRONTEND_DOMAIN} > /dev/null << EOF
server {
    listen 80;
    server_name ${FRONTEND_DOMAIN};
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${FRONTEND_DOMAIN};
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${FRONTEND_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FRONTEND_DOMAIN}/privkey.pem;
    
    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Document root
    root ${WEB_ROOT}/${FRONTEND_DOMAIN};
    index index.html;
    
    # Flutter web routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security for sensitive files
    location ~ /\.(ht|git) {
        deny all;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
EOF
    
    # Enable sites
    sudo ln -sf /etc/nginx/sites-available/${BACKEND_DOMAIN} /etc/nginx/sites-enabled/
    sudo ln -sf /etc/nginx/sites-available/${FRONTEND_DOMAIN} /etc/nginx/sites-enabled/
    
    # Test Nginx configuration
    if sudo nginx -t; then
        log_success "Nginx configuration is valid"
        sudo systemctl reload nginx
    else
        log_error "Nginx configuration is invalid"
        return 1
    fi
    
    log_success "Nginx configuration completed"
}

# Setup SSL certificates
setup_ssl() {
    log_info "Setting up SSL certificates..."
    
    # Install Certbot if not present
    if ! command -v certbot &> /dev/null; then
        log_info "Installing Certbot..."
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
    fi
    
    # Obtain certificates
    log_info "Obtaining SSL certificates..."
    sudo certbot --nginx -d ${BACKEND_DOMAIN} -d ${FRONTEND_DOMAIN} --non-interactive --agree-tos --email admin@${BACKEND_DOMAIN}
    
    # Setup auto-renewal
    log_info "Setting up SSL auto-renewal..."
    (sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload nginx'") | sudo crontab -
    
    log_success "SSL setup completed"
}

# Setup demo data
setup_demo() {
    log_info "Setting up demo data..."
    
    cd "$PROJECT_ROOT"
    
    # Make script executable
    chmod +x scripts/setup-demo-data.sh
    
    # Run demo data setup
    ./scripts/setup-demo-data.sh
    
    log_success "Demo data setup completed"
}

# Main deployment function
main() {
    log_info "🚀 Starting Production Deployment for Expense Tracker"
    echo
    
    check_root
    check_prerequisites
    setup_environment
    
    # Ask for confirmation before proceeding
    read -p "Continue with deployment to production domains? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled"
        exit 0
    fi
    
    deploy_backend
    deploy_frontend
    configure_nginx
    setup_ssl
    setup_demo
    
    echo
    log_success "🎉 Production deployment completed successfully!"
    log_info "Backend API: https://${BACKEND_DOMAIN}"
    log_info "Frontend App: https://${FRONTEND_DOMAIN}"
    log_info "Demo Account: demo@demo.com / password123"
    echo
    log_info "Next steps:"
    log_info "1. Update DNS records to point to this server"
    log_info "2. Test all functionality on production domains"
    log_info "3. Monitor logs and performance"
    log_info "4. Setup automated backups if not already configured"
}

# Error handling
trap 'log_error "Deployment failed on line $LINENO"' ERR

# Run main function
main "$@"
