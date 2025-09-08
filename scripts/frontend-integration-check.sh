#!/bin/bash

# Frontend-Backend Integration Checker
# Specifically checks Flutter app integration with backend APIs
# and validates no mock data is being used

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MOBILE_APP_PATH="$PROJECT_ROOT/mobile-app"

# Results tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
MOCK_DATA_ISSUES=()
INTEGRATION_ISSUES=()

echo -e "${BLUE}🔍 Frontend-Backend Integration Checker${NC}"
echo "========================================"
echo ""

log_check() {
    local status="$1"
    local check_name="$2"
    local details="$3"
    
    ((TOTAL_CHECKS++))
    
    case $status in
        "PASS")
            ((PASSED_CHECKS++))
            echo -e "${GREEN}✅ PASS${NC} - $check_name"
            ;;
        "FAIL")
            ((FAILED_CHECKS++))
            INTEGRATION_ISSUES+=("$check_name: $details")
            echo -e "${RED}❌ FAIL${NC} - $check_name"
            ;;
        "MOCK")
            MOCK_DATA_ISSUES+=("$check_name: $details")
            echo -e "${YELLOW}🔍 MOCK${NC} - $check_name"
            ;;
    esac
    
    if [ -n "$details" ]; then
        echo -e "   ${CYAN}$details${NC}"
    fi
}

