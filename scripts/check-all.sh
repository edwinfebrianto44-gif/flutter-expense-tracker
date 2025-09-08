#!/bin/bash

# Master Check Script - Complete System Validation
# Runs all health checks and integration tests for the Flutter Expense Tracker

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

echo -e "${PURPLE}🔍 FLUTTER EXPENSE TRACKER - COMPLETE SYSTEM CHECK${NC}"
echo "=================================================="
echo -e "${CYAN}Checking all features between frontend and backend${NC}"
echo -e "${CYAN}Ensuring no mock data is present in production code${NC}"
echo "=================================================="
echo ""

# Function to run a check script and capture results
run_check() {
    local script_name="$1"
    local script_path="$2"
    local description="$3"
    
    echo -e "${BLUE}🔍 Running $script_name...${NC}"
    echo "---------------------------------------------------"
    
    if [ -x "$script_path" ]; then
        if "$script_path"; then
            echo -e "${GREEN}✅ $script_name PASSED${NC}"
            return 0
        else
            echo -e "${RED}❌ $script_name FAILED${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ $script_name script not found or not executable${NC}"
        return 1
    fi
}

# Main execution
main() {
    local total_checks=0
    local passed_checks=0
    local failed_checks=0
    
    echo -e "${YELLOW}📋 CHECKLIST OVERVIEW${NC}"
    echo "====================="
    echo "1. ✅ Backend API Health & Services"
    echo "2. ✅ Authentication & Security"
    echo "3. ✅ Database & Data Integrity"
    echo "4. ✅ Transaction Management"
    echo "5. ✅ Category Management"
    echo "6. ✅ Reporting & Analytics"
    echo "7. ✅ Frontend-Backend Integration"
    echo "8. ✅ Flutter App Structure"
    echo "9. ✅ State Management"
    echo "10. ✅ Mock Data Detection"
    echo "11. ✅ Performance & Security"
    echo "12. ✅ Configuration Validation"
    echo ""
    
    # Check 1: Backend Health Check
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}CHECK 1: BACKEND SERVICES & APIs${NC}"
    echo -e "${BLUE}========================================${NC}"
    ((total_checks++))
    if run_check "Backend Health Check" "$SCRIPT_DIR/health-check.sh" "Complete backend API validation"; then
        ((passed_checks++))
    else
        ((failed_checks++))
    fi
    echo ""
    
    # Check 2: Frontend Integration
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}CHECK 2: FRONTEND-BACKEND INTEGRATION${NC}"
    echo -e "${BLUE}========================================${NC}"
    ((total_checks++))
    if run_check "Frontend Integration Check" "$SCRIPT_DIR/frontend-integration-check.sh" "Flutter app integration validation"; then
        ((passed_checks++))
    else
        ((failed_checks++))
    fi
    echo ""
    
    # Additional manual checks
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}CHECK 3: MANUAL VERIFICATION CHECKLIST${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${CYAN}Please verify the following manually:${NC}"
    echo ""
    
    echo -e "${YELLOW}🔧 SETUP REQUIREMENTS:${NC}"
    echo "  □ Backend server is running (docker-compose up or python main.py)"
    echo "  □ Database is initialized and seeded with demo data"
    echo "  □ Flutter dependencies are installed (flutter pub get)"
    echo "  □ Flutter web server is running (flutter run -d web-server)"
    echo ""
    
    echo -e "${YELLOW}📱 FRONTEND FEATURES TO TEST:${NC}"
    echo "  □ User registration and login work"
    echo "  □ Dashboard displays real data from backend"
    echo "  □ Add/Edit/Delete transactions work"
    echo "  □ Add/Edit/Delete categories work"
    echo "  □ Transaction filtering and search work"
    echo "  □ Charts and analytics display correctly"
    echo "  □ Profile management works"
    echo "  □ Data export functionality works"
    echo "  □ Responsive design on different screen sizes"
    echo "  □ Error handling displays proper messages"
    echo ""
    
    echo -e "${YELLOW}🔗 API INTEGRATION TO TEST:${NC}"
    echo "  □ All API calls use real backend endpoints (no mock data)"
    echo "  □ Authentication tokens are properly managed"
    echo "  □ Loading states are implemented"
    echo "  □ Error states are handled gracefully"
    echo "  □ Data synchronization works correctly"
    echo "  □ Real-time updates reflect backend changes"
    echo ""
    
    echo -e "${YELLOW}🚀 PRODUCTION READINESS:${NC}"
    echo "  □ No hardcoded development URLs in production builds"
    echo "  □ Environment variables are properly configured"
    echo "  □ Security headers are implemented"
    echo "  □ Rate limiting is working"
    echo "  □ CORS is properly configured"
    echo "  □ SSL/HTTPS is configured for production"
    echo ""
    
    echo -e "${YELLOW}📊 DATA VALIDATION:${NC}"
    echo "  □ Demo account (demo@demo.com) has realistic transaction data"
    echo "  □ Categories have proper icons and colors"
    echo "  □ Transaction amounts and dates are realistic"
    echo "  □ Reports show accurate calculations"
    echo "  □ Data export contains real transaction data"
    echo ""
    
    # Final summary
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}FINAL SYSTEM STATUS${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    local success_rate=0
    if [ "$total_checks" -gt 0 ]; then
        success_rate=$(( (passed_checks * 100) / total_checks ))
    fi
    
    echo -e "${CYAN}Automated Checks Summary:${NC}"
    echo "  Total Automated Checks: $total_checks"
    echo -e "  ${GREEN}Passed: $passed_checks${NC}"
    echo -e "  ${RED}Failed: $failed_checks${NC}"
    echo -e "  Success Rate: ${success_rate}%"
    echo ""
    
    if [ "$failed_checks" -eq 0 ]; then
        echo -e "${GREEN}🎉 ALL AUTOMATED CHECKS PASSED!${NC}"
        echo -e "${GREEN}✅ Backend services are healthy${NC}"
        echo -e "${GREEN}✅ Frontend-backend integration is working${NC}"
        echo -e "${GREEN}✅ No mock data detected in production code${NC}"
        echo ""
        echo -e "${CYAN}Next Steps:${NC}"
        echo "1. Complete the manual verification checklist above"
        echo "2. Test all features in the Flutter web app"
        echo "3. Verify demo account functionality"
        echo "4. Check production deployment readiness"
        echo ""
        echo -e "${GREEN}🚀 System appears ready for production deployment!${NC}"
    else
        echo -e "${RED}🚨 SOME CHECKS FAILED${NC}"
        echo -e "${RED}❌ Please fix the failed checks before proceeding${NC}"
        echo ""
        echo -e "${CYAN}Required Actions:${NC}"
        echo "1. Review and fix all failed automated checks"
        echo "2. Ensure all services are running properly"
        echo "3. Verify API endpoints are accessible"
        echo "4. Check database connectivity"
        echo "5. Re-run this script after fixes"
    fi
    
    echo ""
    echo -e "${CYAN}Quick Commands:${NC}"
    echo "  Start Backend: cd backend && python main.py"
    echo "  Start Frontend: cd mobile-app && flutter run -d web-server --web-port=8080"
    echo "  Setup Demo Data: ./scripts/setup-demo-data.sh"
    echo "  View API Docs: http://localhost:8000/docs"
    echo "  Access App: http://localhost:8080"
    echo "  Demo Login: demo@demo.com / password123"
    echo ""
    echo -e "${CYAN}Generated: $(date)${NC}"
    
    # Exit with appropriate code
    if [ "$failed_checks" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
