#!/bin/bash

# VPS Monitoring Setup Script
# Installs and configures Netdata for real-time monitoring

set -e

echo "🔧 Setting up VPS monitoring with Netdata..."

# Update system
sudo apt-get update

# Install dependencies
sudo apt-get install -y curl wget git

echo "📊 Installing Netdata..."

# Install Netdata using the kickstart script
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --stable-channel --disable-telemetry

echo "🔧 Configuring Netdata..."

# Create custom Netdata configuration
sudo tee /etc/netdata/netdata.conf > /dev/null << 'EOF'
[global]
    # Default settings
    run as user = netdata
    web files owner = root
    web files group = root
    
    # Bind to all interfaces (change for security)
    bind socket to IP = 0.0.0.0
    default port = 19999
    
    # Enable/disable features
    memory mode = ram
    page cache size = 32
    history = 3600
    
    # Performance settings
    update every = 1
    debug flags = 0x0000000000000000
    
[web]
    # Web server settings
    web files directory = /usr/share/netdata/web
    respect do not track policy = no
    allow connections from = localhost 10.* 192.168.* 172.16.* 172.17.* 172.18.* 172.19.* 172.20.* 172.21.* 172.22.* 172.23.* 172.24.* 172.25.* 172.26.* 172.27.* 172.28.* 172.29.* 172.30.* 172.31.*
    allow dashboard from = localhost 10.* 192.168.* 172.16.* 172.17.* 172.18.* 172.19.* 172.20.* 172.21.* 172.22.* 172.23.* 172.24.* 172.25.* 172.26.* 172.27.* 172.28.* 172.29.* 172.30.* 172.31.*
    
[registry]
    # Disable registry (cloud features)
    enabled = no
    
[health]
    # Health monitoring
    enabled = yes
    in memory max health log entries = 1000
    script to execute on alarm = /usr/libexec/netdata/plugins.d/alarm-notify.sh
    
EOF

# Configure alarm notifications
sudo tee /etc/netdata/health_alarm_notify.conf > /dev/null << 'EOF'
# Health alarm notification configuration

# Email notifications
SEND_EMAIL="YES"
DEFAULT_RECIPIENT_EMAIL="admin@yourdomain.com"
EMAIL_SENDER="netdata@yourdomain.com"

# Slack notifications (optional)
SEND_SLACK="NO"
SLACK_WEBHOOK_URL=""
DEFAULT_RECIPIENT_SLACK=""

# Discord notifications (optional) 
SEND_DISCORD="NO"
DISCORD_WEBHOOK_URL=""
DEFAULT_RECIPIENT_DISCORD=""

# Define severity levels
role_recipients_email[sysadmin]="admin@yourdomain.com"
role_recipients_email[domainadmin]="admin@yourdomain.com"
role_recipients_email[dba]="admin@yourdomain.com"
role_recipients_email[webmaster]="admin@yourdomain.com"

EOF

# Create custom health checks for the expense tracker application
sudo mkdir -p /etc/netdata/health.d

# Docker container health check
sudo tee /etc/netdata/health.d/docker.conf > /dev/null << 'EOF'
# Docker container health monitoring

template: docker_container_running
      on: docker.container_state
   class: Error
    type: Container
component: Docker
  lookup: max -10s unaligned
   units: boolean
   every: 10s
    crit: $this == 0
   delay: down 1m multiplier 1.5 max 1h
    info: Docker container is not running
      to: sysadmin

template: docker_container_health
      on: docker.container_health_status
   class: Error  
    type: Container
component: Docker
  lookup: max -30s unaligned
   units: boolean
   every: 10s
    warn: $this == 2
    crit: $this == 0
   delay: down 1m multiplier 1.5 max 1h
    info: Docker container health check failed
      to: sysadmin

EOF

# Web service health check
sudo tee /etc/netdata/health.d/web_log.conf > /dev/null << 'EOF'
# Web service monitoring

template: web_service_slow_response
      on: web_log.response_time
   class: Latency
    type: Web Server
