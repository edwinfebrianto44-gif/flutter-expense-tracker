#!/bin/bash

# Cleanup script for Phase 15 - Remove unused documentation files
# Keeps only essential files for portfolio presentation

set -e

PROJECT_ROOT="/workspaces/flutter-expense-tracker"
BACKUP_DIR="$PROJECT_ROOT/backup-$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Files to keep (essential for portfolio)
KEEP_FILES=(
    "README.md"
    "LICENSE"
    "CONTRIBUTING.md"
    "backend/README.md"
    "mobile-app/README.md"
    "mobile-app/CHANGELOG.md"
    "mobile-app/DEPLOYMENT.md"
    "mobile-app/SUMMARY.md"
    "backend/PHASE_7_FILE_UPLOAD.md"
)

# Files to remove (phase documentation and temporary files)
REMOVE_FILES=(
    "ALL_PHASES_STATUS.md"
    "API_DOCUMENTATION.md"
    "BACKEND_SETUP_COMPLETE.md"
    "PHASE_12_CI_CD.md"
    "PHASE_13_COMPLETION_SUMMARY.md"
    "PHASE_13_OBSERVABILITY.md"
    "PHASE_14_HARDENING_COMPLETE.md"
    "PHASE_8_REPORTING_ANALYTICS.md"
    "PHASE_9_NOTIFICATIONS.md"
    "PROJECT_OVERVIEW.md"
    "README-DEPLOYMENT.md"
    "SECURITY_IMPLEMENTATION.md"
    "VPS_DEPLOYMENT_COMPLETE.md"
    "mobile-app/android-signing-setup.md"
)

# Create backup directory
create_backup() {
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    log_success "Backup directory created"
}

# Backup files before deletion
backup_files() {
    log_info "Backing up files to be removed..."
    
    cd "$PROJECT_ROOT"
    
    for file in "${REMOVE_FILES[@]}"; do
        if [ -f "$file" ]; then
            log_info "Backing up: $file"
            # Create directory structure in backup
            backup_path="$BACKUP_DIR/$(dirname "$file")"
            mkdir -p "$backup_path"
            cp "$file" "$BACKUP_DIR/$file"
        fi
    done
    
    log_success "Files backed up to: $BACKUP_DIR"
}

# Remove unnecessary files
cleanup_files() {
    log_info "Removing unnecessary documentation files..."
    
    cd "$PROJECT_ROOT"
    
    local removed_count=0
    
    for file in "${REMOVE_FILES[@]}"; do
        if [ -f "$file" ]; then
            log_info "Removing: $file"
            rm "$file"
            ((removed_count++))
        else
            log_warning "File not found: $file"
        fi
    done
    
    log_success "Removed $removed_count files"
}

# Clean up empty directories
cleanup_directories() {
    log_info "Cleaning up empty directories..."
    
    cd "$PROJECT_ROOT"
    
    # Remove empty directories (but keep essential structure)
    find . -type d -empty -not -path "./.git*" -not -path "./node_modules*" -not -path "./assets*" -delete 2>/dev/null || true
    
    log_success "Empty directories cleaned"
}

