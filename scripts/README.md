# 🔍 System Health Check & Integration Testing Scripts

Kumpulan script komprehensif untuk memvalidasi semua fitur antara frontend dan backend Flutter Expense Tracker, memastikan tidak ada mock data yang digunakan dalam production.

## 📋 Daftar Script

### 1. `smart-checker.sh` - **RECOMMENDED** ⭐
**Script utama yang paling direkomendasikan untuk digunakan**

```bash
./scripts/smart-checker.sh
```

**Fitur:**
- ✅ Otomatis mendeteksi dan menjalankan services yang diperlukan
- ✅ Setup backend dan frontend secara otomatis
- ✅ Instalasi dependencies otomatis
- ✅ Setup demo data
- ✅ Menjalankan semua health check
- ✅ Memberikan checklist manual testing
- ✅ Service management dengan cleanup otomatis
- ✅ Interactive dan user-friendly

**Kegunaan:**
- Untuk developer yang ingin langsung test semua fitur
- Untuk CI/CD pipeline
- Untuk demo kepada stakeholder

---

### 2. `health-check.sh` - Backend API Testing
**Script untuk testing mendalam backend API dan services**

```bash
./scripts/health-check.sh
```

**Yang Dicek:**
- ✅ Backend service availability
- ✅ Database connectivity
- ✅ Authentication endpoints
- ✅ Category management API
- ✅ Transaction management API
- ✅ Reporting & analytics API
- ✅ Security features (CORS, rate limiting)
- ✅ Performance metrics
- ✅ Mock data detection
- ✅ Configuration validation

**Output:**
- Detailed test results dengan color coding
- Success rate percentage
- Failed tests dengan details
- Mock data findings
- Recommendations

---

### 3. `frontend-integration-check.sh` - Flutter Integration Testing
**Script untuk validasi Flutter app dan integrasi dengan backend**

```bash
./scripts/frontend-integration-check.sh
```

**Yang Dicek:**
- ✅ Flutter project structure
- ✅ Mock data detection dalam kode Dart
- ✅ API service configuration
- ✅ Data models dan JSON serialization
- ✅ State management (Provider)
- ✅ Screen implementations
- ✅ Dependencies validation
- ✅ Environment configuration
- ✅ Build configuration
- ✅ Integration dengan backend API

**Output:**
- Integration status report
- Mock data issues
- Missing implementations
- Configuration problems

---

### 4. `check-all.sh` - Master Check Script
**Script master yang menjalankan semua pengecekan**

```bash
./scripts/check-all.sh
```

**Fitur:**
- ✅ Menjalankan health-check.sh
- ✅ Menjalankan frontend-integration-check.sh
- ✅ Manual verification checklist lengkap
- ✅ Production readiness checklist
- ✅ Final system status report

---

## 🚀 Quick Start Guide

### Opsi 1: Smart Checker (Recommended)
```bash
# Jalankan script pintar yang otomatis setup semua
./scripts/smart-checker.sh

# Script akan:
# 1. Check service status
# 2. Start backend jika belum running
# 3. Tanya mau start frontend atau tidak
# 4. Setup demo data
# 5. Run automated checks
# 6. Show manual testing checklist
```

### Opsi 2: Manual Step-by-Step
```bash
# 1. Start backend secara manual
cd backend
python main.py &

# 2. Start frontend secara manual
cd mobile-app
flutter run -d web-server --web-port=8080 &

# 3. Setup demo data
./scripts/setup-demo-data.sh

# 4. Run all checks
./scripts/check-all.sh
```

### Opsi 3: Individual Script Testing
```bash
# Test backend saja
./scripts/health-check.sh

# Test frontend integration saja
./scripts/frontend-integration-check.sh

# Test semua dengan manual checklist
./scripts/check-all.sh
```

---

## 📊 Checklist Fitur Yang Divalidasi

### 🔧 Backend API Features
- [ ] User authentication (register, login, logout)
- [ ] JWT token management
- [ ] Category CRUD operations
- [ ] Transaction CRUD operations
- [ ] Transaction filtering & search
- [ ] Monthly/yearly reports
- [ ] Data export (CSV)
- [ ] File upload functionality
- [ ] Rate limiting
- [ ] CORS configuration
- [ ] Security headers
- [ ] Database connectivity
- [ ] Health monitoring
- [ ] API documentation (OpenAPI/Swagger)

