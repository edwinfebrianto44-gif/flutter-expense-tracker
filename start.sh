#!/bin/bash

# Expense Tracker - Quick Start Script
# This script sets up and runs the complete application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi

    log_success "Docker and Docker Compose are installed"
}

# Check if ports are available
check_ports() {
    local ports=(3000 8000 5432 6379)
    for port in "${ports[@]}"; do
        if ss -tulln | grep ":$port " &> /dev/null; then
            log_warning "Port $port is already in use. Please free the port or modify docker-compose.yml"
        fi
    done
}

# Start application with Docker
start_docker() {
    log_info "Starting Flutter Expense Tracker with Docker..."
    
    # Stop any existing containers
    docker-compose down 2>/dev/null || true
    
    # Build and start services
    docker-compose up -d --build
    
    log_info "Waiting for services to be ready..."
    sleep 10
    
    # Check if services are running
    if docker-compose ps | grep -q "Up"; then
        log_success "Application started successfully!"
        echo ""
        echo "🚀 Application URLs:"
        echo "   Frontend (Flutter Web): http://localhost:3000"
        echo "   Backend API: http://localhost:8000"
        echo "   API Documentation: http://localhost:8000/docs"
        echo ""
        echo "📱 Demo Account:"
        echo "   Email: demo@demo.com"
        echo "   Password: password123"
        echo ""
        echo "🔧 Management:"
        echo "   Stop: docker-compose down"
        echo "   Logs: docker-compose logs -f"
        echo "   Restart: docker-compose restart"
    else
        log_error "Some services failed to start. Check logs with: docker-compose logs"
        exit 1
    fi
}

# Development setup
start_dev() {
    log_info "Starting development environment..."
    
    # Stop any existing containers
    docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
    
    # Start development services
    docker-compose -f docker-compose.dev.yml up -d --build
    
    log_info "Waiting for services to be ready..."
    sleep 15
    
    log_success "Development environment started!"
    echo ""
    echo "🛠️ Development URLs:"
    echo "   Flutter Dev Server: http://localhost:8080"
    echo "   Backend API: http://localhost:8001"
    echo "   PostgreSQL: localhost:5433"
    echo "   Redis: localhost:6380"
    echo ""
    echo "📱 Demo Account:"
    echo "   Email: demo@demo.com"
    echo "   Password: password123"
}

# Manual setup for development
manual_setup() {
    log_info "Setting up manual development environment..."
    
    # Check if Python is installed
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed. Please install Python 3.8+ first."
        exit 1
    fi
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed. Please install Flutter first."
        exit 1
    fi
    
    # Setup backend
    log_info "Setting up backend..."
    cd backend
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        log_info "Creating .env file..."
        cat > .env << EOF
DATABASE_URL=postgresql://expense_user:expense_password@localhost:5432/expense_tracker
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=dev-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
ENVIRONMENT=development
DEBUG=True
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
EOF
    fi
    
    log_success "Backend setup completed!"
    cd ..
    
    # Setup frontend
    log_info "Setting up frontend..."
    cd mobile-app
    flutter pub get
    log_success "Frontend setup completed!"
    cd ..
    
    echo ""
    echo "🛠️ Manual Setup Complete!"
    echo ""
    echo "To start the application manually:"
    echo "1. Start PostgreSQL and Redis services"
    echo "2. Backend: cd backend && source venv/bin/activate && uvicorn main:app --reload"
    echo "3. Frontend: cd mobile-app && flutter run -d web-server --web-port 3000"
}

# Show help
show_help() {
    echo "Flutter Expense Tracker - Quick Start Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  start, -s       Start production environment with Docker (default)"
    echo "  dev, -d         Start development environment with Docker"
    echo "  manual, -m      Setup manual development environment"
    echo "  stop            Stop all Docker services"
    echo "  logs            Show Docker logs"
    echo "  clean           Clean up Docker resources"
    echo "  help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Start production environment"
    echo "  $0 dev          # Start development environment"
    echo "  $0 manual       # Setup manual environment"
    echo "  $0 stop         # Stop all services"
    echo ""
}

# Stop services
stop_services() {
    log_info "Stopping all services..."
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.dev.yml down 2>/dev/null || true
    docker-compose -f docker-compose.production.yml down 2>/dev/null || true
    log_success "All services stopped"
}

# Show logs
show_logs() {
    if docker-compose ps | grep -q "Up"; then
        docker-compose logs -f
    elif docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
        docker-compose -f docker-compose.dev.yml logs -f
    else
        log_warning "No running services found"
    fi
}

# Clean up Docker resources
clean_docker() {
    log_info "Cleaning up Docker resources..."
    stop_services
    docker-compose down --volumes --remove-orphans 2>/dev/null || true
    docker-compose -f docker-compose.dev.yml down --volumes --remove-orphans 2>/dev/null || true
    docker system prune -f
    log_success "Docker cleanup completed"
}

# Main script logic
main() {
    case "${1:-start}" in
        start|-s)
            check_docker
            check_ports
            start_docker
            ;;
        dev|-d)
            check_docker
            check_ports
            start_dev
            ;;
        manual|-m)
            manual_setup
            ;;
        stop)
            stop_services
            ;;
        logs)
            show_logs
            ;;
        clean)
            clean_docker
            ;;
        help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Print header
echo ""
echo "💰 Flutter Expense Tracker"
echo "============================"
echo ""

# Run main function
main "$@"
