#!/bin/bash

# Production Firewall Setup Script for Flutter Expense Tracker
# Configures UFW firewall with Fail2ban for intrusion prevention

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔥 Production Firewall Setup for Flutter Expense Tracker${NC}"
echo "========================================================="
echo "This script configures UFW firewall and Fail2ban for production security"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run this script with sudo${NC}"
    exit 1
fi

# Configuration variables
SSH_PORT="22"
FAIL2BAN_BANTIME="3600"  # 1 hour
FAIL2BAN_FINDTIME="600"  # 10 minutes
FAIL2BAN_MAXRETRY="5"    # 5 attempts

echo -e "${YELLOW}📋 Default Configuration:${NC}"
echo "SSH Port: $SSH_PORT"
echo "Fail2ban Ban Time: $FAIL2BAN_BANTIME seconds (1 hour)"
echo "Fail2ban Find Time: $FAIL2BAN_FINDTIME seconds (10 minutes)"
echo "Fail2ban Max Retry: $FAIL2BAN_MAXRETRY attempts"
echo ""

read -p "Do you want to use a custom SSH port? (y/N): " custom_ssh
if [[ $custom_ssh == [yY] ]]; then
    read -p "Enter SSH port (default 22): " new_ssh_port
    if [[ $new_ssh_port =~ ^[0-9]+$ ]] && [[ $new_ssh_port -ge 1024 ]] && [[ $new_ssh_port -le 65535 ]]; then
        SSH_PORT="$new_ssh_port"
        echo -e "${GREEN}✅ Using SSH port: $SSH_PORT${NC}"
    else
        echo -e "${YELLOW}⚠️  Invalid port, using default: 22${NC}"
    fi
fi

echo ""
read -p "Continue with firewall setup? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Aborted."
    exit 1
fi

echo -e "${GREEN}📦 Installing firewall components...${NC}"

# Update system
apt-get update

# Install UFW and Fail2ban
apt-get install -y ufw fail2ban

# Install additional security tools
apt-get install -y iptables-persistent netfilter-persistent

echo -e "${GREEN}🔧 Configuring UFW firewall...${NC}"

# Reset UFW to defaults
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow loopback
ufw allow in on lo
ufw allow out on lo

# Allow SSH (essential - do this first!)
echo -e "${YELLOW}🔑 Configuring SSH access on port $SSH_PORT...${NC}"
ufw allow $SSH_PORT/tcp comment 'SSH access'

# Allow HTTP and HTTPS
echo -e "${YELLOW}🌐 Allowing web traffic...${NC}"
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Allow Docker network communication (if using Docker)
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Configuring Docker network rules...${NC}"
    ufw allow in on docker0
    ufw allow out on docker0
fi

# Rate limiting for SSH
echo -e "${YELLOW}⚡ Setting up rate limiting for SSH...${NC}"
ufw limit $SSH_PORT/tcp comment 'SSH rate limiting'

# Log denied connections
ufw logging on

echo -e "${GREEN}🛡️  Configuring Fail2ban...${NC}"

# Create custom Fail2ban configuration
tee /etc/fail2ban/jail.local > /dev/null << EOF
# Fail2ban configuration for Flutter Expense Tracker
# Custom settings for production environment

[DEFAULT]
# Ban settings
bantime = $FAIL2BAN_BANTIME
findtime = $FAIL2BAN_FINDTIME
maxretry = $FAIL2BAN_MAXRETRY

# Backend for log parsing
backend = auto

# Email notifications (configure as needed)
destemail = root@localhost
sender = root@localhost
mta = sendmail

# Action when ban occurs
action = %(action_)s

# Ignore list (add your trusted IPs here)
ignoreip = 127.0.0.1/8 ::1

# Log level
loglevel = INFO
logtarget = /var/log/fail2ban.log

# SSH protection
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600

# Nginx HTTP authentication failures
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600

# Nginx rate limiting
[nginx-req-limit]
enabled = true
filter = nginx-req-limit
logpath = /var/log/nginx/error.log
maxretry = 10
findtime = 600
bantime = 3600

# Nginx bad bots and scanners
[nginx-bad-request]
enabled = true
filter = nginx-bad-request
logpath = /var/log/nginx/access.log
maxretry = 5
bantime = 86400

# Nginx DoS protection
[nginx-dos]
enabled = true
filter = nginx-dos
logpath = /var/log/nginx/access.log
maxretry = 300
findtime = 300
bantime = 600

