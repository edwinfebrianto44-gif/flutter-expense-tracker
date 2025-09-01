# 🚀 Expense Tracker Mobile App - Flutter

> **Aplikasi mobile Flutter yang lengkap untuk mengelola keuangan pribadi dengan desain Material 3 yang modern dan fitur-fitur canggih.**

## ✨ Highlights

- 🔐 **JWT Authentication** dengan secure storage
- 📊 **Interactive Charts** menggunakan fl_chart
- 💰 **Transaction Management** dengan CRUD lengkap
- 🏷️ **Category Management** dengan icon & color picker
- 🎨 **Material 3 Design** dengan light/dark mode
- 📱 **Responsive Design** untuk HP dan tablet
- 🔄 **State Management** dengan Riverpod
- ⚡ **Smooth Animations** dan micro-interactions

## 📋 Quick Start

### Prerequisites
```bash
# Install Flutter (jika belum ada)
sudo snap install flutter --classic
flutter doctor
```

### Setup & Run
```bash
# 1. Navigate ke folder
cd mobile-app

# 2. Run setup script
chmod +x setup.sh
./setup.sh

# 3. Run aplikasi
flutter run
```

## 🏗️ Project Structure

```
mobile-app/
├── 📱 lib/
│   ├── 🎯 core/                  # Core configurations
│   │   ├── router.dart           # GoRouter navigation
│   │   └── theme/                # Material 3 themes
│   ├── 📊 models/                # Data models
│   │   ├── user.dart            
│   │   ├── category.dart         # 5 demo categories
│   │   └── transaction.dart      # 10 demo transactions
│   ├── 🔄 providers/             # Riverpod state management
│   │   ├── auth_provider.dart    
│   │   ├── theme_provider.dart   
│   │   ├── category_provider.dart
│   │   └── transaction_provider.dart
│   ├── 🌐 services/              # API & storage services
│   │   ├── auth_service.dart     # JWT authentication
│   │   └── storage_service.dart  # Secure storage
│   ├── 📱 screens/               # UI screens
│   │   ├── auth/                 # Login & Register
│   │   ├── dashboard/            # Main dashboard
│   │   ├── transaction/          # Add/Edit transactions
│   │   └── category/             # Manage categories
│   ├── 🧩 widgets/               # Reusable components
│   ├── 🛠️ utils/                 # Helpers & formatters
│   └── main.dart                 # App entry point
├── 🧪 test/                      # Unit & widget tests
├── 📋 docs/                      # Documentation
│   ├── README.md
│   ├── DEPLOYMENT.md
│   └── CHANGELOG.md
└── ⚙️ config files               # Flutter & platform configs
```

## 🎯 Features Overview

### 🔐 Authentication
- **Login/Register** dengan validasi form
- **JWT Token** disimpan di secure storage
- **Auto-logout** saat token expired
- **Loading states** dan error handling

### 📊 Dashboard
- **Financial Summary**: Income, Expense, Balance
- **Interactive Charts**: Monthly comparison
- **Recent Transactions**: 5 transaksi terbaru
- **Animated Numbers**: Smooth counter animations

### 💰 Transaction Management
- **Add Transaction**: Form lengkap dengan validasi
- **Edit/Delete**: Modify dan hapus transaksi
- **Category Selection**: Dropdown berdasarkan tipe
- **Date Picker**: UI yang user-friendly
- **Currency Format**: Auto-format Rupiah

### 🏷️ Category Management
- **CRUD Operations**: Tambah, edit, hapus kategori
- **Icon Picker**: 40+ emoji icons
- **Color Picker**: 10 warna pilihan
- **Type Separation**: Income vs Expense tabs

### 🎨 UI/UX Design
- **Material 3**: Modern design system
- **Light/Dark Mode**: Switch dengan persistensi
- **Responsive**: Adaptif untuk berbagai ukuran layar
- **Animations**: Hero, fade, slide transitions
- **Typography**: Google Fonts (Inter)

## 📊 Demo Data

### Categories (5 items):
- 💰 **Gaji** (Income) - Green
- 🍔 **Makanan** (Expense) - Red  
- 🚗 **Transportasi** (Expense) - Blue
- 📈 **Investasi** (Income) - Green
- 🛒 **Belanja** (Expense) - Orange

### Transactions (10 items):
- **Mixed types**: Income & Expense
- **Realistic amounts**: 50K - 5M Rupiah
- **Recent dates**: Last 2 weeks
- **Complete data**: With categories & descriptions

## 🛠️ Tech Stack

