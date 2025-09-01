# Expense Tracker Backend API

FastAPI backend untuk aplikasi Expense Tracker dengan fitur authentication JWT, CRUD operations, dan filtering.

## Features

- 🔐 JWT Authentication (register, login, refresh)
- 📝 CRUD operations untuk categories dan transactions
- 🔍 Filter transactions berdasarkan date range, category, dan type
- 📊 Summary endpoint (total income, expense, balance)
- 🗄️ Alembic untuk database migrations
- ⚙️ Environment configuration dengan dotenv
- 📋 Standardized JSON response format
- 🧪 Unit tests dengan pytest

## Tech Stack

- **FastAPI** - Modern web framework
- **SQLAlchemy** - ORM
- **Alembic** - Database migrations
- **MySQL** - Database
- **JWT** - Authentication
- **Pytest** - Testing

## Project Structure

```
backend/
├── app/
│   ├── core/           # Config, security, database
│   ├── models/         # SQLAlchemy models
│   ├── schemas/        # Pydantic schemas
│   ├── crud/           # Database operations
│   ├── routes/         # API endpoints
│   ├── services/       # Business logic
│   └── tests/          # Unit tests
├── migrations/         # Alembic migrations
├── main.py            # Application entry point
├── requirements.txt   # Dependencies
└── alembic.ini       # Alembic configuration
```

## Installation

1. **Install dependencies:**
```bash
cd backend
pip install -r requirements.txt
```

2. **Setup environment:**
```bash
cp .env.example .env
# Edit .env with your database credentials
```

3. **Setup database:**
```bash
# Create database
mysql -u root -p -e "CREATE DATABASE expense_tracker;"

# Run migrations
alembic upgrade head
```

4. **Run the application:**
```bash
python main.py
# atau
uvicorn main:app --reload
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register user
- `POST /api/v1/auth/login` - Login user

### Categories
- `GET /api/v1/categories` - Get all categories
- `POST /api/v1/categories` - Create category
- `GET /api/v1/categories/{id}` - Get category by ID
- `PUT /api/v1/categories/{id}` - Update category
- `DELETE /api/v1/categories/{id}` - Delete category

### Transactions
- `GET /api/v1/transactions` - Get transactions (with filters)
- `POST /api/v1/transactions` - Create transaction
- `GET /api/v1/transactions/{id}` - Get transaction by ID
- `PUT /api/v1/transactions/{id}` - Update transaction
- `DELETE /api/v1/transactions/{id}` - Delete transaction
- `GET /api/v1/transactions/summary` - Get summary

### Query Parameters untuk Filtering
- `start_date` - Filter dari tanggal (YYYY-MM-DD)
- `end_date` - Filter sampai tanggal (YYYY-MM-DD)
- `category_id` - Filter berdasarkan category ID
- `category_type` - Filter berdasarkan type (income/expense)

## Database Migration

```bash
# Generate migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Rollback migration
alembic downgrade -1
```

## Testing

```bash
# Run tests
pytest

# Run with coverage
pytest --cov=app
```

## API Response Format

Semua endpoint menggunakan format response yang konsisten:

```json
{
  "status": "success",
  "message": "Description of the operation",
  "data": { ... },
  "meta": { ... }  // Optional, untuk pagination dll
}
```

## Example Usage

### Register User
```bash
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "securepassword123"
  }'
```

### Login
```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "securepassword123"
  }'
```

### Create Transaction
```bash
curl -X POST "http://localhost:8000/api/v1/transactions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "category_id": 1,
    "amount": 50.00,
    "description": "Lunch",
    "trans_date": "2025-09-01"
  }'
```

### Get Transactions with Filters
```bash
curl "http://localhost:8000/api/v1/transactions?start_date=2025-09-01&end_date=2025-09-30&category_type=expense" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Environment Variables

Buat file `.env` dengan konfigurasi berikut:

```env
DATABASE_URL=mysql+pymysql://username:password@localhost:3306/expense_tracker
JWT_SECRET_KEY=your-super-secret-jwt-key-here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7
APP_NAME=Expense Tracker API
APP_VERSION=1.0.0
DEBUG=True
```

## Development

1. **Auto-reload development server:**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

2. **Access API documentation:**
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

3. **Run tests in watch mode:**
```bash
pytest-watch
```

## Production Deployment

1. Update environment variables untuk production
2. Set `DEBUG=False`
3. Konfigurasi CORS dengan domain yang tepat
4. Setup reverse proxy (nginx)
5. Use production WSGI server (gunicorn)

```bash
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker
```
