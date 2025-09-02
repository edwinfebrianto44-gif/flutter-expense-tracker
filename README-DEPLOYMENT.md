# 🚀 VPS Deployment Guide - Expense Tracker

Complete guide for deploying Expense Tracker FastAPI backend + MySQL on Ubuntu VPS with Docker, Nginx reverse proxy, and SSL certificates.

## 📋 Prerequisites

- Ubuntu 20.04+ VPS with root access
- Domain name (e.g., `api.expensetracker.com`)
- Domain pointing to your VPS IP address
- Minimum 2GB RAM, 20GB storage

## 🎯 Deployment Overview

This deployment includes:
- **FastAPI Backend** with Gunicorn + Uvicorn workers
- **MySQL 8.0** with persistent data storage
- **Nginx** reverse proxy with SSL termination
- **Adminer** for database management
- **Let's Encrypt SSL** with automatic renewal
- **Monitoring & Backup** scripts

## 🚀 Quick Deploy (Automated)

### 1. Connect to your VPS
```bash
ssh root@your-vps-ip
# or
ssh username@your-vps-ip
```

### 2. Run the automated setup
```bash
# Download and run setup script
curl -fsSL https://raw.githubusercontent.com/yourusername/flutter-expense-tracker/main/scripts/setup-vps.sh | bash

# Or clone repository first
git clone https://github.com/yourusername/flutter-expense-tracker.git
cd flutter-expense-tracker
chmod +x scripts/*.sh
./scripts/setup-vps.sh
```

### 3. Configure environment
```bash
# Edit environment variables
nano .env

# Update these important values:
MYSQL_ROOT_PASSWORD=your_secure_password
MYSQL_PASSWORD=your_secure_password
JWT_SECRET_KEY=your_super_secure_jwt_secret_key
DOMAIN=api.expensetracker.com
EMAIL=your-email@domain.com
```

### 4. Setup SSL certificates
```bash
./scripts/ssl-setup.sh
```

### 5. Deploy the application
```bash
./scripts/deploy.sh
```

## 🔧 Manual Setup (Step by Step)

### Step 1: Prepare the VPS

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
```

### Step 2: Install Docker

```bash
# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose (standalone)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Step 3: Clone and Setup Repository

```bash
# Clone repository
git clone https://github.com/yourusername/flutter-expense-tracker.git
cd flutter-expense-tracker

# Create necessary directories
mkdir -p nginx/logs certbot/conf certbot/www backend/logs

# Setup environment
cp .env.production .env
nano .env  # Edit with your configurations
```

### Step 4: Configure Domain DNS

Point your domain to your VPS IP address:
```bash
# Check your VPS IP
curl ifconfig.me

# DNS records needed:
# A record: api.expensetracker.com -> YOUR_VPS_IP
```

### Step 5: Deploy Services

```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Step 6: Setup SSL Certificate

```bash
# First, ensure your domain points to this server
nslookup api.expensetracker.com

# Request SSL certificate
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email your-email@domain.com \
    --agree-tos \
    --no-eff-email \
    -d api.expensetracker.com

# Restart nginx with SSL
docker-compose restart nginx
```

## 📁 Project Structure

```
flutter-expense-tracker/
├── backend/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── app/                 # FastAPI application
├── nginx/
│   ├── nginx.conf          # Main nginx config
│   └── conf.d/
│       └── api.conf        # Site-specific config
├── scripts/
│   ├── setup-vps.sh        # VPS setup automation
│   ├── ssl-setup.sh        # SSL certificate setup
│   ├── deploy.sh           # Deployment script
│   ├── monitor.sh          # System monitoring
│   ├── backup.sh           # Database backup
│   └── restore.sh          # Database restore
├── docker-compose.yml      # Services configuration
├── .env.production         # Production environment template
└── README-DEPLOYMENT.md    # This file
```

## 🔌 Service Endpoints

After successful deployment:

| Service | URL | Description |
|---------|-----|-------------|
| API Documentation | `https://api.expensetracker.com/docs` | Swagger UI |
| API Health Check | `https://api.expensetracker.com/health` | Health status |
| Database Admin | `http://your-vps-ip:8080` | Adminer interface |

## 🛠️ Management Commands

### Service Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart backend

# View logs
docker-compose logs -f backend
docker-compose logs -f nginx
docker-compose logs -f mysql

# Check service status
docker-compose ps
```

### Database Management
```bash
# Access MySQL CLI
docker-compose exec mysql mysql -u root -p

# Run migrations
docker-compose exec backend python -c "
from alembic import command
from alembic.config import Config
config = Config('/app/alembic.ini')
command.upgrade(config, 'head')
"

# Backup database
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh ./backups/backup_file.tar.gz
```

### SSL Certificate Management
```bash
# Check certificate status
docker-compose exec certbot certbot certificates