| Category | Library | Version | Purpose |
|----------|---------|---------|---------|
| **Framework** | Flutter | 3.x | Mobile development |
| **Language** | Dart | 3.x | Programming language |
| **State Management** | Riverpod | 2.4.7 | Reactive state |
| **Navigation** | GoRouter | 12.1.1 | Declarative routing |
| **Charts** | FL Chart | 0.65.0 | Data visualization |
| **HTTP** | Dio | 5.3.2 | API communication |
| **Storage** | Flutter Secure Storage | 9.0.0 | Encrypted storage |
| **UI** | Google Fonts | 6.1.0 | Typography |
| **Validation** | Form Builder Validators | 9.1.0 | Input validation |
| **Date/Time** | Intl | 0.18.1 | Internationalization |

## 🚀 Commands Cheat Sheet

```bash
# Development
flutter run                    # Run debug mode
flutter run --release         # Run release mode
flutter hot-reload            # Hot reload (r in terminal)

# Testing
flutter test                  # Run all tests
flutter test test/models/     # Run specific tests
flutter analyze              # Static analysis

# Building
flutter build apk            # Build Android APK
flutter build appbundle     # Build Android App Bundle
flutter build ios           # Build iOS app

# Maintenance
flutter clean               # Clean build cache
flutter pub get            # Get dependencies
flutter pub upgrade        # Upgrade dependencies
flutter doctor             # Check Flutter installation
```

## 🎯 Key Features Walkthrough

### 1. 🔐 Authentication Flow
```dart
// Login dengan JWT
final success = await authProvider.login(email, password);
if (success) {
  // Token tersimpan otomatis di secure storage
  context.goNamed('dashboard');
}
```

### 2. 📊 Dashboard Widgets
```dart
// Balance Card dengan animasi
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  child: Text(CurrencyFormatter.format(balance)),
)

// Chart dengan interaksi
BarChart(BarChartData(
  barTouchData: BarTouchData(enabled: true),
  // ... chart configuration
))
```

### 3. 💰 Transaction Form
```dart
// Currency formatting otomatis
TextFormField(
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  onChanged: (value) => formatCurrency(value),
  validator: AppValidators.amount,
)
```

### 4. 🎨 Theme Switching
```dart
// Toggle theme dengan persistensi
ref.read(themeProvider.notifier).toggleTheme();
// Otomatis tersimpan di SharedPreferences
```

## 🔧 Development Tips

### State Management Patterns
```dart
// Provider pattern
final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>();

// Consumer usage
Consumer(builder: (context, ref, child) {
  final transactions = ref.watch(transactionProvider);
  return TransactionList(transactions: transactions);
})
```

### Navigation Patterns
```dart
// Declarative routing
context.pushNamed('edit-transaction', 
  pathParameters: {'id': transaction.id.toString()},
  extra: transaction,
);
```

### Error Handling
```dart
// Consistent error handling
try {
  final result = await apiCall();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_getErrorMessage(e))),
  );
}
```

## 🧪 Testing Strategy

### Unit Tests
```bash
# Test business logic
flutter test test/models/
flutter test test/providers/
```

### Widget Tests
```bash
# Test UI components
flutter test test/widgets/
flutter test test/screens/
```

### Integration Tests
```bash
# Test full user flows
flutter test integration_test/
```

## 📈 Performance Optimizations

- ✅ **Const constructors** untuk widget immutable
- ✅ **Widget rebuild optimization** dengan Consumer
- ✅ **Lazy loading** untuk list besar
- ✅ **Image optimization** dan caching
- ✅ **Bundle size optimization** dengan tree shaking

## 🔒 Security Features

- 🔐 **JWT Token** di encrypted storage
- ✅ **Input validation** dan sanitization
- 🛡️ **SSL certificate pinning** ready
- 🔒 **Secure API communication** dengan Dio interceptors

## 📱 Platform Support

### Android
- ✅ **Material Design** theming
- ✅ **Adaptive icons** dan splash screen
- ✅ **Permission handling** yang proper
- ✅ **ProGuard** configuration ready

### iOS
- ✅ **Cupertino** design elements
- ✅ **Safe area** handling
- ✅ **App Store** guidelines compliance
- ✅ **Device compatibility** optimized

## 🚀 Deployment Ready

### Production Checklist
- ✅ Code obfuscation enabled
- ✅ App signing configured
- ✅ Release build optimized
- ✅ Store metadata prepared
- ✅ Privacy policy included
- ✅ Performance tested

### CI/CD Pipeline
```yaml
# GitHub Actions ready
- Flutter analyze
- Run tests
- Build APK/iOS
- Deploy to stores
```

## 🤝 Contributing

1. **Fork** repository
2. **Create** feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** changes: `git commit -m 'Add amazing feature'`
4. **Push** branch: `git push origin feature/amazing-feature`
5. **Open** Pull Request

## 📄 License

MIT License - bebas digunakan untuk project pribadi maupun komersial.

---

**🎉 Happy Coding! Aplikasi siap untuk development dan deployment.**

*Generated with ❤️ untuk membantu developers membuat aplikasi keuangan yang amazing!*
