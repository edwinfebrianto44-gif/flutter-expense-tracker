# Deployment Guide

## Prerequisites

1. **Flutter SDK**: Pastikan Flutter telah terinstall dengan versi terbaru
   ```bash
   flutter doctor
   ```

2. **Platform Setup**:
   - **Android**: Android Studio dengan Android SDK
   - **iOS**: Xcode (macOS only)

## Development Setup

1. **Clone dan Install Dependencies**:
   ```bash
   git clone <repository-url>
   cd mobile-app
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Environment Configuration**:
   - Update backend URL di `lib/services/auth_service.dart`
   - Sesuaikan configuration sesuai environment

## Build Commands

### Android

#### Debug Build
```bash
flutter run
# atau
flutter run --debug
```

#### Release Build
```bash
# APK
flutter build apk --release

# App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### Build Configurations
```bash
# Build with specific flavor
flutter build apk --flavor production --release

# Build with custom build name and number
flutter build apk --build-name=1.0.0 --build-number=1 --release
```

### iOS

#### Debug Build
```bash
flutter run
```

#### Release Build
```bash
# iOS App
flutter build ios --release

# Build untuk simulator
flutter build ios --debug --simulator
```

## Code Signing & Distribution

### Android

1. **Generate Keystore** (production):
   ```bash
   keytool -genkey -v -keystore release-key.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Configure Signing** di `android/app/build.gradle`:
   ```gradle
   android {
       signingConfigs {
           release {
               keyAlias 'release'
               keyPassword 'your-password'
               storeFile file('release-key.keystore')
               storePassword 'your-password'
           }
       }
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

3. **Build Signed APK**:
   ```bash
   flutter build apk --release
   ```

### iOS

1. **Setup provisioning profiles** di Xcode
2. **Configure Team dan Bundle ID**
3. **Archive dan upload** via Xcode atau App Store Connect

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/
```

## Performance Optimization

### 1. Build Optimization
```bash
# Enable obfuscation
flutter build apk --obfuscate --split-debug-info=<directory>

# Tree shaking
flutter build apk --tree-shake-icons
```

### 2. Asset Optimization
- Compress images
- Use vector assets when possible
- Minimize font files

### 3. Code Optimization
- Use const constructors
- Optimize widget rebuilds
- Implement lazy loading

## CI/CD Setup

### GitHub Actions Example
```yaml
name: Build and Deploy
on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/flutter-apk/app-release.apk
```

## Monitoring & Analytics

### 1. Firebase Crashlytics
```dart
// Add to pubspec.yaml
firebase_crashlytics: ^3.4.0

// Initialize in main.dart
await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
```

### 2. Performance Monitoring
```dart
// Add performance monitoring
firebase_performance: ^0.9.3
```

## Security Considerations

1. **API Keys**: Store di environment variables
2. **Obfuscation**: Enable untuk production builds
3. **SSL Pinning**: Implement untuk API calls
4. **Secure Storage**: Gunakan untuk sensitive data

## App Store Guidelines

### Google Play Store
1. **Target API Level**: Minimal API 31 (Android 12)
2. **App Bundle**: Gunakan AAB format
3. **Privacy Policy**: Wajib jika collect user data
4. **App Signing**: Enable Play App Signing

### Apple App Store
1. **iOS Version**: Support minimal iOS 12
2. **App Store Guidelines**: Follow Apple's guidelines
3. **Privacy Labels**: Declare data usage
4. **TestFlight**: Use untuk beta testing

## Environment-Specific Builds

### Development
```bash
flutter run --debug
```

### Staging
```bash
flutter build apk --flavor staging --debug
```

### Production
```bash
flutter build apk --flavor production --release
```

## Troubleshooting

### Common Issues

1. **Build Failures**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

2. **Dependency Conflicts**:
   ```bash
   flutter pub deps
   flutter pub upgrade
   ```

3. **Platform Issues**:
   ```bash
   flutter doctor
   flutter doctor --android-licenses
   ```

### Performance Issues
- Use Flutter Inspector untuk debugging
- Profile app dengan `flutter run --profile`
- Monitor memory usage

## Checklist sebelum Release

- [ ] All tests passing
- [ ] Performance tested
- [ ] UI tested on multiple devices
- [ ] Security review completed
- [ ] App icons and metadata updated
- [ ] Privacy policy updated
- [ ] Store listing prepared
- [ ] Beta testing completed
