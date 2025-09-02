#!/bin/bash

# VPS Monitoring Setup with Prometheus + Grafana
# Alternative to Netdata for more advanced monitoring

set -e

echo "🔧 Setting up VPS monitoring with Prometheus + Grafana..."

# Update system
sudo apt-get update
sudo apt-get install -y curl wget git

# Create monitoring user
sudo useradd --no-create-home --shell /bin/false prometheus
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo useradd --no-create-home --shell /bin/false grafana

# Create directories
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

echo "📊 Installing Prometheus..."

# Download and install Prometheus
PROMETHEUS_VERSION="2.45.0"
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# Copy binaries
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Copy console files
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

# Create Prometheus configuration
sudo tee /etc/prometheus/prometheus.yml > /dev/null << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'expense-tracker-api'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:9113']

  - job_name: 'postgres'
    static_configs:
      - targets: ['localhost:9187']

EOF

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# Create alert rules
sudo tee /etc/prometheus/alerts.yml > /dev/null << 'EOF'
groups:
- name: expense_tracker_alerts
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."

  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: "CPU usage is above 80% for more than 2 minutes."

  - alert: HighMemoryUsage
    expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage on {{ $labels.instance }}"
      description: "Memory usage is above 80% for more than 2 minutes."

  - alert: DiskSpaceLow
    expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 85
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Disk space low on {{ $labels.instance }}"
      description: "Disk usage is above 85%."

  - alert: ApplicationDown
    expr: up{job="expense-tracker-api"} == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Expense Tracker API is down"
      description: "The Expense Tracker API has been down for more than 1 minute."

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "High response time for {{ $labels.instance }}"
      description: "95th percentile response time is above 2 seconds."

EOF

sudo chown prometheus:prometheus /etc/prometheus/alerts.yml

# Create Prometheus systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

echo "📊 Installing Node Exporter..."

# Download and install Node Exporter
NODE_EXPORTER_VERSION="1.6.0"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

sudo cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create Node Exporter systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "📊 Installing Grafana..."

# Install Grafana
sudo apt-get install -y software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

sudo apt-get update
sudo apt-get install -y grafana

# Configure Grafana
sudo tee /etc/grafana/grafana.ini > /dev/null << 'EOF'
[server]
protocol = http
http_addr = 0.0.0.0
http_port = 3000
domain = localhost
enforce_domain = false
root_url = %(protocol)s://%(domain)s:%(http_port)s/
serve_from_sub_path = false

[database]
type = sqlite3
path = grafana.db

[users]
allow_sign_up = false
allow_org_create = false
default_theme = dark

[auth.anonymous]
enabled = false

[security]
admin_user = admin
admin_password = admin123
secret_key = SW2YcwTIb9zpOOhoPsMm
disable_gravatar = true

[snapshots]
external_enabled = false

[analytics]
reporting_enabled = false
check_for_updates = false

[log]
mode = file
level = info
EOF

echo "📊 Installing additional exporters..."

# Install PostgreSQL Exporter
POSTGRES_EXPORTER_VERSION="0.13.2"
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64.tar.gz

sudo cp postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64/postgres_exporter /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/postgres_exporter

# Create PostgreSQL Exporter systemd service
sudo tee /etc/systemd/system/postgres_exporter.service > /dev/null << 'EOF'
[Unit]
Description=PostgreSQL Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
Environment=DATA_SOURCE_NAME=postgresql://postgres:password@localhost:5432/expense_tracker?sslmode=disable
ExecStart=/usr/local/bin/postgres_exporter

[Install]
WantedBy=multi-user.target
EOF

# Install Nginx Exporter
NGINX_EXPORTER_VERSION="0.11.0"
cd /tmp
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VERSION}/nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz
tar xvf nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz

sudo cp nginx-prometheus-exporter /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/nginx-prometheus-exporter

# Create Nginx Exporter systemd service
sudo tee /etc/systemd/system/nginx_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Nginx Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost/nginx_status

[Install]
WantedBy=multi-user.target
EOF

# Configure Nginx for metrics
sudo tee -a /etc/nginx/sites-available/default > /dev/null << 'EOF'