# Check Flutter project structure
check_flutter_structure() {
    echo -e "${BLUE}📱 Flutter Project Structure${NC}"
    echo "============================="
    
    # Check main directories
    local required_dirs=(
        "lib"
        "lib/core"
        "lib/data"
        "lib/models"
        "lib/providers"
        "lib/screens"
        "lib/services"
        "lib/widgets"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$MOBILE_APP_PATH/$dir" ]; then
            log_check "PASS" "Directory Structure" "$dir exists"
        else
            log_check "FAIL" "Directory Structure" "$dir is missing"
        fi
    done
    
    # Check critical files
    local required_files=(
        "lib/main.dart"
        "pubspec.yaml"
        "lib/core/constants.dart"
        "lib/services/api_service.dart"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$MOBILE_APP_PATH/$file" ]; then
            log_check "PASS" "Critical Files" "$file exists"
        else
            log_check "FAIL" "Critical Files" "$file is missing"
        fi
    done
}

# Check for mock data in Flutter code
check_flutter_mock_data() {
    echo -e "\n${BLUE}🔍 Flutter Mock Data Detection${NC}"
    echo "================================"
    
    local mock_patterns=(
        "MockApiService"
        "FakeData"
        "DummyData"
        "TestData"
        "mock.*"
        "fake.*"
        "dummy.*"
        "localhost.*8080"
        "example\.com"
        "test@test\.com"
        "mockito"
        "http_mock_adapter"
    )
    
    local found_mock=false
    
    # Search in Dart files
    find "$MOBILE_APP_PATH/lib" -name "*.dart" -type f | while read -r file; do
        local relative_path=${file#$MOBILE_APP_PATH/}
        
        # Skip test files
        if [[ "$file" == *"test"* ]] || [[ "$file" == *"_test.dart" ]]; then
            continue
        fi
        
        for pattern in "${mock_patterns[@]}"; do
            if grep -i -q "$pattern" "$file"; then
                found_mock=true
                log_check "MOCK" "Mock Data Found" "$pattern in $relative_path"
            fi
        done
    done
    
    # Check pubspec.yaml for test dependencies in main dependencies
    if [ -f "$MOBILE_APP_PATH/pubspec.yaml" ]; then
        local test_deps=$(grep -A 20 "^dependencies:" "$MOBILE_APP_PATH/pubspec.yaml" | grep -E "(mockito|http_mock_adapter|fake_async)" || true)
        if [ -n "$test_deps" ]; then
            log_check "MOCK" "Test Dependencies" "Test dependencies found in main dependencies section"
        else
            log_check "PASS" "Test Dependencies" "No test dependencies in main dependencies"
        fi
    fi
    
    if [ "$found_mock" = false ]; then
        log_check "PASS" "Mock Data Check" "No mock data patterns found in production code"
    fi
}

# Check API service configuration
check_api_configuration() {
    echo -e "\n${BLUE}🌐 API Configuration Check${NC}"
    echo "============================="
    
    local api_service_file="$MOBILE_APP_PATH/lib/services/api_service.dart"
    
    if [ -f "$api_service_file" ]; then
        # Check for hardcoded localhost URLs
        if grep -q "localhost.*8000\|127\.0\.0\.1.*8000" "$api_service_file"; then
            log_check "PASS" "API Base URL" "Backend URL configured for development"
        else
            log_check "FAIL" "API Base URL" "Backend URL not properly configured"
        fi
        
        # Check for proper HTTP client usage
        if grep -q "http\|dio" "$api_service_file"; then
            log_check "PASS" "HTTP Client" "HTTP client configured"
        else
            log_check "FAIL" "HTTP Client" "No HTTP client found"
        fi
        
        # Check for authentication headers
        if grep -i -q "authorization\|bearer\|token" "$api_service_file"; then
            log_check "PASS" "Authentication" "Authentication headers configured"
        else
            log_check "FAIL" "Authentication" "Authentication not properly configured"
        fi
        
        # Check for error handling
        if grep -i -q "try.*catch\|exception\|error" "$api_service_file"; then
            log_check "PASS" "Error Handling" "Error handling implemented"
        else
            log_check "FAIL" "Error Handling" "Error handling not implemented"
        fi
    else
        log_check "FAIL" "API Service" "API service file not found"
    fi
}

# Check data models
check_data_models() {
    echo -e "\n${BLUE}📊 Data Models Check${NC}"
    echo "====================="
    
    local models_dir="$MOBILE_APP_PATH/lib/models"
    
    if [ -d "$models_dir" ]; then
        local required_models=(
            "user.dart"
            "transaction.dart"
            "category.dart"
        )
        
        for model in "${required_models[@]}"; do
            if [ -f "$models_dir/$model" ]; then
                log_check "PASS" "Data Models" "$model exists"
                
                # Check for JSON serialization
                if grep -q "fromJson\|toJson" "$models_dir/$model"; then
                    log_check "PASS" "JSON Serialization" "$model has JSON methods"
                else
                    log_check "FAIL" "JSON Serialization" "$model missing JSON methods"
                fi
                
                # Check for mock data in models
                if grep -i -q "mock\|fake\|dummy\|test.*data" "$models_dir/$model"; then
                    log_check "MOCK" "Model Mock Data" "Mock data found in $model"
                fi
            else
                log_check "FAIL" "Data Models" "$model is missing"
            fi
        done
    else
        log_check "FAIL" "Models Directory" "Models directory not found"
    fi
}

# Check state management
check_state_management() {
    echo -e "\n${BLUE}🔄 State Management Check${NC}"
    echo "=========================="
    
    local providers_dir="$MOBILE_APP_PATH/lib/providers"
    
    if [ -d "$providers_dir" ]; then
        local required_providers=(
            "auth_provider.dart"
            "transaction_provider.dart"
            "category_provider.dart"
        )
        
        for provider in "${required_providers[@]}"; do
            if [ -f "$providers_dir/$provider" ]; then
                log_check "PASS" "State Providers" "$provider exists"
                
                # Check for API integration
                if grep -q "apiService\|http\|dio" "$providers_dir/$provider"; then
                    log_check "PASS" "API Integration" "$provider integrates with API"
                else
                    log_check "FAIL" "API Integration" "$provider not integrated with API"
                fi
                
                # Check for mock data
                if grep -i -q "mock\|fake\|dummy" "$providers_dir/$provider"; then
                    log_check "MOCK" "Provider Mock Data" "Mock data found in $provider"
                fi
            else
                log_check "FAIL" "State Providers" "$provider is missing"
            fi
        done
    else
        log_check "FAIL" "Providers Directory" "Providers directory not found"
    fi
}

# Check screen implementations
check_screens() {
    echo -e "\n${BLUE}📱 Screen Implementations${NC}"
    echo "=========================="
    
    local screens_dir="$MOBILE_APP_PATH/lib/screens"
    
    if [ -d "$screens_dir" ]; then
        local required_screens=(
            "auth"
            "dashboard"
            "transactions"
            "categories"
            "profile"
        )
        
        for screen in "${required_screens[@]}"; do
            if [ -d "$screens_dir/$screen" ] || find "$screens_dir" -name "*$screen*" -type f | grep -q .; then
                log_check "PASS" "Screen Implementation" "$screen screen exists"
                
                # Check for API calls in screens
                local screen_files=$(find "$screens_dir" -name "*$screen*" -type f 2>/dev/null || true)
                if [ -n "$screen_files" ]; then
                    if echo "$screen_files" | xargs grep -l "provider\|apiService\|setState" 2>/dev/null | grep -q .; then
                        log_check "PASS" "Screen API Integration" "$screen screen has API integration"
                    else
                        log_check "FAIL" "Screen API Integration" "$screen screen lacks API integration"
                    fi
                fi
            else
                log_check "FAIL" "Screen Implementation" "$screen screen is missing"
            fi
        done
    else
        log_check "FAIL" "Screens Directory" "Screens directory not found"
    fi
}

# Check dependencies
check_dependencies() {
    echo -e "\n${BLUE}📦 Dependencies Check${NC}"
    echo "======================"
    
    if [ -f "$MOBILE_APP_PATH/pubspec.yaml" ]; then
        local required_deps=(
            "http:"
            "provider:"
            "shared_preferences:"
            "flutter_secure_storage:"
        )
        
        for dep in "${required_deps[@]}"; do
            if grep -q "$dep" "$MOBILE_APP_PATH/pubspec.yaml"; then
                log_check "PASS" "Dependencies" "$dep is configured"
            else
                log_check "FAIL" "Dependencies" "$dep is missing"
            fi
        done
        
        # Check for unnecessary test dependencies in main deps
        local test_deps_in_main=$(grep -A 50 "^dependencies:" "$MOBILE_APP_PATH/pubspec.yaml" | grep -B 50 "^dev_dependencies:" | grep -E "(test:|mockito:|http_mock_adapter:)" || true)
        if [ -n "$test_deps_in_main" ]; then
            log_check "MOCK" "Dependency Configuration" "Test dependencies found in main dependencies"
        else
            log_check "PASS" "Dependency Configuration" "Clean dependency configuration"
        fi
    else
        log_check "FAIL" "Pubspec File" "pubspec.yaml not found"
    fi
}

# Check environment configuration
check_environment_config() {
    echo -e "\n${BLUE}⚙️  Environment Configuration${NC}"
    echo "=============================="
    
    # Check for environment-specific configurations
    local config_files=(
        "lib/core/constants.dart"
        "lib/core/config.dart"
        "lib/core/environment.dart"
    )
    
    local config_found=false
    for config_file in "${config_files[@]}"; do
        if [ -f "$MOBILE_APP_PATH/$config_file" ]; then
            config_found=true
            log_check "PASS" "Environment Config" "$config_file exists"
            
            # Check for hardcoded values
            if grep -q "localhost\|127\.0\.0\.1" "$MOBILE_APP_PATH/$config_file"; then
                if grep -q "kDebugMode\|DEBUG\|development" "$MOBILE_APP_PATH/$config_file"; then
                    log_check "PASS" "Environment Values" "Development URLs properly configured"
                else
                    log_check "FAIL" "Environment Values" "Hardcoded URLs without environment check"
                fi
            fi
            
            # Check for production readiness
            if grep -i -q "production\|release\|prod" "$MOBILE_APP_PATH/$config_file"; then
                log_check "PASS" "Production Config" "Production configuration present"
            else
                log_check "FAIL" "Production Config" "No production configuration found"
            fi
        fi
    done
    
    if [ "$config_found" = false ]; then
        log_check "FAIL" "Environment Config" "No environment configuration files found"
    fi
}

# Check build configuration
check_build_config() {
    echo -e "\n${BLUE}🔧 Build Configuration${NC}"
    echo "======================="
    
    # Check for web build capability
    if [ -d "$MOBILE_APP_PATH/web" ]; then
        log_check "PASS" "Web Support" "Web directory exists"
        
        if [ -f "$MOBILE_APP_PATH/web/index.html" ]; then
            log_check "PASS" "Web Index" "Web index.html exists"
        else
            log_check "FAIL" "Web Index" "Web index.html missing"
        fi
    else
        log_check "FAIL" "Web Support" "Web directory missing"
    fi
    
    # Check for Android build files
    if [ -d "$MOBILE_APP_PATH/android" ]; then
        log_check "PASS" "Android Support" "Android directory exists"
        
        if [ -f "$MOBILE_APP_PATH/android/app/build.gradle" ]; then
            log_check "PASS" "Android Build" "Android build.gradle exists"
        else
            log_check "FAIL" "Android Build" "Android build.gradle missing"
        fi
    else
        log_check "FAIL" "Android Support" "Android directory missing"
    fi
    
    # Check for iOS build files
    if [ -d "$MOBILE_APP_PATH/ios" ]; then
        log_check "PASS" "iOS Support" "iOS directory exists"
    else
        log_check "FAIL" "iOS Support" "iOS directory missing"
    fi
}

# Generate integration report
generate_integration_report() {
    echo -e "\n${BLUE}📋 INTEGRATION REPORT${NC}"
    echo "======================"
    echo ""
    
    local success_rate=0
    if [ "$TOTAL_CHECKS" -gt 0 ]; then
        success_rate=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    fi
    
    echo -e "${CYAN}Integration Statistics:${NC}"
    echo "  Total Checks: $TOTAL_CHECKS"
    echo -e "  ${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "  ${RED}Failed: $FAILED_CHECKS${NC}"
    echo -e "  Success Rate: ${success_rate}%"
    echo ""
    
    # Integration status
    if [ "$FAILED_CHECKS" -eq 0 ] && [ ${#MOCK_DATA_ISSUES[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 INTEGRATION STATUS: PRODUCTION READY${NC}"
    elif [ "$FAILED_CHECKS" -le 2 ] && [ ${#MOCK_DATA_ISSUES[@]} -le 1 ]; then
        echo -e "${YELLOW}⚠️  INTEGRATION STATUS: MINOR ISSUES${NC}"
    else
        echo -e "${RED}🚨 INTEGRATION STATUS: CRITICAL ISSUES${NC}"
    fi
    echo ""
    
    # Failed checks
    if [ ${#INTEGRATION_ISSUES[@]} -gt 0 ]; then
        echo -e "${RED}❌ Integration Issues:${NC}"
        for issue in "${INTEGRATION_ISSUES[@]}"; do
            echo -e "  ${RED}•${NC} $issue"
        done
        echo ""
    fi
    
    # Mock data issues
    if [ ${#MOCK_DATA_ISSUES[@]} -gt 0 ]; then
        echo -e "${YELLOW}🔍 Mock Data Issues:${NC}"
        for mock in "${MOCK_DATA_ISSUES[@]}"; do
            echo -e "  ${YELLOW}•${NC} $mock"
        done
        echo ""
    fi
    
    echo -e "${CYAN}Next Steps:${NC}"
    if [ ${#INTEGRATION_ISSUES[@]} -gt 0 ]; then
        echo "  1. Fix integration issues before deployment"
    fi
    if [ ${#MOCK_DATA_ISSUES[@]} -gt 0 ]; then
        echo "  2. Remove all mock data and implement real API calls"
    fi
    if [ "$success_rate" -eq 100 ] && [ ${#MOCK_DATA_ISSUES[@]} -eq 0 ]; then
        echo "  🚀 Frontend-Backend integration is ready for production!"
    fi
    
    echo ""
    echo -e "${CYAN}To run the app:${NC}"
    echo "  cd mobile-app && flutter pub get && flutter run -d web-server --web-port=8080"
    echo ""
    echo -e "${CYAN}Generated: $(date)${NC}"
}

# Main execution
main() {
    check_flutter_structure
    check_flutter_mock_data
    check_api_configuration
    check_data_models
    check_state_management
    check_screens
    check_dependencies
    check_environment_config
    check_build_config
    
    generate_integration_report
    
    # Exit with appropriate code
    if [ "$FAILED_CHECKS" -eq 0 ] && [ ${#MOCK_DATA_ISSUES[@]} -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
