#!/bin/bash

# Smart System Checker with Service Management
# Automatically starts services if needed and runs comprehensive checks

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
BACKEND_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:8080"
BACKEND_DIR="$PROJECT_ROOT/backend"
MOBILE_APP_DIR="$PROJECT_ROOT/mobile-app"

# Service status tracking
BACKEND_STARTED=false
FRONTEND_STARTED=false
SERVICES_TO_CLEANUP=()

echo -e "${PURPLE}🚀 SMART SYSTEM CHECKER${NC}"
echo "========================"
echo -e "${CYAN}Intelligent service management and comprehensive testing${NC}"
echo ""

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    
    for service in "${SERVICES_TO_CLEANUP[@]}"; do
        echo "Stopping $service..."
        case $service in
            "backend")
                pkill -f "python.*main.py" 2>/dev/null || true
                ;;
            "frontend")
                pkill -f "flutter.*run" 2>/dev/null || true
                ;;
        esac
    done
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Set up cleanup trap
trap cleanup EXIT

# Function to check if service is running
check_service() {
    local url="$1"
    local timeout=3
    
    if curl -f -s --max-time $timeout "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to start backend
start_backend() {
    echo -e "${BLUE}🔧 Starting Backend Service...${NC}"
    
    # Check if backend directory exists
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${RED}❌ Backend directory not found: $BACKEND_DIR${NC}"
        return 1
    fi
    
    # Check if main.py exists
    if [ ! -f "$BACKEND_DIR/main.py" ]; then
        echo -e "${RED}❌ Backend main.py not found${NC}"
        return 1
    fi
    
    # Configure Python environment
    echo "Setting up Python environment..."
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python3 not found${NC}"
        return 1
    fi
    
    # Install dependencies if needed
    if [ -f "$BACKEND_DIR/requirements.txt" ]; then
        echo "Installing Python dependencies..."
        cd "$PROJECT_ROOT"
        
        # Use virtual environment if available
        if [ -f ".venv/bin/python" ]; then
            .venv/bin/pip install -r backend/requirements.txt >/dev/null 2>&1 || {
                echo -e "${YELLOW}⚠️  Failed to install some dependencies, continuing...${NC}"
            }
        else
            pip install -r backend/requirements.txt >/dev/null 2>&1 || {
                echo -e "${YELLOW}⚠️  Failed to install some dependencies, continuing...${NC}"
            }
        fi
    fi
    
    # Check for .env file
    if [ ! -f "$BACKEND_DIR/.env" ]; then
        echo "Creating default .env file..."
        cat > "$BACKEND_DIR/.env" << 'EOF'
# Database
DATABASE_URL=sqlite:///./expense_tracker.db

# Security
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production
API_SECRET_KEY=your-api-secret-key-change-this-in-production

# Environment
ENVIRONMENT=development
DEBUG=true

# CORS
CORS_ORIGINS=["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:8080"]

# File Upload
MAX_FILE_SIZE=10485760
UPLOAD_DIR=storage/uploads
EOF
    fi
    
    # Start backend in background
    echo "Starting backend server..."
    cd "$BACKEND_DIR"
    
    # Use virtual environment if available
    if [ -f "$PROJECT_ROOT/.venv/bin/python" ]; then
        nohup "$PROJECT_ROOT/.venv/bin/python" main.py > /tmp/backend.log 2>&1 &
    else
        nohup python3 main.py > /tmp/backend.log 2>&1 &
    fi
    local backend_pid=$!
    
    # Wait for backend to start
    echo "Waiting for backend to start..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if check_service "$BACKEND_URL/health"; then
            echo -e "${GREEN}✅ Backend started successfully${NC}"
            BACKEND_STARTED=true
            SERVICES_TO_CLEANUP+=("backend")
            return 0
        fi
        
        # Check if process is still running
        if ! kill -0 $backend_pid 2>/dev/null; then
            echo -e "${RED}❌ Backend process died${NC}"
            echo "Backend logs:"
            tail -20 /tmp/backend.log
            return 1
        fi
        
        sleep 2
        ((attempt++))
        echo -n "."
    done
    
    echo -e "\n${RED}❌ Backend failed to start within timeout${NC}"
    echo "Backend logs:"
    tail -20 /tmp/backend.log
    return 1
}

# Function to start frontend
start_frontend() {
    echo -e "${BLUE}🌐 Starting Frontend Service...${NC}"
    
    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
        return 1
    fi
    
    # Check if mobile-app directory exists
    if [ ! -d "$MOBILE_APP_DIR" ]; then
        echo -e "${RED}❌ Mobile app directory not found: $MOBILE_APP_DIR${NC}"
        return 1
    fi
    
    # Check if pubspec.yaml exists
    if [ ! -f "$MOBILE_APP_DIR/pubspec.yaml" ]; then
        echo -e "${RED}❌ Flutter pubspec.yaml not found${NC}"
        return 1
    fi
    
    # Install Flutter dependencies
    echo "Installing Flutter dependencies..."
    cd "$MOBILE_APP_DIR"
    flutter pub get >/dev/null 2>&1 || {
        echo -e "${YELLOW}⚠️  Failed to get Flutter dependencies, continuing...${NC}"
    }
    
    # Start Flutter web server in background
    echo "Starting Flutter web server..."
    nohup flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0 > /tmp/frontend.log 2>&1 &
    
    # Wait for frontend to start
    echo "Waiting for frontend to start..."
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if check_service "$FRONTEND_URL"; then
            echo -e "${GREEN}✅ Frontend started successfully${NC}"
            FRONTEND_STARTED=true
            SERVICES_TO_CLEANUP+=("frontend")
            return 0
        fi
        
        sleep 3
        ((attempt++))
        echo -n "."
    done
    
    echo -e "\n${YELLOW}⚠️  Frontend may not be fully ready yet${NC}"
    echo "Frontend logs:"
    tail -20 /tmp/frontend.log
    return 0
}

# Function to setup demo data
setup_demo_data() {
    echo -e "${BLUE}📊 Setting up Demo Data...${NC}"
    
    if [ -f "$SCRIPT_DIR/setup-demo-data.sh" ] && [ -x "$SCRIPT_DIR/setup-demo-data.sh" ]; then
        if "$SCRIPT_DIR/setup-demo-data.sh"; then
            echo -e "${GREEN}✅ Demo data setup completed${NC}"
        else
            echo -e "${YELLOW}⚠️  Demo data setup had issues${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Demo data setup script not found${NC}"
    fi
}

# Function to run system checks
run_system_checks() {
    echo -e "\n${BLUE}🔍 Running System Checks...${NC}"
    echo "============================"
    
    local all_passed=true
    
    # Run backend health check
    if [ -f "$SCRIPT_DIR/health-check.sh" ] && [ -x "$SCRIPT_DIR/health-check.sh" ]; then
        echo -e "\n${CYAN}Backend Health Check:${NC}"
        if "$SCRIPT_DIR/health-check.sh"; then
            echo -e "${GREEN}✅ Backend health check passed${NC}"
        else
            echo -e "${RED}❌ Backend health check failed${NC}"
            all_passed=false
        fi
    else
        echo -e "${YELLOW}⚠️  Backend health check script not found${NC}"
    fi
    
    # Run frontend integration check
    if [ -f "$SCRIPT_DIR/frontend-integration-check.sh" ] && [ -x "$SCRIPT_DIR/frontend-integration-check.sh" ]; then
        echo -e "\n${CYAN}Frontend Integration Check:${NC}"
        if "$SCRIPT_DIR/frontend-integration-check.sh"; then
            echo -e "${GREEN}✅ Frontend integration check passed${NC}"
        else
            echo -e "${RED}❌ Frontend integration check failed${NC}"
            all_passed=false
        fi
    else
        echo -e "${YELLOW}⚠️  Frontend integration check script not found${NC}"
    fi
    
    return $( [ "$all_passed" = true ] && echo 0 || echo 1 )
}

# Function to display manual test checklist
display_manual_checklist() {
    echo -e "\n${BLUE}📋 MANUAL TESTING CHECKLIST${NC}"
    echo "============================"
    echo ""
    echo -e "${YELLOW}🔗 Quick Access Links:${NC}"
    echo "  🌐 Frontend App: $FRONTEND_URL"
    echo "  📚 API Documentation: $BACKEND_URL/docs"
    echo "  ❤️  Backend Health: $BACKEND_URL/health"
    echo "  📊 API Metrics: $BACKEND_URL/metrics"
    echo ""
    echo -e "${YELLOW}🔐 Demo Account:${NC}"
    echo "  📧 Email: demo@demo.com"
    echo "  🔑 Password: password123"
    echo ""
    echo -e "${YELLOW}✅ Features to Test:${NC}"
    echo "  □ 1. Login with demo account"
    echo "  □ 2. Dashboard displays transactions and charts"
    echo "  □ 3. Add new transaction"
    echo "  □ 4. Edit existing transaction"
    echo "  □ 5. Delete transaction"
    echo "  □ 6. Add new category"
    echo "  □ 7. Edit category"
    echo "  □ 8. Filter transactions by category"
    echo "  □ 9. Filter transactions by date range"
    echo "  □ 10. Search transactions"
    echo "  □ 11. View monthly/yearly reports"
    echo "  □ 12. Export data to CSV"
    echo "  □ 13. Update profile information"
    echo "  □ 14. Logout and login again"
    echo "  □ 15. Test responsive design on mobile"
    echo ""
    echo -e "${YELLOW}🔍 Data Validation:${NC}"
    echo "  □ All data comes from backend (no mock data)"
    echo "  □ Real-time updates work"
    echo "  □ Error messages are user-friendly"
    echo "  □ Loading states are visible"
    echo "  □ Charts display accurate data"
    echo ""
}

# Main execution
main() {
    echo -e "${CYAN}Step 1: Checking Current Service Status...${NC}"
    
    # Check if backend is already running
    if check_service "$BACKEND_URL/health"; then
        echo -e "${GREEN}✅ Backend is already running${NC}"
        BACKEND_STARTED=true
    else
        echo -e "${YELLOW}⚠️  Backend is not running${NC}"
        if ! start_backend; then
            echo -e "${RED}❌ Failed to start backend${NC}"
            exit 1
        fi
    fi
    
    # Check if frontend is already running
    if check_service "$FRONTEND_URL"; then
        echo -e "${GREEN}✅ Frontend is already running${NC}"
        FRONTEND_STARTED=true
    else
        echo -e "${YELLOW}⚠️  Frontend is not running${NC}"
        echo -e "${CYAN}Would you like to start the frontend? (y/n)${NC}"
        read -r start_frontend_choice
        if [[ "$start_frontend_choice" =~ ^[Yy]$ ]]; then
            start_frontend
        else
            echo -e "${YELLOW}⚠️  Skipping frontend startup${NC}"
        fi
    fi
    
    echo -e "\n${CYAN}Step 2: Setting up Demo Data...${NC}"
    setup_demo_data
    
    echo -e "\n${CYAN}Step 3: Running Automated Checks...${NC}"
    if run_system_checks; then
        echo -e "\n${GREEN}🎉 ALL AUTOMATED CHECKS PASSED!${NC}"
    else
        echo -e "\n${YELLOW}⚠️  Some automated checks failed${NC}"
    fi
    
    echo -e "\n${CYAN}Step 4: Manual Testing${NC}"
    display_manual_checklist
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}SYSTEM STATUS SUMMARY${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    local status_color=$GREEN
    local status_text="READY FOR TESTING"
    
    if [ "$BACKEND_STARTED" = true ]; then
        echo -e "${GREEN}✅ Backend: Running${NC}"
    else
        echo -e "${RED}❌ Backend: Not Running${NC}"
        status_color=$RED
        status_text="BACKEND ISSUES"
    fi
    
    if [ "$FRONTEND_STARTED" = true ]; then
        echo -e "${GREEN}✅ Frontend: Running${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend: Not Running${NC}"
        if [ "$status_color" != "$RED" ]; then
            status_color=$YELLOW
            status_text="BACKEND ONLY"
        fi
    fi
    
    echo ""
    echo -e "${status_color}🚀 SYSTEM STATUS: $status_text${NC}"
    
    if [ "$BACKEND_STARTED" = true ]; then
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo "1. Open $FRONTEND_URL in your browser"
        echo "2. Login with demo@demo.com / password123"
        echo "3. Complete the manual testing checklist above"
        echo "4. Check API documentation at $BACKEND_URL/docs"
        echo ""
        echo -e "${CYAN}To stop services:${NC}"
        echo "Press Ctrl+C to stop all services"
    fi
    
    # Keep script running to maintain services
    if [ "$BACKEND_STARTED" = true ] || [ "$FRONTEND_STARTED" = true ]; then
        echo ""
        echo -e "${YELLOW}Services are running. Press Ctrl+C to stop all services.${NC}"
        
        # Wait for interrupt
        while true; do
            sleep 10
            
            # Check if services are still running
            if [ "$BACKEND_STARTED" = true ]; then
                if ! check_service "$BACKEND_URL/health"; then
                    echo -e "\n${RED}⚠️  Backend service appears to have stopped${NC}"
                    break
                fi
            fi
        done
    fi
}

# Run main function
main "$@"
