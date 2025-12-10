# English Learning App

A comprehensive English pronunciation practice application with AI-powered speech assessment, gamified learning, and content management.

## 🌟 Features

### For Learners
- **Intelligent Speech Practice**: Listen to authentic English speech samples and practice pronunciation
- **AI-Powered Feedback**: Real-time pronunciation scoring using Azure Speech Services
- **Adaptive Difficulty**: Filter content by level (beginner, intermediate, advanced) and type (word, phrase, sentence, paragraph)
- **Progress Tracking**: View detailed history of practice sessions and track improvement over time
- **Gamified Learning**: Earn scores and track metrics (accuracy, fluency, completeness)
- **Multi-Platform**: Mobile app (iOS/Android) and web interface

### For Administrators
- **Content Management**: CRUD operations for speech samples and tags through admin panel
- **Bulk Import**: CSV-based bulk content upload with audio file management
- **Analytics Dashboard**: Monitor user engagement and content performance
- **Tag System**: Organize content by topics, themes, and difficulty

## 🏗️ Architecture

```
english-learning-app/
├── apps/
│   ├── backend/          # FastAPI REST API
│   └── mobile/           # React Native mobile app
├── spec/                 # Technical specifications
└── README.md            # This file
```

### Tech Stack

**Backend**:
- **Framework**: FastAPI (Python 3.12)
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Storage**: MinIO (S3-compatible)
- **AI/ML**: Azure Speech Services
- **Monitoring**: Prometheus + Grafana
- **Testing**: pytest, pytest-asyncio

**Mobile**:
- React Native
- TypeScript
- Expo

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Python 3.12+ (for local development)
- Node.js 18+ (for mobile app)
- Azure Speech Services API key

### Backend Setup

1. **Clone the repository**:
```bash
git clone https://github.com/yourusername/english-learning-app.git
cd english-learning-app/apps/backend
```

2. **Copy environment template**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Start services with Docker Compose**:
```bash
docker-compose up -d
```

4. **Run database migrations**:
```bash
docker-compose exec backend alembic upgrade head
```

5. **Seed initial data**:
```bash
docker-compose exec backend python scripts/seed_database.py
```

6. **Access the application**:
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- Admin Panel: http://localhost:8000/admin
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001

### Development Mode

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run migrations
alembic upgrade head

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 📖 API Documentation

### Authentication

#### Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "learner123",
  "password": "SecurePass123!"
}
```

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

#### Social OAuth
```http
POST /api/v1/auth/social
Content-Type: application/json

{
  "provider": "google",
  "token": "oauth_token_here"
}
```

### Game Play

#### Get Random Speeches
```http
POST /api/v1/game/speeches/random
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "count": 10,
  "level": "beginner",
  "type": "word",
  "tag_ids": [1, 2, 3]
}
```

#### Score Pronunciation
```http
POST /api/v1/speech/score
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

reference_text: "Hello world"
audio_file: <binary_audio_data>
```

#### Create Game Session
```http
POST /api/v1/game/sessions
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "mode": "practice",
  "speeches": [
    {
      "speech_id": 1,
      "accuracy_score": 85,
      "fluency_score": 90,
      "completeness_score": 95,
      "overall_score": 90,
      "pronunciation_assessment": { ... }
    }
  ]
}
```

### User Profile

#### Get Profile
```http
GET /api/v1/users/me
Authorization: Bearer <access_token>
```

#### Update Profile
```http
PUT /api/v1/users/me
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "username": "newusername"
}
```

#### Get Session History
```http
GET /api/v1/game/sessions?page=1&page_size=20&mode=practice&level=beginner
Authorization: Bearer <access_token>
```

### Admin APIs

#### Create Speech
```http
POST /api/v1/admin/speeches
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "text": "Hello world",
  "level": "beginner",
  "type": "phrase",
  "audio_url": "https://storage.example.com/audio.mp3",
  "phonetic": "həˈloʊ wɜrld",
  "translation": "Xin chào thế giới",
  "tag_ids": [1, 2]
}
```

#### Bulk Import CSV
```http
POST /api/v1/admin/import/csv
Authorization: Bearer <admin_token>
Content-Type: multipart/form-data

csv_file: <speeches.csv>
```

Full API documentation available at `/docs` when the server is running.

## 🧪 Testing

### Run All Tests
```bash
pytest
```

### Run with Coverage
```bash
pytest --cov=app --cov-report=html
```

### Run Specific Test Suite
```bash
# Unit tests
pytest tests/unit/

# Integration tests
pytest tests/integration/

# E2E tests
pytest tests/e2e/
```

### Security Scans
```bash
# Check for security vulnerabilities
bandit -r app/ -ll

# Check dependencies
safety check
```

## 🚢 Deployment

### Production Deployment

1. **Configure production environment**:
```bash
cp .env.prod.template .env.prod
# Edit .env.prod with production values
```

2. **Build and start production stack**:
```bash
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

3. **Run migrations**:
```bash
docker-compose -f docker-compose.prod.yml exec backend alembic upgrade head
```

4. **Monitor services**:
- Application health: http://your-domain:8000/health
- Metrics: http://your-domain:8000/metrics
- Prometheus: http://your-domain:9090
- Grafana: http://your-domain:3001

### Environment Variables

See `.env.prod.template` for all required configuration.

**Critical Variables**:
- `AZURE_SPEECH_KEY`: Azure Speech Services API key
- `AZURE_SPEECH_REGION`: Azure region (e.g., eastus)
- `JWT_SECRET_KEY`: Secret key for JWT token signing
- `POSTGRES_PASSWORD`: Database password
- `REDIS_PASSWORD`: Redis password
- `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`: MinIO credentials

### Database Migrations

```bash
# Create new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback one version
alembic downgrade -1

# View migration history
alembic history
```

## 📊 Monitoring

### Prometheus Metrics

Available at `/metrics` endpoint:
- `http_requests_total`: Total HTTP requests by method, endpoint, status
- `http_request_duration_seconds`: Request latency histogram
- `database_operations_total`: Database operations counter
- `business_events_total`: Business events (registrations, games played, etc.)

### Grafana Dashboards

Pre-configured dashboards for:
- Application performance (request rate, latency, errors)
- Database metrics (connections, query performance)
- Business metrics (daily active users, game sessions, pronunciation scores)

## 🔒 Security

### Rate Limiting
- Default: 100 requests/minute per IP
- Login: 10 attempts/minute
- Registration: 5 attempts/minute

### Authentication
- JWT tokens with 30-minute expiration
- Refresh tokens with 7-day expiration
- bcrypt password hashing
- OAuth support (Google, Apple, Facebook)

### Data Protection
- User audio never persisted (memory buffers only)
- HTTPS enforced in production
- SQL injection protection via SQLAlchemy ORM
- CORS configuration for trusted origins

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Python: Follow PEP 8, use Black formatter
- Type hints required for all functions
- Docstrings for public APIs
- 80%+ test coverage

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact

For questions or support, please open an issue on GitHub.

## 🙏 Acknowledgments

- Azure Speech Services for pronunciation assessment
- FastAPI framework and community
- MinIO for object storage
- All open-source contributors