component: Response time
  lookup: average -3m unaligned of avg
   units: milliseconds
   every: 10s
    warn: $this > 1000
    crit: $this > 5000
   delay: down 5m multiplier 1.5 max 1h
    info: Web service response time is high
      to: webmaster

template: web_service_5xx_errors
      on: web_log.response_codes
   class: Errors
    type: Web Server
component: Response codes
  lookup: sum -5m unaligned of 5xx
   units: requests/s
   every: 10s
    warn: $this > 5
    crit: $this > 20
   delay: down 1m multiplier 1.5 max 1h
    info: High number of 5xx errors detected
      to: webmaster

EOF

# Database monitoring (PostgreSQL)
sudo tee /etc/netdata/health.d/postgres.conf > /dev/null << 'EOF'
# PostgreSQL monitoring

template: postgres_connections_utilization
      on: postgres.connections_utilization
   class: Utilization
    type: Database
component: PostgreSQL
  lookup: average -1m unaligned
   units: %
   every: 10s
    warn: $this > 70
    crit: $this > 90
   delay: down 5m multiplier 1.5 max 1h
    info: PostgreSQL connection utilization is high
      to: dba

template: postgres_locks
      on: postgres.locks
   class: Errors
    type: Database  
component: PostgreSQL
  lookup: average -1m unaligned of waiting
   units: locks
   every: 10s
    warn: $this > 10
    crit: $this > 50
   delay: down 2m multiplier 1.5 max 1h
    info: PostgreSQL has many waiting locks
      to: dba

EOF

# System resource monitoring
sudo tee /etc/netdata/health.d/system.conf > /dev/null << 'EOF'
# System resource monitoring

template: disk_space_usage
      on: disk.space
   class: Utilization
    type: System
component: Disk
  lookup: average -1m unaligned of used
   units: %
   every: 10s
    warn: $this > 80
    crit: $this > 90
   delay: down 5m multiplier 1.5 max 1h
    info: Disk space usage is high
      to: sysadmin

template: memory_usage
      on: system.ram
   class: Utilization
    type: System
component: Memory
  lookup: average -1m unaligned of used
   units: %
   every: 10s
    warn: $this > 80
    crit: $this > 95
   delay: down 5m multiplier 1.5 max 1h
    info: Memory usage is high
      to: sysadmin

template: cpu_usage
      on: system.cpu
   class: Utilization
    type: System
component: CPU
  lookup: average -10m unaligned of user,system
   units: %
   every: 10s
    warn: $this > 80
    crit: $this > 95
   delay: down 15m multiplier 1.5 max 1h
    info: CPU usage is high
      to: sysadmin

EOF

# Configure firewall rule for Netdata
echo "🔥 Configuring firewall for Netdata..."
sudo ufw allow 19999/tcp comment "Netdata monitoring"

# Restart Netdata to apply configuration
echo "🔄 Restarting Netdata service..."
sudo systemctl restart netdata
sudo systemctl enable netdata

# Install additional monitoring tools
echo "🛠️ Installing additional monitoring tools..."

# Install htop for process monitoring
sudo apt-get install -y htop iotop nethogs

# Install log monitoring tools
sudo apt-get install -y logwatch fail2ban

# Configure fail2ban for additional security
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600  
maxretry = 5
backend = auto

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log

EOF

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Create monitoring dashboard script
sudo tee /usr/local/bin/monitoring-dashboard > /dev/null << 'EOF'
#!/bin/bash

# Simple monitoring dashboard script

echo "=== Expense Tracker Monitoring Dashboard ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo ""

echo "=== System Resources ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2 $3 $4 $5 $6 $7 $8}'

echo ""
echo "Memory Usage:"
free -h

echo ""
echo "Disk Usage:"
df -h | grep -E '^/dev/'

echo ""
echo "=== Docker Containers ==="
if command -v docker &> /dev/null; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "Docker not installed"
fi

echo ""
echo "=== Active Network Connections ==="
netstat -tuln | grep LISTEN | head -10

echo ""
echo "=== Recent Log Entries ==="
echo "--- Nginx Access Log (last 5 entries) ---"
tail -5 /var/log/nginx/access.log 2>/dev/null || echo "Nginx logs not found"