# Nginx status endpoint for monitoring
server {
    listen 127.0.0.1:80;
    server_name localhost;

    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

echo "🔥 Configuring firewall..."

# Configure firewall
sudo ufw allow 9090/tcp comment "Prometheus"
sudo ufw allow 3000/tcp comment "Grafana"
sudo ufw allow 9100/tcp comment "Node Exporter"

echo "🔄 Starting services..."

# Reload systemd and start services
sudo systemctl daemon-reload

# Start and enable Prometheus
sudo systemctl start prometheus
sudo systemctl enable prometheus

# Start and enable Node Exporter
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Start and enable Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server

# Start PostgreSQL Exporter (if PostgreSQL is configured)
sudo systemctl start postgres_exporter || echo "PostgreSQL exporter failed to start - check database connection"
sudo systemctl enable postgres_exporter

# Start Nginx Exporter (if Nginx is configured)
sudo systemctl start nginx_exporter || echo "Nginx exporter failed to start - check nginx configuration"
sudo systemctl enable nginx_exporter

# Restart Nginx to apply changes
sudo systemctl reload nginx || echo "Nginx reload failed"

echo "📊 Creating Grafana dashboard..."

# Wait for Grafana to start
sleep 10

# Create Grafana dashboard via API
curl -X POST \
  http://admin:admin123@localhost:3000/api/datasources \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://localhost:9090",
    "access": "proxy",
    "isDefault": true
  }' || echo "Failed to create Prometheus datasource"

# Create dashboard configuration
sudo tee /tmp/expense-tracker-dashboard.json > /dev/null << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Expense Tracker Monitoring",
    "tags": ["expense-tracker"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "System CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[2m])) * 100)",
            "legendFormat": "CPU Usage %"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "graph", 
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "Memory Usage %"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "30s"
  },
  "overwrite": true
}
EOF

# Import dashboard
curl -X POST \
  http://admin:admin123@localhost:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d @/tmp/expense-tracker-dashboard.json || echo "Failed to create dashboard"

# Create monitoring check script
sudo tee /usr/local/bin/prometheus-check > /dev/null << 'EOF'
#!/bin/bash

echo "=== Prometheus + Grafana Monitoring Status ==="
echo "Date: $(date)"
echo ""

echo "=== Service Status ==="
services=("prometheus" "node_exporter" "grafana-server" "postgres_exporter" "nginx_exporter")
for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "✅ $service: Active"
    else
        echo "❌ $service: Inactive"
    fi
done

echo ""
echo "=== Monitoring URLs ==="
echo "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo "Grafana: http://$(hostname -I | awk '{print $1}'):3000 (admin/admin123)"
echo "Node Exporter: http://$(hostname -I | awk '{print $1}'):9100/metrics"

echo ""
echo "=== Quick Metrics ==="
echo "Targets Status:"
curl -s http://localhost:9090/api/v1/targets | grep -o '"health":"[^"]*"' | sort | uniq -c

EOF

sudo chmod +x /usr/local/bin/prometheus-check

# Clean up temporary files
rm -f /tmp/prometheus-*.tar.gz
rm -f /tmp/node_exporter-*.tar.gz
rm -f /tmp/postgres_exporter-*.tar.gz
rm -f /tmp/nginx-prometheus-exporter_*.tar.gz
rm -f /tmp/expense-tracker-dashboard.json

echo "✅ Prometheus + Grafana monitoring setup completed!"
echo ""
echo "📊 Access URLs:"
echo "  Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo "  Grafana: http://$(hostname -I | awk '{print $1}'):3000"
echo "  Default login: admin / admin123"
echo ""
echo "🔧 Commands:"
echo "  Status check: prometheus-check"
echo "  View logs: journalctl -u prometheus -f"
echo ""
echo "📖 Next Steps:"
echo "1. Change default Grafana password"
echo "2. Configure PostgreSQL database connection for postgres_exporter"
echo "3. Set up SSL certificates for production"
echo "4. Configure alerting rules as needed"
echo "5. Set up notification channels (email, slack, etc.)"