# Recidive jail (repeat offenders)
[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
bantime = 604800
findtime = 86400
maxretry = 5
EOF

# Create custom Nginx filters for Fail2ban
mkdir -p /etc/fail2ban/filter.d

# Nginx request limiting filter
tee /etc/fail2ban/filter.d/nginx-req-limit.conf > /dev/null << 'EOF'
[Definition]
failregex = limiting requests, excess: .* by zone .*, client: <HOST>
ignoreregex =
EOF

# Nginx bad request filter
tee /etc/fail2ban/filter.d/nginx-bad-request.conf > /dev/null << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*" (400|401|403|404|444|499|500|502|503) .*$
ignoreregex =
EOF

# Nginx DoS filter
tee /etc/fail2ban/filter.d/nginx-dos.conf > /dev/null << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*" 200 .*$
ignoreregex =
EOF

echo -e "${GREEN}📊 Creating firewall monitoring script...${NC}"

# Create firewall monitoring script
tee /usr/local/bin/firewall-monitor.sh > /dev/null << 'EOF'
#!/bin/bash

# Firewall Monitoring Script for Flutter Expense Tracker
# Provides real-time monitoring and alerts

LOG_FILE="/var/log/firewall-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting firewall status check..." >> $LOG_FILE

# Check UFW status
UFW_STATUS=$(ufw status | grep "Status:" | awk '{print $2}')
echo "[$DATE] UFW Status: $UFW_STATUS" >> $LOG_FILE

if [ "$UFW_STATUS" != "active" ]; then
    echo "[$DATE] WARNING: UFW is not active!" >> $LOG_FILE
    # Add alert mechanism here (email, webhook, etc.)
fi

# Check Fail2ban status
FAIL2BAN_STATUS=$(systemctl is-active fail2ban)
echo "[$DATE] Fail2ban Status: $FAIL2BAN_STATUS" >> $LOG_FILE

if [ "$FAIL2BAN_STATUS" != "active" ]; then
    echo "[$DATE] WARNING: Fail2ban is not running!" >> $LOG_FILE
    # Add alert mechanism here
fi

# Log current banned IPs
BANNED_IPS=$(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | while read jail; do
    if [ -n "$jail" ]; then
        jail=$(echo $jail | xargs)  # trim whitespace
        fail2ban-client status "$jail" 2>/dev/null | grep "Banned IP list:" | cut -d: -f2
    fi
done | tr ' ' '\n' | sort -u | grep -v '^$')

if [ -n "$BANNED_IPS" ]; then
    echo "[$DATE] Currently banned IPs:" >> $LOG_FILE
    echo "$BANNED_IPS" | while read ip; do
        echo "[$DATE]   - $ip" >> $LOG_FILE
    done
else
    echo "[$DATE] No IPs currently banned" >> $LOG_FILE
fi

# Check recent connection attempts
RECENT_ATTEMPTS=$(grep "$(date '+%b %d')" /var/log/auth.log | grep "Failed password" | wc -l)
echo "[$DATE] Failed SSH attempts today: $RECENT_ATTEMPTS" >> $LOG_FILE

# Check disk space for logs
LOG_USAGE=$(df /var/log | tail -1 | awk '{print $5}' | sed 's/%//')
echo "[$DATE] Log disk usage: ${LOG_USAGE}%" >> $LOG_FILE

if [ "$LOG_USAGE" -gt 80 ]; then
    echo "[$DATE] WARNING: Log disk usage above 80%!" >> $LOG_FILE
    # Cleanup old logs
    find /var/log -name "*.log" -mtime +30 -delete
    find /var/log -name "*.gz" -mtime +90 -delete
fi

# Cleanup old monitoring logs
find /var/log -name "firewall-monitor.log" -size +10M -exec truncate -s 5M {} \;

echo "[$DATE] Firewall monitoring check completed" >> $LOG_FILE
EOF

chmod +x /usr/local/bin/firewall-monitor.sh

# Create firewall status script
tee /usr/local/bin/firewall-status.sh > /dev/null << 'EOF'
#!/bin/bash

# Firewall Status Display Script

echo "🔥 Firewall Status for Flutter Expense Tracker"
echo "==============================================="
echo ""

# UFW Status
echo "🛡️  UFW Firewall Status:"
ufw status verbose
echo ""

# Fail2ban Status
echo "🚫 Fail2ban Status:"
if systemctl is-active --quiet fail2ban; then
    echo "✅ Fail2ban is running"
    echo ""
    echo "📊 Jail Status:"
    fail2ban-client status
    echo ""
    
    # Show banned IPs for each jail
    JAILS=$(fail2ban-client status | grep "Jail list:" | cut -d: -f2 | tr ',' ' ')
    for jail in $JAILS; do
        jail=$(echo $jail | xargs)  # trim whitespace
        if [ -n "$jail" ]; then
            echo "🔒 Jail: $jail"
            fail2ban-client status "$jail" 2>/dev/null || echo "  No status available"
            echo ""
        fi
    done
else
    echo "❌ Fail2ban is not running"
fi

# Recent log activity
echo "📋 Recent Security Events:"
echo "Last 10 SSH failures:"
grep "Failed password" /var/log/auth.log | tail -10 | while read line; do
    echo "  $line"
done

echo ""
echo "Last 5 banned actions:"
tail -5 /var/log/fail2ban.log | grep "Ban " | while read line; do
    echo "  $line"
done

echo ""
echo "💾 Log File Sizes:"
ls -lh /var/log/auth.log /var/log/fail2ban.log /var/log/firewall-monitor.log 2>/dev/null || echo "Some log files not found"

echo ""
echo "🔧 Monitoring Commands:"
echo "  firewall-status.sh    - Show this status"
echo "  firewall-monitor.sh   - Run monitoring check"
echo "  ufw status numbered   - Show numbered rules"
echo "  fail2ban-client status - Fail2ban overview"
echo "  tail -f /var/log/fail2ban.log - Watch live bans"
EOF

chmod +x /usr/local/bin/firewall-status.sh

echo -e "${GREEN}⚙️  Creating automated firewall maintenance...${NC}"

# Add monitoring to crontab (run every 15 minutes)
(crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/firewall-monitor.sh") | crontab -

# Create systemd service for enhanced monitoring
tee /etc/systemd/system/firewall-monitor.service > /dev/null << 'EOF'
[Unit]
Description=Firewall Monitor Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/firewall-monitor.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create timer for the service
tee /etc/systemd/system/firewall-monitor.timer > /dev/null << 'EOF'
[Unit]
Description=Run Firewall Monitor every 15 minutes
Requires=firewall-monitor.service

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
systemctl daemon-reload
systemctl enable firewall-monitor.timer
systemctl start firewall-monitor.timer

echo -e "${GREEN}🚀 Starting firewall services...${NC}"

# Enable and start UFW
echo -e "${YELLOW}⚡ Enabling UFW firewall...${NC}"
ufw --force enable

# Start and enable Fail2ban
echo -e "${YELLOW}🚫 Starting Fail2ban...${NC}"
systemctl enable fail2ban
systemctl start fail2ban

# Wait a moment for services to start
sleep 3

echo -e "${GREEN}🧪 Testing firewall configuration...${NC}"

# Test UFW status
UFW_TEST=$(ufw status | grep "Status: active")
if [ -n "$UFW_TEST" ]; then
    echo -e "${GREEN}✅ UFW is active and configured${NC}"
else
    echo -e "${RED}❌ UFW configuration issue${NC}"
    exit 1
fi

# Test Fail2ban status
FAIL2BAN_TEST=$(systemctl is-active fail2ban)
if [ "$FAIL2BAN_TEST" = "active" ]; then
    echo -e "${GREEN}✅ Fail2ban is running${NC}"
else
    echo -e "${RED}❌ Fail2ban startup issue${NC}"
    exit 1
fi

# Show initial status
echo ""
echo -e "${GREEN}🎉 Production Firewall Setup Complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Configuration Summary:${NC}"
echo "• UFW Firewall: Active with restrictive rules"
echo "• SSH Port: $SSH_PORT (rate limited)"
echo "• Web Ports: 80, 443 (HTTP/HTTPS)"
echo "• Fail2ban: Active with custom Nginx protection"
echo "• Monitoring: Automated every 15 minutes"
echo ""
echo -e "${YELLOW}🔧 Management Commands:${NC}"
echo "• firewall-status.sh     - Show current status"
echo "• firewall-monitor.sh    - Run manual monitoring"
echo "• sudo ufw status        - UFW status"
echo "• sudo fail2ban-client status - Fail2ban status"
echo ""
echo -e "${YELLOW}📊 Current Status:${NC}"
ufw status numbered
echo ""
echo -e "${YELLOW}🚫 Fail2ban Jails:${NC}"
fail2ban-client status
echo ""
echo -e "${YELLOW}📁 Important Files:${NC}"
echo "• UFW rules: /etc/ufw/"
echo "• Fail2ban config: /etc/fail2ban/jail.local"
echo "• Monitoring logs: /var/log/firewall-monitor.log"
echo "• Fail2ban logs: /var/log/fail2ban.log"
echo ""
echo -e "${GREEN}🔒 Your server is now protected with production-grade firewall rules!${NC}"
echo -e "${YELLOW}⚠️  Remember: Test SSH access before closing this session!${NC}"

# Final security reminder
echo ""
echo -e "${RED}🚨 IMPORTANT SECURITY REMINDER:${NC}"
echo "1. Test SSH access from another terminal before closing this session"
echo "2. Add your trusted IP addresses to Fail2ban ignore list if needed"
echo "3. Monitor logs regularly: tail -f /var/log/fail2ban.log"
echo "4. Consider setting up email alerts for security events"
echo "5. Keep firewall rules updated as your application evolves"
