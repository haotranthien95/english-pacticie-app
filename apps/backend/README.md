# English Learning App - Backend API

Backend API for English pronunciation practice application built with FastAPI, PostgreSQL, and Azure Speech Services.

## Features

- 🔐 JWT-based authentication with OAuth support (Google, Apple, Facebook)
- 🎮 Game modes: Listen-only and Listen-and-Repeat with pronunciation scoring
- 🗣️ Azure Speech SDK integration for pronunciation assessment
- 📊 Game history and user progress tracking
- 👨‍💼 Admin panel for content management
- 🎯 Tag-based speech filtering and random selection
- 📦 MinIO/S3-compatible object storage for audio files
- ✅ 80%+ test coverage with pytest
- 🐳 Docker Compose for local development

## Tech Stack

- **Framework**: FastAPI 0.109+
- **Database**: PostgreSQL 15+ with SQLAlchemy
- **Cache**: Redis 7+
- **Storage**: MinIO (S3-compatible)
- **Speech**: Azure Cognitive Services Speech SDK
- **Auth**: JWT (python-jose)
- **Admin**: SQLAdmin
- **Testing**: pytest, pytest-asyncio, pytest-cov

## Prerequisites

- Python 3.12+
- Docker & Docker Compose
- PostgreSQL 15+ (if not using Docker)
- Redis 7+ (if not using Docker)
- Azure Speech Services API key

## Quick Start

### 1. Clone and Setup

```bash
cd apps/backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env and set your values
# IMPORTANT: Set AZURE_SPEECH_KEY, JWT_SECRET_KEY, DATABASE_URL
```

### 3. Start Services with Docker

```bash
# Start PostgreSQL, Redis, MinIO
docker-compose up -d

# Check services are running
docker-compose ps
```

### 4. Run Database Migrations

```bash
# Initialize Alembic (first time only)
alembic init alembic

# Create migration
alembic revision --autogenerate -m "Initial schema"

# Apply migrations
alembic upgrade head
```

### 5. Run Development Server

```bash
# Start FastAPI server with auto-reload
python -m app.main

# Or use uvicorn directly
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 6. Access API

- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health**: http://localhost:8000/health
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin)

## Project Structure

```
apps/backend/
├── app/
│   ├── api/v1/          # API endpoints
│   ├── models/          # SQLAlchemy models
│   ├── schemas/         # Pydantic schemas
│   ├── services/        # Business logic
│   ├── utils/           # Utilities
│   ├── core/            # Core (exceptions)
│   ├── admin/           # Admin panel
│   ├── config.py        # Settings
│   ├── database.py      # DB connection
│   └── main.py          # FastAPI app
├── alembic/             # Migrations
├── tests/               # Test suite
├── requirements.txt     # Dependencies
└── docker-compose.yml   # Services
```

## Development

### Running Tests

```bash
# All tests
pytest

# With coverage
pytest --cov=app --cov-report=html

# Unit tests only
pytest tests/unit -v

# Integration tests
pytest tests/integration -v

# Specific test file
pytest tests/unit/services/test_auth_service.py
```

### Code Quality

```bash
# Format code
black app/ tests/
isort app/ tests/

# Lint
flake8 app/ tests/
mypy app/

# Security scan
bandit -r app/
safety check
```

### Database Migrations

```bash
# Create new migration
alembic revision --autogenerate -m "Add new field"

# Apply migrations
alembic upgrade head

# Rollback last migration
alembic downgrade -1

# View migration history
alembic history
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - Login with email/password
- `POST /api/v1/auth/social` - Login with OAuth (Google/Apple/Facebook)
- `POST /api/v1/auth/refresh` - Refresh JWT token

### Game
- `POST /api/v1/game/speeches/random` - Get random speeches for practice
- `POST /api/v1/game/sessions` - Save completed game session
- `GET /api/v1/game/sessions` - Get user's game history
- `GET /api/v1/game/sessions/{id}` - Get session details

### Speech
- `POST /api/v1/speech/score` - Score pronunciation (audio upload)

### Users
- `GET /api/v1/users/me` - Get current user profile
- `PUT /api/v1/users/me` - Update profile
- `DELETE /api/v1/users/me` - Delete account

### Tags
- `GET /api/v1/tags` - List public tags

### Admin (Protected)
- `GET /api/v1/admin/speeches` - List speeches (CRUD)
- `POST /api/v1/admin/imports/audio` - Bulk upload audio
- `POST /api/v1/admin/imports/csv` - Import speeches from CSV

## Environment Variables

See `.env.example` for complete list. Key variables:

- `DATABASE_URL` - PostgreSQL connection string
- `AZURE_SPEECH_KEY` - Azure Speech Services API key
- `JWT_SECRET_KEY` - Secret key for JWT (32+ chars)
- `S3_ENDPOINT_URL` - MinIO/S3 endpoint
- `ALLOWED_ORIGINS` - CORS origins (comma-separated)

## Constitution Compliance

This implementation follows [Constitution v1.0.0](../../.specify/memory/constitution.md):

- ✅ **Clean Architecture**: 3-layer separation (API → Services → Data)
- ✅ **Test Coverage**: ≥80% for services and business logic
- ✅ **Immutability**: Typed exceptions, context managers
- ✅ **Security**: No secrets in code, environment variables only
- ✅ **Error Handling**: Typed exceptions at service layer, HTTP conversion at API layer
- ✅ **Buffer Cleanup**: Context managers for guaranteed audio buffer deletion

## Troubleshooting

### Database Connection Failed
```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check connection string in .env
echo $DATABASE_URL
```

### MinIO Connection Failed
```bash
# Check MinIO is running
docker-compose ps minio

# Test connection
curl http://localhost:9000/minio/health/live
```

### Azure Speech API Errors
- Verify `AZURE_SPEECH_KEY` is set correctly
- Check `AZURE_SPEECH_REGION` matches your Azure resource region
- Ensure API quota is not exceeded

## License

See LICENSE file in repository root.

## Support

For issues and questions, please refer to project documentation in `spec/` directory.
