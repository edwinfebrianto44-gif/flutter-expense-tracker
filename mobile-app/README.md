# Expense Tracker Mobile App

Aplikasi mobile Flutter untuk mengelola keuangan pribadi dengan fitur-fitur lengkap dan desain modern menggunakan Material 3.

## Features

### 🔐 Authentication
- Login dan Register dengan JWT authentication
- Secure token storage menggunakan Flutter Secure Storage
- Auto logout saat token expired

### 📊 Dashboard
- **Ringkasan Keuangan**: Total pemasukan, pengeluaran, dan saldo
- **Grafik Interaktif**: Visualisasi data keuangan dengan fl_chart
- **Transaksi Terbaru**: List 5 transaksi terakhir dengan navigasi ke detail

### 💰 Transaction Management
- **Tambah Transaksi**: Form lengkap dengan validasi
- **Edit/Update**: Modify transaksi existing
- **Delete**: Hapus transaksi dengan konfirmasi
- **Kategori Dropdown**: Pilih kategori berdasarkan tipe transaksi
- **Date Picker**: Pilih tanggal transaksi
- **Amount Formatting**: Format mata uang Rupiah otomatis

### 🏷️ Category Management
- **CRUD Operations**: Create, Read, Update, Delete kategori
- **Icon Picker**: Pilih dari 40+ icon predefined
- **Color Picker**: 10 pilihan warna menarik
- **Type Filtering**: Terpisah untuk income dan expense
- **Tab Navigation**: Interface yang user-friendly

### 🎨 UI/UX
- **Material 3 Design**: Desain modern dan konsisten
- **Light/Dark Mode**: Switch tema secara real-time
- **Responsive Design**: Support HP dan tablet
- **Smooth Animations**: Transisi halus antar halaman
- **Hero Animations**: Animasi logo dan elemen
- **Custom Transitions**: Fade dan slide animations

### 🔧 Technical Features
- **State Management**: Riverpod untuk state management
- **Routing**: GoRouter untuk navigasi
- **Secure Storage**: JWT token disimpan aman
- **Form Validation**: Validasi input yang komprehensif
- **Error Handling**: Penanganan error yang user-friendly
- **Demo Data**: 5 kategori dan 10 transaksi demo

## Dependencies

### Core
- `flutter_riverpod`: State management
- `go_router`: Routing dan navigasi
- `dio`: HTTP client untuk API calls
- `flutter_secure_storage`: Secure token storage

### UI & Charts
- `fl_chart`: Interactive charts
- `google_fonts`: Typography (Inter font)
- `form_builder_validators`: Form validation

### Utils
- `intl`: Internationalization dan formatting
- `shared_preferences`: Simple data storage

## Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart          # Material 3 theme configuration
│   └── app_router.dart             # GoRouter configuration
├── models/
│   ├── user.dart                   # User model
│   ├── category.dart               # Category model dengan demo data
│   └── transaction.dart            # Transaction model dengan demo data
├── providers/
│   ├── auth_provider.dart          # Authentication state management
│   ├── theme_provider.dart         # Theme state management
│   ├── category_provider.dart      # Category state management
│   └── transaction_provider.dart   # Transaction state management
├── services/
│   ├── auth_service.dart           # Authentication API service
│   └── storage_service.dart        # Secure storage service
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart       # Login page
│   │   └── register_screen.dart    # Register page
│   ├── dashboard/
│   │   ├── dashboard_screen.dart   # Main dashboard
│   │   └── widgets/
│   │       ├── balance_card.dart   # Balance summary widget
│   │       ├── chart_card.dart     # Chart widget
│   │       └── recent_transactions_card.dart
│   ├── transaction/
│   │   ├── add_transaction_screen.dart
│   │   └── edit_transaction_screen.dart
│   ├── category/
│   │   └── category_management_screen.dart
│   └── splash_screen.dart
├── widgets/
│   ├── loading_button.dart         # Loading state button
│   ├── custom_card.dart           # Reusable card widget
│   └── empty_state.dart           # Empty state widget
├── utils/
│   ├── formatters.dart            # Currency dan date formatters
│   └── validators.dart            # Form validators
└── main.dart
```

## Color Scheme

### Light Mode
- **Primary**: #6366F1 (Soft Purple)
- **Secondary**: #10B981 (Soft Green)
- **Error**: #EF4444 (Soft Red)
- **Warning**: #F59E0B (Soft Amber)

### Dark Mode
- **Surface**: #1F2937 (Dark Gray)
- **On Surface**: #F9FAFB (Light Gray)
- Automatic color adaptation dengan Material 3

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio atau VS Code
- Android/iOS device atau emulator

### Installation

1. Clone repository
```bash
git clone <repository-url>
cd mobile-app
```

2. Install dependencies
```bash
flutter pub get
```

3. Run aplikasi
```bash
flutter run
```

### Backend Integration

Untuk koneksi dengan backend, update base URL di `lib/services/auth_service.dart`:

```dart
static const String baseUrl = 'YOUR_BACKEND_URL';
```

## Demo Data

Aplikasi sudah dilengkapi dengan data demo:

### Kategori Demo (5 items):
- 💰 Gaji (Income)
- 🍔 Makanan (Expense)
- 🚗 Transportasi (Expense)
- 📈 Investasi (Income)
- 🛒 Belanja (Expense)

### Transaksi Demo (10 items):
- Mix income dan expense
- Berbagai kategori
- Tanggal bervariasi
- Amount realistis dalam Rupiah

## Features Highlights

### 🎯 Advanced State Management
- Menggunakan Riverpod untuk state management yang powerful
- Automatic state persistence untuk theme
- Reactive UI updates

### 🔒 Security
- JWT token disimpan di secure storage
- Auto logout pada token expired
- Input validation dan sanitization

### 📱 Responsive Design
- Layout yang adaptif untuk berbagai ukuran layar
- Touch-friendly interface
- Optimized untuk mobile dan tablet

### 🎨 Modern UI
- Material 3 design language
- Consistent color scheme
- Smooth animations dan transitions
- Professional typography dengan Google Fonts

### 📈 Data Visualization
- Interactive bar charts
- Monthly comparison
- Real-time updates
- Responsive chart design

## Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push ke branch
5. Create Pull Request

## License

MIT License - see LICENSE file for details
