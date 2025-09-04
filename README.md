# 💰 Flutter Expense Tracker

> A modern, full-stack expense tracking application built with Flutter and FastAPI

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104-green.svg)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://docker.com/)

## 🚀 Quick Start

### Using Docker (Recommended)

1. **Clone the repository**
```bash
git clone https://github.com/edwinfebrianto44-gif/flutter-expense-tracker.git
cd flutter-expense-tracker
```

2. **Start the application**
```bash
# Start all services
docker-compose up -d

# Or for development
docker-compose -f docker-compose.dev.yml up -d
```

3. **Access the application**
- **Frontend (Flutter Web)**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs

### Demo Account
```
Email: demo@demo.com
Password: password123
```

## 🛠️ Manual Setup

### Backend Setup

1. **Navigate to backend directory**
```bash
cd backend
```

2. **Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Set environment variables**
```bash
cp .env.example .env
# Edit .env with your configuration
```

5. **Setup database**
```bash
# Run migrations
alembic upgrade head

# Create demo data
python setup_admin.py
```

6. **Start backend server**
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend Setup

1. **Navigate to mobile-app directory**
```bash
cd mobile-app
```

2. **Install Flutter dependencies**
```bash
flutter pub get
```

3. **Run for web**
```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```

## 📊 Features

### 💡 Core Features
- ✅ User authentication & authorization
- ✅ Transaction management (income/expense)
- ✅ Category management with icons
- ✅ Monthly/yearly reporting
- ✅ Data export (CSV, PDF)
- ✅ File attachments for transactions
- ✅ Real-time dashboard
- ✅ Responsive web interface

### 🎨 UI/UX Features
- ✅ Material Design 3
- ✅ Dark/Light theme support
- ✅ Interactive charts & graphs
- ✅ Mobile-first responsive design
- ✅ Smooth animations

### 🔧 Technical Features
- ✅ JWT Authentication
- ✅ PostgreSQL database
- ✅ Redis caching
- ✅ File upload support
- ✅ RESTful API
- ✅ Docker containerization
- ✅ Health monitoring
- ✅ API documentation

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter Web   │────│   FastAPI       │────│   PostgreSQL    │
│   (Frontend)    │    │   (Backend)     │    │   (Database)    │
│   Port: 3000    │    │   Port: 8000    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         └──────────────│     Redis       │──────────────┘
                        │    (Cache)      │
                        │   Port: 6379    │
                        └─────────────────┘
```

## 📁 Project Structure

```
flutter-expense-tracker/
├── 🔧 backend/                 # FastAPI Backend
│   ├── app/
│   │   ├── core/              # Core configurations
│   │   ├── models/            # Database models
│   │   ├── routes/            # API endpoints
│   │   ├── services/          # Business logic
│   │   └── schemas/           # Pydantic models
│   ├── migrations/            # Database migrations
│   ├── Dockerfile
│   └── requirements.txt
├── 📱 mobile-app/             # Flutter Frontend
│   ├── lib/
│   │   ├── core/              # App configuration
│   │   ├── models/            # Data models
│   │   ├── providers/         # State management
│   │   ├── screens/           # UI screens
│   │   ├── services/          # API services
│   │   └── widgets/           # Reusable widgets
│   ├── Dockerfile.web
│   └── pubspec.yaml
├── 🐳 docker-compose.yml      # Production setup
├── 🛠️ docker-compose.dev.yml  # Development setup
└── 📖 README.md
```

## 🚀 Deployment

### Docker Production

1. **Production deployment**
```bash
docker-compose -f docker-compose.production.yml up -d
```

2. **Environment variables**
```bash
# Set production environment variables
export SECRET_KEY="your-production-secret-key"
export DATABASE_URL="postgresql://user:pass@host:5432/db"
export REDIS_URL="redis://host:6379/0"
```

### Manual Deployment

1. **Backend deployment**
```bash
cd backend
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

2. **Frontend deployment**
```bash
cd mobile-app
flutter build web --release
# Serve build/web with nginx or any web server
```

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```env
DATABASE_URL=postgresql://user:password@localhost:5432/expense_tracker
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=your-super-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
CORS_ORIGINS=http://localhost:3000
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760
```

#### Frontend (lib/core/config.dart)
```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
```

## 📱 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - User logout

### Transactions
- `GET /api/v1/transactions` - Get all transactions
- `POST /api/v1/transactions` - Create transaction
- `PUT /api/v1/transactions/{id}` - Update transaction
- `DELETE /api/v1/transactions/{id}` - Delete transaction

### Categories
- `GET /api/v1/categories` - Get all categories
- `POST /api/v1/categories` - Create category
- `PUT /api/v1/categories/{id}` - Update category
- `DELETE /api/v1/categories/{id}` - Delete category

### Reports
- `GET /api/v1/reports/monthly` - Monthly report
- `GET /api/v1/reports/yearly` - Yearly report
- `GET /api/v1/reports/export` - Export data

## 🧪 Development

### Run Tests
```bash
# Backend tests
cd backend
python -m pytest

# Frontend tests
cd mobile-app
flutter test
```

### Database Migration
```bash
cd backend
alembic revision --autogenerate -m "migration message"
alembic upgrade head
```

### Add New Dependencies

#### Backend
```bash
cd backend
pip install new-package
pip freeze > requirements.txt
```

#### Frontend
```bash
cd mobile-app
flutter pub add new_package
```

## 🔒 Security Features

- 🔐 JWT-based authentication
- 🛡️ Password hashing with bcrypt
- 🔒 CORS protection
- 🚫 SQL injection prevention
- 📊 Rate limiting
- 🔍 Input validation
- 🛡️ XSS protection

## 📊 Monitoring

Access monitoring tools:
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001 (admin/admin123)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Edwin Febrianto**
- GitHub: [@edwinfebrianto44-gif](https://github.com/edwinfebrianto44-gif)
- Email: edwinfebrianto44@gmail.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- FastAPI for the modern Python web framework
- PostgreSQL for reliable database
- Docker for containerization

---

⭐ If you found this project helpful, please give it a star!
