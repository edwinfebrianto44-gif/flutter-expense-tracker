#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 Expense Tracker System Monitor${NC}"
echo "=================================="

# System information
echo -e "${YELLOW}🖥️  System Information:${NC}"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk '{print $8 $9 $10}')"
echo "Memory Usage: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo ""

# Docker information
echo -e "${YELLOW}🐳 Docker Status:${NC}"
echo "Docker Version: $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo "Docker Compose Version: $(docker-compose --version | cut -d' ' -f4 | tr -d ',')"
echo ""

# Service status
echo -e "${YELLOW}🚀 Service Status:${NC}"
docker-compose ps
echo ""

# Container resource usage
echo -e "${YELLOW}📈 Container Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
echo ""

# Check SSL certificate expiry
if [ -f "./certbot/conf/live/api.expensetracker.com/fullchain.pem" ]; then
    echo -e "${YELLOW}🔒 SSL Certificate Status:${NC}"
    EXPIRY=$(openssl x509 -enddate -noout -in ./certbot/conf/live/api.expensetracker.com/fullchain.pem | cut -d= -f2)
    echo "Certificate expires: $EXPIRY"
    
    # Calculate days until expiry
    EXPIRY_DATE=$(date -d "$EXPIRY" +%s)
    CURRENT_DATE=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_DATE - $CURRENT_DATE) / 86400 ))
    
    if [ $DAYS_LEFT -lt 30 ]; then
        echo -e "${YELLOW}⚠️  Certificate expires in $DAYS_LEFT days!${NC}"
    else
        echo -e "${GREEN}✅ Certificate is valid for $DAYS_LEFT more days${NC}"
    fi
    echo ""
fi

# Database status
echo -e "${YELLOW}🗄️  Database Status:${NC}"
DB_STATUS=$(docker-compose exec -T mysql mysqladmin ping -h localhost --silent && echo "UP" || echo "DOWN")
echo "MySQL Status: $DB_STATUS"

if [ "$DB_STATUS" = "UP" ]; then
    DB_SIZE=$(docker-compose exec -T mysql mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'Database Size (MB)' FROM information_schema.tables WHERE table_schema='expense_tracker';" | tail -n1)
    echo "Database Size: ${DB_SIZE} MB"
fi
echo ""

# API health check
echo -e "${YELLOW}🔌 API Health Check:${NC}"
if curl -f -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}✅ API is responding${NC}"
    RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:8000/health)
    echo "Response Time: ${RESPONSE_TIME}s"
else
    echo -e "${RED}❌ API is not responding${NC}"
fi
echo ""

# Log file sizes
echo -e "${YELLOW}📝 Log File Sizes:${NC}"
if [ -d "./nginx/logs" ]; then
    echo "Nginx Access Log: $(du -h ./nginx/logs/access.log 2>/dev/null | cut -f1 || echo "0B")"
    echo "Nginx Error Log: $(du -h ./nginx/logs/error.log 2>/dev/null | cut -f1 || echo "0B")"
fi
echo ""

# Recent errors in logs
echo -e "${YELLOW}🚨 Recent Errors (last 10):${NC}"
echo "Backend errors:"
docker-compose logs --tail=50 backend 2>/dev/null | grep -i error | tail -5 || echo "No recent errors"
echo ""
echo "Nginx errors:"
docker-compose logs --tail=50 nginx 2>/dev/null | grep -i error | tail -5 || echo "No recent errors"
echo ""

echo -e "${GREEN}📊 Monitoring completed!${NC}"