echo ""
echo "--- System Log (last 5 entries) ---"
tail -5 /var/log/syslog

echo ""
echo "=== Service Status ==="
services=("nginx" "netdata" "docker" "postgresql" "fail2ban")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service: Active"
    else
        echo "❌ $service: Inactive"
    fi
done

echo ""
echo "=== Monitoring URLs ==="
echo "Netdata Dashboard: http://$(hostname -I | awk '{print $1}'):19999"
echo "Application Health: http://$(hostname -I | awk '{print $1}'):8000/health"

EOF

sudo chmod +x /usr/local/bin/monitoring-dashboard

# Create automated monitoring script
sudo tee /usr/local/bin/auto-monitor > /dev/null << 'EOF'
#!/bin/bash

# Automated monitoring and alerting script

LOG_FILE="/var/log/auto-monitor.log"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=80  
ALERT_THRESHOLD_DISK=85

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

check_system_resources() {
    # Check CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    CPU_USAGE=${CPU_USAGE%.*}
    
    if [ "$CPU_USAGE" -gt "$ALERT_THRESHOLD_CPU" ]; then
        log_message "ALERT: High CPU usage: ${CPU_USAGE}%"
    fi
    
    # Check memory usage
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    
    if [ "$MEMORY_USAGE" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
        log_message "ALERT: High memory usage: ${MEMORY_USAGE}%"
    fi
    
    # Check disk usage
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$DISK_USAGE" -gt "$ALERT_THRESHOLD_DISK" ]; then
        log_message "ALERT: High disk usage: ${DISK_USAGE}%"
    fi
}

check_docker_containers() {
    if command -v docker &> /dev/null; then
        # Check if containers are running
        STOPPED_CONTAINERS=$(docker ps -f "status=exited" --format "{{.Names}}" | wc -l)
        
        if [ "$STOPPED_CONTAINERS" -gt 0 ]; then
            log_message "ALERT: $STOPPED_CONTAINERS Docker container(s) stopped"
        fi
    fi
}

check_application_health() {
    # Check application health endpoint
    HEALTH_URL="http://localhost:8000/health"
    
    if curl -s --max-time 10 "$HEALTH_URL" | grep -q "healthy"; then
        log_message "INFO: Application health check passed"
    else
        log_message "ALERT: Application health check failed"
    fi
}

# Run checks
check_system_resources
check_docker_containers  
check_application_health

log_message "Monitoring check completed"

EOF

sudo chmod +x /usr/local/bin/auto-monitor

# Add monitoring script to crontab (runs every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/auto-monitor") | crontab -

# Create backup script for monitoring logs
sudo tee /usr/local/bin/cleanup-logs > /dev/null << 'EOF'
#!/bin/bash

# Log cleanup script - runs weekly

# Rotate and compress old logs
find /var/log -name "*.log" -size +100M -exec gzip {} \;

# Clean up old compressed logs (older than 30 days)
find /var/log -name "*.gz" -mtime +30 -delete

# Clean up old monitoring logs
find /var/log -name "auto-monitor.log.*" -mtime +7 -delete

# Restart services to refresh log files
systemctl reload nginx
systemctl restart netdata

echo "Log cleanup completed at $(date)" >> /var/log/cleanup.log

EOF

sudo chmod +x /usr/local/bin/cleanup-logs

# Add log cleanup to weekly cron
(sudo crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/local/bin/cleanup-logs") | sudo crontab -

echo "✅ Netdata monitoring setup completed!"
echo ""
echo "📊 Monitoring Dashboard: http://$(hostname -I | awk '{print $1}'):19999"
echo "🖥️  Quick Status: monitoring-dashboard"
echo "📝 Auto Monitor Log: /var/log/auto-monitor.log"
echo ""
echo "🔧 Next Steps:"
echo "1. Configure email notifications in /etc/netdata/health_alarm_notify.conf"
echo "2. Set up HTTPS for Netdata dashboard"
echo "3. Configure firewall rules as needed"
echo "4. Test monitoring alerts"
echo ""
echo "📖 Netdata Documentation: https://learn.netdata.cloud/"