# Clean up cache and temporary files
cleanup_cache() {
    log_info "Cleaning up cache and temporary files..."
    
    cd "$PROJECT_ROOT"
    
    # Flutter cache
    if [ -d "mobile-app" ]; then
        cd mobile-app
        flutter clean > /dev/null 2>&1 || true
        cd ..
    fi
    
    # Python cache
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.pyo" -delete 2>/dev/null || true
    
    # Node.js cache (if any)
    find . -type d -name "node_modules" -exec rm -rf {} + 2>/dev/null || true
    
    # Docker cache (build context files)
    find . -name ".dockerignore" -not -path "./.git/*" -delete 2>/dev/null || true
    
    # Temporary files
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*.log" -not -path "./storage/*" -delete 2>/dev/null || true
    
    # IDE files
    find . -name ".vscode" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name ".idea" -type d -exec rm -rf {} + 2>/dev/null || true
    
    log_success "Cache and temporary files cleaned"
}

# Optimize git repository
optimize_git() {
    log_info "Optimizing git repository..."
    
    cd "$PROJECT_ROOT"
    
    # Git garbage collection
    git gc --aggressive --prune=now > /dev/null 2>&1 || true
    
    # Remove untracked files (with confirmation)
    if git status --porcelain | grep -q "^??"; then
        log_warning "Found untracked files:"
        git status --porcelain | grep "^??" | head -5
        read -p "Remove all untracked files? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git clean -fd
            log_success "Untracked files removed"
        fi
    fi
    
    log_success "Git repository optimized"
}

# Create final project structure documentation
create_structure_doc() {
    log_info "Creating final project structure documentation..."
    
    cd "$PROJECT_ROOT"
    
    cat > PROJECT_STRUCTURE.md << 'EOF'
# 📁 Project Structure

This document outlines the final structure of the Flutter Expense Tracker project after Phase 15 cleanup.

## 🏗️ Root Directory
```
flutter-expense-tracker/
├── README.md                 # Main project documentation
├── LICENSE                   # MIT license
├── docker-compose.yml        # Docker services configuration
├── PROJECT_STRUCTURE.md      # This file
├── backend/                  # FastAPI backend application
├── mobile-app/              # Flutter mobile & web application
├── nginx/                   # Nginx configuration
├── scripts/                 # Deployment and utility scripts
├── storage/                 # File storage directory
├── db/                      # Database schema and seeds
└── assets/                  # Project assets (screenshots, GIFs)
```

## 🔧 Backend (`/backend/`)
```
backend/
├── Dockerfile               # Backend container configuration
├── main.py                  # FastAPI application entry point
├── requirements.txt         # Python dependencies
├── README.md               # Backend-specific documentation
├── alembic.ini             # Database migration configuration
├── pytest.ini             # Test configuration
├── app/                    # Application source code
│   ├── core/              # Core functionality (auth, config, etc.)
│   ├── models/            # SQLAlchemy models
│   ├── schemas/           # Pydantic schemas
│   ├── routes/            # API route handlers
│   ├── crud/              # Database operations
│   ├── services/          # Business logic services
│   └── tests/             # Test files
├── migrations/            # Alembic database migrations
└── storage/              # File upload storage
```

## 📱 Mobile App (`/mobile-app/`)
```
mobile-app/
├── pubspec.yaml            # Flutter dependencies
├── README.md              # Mobile app documentation
├── CHANGELOG.md           # Version history
├── DEPLOYMENT.md          # Deployment instructions
├── lib/                   # Dart source code
│   ├── main.dart         # Application entry point
│   ├── core/             # Core utilities and configuration
│   ├── models/           # Data models
│   ├── services/         # API and business services
│   ├── providers/        # State management
│   ├── screens/          # UI screens
│   ├── widgets/          # Reusable UI components
│   └── utils/            # Utility functions
├── assets/               # Images, icons, fonts
├── test/                 # Unit and widget tests
├── integration_test/     # Integration tests
├── android/             # Android-specific configuration
└── ios/                 # iOS-specific configuration
```

## 🚀 Deployment (`/scripts/`)
```
scripts/
├── deploy-production.sh    # Full production deployment
├── setup-demo-data.sh     # Demo account and data setup
├── backup-system.sh       # Automated backup system
├── ssl-setup-production.sh # SSL certificate setup
├── firewall-setup.sh      # Security configuration
└── monitor.sh            # System monitoring
```

## 🎨 Assets (`/assets/`)
```
assets/
├── screenshots/           # Application screenshots
│   ├── mobile-*.png      # Mobile app screenshots
│   └── web-*.png         # Web app screenshots
└── gifs/                 # Demo GIFs
    ├── add-transaction-demo.gif
    └── analytics-demo.gif
```

## 🗄️ Database (`/db/`)
```
db/
└── schema_and_seed.sql    # Database schema and initial data
```

## 🌐 Nginx (`/nginx/`)
```
nginx/
├── nginx.conf            # Main Nginx configuration
└── conf.d/              # Site-specific configurations
    └── api.conf         # API proxy configuration
```

## 🔄 Docker Configuration
- `docker-compose.yml` - Development environment
- `docker-compose.prod.yml` - Production environment
- `backend/Dockerfile` - Backend container image

## 📦 Key Dependencies

### Backend (Python)
- **FastAPI** - Modern web framework
- **SQLAlchemy** - ORM for database operations
- **Alembic** - Database migrations
- **Pydantic** - Data validation
- **PyJWT** - JWT authentication
- **Pytest** - Testing framework

### Frontend (Flutter)
- **Provider/Riverpod** - State management
- **Dio** - HTTP client
- **FL Chart** - Data visualization
- **Hive** - Local storage
- **Flutter Intl** - Internationalization

### Infrastructure
- **PostgreSQL** - Primary database
- **Redis** - Caching and sessions
- **Nginx** - Reverse proxy and static files
- **Docker** - Containerization
- **Let's Encrypt** - SSL certificates

## 🎯 Production Domains
- **Frontend:** https://app.expensetracker.com
- **Backend API:** https://api.expensetracker.com
- **Demo Account:** demo@demo.com / password123

## 📋 Development Workflow
1. **Backend Development:** Use FastAPI with hot reload
2. **Frontend Development:** Use Flutter hot reload
3. **Testing:** Run pytest (backend) and flutter test (frontend)
4. **Deployment:** Use deployment scripts for production

## 🔒 Security Features
- JWT authentication with refresh tokens
- SSL/TLS encryption (A+ grade)
- Rate limiting and DDoS protection
- Input validation and sanitization
- Secure file upload handling
- Firewall configuration

## 📊 Performance Optimizations
- Database indexing and query optimization
- Redis caching for frequently accessed data
- Nginx gzip compression
- Static asset caching
- Image optimization and lazy loading

## 🛠️ Maintenance
- Automated backups with encryption
- Log rotation and monitoring
- SSL certificate auto-renewal
- Database migration management
- Health checks and alerting
EOF
    
    log_success "Project structure documentation created"
}

# Display cleanup summary
show_summary() {
    echo
    log_success "🧹 Cleanup completed successfully!"
    echo
    log_info "Summary:"
    log_info "• Backed up files to: $BACKUP_DIR"
    log_info "• Removed unnecessary documentation files"
    log_info "• Cleaned cache and temporary files"
    log_info "• Optimized git repository"
    log_info "• Created PROJECT_STRUCTURE.md"
    echo
    log_info "Portfolio-ready structure:"
    log_info "• README.md - Comprehensive project documentation"
    log_info "• assets/ - Screenshots and GIFs directory"
    log_info "• scripts/ - Production deployment scripts"
    log_info "• PROJECT_STRUCTURE.md - Project organization guide"
    echo
    log_info "Next steps:"
    log_info "1. Add screenshots to assets/screenshots/"
    log_info "2. Create demo GIFs in assets/gifs/"
    log_info "3. Run deployment script: ./scripts/deploy-production.sh"
    log_info "4. Test demo account functionality"
}

# Main function
main() {
    log_info "🧹 Starting Phase 15 cleanup..."
    echo
    
    cd "$PROJECT_ROOT"
    
    # Confirmation
    log_warning "This will remove development documentation files and clean up the project."
    log_warning "A backup will be created before any files are removed."
    read -p "Continue with cleanup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
    
    create_backup
    backup_files
    cleanup_files
    cleanup_directories
    cleanup_cache
    optimize_git
    create_structure_doc
    show_summary
}

# Error handling
trap 'log_error "Cleanup failed on line $LINENO"' ERR

# Run main function
main "$@"
