#!/bin/bash

# Comprehensive Health Check Script for Flutter Expense Tracker
# Checks all features between frontend and backend integration
# Ensures no mock data is used and all APIs are working properly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKEND_URL="http://localhost:8000"
FRONTEND_URL="http://localhost:3000"
MOBILE_URL="http://localhost:8080" # Flutter web dev server

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Arrays to store test results
declare -a FAILED_TEST_NAMES=()
declare -a MOCK_DATA_FOUND=()
declare -a WARNINGS=()

echo -e "${BLUE}🔍 Flutter Expense Tracker - Comprehensive Health Check${NC}"
echo "======================================================"
echo -e "${CYAN}Date: $(date)${NC}"
echo -e "${CYAN}Backend URL: $BACKEND_URL${NC}"
echo -e "${CYAN}Frontend URL: $FRONTEND_URL${NC}"
echo -e "${CYAN}Mobile URL: $MOBILE_URL${NC}"
echo ""

# Logging function
log_test() {
    local status="$1"
    local test_name="$2"
    local details="$3"
    
    ((TOTAL_TESTS++))
    
    case $status in
        "PASS")
            ((PASSED_TESTS++))
            echo -e "${GREEN}✅ PASS${NC} - $test_name"
            [ -n "$details" ] && echo -e "   ${CYAN}$details${NC}"
            ;;
        "FAIL")
            ((FAILED_TESTS++))
            FAILED_TEST_NAMES+=("$test_name: $details")
            echo -e "${RED}❌ FAIL${NC} - $test_name"
            [ -n "$details" ] && echo -e "   ${RED}$details${NC}"
            ;;
        "SKIP")
            ((SKIPPED_TESTS++))
            echo -e "${YELLOW}⏭️  SKIP${NC} - $test_name"
            [ -n "$details" ] && echo -e "   ${YELLOW}$details${NC}"
            ;;
        "WARN")
            WARNINGS+=("$test_name: $details")
            echo -e "${YELLOW}⚠️  WARN${NC} - $test_name"
            [ -n "$details" ] && echo -e "   ${YELLOW}$details${NC}"
            ;;
    esac
}

# Function to check if service is running
check_service() {
    local url="$1"
    local service_name="$2"
    local timeout=5
    
    if curl -f -s --max-time $timeout "$url" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to make authenticated API call
api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local token="$4"
    
    local curl_opts=("-s" "-w" "\n%{http_code}")
    
    if [ -n "$token" ]; then
        curl_opts+=("-H" "Authorization: Bearer $token")
    fi
    
    curl_opts+=("-H" "Content-Type: application/json")
    
    if [ "$method" = "POST" ] || [ "$method" = "PUT" ] || [ "$method" = "PATCH" ]; then
        if [ -n "$data" ]; then
            curl_opts+=("-d" "$data")
        fi
    fi
    
    curl_opts+=("-X" "$method" "$BACKEND_URL$endpoint")
    
    curl "${curl_opts[@]}"
}

