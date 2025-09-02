#!/bin/bash

# VPS Initial Setup Script for Expense Tracker CI/CD
# Run this script once on your VPS to prepare for automated deployments

set -e

echo "🚀 Setting up VPS for Expense Tracker CI/CD..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "🔧 Installing required packages..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    fail2ban

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo "🔨 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/expense-tracker
sudo chown $USER:$USER /opt/expense-tracker

# Clone repository (you'll need to configure SSH keys separately)
echo "📥 Setting up git repository..."
cd /opt/expense-tracker
# git clone your-repo-url .

# Create backup directory
echo "💾 Creating backup directory..."
sudo mkdir -p /opt/backups
sudo chown $USER:$USER /opt/backups

# Setup log rotation
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/docker-containers << EOF
/var/lib/docker/containers/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Configure fail2ban
echo "🛡️ Configuring fail2ban..."
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Setup SSL certificate (Let's Encrypt)
echo "🔒 Setting up SSL certificate..."
# Replace with your actual domain
# sudo certbot --nginx -d your-domain.com -d api.your-domain.com --non-interactive --agree-tos -m your-email@example.com

# Create systemd service for the application
echo "⚙️ Creating systemd service..."
sudo tee /etc/systemd/system/expense-tracker.service << EOF
[Unit]
Description=Expense Tracker Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/opt/expense-tracker
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl enable expense-tracker.service

# Setup monitoring (optional)
echo "📊 Setting up basic monitoring..."
# Install htop, iotop, etc.
sudo apt install -y htop iotop nethogs

# Create deployment script
echo "🚀 Creating deployment script..."
tee /opt/expense-tracker/deploy.sh << 'EOF'
#!/bin/bash

set -e

echo "🚀 Starting deployment..."

# Variables
APP_DIR="/opt/expense-tracker"
DOCKER_IMAGE="your-username/expense-tracker-backend:latest"
BACKUP_DIR="/opt/backups/$(date +%Y%m%d_%H%M%S)"

cd $APP_DIR

# Create backup
echo "📦 Creating backup..."
mkdir -p $BACKUP_DIR
docker exec expense-tracker-db pg_dump -U postgres expense_tracker > $BACKUP_DIR/database.sql || true

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Pull latest Docker image
echo "🔄 Pulling latest Docker image..."
docker pull $DOCKER_IMAGE

# Stop services
echo "⏹️ Stopping services..."
docker-compose down

# Start services
echo "▶️ Starting services..."
docker-compose up -d

# Health check
echo "🏥 Performing health check..."
sleep 30
for i in {1..5}; do
  if curl -f http://localhost:8000/health; then
    echo "✅ Health check passed!"
    break
  fi
  echo "⏳ Waiting for service to be ready..."
  sleep 10
done

# Cleanup old images
echo "🧹 Cleaning up old images..."
docker image prune -f

echo "🎉 Deployment completed successfully!"
EOF

chmod +x /opt/expense-tracker/deploy.sh

# Setup SSH key for GitHub Actions (you'll need to add this manually)
echo "🔑 Setting up SSH for GitHub Actions..."
echo "Please add your GitHub Actions SSH public key to ~/.ssh/authorized_keys"
echo "Generate the key pair and add the private key to GitHub Secrets as VPS_SSH_KEY"

# Setup monitoring dashboards (optional)
echo "📈 Setting up monitoring..."
# You can add Grafana, Prometheus, etc. here

# Final setup
echo "🏁 Final setup..."
sudo systemctl daemon-reload

echo ""
echo "✅ VPS setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Add SSH public key for GitHub Actions to ~/.ssh/authorized_keys"
echo "2. Configure your domain name and SSL certificate"
echo "3. Update docker-compose.yml with production environment variables"
echo "4. Test the deployment script manually"
echo "5. Configure GitHub repository secrets"
echo ""
echo "🔧 Useful commands:"
echo "- Check application status: sudo systemctl status expense-tracker"
echo "- View logs: docker-compose logs -f"
echo "- Manual deployment: ./deploy.sh"
echo "- Backup database: docker exec expense-tracker-db pg_dump -U postgres expense_tracker > backup.sql"
echo ""