### 📱 Frontend Features
- [ ] User interface responsiveness
- [ ] Login/logout functionality
- [ ] Dashboard dengan real data
- [ ] Transaction management UI
- [ ] Category management UI
- [ ] Charts dan analytics
- [ ] Data filtering
- [ ] Export functionality
- [ ] Profile management
- [ ] Error handling
- [ ] Loading states
- [ ] Real-time data updates

### 🔗 Integration Features
- [ ] API calls menggunakan real endpoints
- [ ] Authentication token management
- [ ] Data synchronization
- [ ] Error handling yang proper
- [ ] No mock data dalam production code
- [ ] Environment configuration
- [ ] Cross-platform compatibility

---

## 🔍 Mock Data Detection

Script-script ini secara otomatis mendeteksi penggunaan mock data dengan mencari pattern:

### Pattern yang Dicari:
- `mock`, `fake`, `dummy`
- `test.*data`, `sample.*data`
- `placeholder`, `lorem.*ipsum`
- `example@example`, `user@test`
- `localhost.*8080` (hardcoded URLs)
- Test dependencies di main dependencies
- Hardcoded development values

### Lokasi yang Dicek:
- ✅ Backend Python code
- ✅ Frontend Dart code
- ✅ Configuration files
- ✅ Dependencies
- ❌ Test files (dikecualikan)
- ❌ Documentation files

---

## 📈 Output Examples

### ✅ Healthy System
```
🎉 ALL AUTOMATED CHECKS PASSED!
✅ Backend services are healthy
✅ Frontend-backend integration is working
✅ No mock data detected in production code
🚀 System appears ready for production deployment!
```

### ⚠️ Issues Found
```
🚨 SOME CHECKS FAILED
❌ Please fix the failed checks before proceeding
• Authentication: Demo account login failed
• Mock Data Found: Pattern 'mock' found in: lib/services/api_service.dart
```

---

## 🔧 Troubleshooting

### Backend Issues
```bash
# Check backend logs
tail -f /tmp/backend.log

# Check if port 8000 is busy
lsof -i :8000

# Manual backend start
cd backend && python main.py
```

### Frontend Issues
```bash
# Check frontend logs
tail -f /tmp/frontend.log

# Check Flutter installation
flutter doctor

# Manual frontend start
cd mobile-app && flutter run -d web-server --web-port=8080
```

### Database Issues
```bash
# Reset database
rm backend/expense_tracker.db

# Setup demo data again
./scripts/setup-demo-data.sh
```

---

## 🎯 Demo Account

**Email:** `demo@demo.com`  
**Password:** `password123`

**Demo Data Includes:**
- 5 Categories (Food, Transportation, Shopping, Entertainment, Bills)
- 30+ realistic transactions
- Income dan expense transactions
- Data dari 3 bulan terakhir
- Berbagai amount dan descriptions

---

## 🚀 Production Deployment Checklist

Setelah semua script pass, pastikan:

- [ ] Environment variables di-set dengan proper values
- [ ] Database credentials aman
- [ ] JWT secrets di-generate ulang
- [ ] CORS origins di-configure untuk production domains
- [ ] SSL certificates installed
- [ ] Rate limiting enabled
- [ ] Monitoring setup
- [ ] Backup strategy implemented
- [ ] Error logging configured

---

## 🤝 Contributing

Untuk menambah test case baru:

1. Edit script yang sesuai (`health-check.sh` untuk backend, `frontend-integration-check.sh` untuk frontend)
2. Tambahkan test function baru
3. Update checklist di `check-all.sh`
4. Test script dengan `./scripts/smart-checker.sh`

---

## 📝 Notes

- Semua script menggunakan bash dan compatible dengan Linux/macOS
- Script otomatis cleanup services saat dihentikan (Ctrl+C)
- Logs disimpan di `/tmp/` untuk debugging
- Color coding: 🟢 Pass, 🔴 Fail, 🟡 Warning/Skip
- Exit codes: 0 = success, 1 = failure

---

**Powered by Flutter Expense Tracker Team** 🚀