# Renew certificates (automatic, but can be manual)
docker-compose exec certbot certbot renew

# Test renewal process
docker-compose exec certbot certbot renew --dry-run
```

## 📊 Monitoring & Maintenance

### System Monitoring
```bash
# Run system monitor
./scripts/monitor.sh

# Check resource usage
docker stats

# Check disk usage
df -h
du -sh ./*
```

### Log Management
```bash
# View recent API logs
docker-compose logs --tail=100 backend

# View nginx access logs
docker-compose exec nginx tail -f /var/log/nginx/access.log

# View nginx error logs
docker-compose exec nginx tail -f /var/log/nginx/error.log
```

### Backup Strategy
```bash
# Manual backup
./scripts/backup.sh

# Setup automated daily backup (crontab)
crontab -e
# Add: 0 2 * * * /path/to/flutter-expense-tracker/scripts/backup.sh
```

## 🔐 Security Configuration

### Firewall Setup
```bash
# Install UFW
sudo apt install ufw

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8080/tcp  # For Adminer (optional, can be restricted)

# Enable firewall
sudo ufw enable
```

### Security Headers
The Nginx configuration includes security headers:
- HSTS (HTTP Strict Transport Security)
- X-Frame-Options
- X-XSS-Protection
- X-Content-Type-Options
- Content Security Policy

### Rate Limiting
- API endpoints: 10 requests/second
- Login endpoints: 5 requests/minute
- Configurable in `nginx/conf.d/api.conf`

## 🚨 Troubleshooting

### Common Issues

**1. SSL Certificate Issues**
```bash
# Check if domain points to server
nslookup api.expensetracker.com

# Check if port 80 is accessible
curl http://api.expensetracker.com/.well-known/acme-challenge/test

# Check certificate files
ls -la ./certbot/conf/live/api.expensetracker.com/
```

**2. Database Connection Issues**
```bash
# Check MySQL container
docker-compose logs mysql

# Test database connection
docker-compose exec backend python -c "
from app.core.database import engine
try:
    conn = engine.connect()
    print('Database connection successful')
    conn.close()
except Exception as e:
    print(f'Database connection failed: {e}')
"
```

**3. API Not Responding**
```bash
# Check backend container
docker-compose logs backend

# Check if backend is accessible from nginx
docker-compose exec nginx curl http://backend:8000/health

# Check nginx configuration
docker-compose exec nginx nginx -t
```

**4. High Memory Usage**
```bash
# Check container memory usage
docker stats

# Restart services to free memory
docker-compose restart

# Check for memory leaks in logs
docker-compose logs backend | grep -i memory
```

### Log Locations
- Backend logs: `docker-compose logs backend`
- Nginx logs: `./nginx/logs/`
- MySQL logs: `docker-compose logs mysql`
- Certbot logs: `docker-compose logs certbot`

## 🔄 Updates and Maintenance

### Update Application
```bash
# Pull latest code
git pull origin main

# Deploy updates
./scripts/deploy.sh
```

### Update Docker Images
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d --force-recreate
```

### Database Migrations
```bash
# Create new migration
docker-compose exec backend alembic revision --autogenerate -m "Description"

# Apply migrations
docker-compose exec backend alembic upgrade head
```

## 💾 Backup and Recovery

### Automated Backup
The backup script creates:
- Database dump
- SSL certificates
- Configuration files
- Compressed archive with timestamp

### Restore Process
1. Stop services: `docker-compose down`
2. Run restore script: `./scripts/restore.sh backup_file.tar.gz`
3. Verify services: `./scripts/monitor.sh`

## 📞 Support

### Health Checks
- API Health: `https://api.expensetracker.com/health`
- Database: Check in Adminer or run monitor script
- SSL: Check certificate expiry dates

### Performance Monitoring
- Use `./scripts/monitor.sh` for system overview
- Monitor Docker stats: `docker stats`
- Check API response times in nginx logs

## 🎉 Success Indicators

Your deployment is successful when:
- ✅ All containers are running: `docker-compose ps`
- ✅ API responds: `curl https://api.expensetracker.com/health`
- ✅ SSL certificate is valid: `curl -I https://api.expensetracker.com`
- ✅ Database is accessible via Adminer
- ✅ API documentation loads: `https://api.expensetracker.com/docs`

---

## 📋 Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | MySQL root password | `secure_root_pass_2025` |
| `MYSQL_DATABASE` | Database name | `expense_tracker` |
| `MYSQL_USER` | Application database user | `expense_user` |
| `MYSQL_PASSWORD` | Application database password | `secure_db_pass_2025` |
| `JWT_SECRET_KEY` | JWT signing secret | `super-secure-jwt-secret...` |
| `DOMAIN` | Your API domain | `api.expensetracker.com` |
| `EMAIL` | Email for Let's Encrypt | `admin@expensetracker.com` |

**🔥 Production Ready Deployment Complete!**
