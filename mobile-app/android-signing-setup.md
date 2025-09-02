# Android App Signing Configuration

## Overview
This guide explains how to configure Android app signing for automated APK generation in CI/CD.

## Prerequisites
- Android Studio installed
- JDK 11 or higher
- Access to your GitHub repository settings

## Step 1: Generate Signing Key

### Option A: Using Android Studio
1. Open Android Studio
2. Go to `Build` > `Generate Signed Bundle / APK`
3. Choose `APK` and click `Next`
4. Click `Create new...` to create a new keystore
5. Fill in the keystore details:
   - Key store path: Choose location and filename
   - Password: Strong password for keystore
   - Key alias: Unique alias for your key
   - Key password: Strong password for key
   - Validity: 25+ years
   - Certificate info: Your app/company details

### Option B: Using Command Line
```bash
# Generate keystore
keytool -genkeypair -v -keystore expense-tracker-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias expense-tracker \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=Your Name, OU=Your Organization, O=Your Company, L=Your City, ST=Your State, C=Your Country"
```

## Step 2: Configure Android App for Signing

### Create key.properties (for local development)
```properties
# android/key.properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=expense-tracker
storeFile=../expense-tracker-release.jks
```

### Update android/app/build.gradle
```gradle
android {
    // ... existing configuration

    signingConfigs {
        release {
            if (project.hasProperty('android.injected.signing.store.file')) {
                storeFile file(project.property('android.injected.signing.store.file'))
                storePassword project.property('android.injected.signing.store.password')
                keyAlias project.property('android.injected.signing.key.alias')
                keyPassword project.property('android.injected.signing.key.password')
            } else {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... other release configuration
        }
    }
}

// Load keystore properties
def keystorePropertiesFile = rootProject.file('key.properties')
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

## Step 3: Setup GitHub Secrets

### Convert keystore to base64
```bash
# Linux/macOS
base64 -i expense-tracker-release.jks | tr -d '\n' | pbcopy

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("expense-tracker-release.jks")) | Set-Clipboard
```

### Add GitHub Repository Secrets
Go to your GitHub repository > Settings > Secrets and variables > Actions

Add these secrets:
- `ANDROID_KEYSTORE_BASE64`: Base64 encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_PASSWORD`: Key password  
- `ANDROID_KEY_ALIAS`: Key alias (expense-tracker)

## Step 4: Security Best Practices

### Keystore Security
- ⚠️ **Never commit keystore files to version control**
- 🔒 Use strong, unique passwords
- 💾 Keep multiple secure backups of your keystore
- 🎯 Limit access to keystore and passwords
- 🔄 Rotate secrets periodically

### GitHub Secrets Security
- 🔐 Use environment protection rules for production
- 👥 Limit repository access to trusted collaborators
- 📝 Audit secret access regularly
- 🚫 Never log or expose secrets in workflows

## Step 5: Add to .gitignore

```gitignore
# Android signing
*.jks
*.keystore
key.properties
android/key.properties

# Keystore backups
*.jks.backup
*.keystore.backup
```

## Step 6: Local Development Setup

### For development builds (debug)
```bash
# No signing required for debug builds
flutter build apk --debug
```

### For local release builds
```bash
# Ensure key.properties exists with correct paths
flutter build apk --release
```

## Step 7: CI/CD Integration

The GitHub Actions workflow automatically:
1. Decodes the base64 keystore
2. Creates key.properties file
3. Builds and signs the APK
4. Uploads signed APK as release asset

## Troubleshooting

### Common Issues

#### "key.properties not found"
- Ensure the workflow creates key.properties before building
- Check file paths in build.gradle

#### "keystore not found"
- Verify base64 encoding is correct
- Check keystore path in workflow

#### "Wrong password"
- Verify GitHub secrets match keystore passwords
- Check for special characters in passwords

#### "Key alias not found"
- Confirm ANDROID_KEY_ALIAS matches keystore alias
- Check keystore contents: `keytool -list -v -keystore your-keystore.jks`

### Debug Commands

```bash
# List keystore contents
keytool -list -v -keystore expense-tracker-release.jks

# Verify APK signature
jarsigner -verify -verbose -certs app-release.apk

# Check APK details
aapt dump badging app-release.apk
```

## Production Deployment

### Google Play Store
1. Upload signed APK/AAB to Google Play Console
2. Configure app signing by Google Play (recommended)
3. Upload your signing key to Google Play for enhanced security

### Alternative Distribution
- Direct APK download from GitHub releases
- Internal distribution via Firebase App Distribution
- Enterprise deployment via MDM solutions

## Key Rotation

If you need to rotate your signing key:
1. Generate new keystore
2. Update GitHub secrets
3. Plan migration strategy for existing users
4. Consider Google Play App Signing for easier rotation

## Backup Strategy

### Essential Backups
- 💾 Original keystore file (multiple copies)
- 🔑 Keystore and key passwords (secure password manager)
- 📄 Key generation commands and parameters
- 🗂️ Certificate information and details

### Storage Locations
- 🏢 Corporate secure storage
- ☁️ Encrypted cloud storage
- 🔐 Physical secure media (for critical applications)
- 👥 Shared access with team members (for business continuity)
