#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Expense Tracker VPS Setup Script${NC}"
echo "=========================================="

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

print_status "Starting VPS setup for Expense Tracker..."

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_status "Installing required packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
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
    
    print_status "Docker installed successfully!"
else
    print_status "Docker is already installed."
fi

# Install Docker Compose (standalone)
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed successfully!"
else
    print_status "Docker Compose is already installed."
fi

# Clone repository (if not already present)
if [ ! -d "/home/$(whoami)/flutter-expense-tracker" ]; then
    print_status "Cloning repository..."
    cd /home/$(whoami)
    git clone https://github.com/edwinfebrianto44-gif/flutter-expense-tracker.git
    cd flutter-expense-tracker
else
    print_status "Repository already exists, pulling latest changes..."
    cd /home/$(whoami)/flutter-expense-tracker
    git pull origin main
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p nginx/logs
mkdir -p certbot/conf
mkdir -p certbot/www
mkdir -p backend/logs

# Copy environment file
if [ ! -f ".env" ]; then
    print_status "Setting up environment configuration..."
    cp .env.production .env
    print_warning "Please edit the .env file with your actual configuration!"
    print_warning "Don't forget to change passwords and JWT secret!"
else
    print_status "Environment file already exists."
fi

# Set proper permissions
print_status "Setting permissions..."
chmod +x scripts/*.sh 2>/dev/null || true
sudo chown -R $(whoami):$(whoami) .

print_status "Basic setup completed!"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "1. Edit .env file with your actual configuration"
echo "2. Update domain name in nginx/conf.d/api.conf"
echo "3. Run: ./scripts/ssl-setup.sh to setup SSL certificates"
echo "4. Run: docker-compose up -d to start services"
echo ""
echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo "• Check status: docker-compose ps"
echo "• View logs: docker-compose logs -f [service]"
echo "• Stop services: docker-compose down"
echo "• Update services: docker-compose pull && docker-compose up -d"
echo ""
print_status "Setup script completed successfully!"

# Check if reboot is needed (for docker group)
if groups $USER | grep &>/dev/null '\bdocker\b'; then
    print_status "Docker group already active."
else
    print_warning "Please log out and log back in (or reboot) for docker group changes to take effect."
fi
