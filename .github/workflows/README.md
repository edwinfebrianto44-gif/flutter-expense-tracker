# CI/CD Pipeline Documentation

## Overview

This project uses GitHub Actions for automated CI/CD pipelines with three main workflows:

1. **Backend CI/CD** (`backend-ci-cd.yml`) - FastAPI backend pipeline
2. **Frontend CI/CD** (`frontend-ci-cd.yml`) - Flutter mobile and web pipeline  
3. **Full Stack CI/CD** (`full-stack-ci-cd.yml`) - Orchestrates both pipelines

## Backend Pipeline Features

### 🧪 Testing & Quality
- **Linting**: flake8 for code style and syntax checking
- **Type Checking**: mypy for static type analysis
- **Security**: Bandit for security vulnerability scanning
- **Unit Tests**: pytest with coverage reporting
- **Database Tests**: PostgreSQL service for integration tests

### 🐳 Docker Build & Registry
- Multi-platform builds (linux/amd64, linux/arm64)
- Automated tagging with branch names and SHA
- Push to Docker Hub registry
- SBOM (Software Bill of Materials) generation
- Build caching for faster builds

### 🚀 VPS Deployment
- Automated SSH deployment to VPS
- Database backup before deployment
- Health checks after deployment
- Rollback capability on failure
- Docker image cleanup

### 🔒 Security Scanning
- Trivy vulnerability scanner for container images
- Results uploaded to GitHub Security tab
- SARIF format for integration with GitHub Advanced Security

## Frontend Pipeline Features

### 📱 Mobile (Android)
- **Testing**: Unit tests with coverage
- **Code Quality**: Flutter analyze and dart format
- **APK Build**: Debug (PR) and Release (main branch)
- **App Bundle**: AAB format for Google Play
- **Code Signing**: Automatic APK signing for releases
- **Artifacts**: APK and AAB uploaded as GitHub releases

### 🌐 Web Deployment
- **Build**: Flutter web with HTML renderer
- **PWA**: Service worker and manifest generation
- **CDN Headers**: Cache optimization and security headers
- **Netlify Deploy**: Automatic deployment with preview URLs
- **Surge Alternative**: Optional Surge.sh deployment

### 🍎 iOS (Optional)
- **Build**: iOS app build (no code signing)
- **Requires**: macOS runner (additional cost)
- **Artifacts**: IPA build uploaded for manual distribution

### ⚡ Performance
- **Integration Tests**: E2E testing with Flutter driver
- **Lighthouse**: Web performance auditing
- **Performance Reports**: Uploaded as artifacts

## Repository Secrets Required

### Backend Secrets
```
DOCKER_USERNAME          # Docker Hub username
DOCKER_PASSWORD          # Docker Hub password/token
VPS_HOST                 # VPS server IP/hostname
VPS_USER                 # VPS SSH username
VPS_SSH_KEY              # Private SSH key for VPS access
```

### Frontend Secrets
```
ANDROID_KEYSTORE_BASE64   # Base64 encoded Android keystore
ANDROID_KEYSTORE_PASSWORD # Keystore password
ANDROID_KEY_PASSWORD      # Key password
ANDROID_KEY_ALIAS         # Key alias
NETLIFY_AUTH_TOKEN        # Netlify authentication token
NETLIFY_SITE_ID          # Netlify site ID
SURGE_DOMAIN             # Surge.sh domain (if using Surge)
SURGE_TOKEN              # Surge.sh token (if using Surge)
```

### Optional Secrets
```
SNYK_TOKEN               # Snyk security scanning
CODECOV_TOKEN            # Codecov integration
SLACK_WEBHOOK            # Slack notifications
```

## Trigger Conditions

### Automatic Triggers
- **Push to main/develop**: Full pipeline execution
- **Pull Request**: Testing and preview builds
- **Path-based**: Only affected components are built

### Manual Triggers
- **Workflow Dispatch**: Manual deployment with environment selection
- **Environment Gates**: Production deployments require approval

## Environments

### Staging
- Automatic deployment from main branch
- Full feature testing environment
- Preview deployments for testing

### Production
- Manual approval required
- Comprehensive health checks
- Rollback procedures in place

## Artifacts & Reports

### Generated Artifacts
- **APK/AAB Files**: Android distribution packages
- **Web Build**: Static web files for deployment
- **Coverage Reports**: Test coverage HTML reports
- **Security Reports**: Vulnerability scan results
- **Performance Reports**: Lighthouse audit results
- **SBOM**: Software Bill of Materials

### Retention Policies
- **APK/AAB**: 30 days
- **Web Builds**: 7 days
- **Reports**: 7 days
- **Releases**: Permanent (until manually deleted)

## Monitoring & Notifications

### Health Checks
- API endpoint availability
- Database connectivity
- Service response times
- Critical user journey testing

### Notifications
- Deployment status updates
- Security vulnerability alerts
- Performance regression warnings
- Build failure notifications

## Getting Started

1. **Setup Secrets**: Add all required secrets to GitHub repository settings
2. **Configure VPS**: Ensure VPS has Docker and docker-compose installed
3. **Setup Registries**: Configure Docker Hub and deployment targets
4. **Test Pipeline**: Create a PR to test the pipeline

## Customization

### Adding New Environments
1. Create environment in GitHub repository settings
2. Add environment-specific secrets
3. Update workflow files with new environment logic

### Adding Notifications
1. Add webhook URLs to secrets
2. Customize notification steps in workflows
3. Configure notification triggers

### Security Hardening
1. Enable branch protection rules
2. Require status checks before merge
3. Enable vulnerability alerts
4. Configure secret scanning

## Troubleshooting

### Common Issues
- **Build Failures**: Check dependencies and versions
- **Deployment Failures**: Verify SSH access and VPS configuration
- **Test Failures**: Review test logs and database setup
- **Security Scans**: Address vulnerabilities or add exceptions

### Debug Steps
1. Check workflow logs in GitHub Actions tab
2. Verify secrets are correctly configured
3. Test deployment scripts manually
4. Review artifact uploads and downloads

## Performance Optimization

### Build Speed
- Dependency caching enabled
- Multi-stage Docker builds
- Parallel job execution
- Conditional workflow triggers

### Cost Optimization
- Path-based triggering
- Efficient resource usage
- Artifact cleanup policies
- Optimized runner selection