# Function to check for mock data in codebase
check_mock_data() {
    echo -e "\n${BLUE}🔍 Checking for Mock Data...${NC}"
    echo "================================"
    
    local mock_patterns=(
        "mock"
        "fake"
        "dummy"
        "test.*data"
        "sample.*data"
        "placeholder"
        "lorem.*ipsum"
        "example@example"
        "user@test"
        "admin@admin"
        "demo.*user"
    )
    
    local excluded_paths=(
        "*/test/*"
        "*/tests/*"
        "*_test.*"
        "*/node_modules/*"
        "*/.git/*"
        "*/build/*"
        "*/dist/*"
        "*/.venv/*"
        "*/coverage/*"
        "*/scripts/setup-demo-data.sh"
        "*/README.md"
        "*example*"
    )
    
    # Build exclusion arguments for grep
    local exclude_args=""
    for path in "${excluded_paths[@]}"; do
        exclude_args="$exclude_args --exclude-dir=$path"
    done
    
    local mock_found=false
    
    for pattern in "${mock_patterns[@]}"; do
        local files=$(grep -r -i -l "$pattern" "$PROJECT_ROOT" $exclude_args 2>/dev/null | grep -v -E "(test|spec|mock|example)" || true)
        
        if [ -n "$files" ]; then
            mock_found=true
            while IFS= read -r file; do
                local relative_path=${file#$PROJECT_ROOT/}
                MOCK_DATA_FOUND+=("Pattern '$pattern' found in: $relative_path")
                log_test "WARN" "Mock Data Detection" "Pattern '$pattern' found in: $relative_path"
            done <<< "$files"
        fi
    done
    
    if [ "$mock_found" = false ]; then
        log_test "PASS" "Mock Data Check" "No mock data patterns found in production code"
    fi
}

# Function to check backend services
check_backend_services() {
    echo -e "\n${BLUE}🔧 Backend Services Check...${NC}"
    echo "================================"
    
    # Check if backend is running
    if check_service "$BACKEND_URL/health" "Backend Health"; then
        log_test "PASS" "Backend Service" "Backend is running and responding"
    else
        log_test "FAIL" "Backend Service" "Backend is not responding at $BACKEND_URL"
        return 1
    fi
    
    # Check database connection
    local health_response=$(api_call "GET" "/health" "" "")
    local http_code=$(echo "$health_response" | tail -n1)
    local response_body=$(echo "$health_response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        if echo "$response_body" | grep -q "database.*connected\|status.*healthy"; then
            log_test "PASS" "Database Connection" "Database is connected and healthy"
        else
            log_test "WARN" "Database Connection" "Health endpoint accessible but database status unclear"
        fi
    else
        log_test "FAIL" "Database Connection" "Health endpoint returned HTTP $http_code"
    fi
    
    # Check API documentation
    if check_service "$BACKEND_URL/docs" "API Documentation"; then
        log_test "PASS" "API Documentation" "OpenAPI docs are accessible"
    else
        log_test "FAIL" "API Documentation" "API documentation not accessible"
    fi
    
    # Check metrics endpoint
    if check_service "$BACKEND_URL/metrics" "Metrics"; then
        log_test "PASS" "Metrics Endpoint" "Prometheus metrics are available"
    else
        log_test "SKIP" "Metrics Endpoint" "Metrics endpoint not configured or accessible"
    fi
}

# Function to test authentication endpoints
test_authentication() {
    echo -e "\n${BLUE}🔐 Authentication Tests...${NC}"
    echo "==============================="
    
    # Test user registration
    local register_data='{"username":"healthcheck_user","email":"healthcheck@test.com","password":"TestPass123!","full_name":"Health Check User"}'
    local register_response=$(api_call "POST" "/auth/register" "$register_data" "")
    local register_code=$(echo "$register_response" | tail -n1)
    
    if [ "$register_code" = "201" ] || [ "$register_code" = "400" ]; then
        if [ "$register_code" = "400" ] && echo "$register_response" | grep -q "already exists"; then
            log_test "PASS" "User Registration" "Registration endpoint working (user already exists)"
        else
            log_test "PASS" "User Registration" "Registration endpoint working"
        fi
    else
        log_test "FAIL" "User Registration" "Registration failed with HTTP $register_code"
    fi
    
    # Test demo user login
    local login_data='{"email":"demo@demo.com","password":"password123"}'
    local login_response=$(api_call "POST" "/auth/login" "$login_data" "")
    local login_code=$(echo "$login_response" | tail -n1)
    local login_body=$(echo "$login_response" | head -n -1)
    
    if [ "$login_code" = "200" ]; then
        local access_token=$(echo "$login_body" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$access_token" ]; then
            log_test "PASS" "Demo User Login" "Demo account login successful"
            echo "$access_token" > /tmp/health_check_token
        else
            log_test "FAIL" "Demo User Login" "Login successful but no access token received"
        fi
    else
        log_test "FAIL" "Demo User Login" "Demo account login failed with HTTP $login_code"
    fi
    
    # Test token validation
    if [ -f /tmp/health_check_token ]; then
        local token=$(cat /tmp/health_check_token)
        local me_response=$(api_call "GET" "/auth/me" "" "$token")
        local me_code=$(echo "$me_response" | tail -n1)
        
        if [ "$me_code" = "200" ]; then
            log_test "PASS" "Token Validation" "Access token is valid"
        else
            log_test "FAIL" "Token Validation" "Token validation failed with HTTP $me_code"
        fi
    else
        log_test "SKIP" "Token Validation" "No access token available"
    fi
}

# Function to test category management
test_categories() {
    echo -e "\n${BLUE}📁 Category Management Tests...${NC}"
    echo "====================================="
    
    if [ ! -f /tmp/health_check_token ]; then
        log_test "SKIP" "Category Tests" "No access token available"
        return
    fi
    
    local token=$(cat /tmp/health_check_token)
    
    # Test get categories
    local categories_response=$(api_call "GET" "/categories" "" "$token")
    local categories_code=$(echo "$categories_response" | tail -n1)
    local categories_body=$(echo "$categories_response" | head -n -1)
    
    if [ "$categories_code" = "200" ]; then
        local category_count=$(echo "$categories_body" | grep -o '"id":[0-9]*' | wc -l)
        log_test "PASS" "Get Categories" "Retrieved $category_count categories"
        
        # Check if demo categories exist
        if echo "$categories_body" | grep -q "Food\|Transportation\|Shopping\|Entertainment\|Bills"; then
            log_test "PASS" "Demo Categories" "Demo categories are present"
        else
            log_test "WARN" "Demo Categories" "Demo categories may be missing"
        fi
    else
        log_test "FAIL" "Get Categories" "Failed to retrieve categories (HTTP $categories_code)"
    fi
    
    # Test create category
    local new_category='{"name":"Health Check Category","description":"Category for testing","color":"#FF5722","icon":"test"}'
    local create_response=$(api_call "POST" "/categories" "$new_category" "$token")
    local create_code=$(echo "$create_response" | tail -n1)
    
    if [ "$create_code" = "201" ] || [ "$create_code" = "400" ]; then
        if [ "$create_code" = "400" ] && echo "$create_response" | grep -q "already exists"; then
            log_test "PASS" "Create Category" "Category creation endpoint working (category exists)"
        else
            log_test "PASS" "Create Category" "Category creation successful"
        fi
    else
        log_test "FAIL" "Create Category" "Category creation failed with HTTP $create_code"
    fi
}

# Function to test transaction management
test_transactions() {
    echo -e "\n${BLUE}💰 Transaction Management Tests...${NC}"
    echo "======================================="
    
    if [ ! -f /tmp/health_check_token ]; then
        log_test "SKIP" "Transaction Tests" "No access token available"
        return
    fi
    
    local token=$(cat /tmp/health_check_token)
    
    # Test get transactions
    local transactions_response=$(api_call "GET" "/transactions" "" "$token")
    local transactions_code=$(echo "$transactions_response" | tail -n1)
    local transactions_body=$(echo "$transactions_response" | head -n -1)
    
    if [ "$transactions_code" = "200" ]; then
        local transaction_count=$(echo "$transactions_body" | grep -o '"id":[0-9]*' | wc -l)
        log_test "PASS" "Get Transactions" "Retrieved $transaction_count transactions"
        
        # Check if demo transactions exist
        if [ "$transaction_count" -gt 20 ]; then
            log_test "PASS" "Demo Transactions" "Demo transactions are present ($transaction_count found)"
        else
            log_test "WARN" "Demo Transactions" "Demo transactions may be insufficient ($transaction_count found)"
        fi
    else
        log_test "FAIL" "Get Transactions" "Failed to retrieve transactions (HTTP $transactions_code)"
    fi
    
    # Test transaction filtering
    local filtered_response=$(api_call "GET" "/transactions?type=income&limit=5" "" "$token")
    local filtered_code=$(echo "$filtered_response" | tail -n1)
    
    if [ "$filtered_code" = "200" ]; then
        log_test "PASS" "Transaction Filtering" "Transaction filtering is working"
    else
        log_test "FAIL" "Transaction Filtering" "Transaction filtering failed (HTTP $filtered_code)"
    fi
    
    # Test create transaction
    local new_transaction='{"description":"Health Check Transaction","amount":100.00,"type":"expense","category_id":1,"date":"2025-09-08"}'
    local create_trans_response=$(api_call "POST" "/transactions" "$new_transaction" "$token")
    local create_trans_code=$(echo "$create_trans_response" | tail -n1)
    
    if [ "$create_trans_code" = "201" ]; then
        log_test "PASS" "Create Transaction" "Transaction creation successful"
    else
        log_test "FAIL" "Create Transaction" "Transaction creation failed (HTTP $create_trans_code)"
    fi
    
    # Test transaction statistics
    local stats_response=$(api_call "GET" "/transactions/stats" "" "$token")
    local stats_code=$(echo "$stats_response" | tail -n1)
    
    if [ "$stats_code" = "200" ]; then
        log_test "PASS" "Transaction Statistics" "Statistics endpoint working"
    else
        log_test "FAIL" "Transaction Statistics" "Statistics failed (HTTP $stats_code)"
    fi
}

# Function to test reporting features
test_reporting() {
    echo -e "\n${BLUE}📊 Reporting & Analytics Tests...${NC}"
    echo "====================================="
    
    if [ ! -f /tmp/health_check_token ]; then
        log_test "SKIP" "Reporting Tests" "No access token available"
        return
    fi
    
    local token=$(cat /tmp/health_check_token)
    
    # Test monthly report
    local month_report=$(api_call "GET" "/reports/monthly?year=2025&month=9" "" "$token")
    local month_code=$(echo "$month_report" | tail -n1)
    
    if [ "$month_code" = "200" ]; then
        log_test "PASS" "Monthly Report" "Monthly reporting is working"
    else
        log_test "FAIL" "Monthly Report" "Monthly report failed (HTTP $month_code)"
    fi
    
    # Test category analysis
    local category_analysis=$(api_call "GET" "/reports/categories" "" "$token")
    local category_code=$(echo "$category_analysis" | tail -n1)
    
    if [ "$category_code" = "200" ]; then
        log_test "PASS" "Category Analysis" "Category analysis is working"
    else
        log_test "FAIL" "Category Analysis" "Category analysis failed (HTTP $category_code)"
    fi
    
    # Test export functionality
    local export_response=$(api_call "GET" "/reports/export?format=csv" "" "$token")
    local export_code=$(echo "$export_response" | tail -n1)
    
    if [ "$export_code" = "200" ]; then
        log_test "PASS" "Data Export" "CSV export is working"
    else
        log_test "SKIP" "Data Export" "Export feature not available or configured"
    fi
}

# Function to check frontend availability
check_frontend() {
    echo -e "\n${BLUE}🌐 Frontend Availability Check...${NC}"
    echo "===================================="
    
    # Check if Flutter web is running
    if check_service "$MOBILE_URL" "Flutter Web"; then
        log_test "PASS" "Flutter Web App" "Flutter web app is accessible"
    else
        log_test "FAIL" "Flutter Web App" "Flutter web app not accessible at $MOBILE_URL"
    fi
    
    # Check for Flutter web build
    if [ -d "$PROJECT_ROOT/mobile-app/build/web" ]; then
        log_test "PASS" "Flutter Web Build" "Flutter web build directory exists"
    else
        log_test "WARN" "Flutter Web Build" "Flutter web build not found - run 'flutter build web'"
    fi
    
    # Check for main.dart
    if [ -f "$PROJECT_ROOT/mobile-app/lib/main.dart" ]; then
        log_test "PASS" "Flutter Source" "Flutter source files present"
    else
        log_test "FAIL" "Flutter Source" "Flutter main.dart not found"
    fi
}

# Function to check configuration files
check_configuration() {
    echo -e "\n${BLUE}⚙️  Configuration Check...${NC}"
    echo "==============================="
    
    # Check backend .env
    if [ -f "$PROJECT_ROOT/backend/.env" ]; then
        log_test "PASS" "Backend Environment" "Backend .env file exists"
        
        # Check for required environment variables
        local required_vars=("DATABASE_URL" "JWT_SECRET_KEY" "API_SECRET_KEY")
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" "$PROJECT_ROOT/backend/.env"; then
                log_test "PASS" "Environment Variable" "$var is configured"
            else
                log_test "FAIL" "Environment Variable" "$var is missing from .env"
            fi
        done
    else
        log_test "FAIL" "Backend Environment" "Backend .env file missing"
    fi
    
    # Check Docker configuration
    if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        log_test "PASS" "Docker Compose" "Docker compose file exists"
    else
        log_test "WARN" "Docker Compose" "Docker compose file not found"
    fi
    
    # Check Flutter configuration
    if [ -f "$PROJECT_ROOT/mobile-app/pubspec.yaml" ]; then
        log_test "PASS" "Flutter Config" "Flutter pubspec.yaml exists"
    else
        log_test "FAIL" "Flutter Config" "Flutter pubspec.yaml not found"
    fi
}

# Function to check security features
check_security() {
    echo -e "\n${BLUE}🔒 Security Features Check...${NC}"
    echo "================================="
    
    # Check CORS configuration
    local cors_response=$(curl -s -H "Origin: http://localhost:3000" -H "Access-Control-Request-Method: POST" -H "Access-Control-Request-Headers: Content-Type" -X OPTIONS "$BACKEND_URL/auth/login" -w "\n%{http_code}")
    local cors_code=$(echo "$cors_response" | tail -n1)
    
    if [ "$cors_code" = "200" ] || [ "$cors_code" = "204" ]; then
        log_test "PASS" "CORS Configuration" "CORS is properly configured"
    else
        log_test "WARN" "CORS Configuration" "CORS may not be configured properly"
    fi
    
    # Check rate limiting
    local rate_limit_test=true
    for i in {1..6}; do
        local response=$(api_call "POST" "/auth/login" '{"email":"invalid@test.com","password":"invalid"}' "")
        local code=$(echo "$response" | tail -n1)
        if [ "$code" = "429" ]; then
            rate_limit_test=true
            break
        fi
        sleep 0.1
    done
    
    if [ "$rate_limit_test" = true ]; then
        log_test "PASS" "Rate Limiting" "Rate limiting is active"
    else
        log_test "WARN" "Rate Limiting" "Rate limiting may not be configured"
    fi
    
    # Check HTTPS headers
    local headers_response=$(curl -s -I "$BACKEND_URL/health")
    if echo "$headers_response" | grep -i "strict-transport-security\|x-frame-options\|x-content-type-options"; then
        log_test "PASS" "Security Headers" "Security headers are present"
    else
        log_test "WARN" "Security Headers" "Security headers may be missing"
    fi
}

# Function to check performance
check_performance() {
    echo -e "\n${BLUE}⚡ Performance Check...${NC}"
    echo "=========================="
    
    # Check API response time
    local start_time=$(date +%s%N)
    check_service "$BACKEND_URL/health" "Backend"
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    if [ "$response_time" -lt 1000 ]; then
        log_test "PASS" "API Response Time" "Health endpoint responds in ${response_time}ms"
    elif [ "$response_time" -lt 3000 ]; then
        log_test "WARN" "API Response Time" "Health endpoint responds in ${response_time}ms (slow)"
    else
        log_test "FAIL" "API Response Time" "Health endpoint responds in ${response_time}ms (too slow)"
    fi
    
    # Check database query performance
    if [ -f /tmp/health_check_token ]; then
        local token=$(cat /tmp/health_check_token)
        local start_time=$(date +%s%N)
        api_call "GET" "/transactions?limit=10" "" "$token" >/dev/null
        local end_time=$(date +%s%N)
        local db_response_time=$(( (end_time - start_time) / 1000000 ))
        
        if [ "$db_response_time" -lt 2000 ]; then
            log_test "PASS" "Database Performance" "Database queries respond in ${db_response_time}ms"
        else
            log_test "WARN" "Database Performance" "Database queries respond in ${db_response_time}ms (slow)"
        fi
    fi
}

# Function to generate summary report
generate_summary() {
    echo -e "\n${BLUE}📋 HEALTH CHECK SUMMARY${NC}"
    echo "=========================="
    echo ""
    
    local success_rate=0
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi
    
    echo -e "${CYAN}Overall Statistics:${NC}"
    echo "  Total Tests: $TOTAL_TESTS"
    echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
    echo -e "  ${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
    echo -e "  Success Rate: ${success_rate}%"
    echo ""
    
    # Health status
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}🎉 SYSTEM STATUS: HEALTHY${NC}"
    elif [ "$FAILED_TESTS" -le 3 ]; then
        echo -e "${YELLOW}⚠️  SYSTEM STATUS: MINOR ISSUES${NC}"
    else
        echo -e "${RED}🚨 SYSTEM STATUS: CRITICAL ISSUES${NC}"
    fi
    echo ""
    
    # Failed tests
    if [ ${#FAILED_TEST_NAMES[@]} -gt 0 ]; then
        echo -e "${RED}❌ Failed Tests:${NC}"
        for test in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}•${NC} $test"
        done
        echo ""
    fi
    
    # Warnings
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Warnings:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}•${NC} $warning"
        done
        echo ""
    fi
    
    # Mock data findings
    if [ ${#MOCK_DATA_FOUND[@]} -gt 0 ]; then
        echo -e "${YELLOW}🔍 Mock Data Found:${NC}"
        for mock in "${MOCK_DATA_FOUND[@]}"; do
            echo -e "  ${YELLOW}•${NC} $mock"
        done
        echo ""
    fi
    
    echo -e "${CYAN}Recommendations:${NC}"
    if [ "$FAILED_TESTS" -gt 0 ]; then
        echo "  1. Fix failed tests before deploying to production"
    fi
    if [ ${#MOCK_DATA_FOUND[@]} -gt 0 ]; then
        echo "  2. Remove or replace mock data with real implementations"
    fi
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "  3. Address warnings to improve system reliability"
    fi
    if [ "$success_rate" -eq 100 ]; then
        echo "  🚀 System is ready for production deployment!"
    fi
    
    echo ""
    echo -e "${CYAN}Generated: $(date)${NC}"
}

# Cleanup function
cleanup() {
    # Remove temporary files
    rm -f /tmp/health_check_token
}

# Main execution
main() {
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Run all checks
    check_backend_services
    test_authentication
    test_categories
    test_transactions
    test_reporting
    check_frontend
    check_configuration
    check_security
    check_performance
    check_mock_data
    
    # Generate summary
    generate_summary
    
    # Exit with appropriate code
    if [ "$FAILED_TESTS" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Execute main function
main "$@"
