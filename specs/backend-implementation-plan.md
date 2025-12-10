# Backend Implementation Plan

**Project**: English Learning App - Backend API & Admin System  
**Version**: 1.2.0 (Updated with Session 2025-12-10 clarifications)  
**Date**: December 10, 2025  
**Technology Stack**: Python 3.12, FastAPI, SQLAlchemy, PostgreSQL, MinIO, Azure Speech SDK  
**Based on**: [spec/backend.md](../spec/backend.md) v1.2.0

## Key Architectural Decisions (from backend.md Clarifications)

### Session 2025-12-09 (Original 5)
1. **Authentication**: JWT-based custom implementation (HS256) - No Firebase Auth dependency
2. **Audio Storage**: MinIO (self-hosted S3-compatible) - User recordings handled as temporary memory buffers, deleted immediately after processing
3. **Speech-to-Text**: Azure Cognitive Services Speech SDK only (built-in pronunciation assessment)
4. **Admin Panel**: SQLAdmin auto-generated admin (FastAPI plugin with automatic UI)
5. **OAuth Flow**: Backend validates OAuth tokens directly, issues JWT tokens

### Session 2025-12-10 (New Clarifications)
6. **Error Handling**: Service methods raise typed exceptions (AuthenticationError, SpeechProcessingError, etc.) - FastAPI exception handlers catch and convert to appropriate HTTP responses. More Pythonic than Result types.
7. **Buffer Cleanup**: Context manager pattern (with statement) for guaranteed audio buffer deletion - Ensures cleanup even on exceptions, most reliable for security compliance

---

## Project Structure

```
apps/backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── config.py               # Configuration and settings
│   ├── database.py             # Database connection and session
│   ├── dependencies.py         # FastAPI dependencies (auth, db session)
│   │
│   ├── api/                    # API routes
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py         # Authentication endpoints
│   │   │   ├── users.py        # User management endpoints
│   │   │   ├── tags.py         # Tag endpoints
│   │   │   ├── game.py         # Game session endpoints
│   │   │   ├── speech.py       # Speech-to-text scoring endpoint
│   │   │   └── admin/
│   │   │       ├── __init__.py
│   │   │       ├── speeches.py # Admin speech CRUD
│   │   │       ├── tags.py     # Admin tag CRUD
│   │   │       └── imports.py  # CSV/audio import
│   │
│   ├── models/                 # SQLAlchemy ORM models
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── tag.py
│   │   ├── speech.py
│   │   ├── game_session.py
│   │   └── game_result.py
│   │
│   ├── schemas/                # Pydantic request/response models
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── tag.py
│   │   ├── speech.py
│   │   ├── game.py
│   │   └── common.py           # Shared schemas (pagination, errors)
│   │
│   ├── services/               # Business logic layer
│   │   ├── __init__.py
│   │   ├── auth_service.py     # Authentication logic
│   │   ├── user_service.py     # User management
│   │   ├── speech_service.py   # Speech filtering and random selection
│   │   ├── game_service.py     # Game session management
│   │   ├── import_service.py   # CSV/audio import logic
│   │   ├── storage_service.py  # MinIO object storage operations
│   │   └── speech_provider/    # Speech-to-text abstraction
│   │       ├── __init__.py
│   │       ├── base.py         # Abstract provider interface
│   │       ├── azure_provider.py  # Azure Speech SDK (MVP)
│   │       └── factory.py      # Provider factory (returns Azure for MVP)
│   │
│   ├── utils/                  # Utility functions
│   │   ├── __init__.py
│   │   ├── security.py         # Password hashing, JWT tokens
│   │   ├── validators.py       # Input validation helpers
│   │   └── logging.py          # Logging configuration
│   │
│   └── admin/                  # Admin panel (SQLAdmin)
│       ├── __init__.py
│       ├── auth.py             # Admin authentication backend
│       └── views.py            # Admin model views
│
├── alembic/                    # Database migrations
│   ├── versions/
│   └── env.py
│
├── tests/                      # Test suite
│   ├── __init__.py
│   ├── conftest.py             # Pytest fixtures
│   ├── unit/
│   │   ├── services/
│   │   └── utils/
│   ├── integration/
│   │   ├── api/
│   │   └── services/
│   └── e2e/
│
├── requirements.txt            # Production dependencies
├── requirements-dev.txt        # Development dependencies
├── alembic.ini                 # Alembic configuration
├── pytest.ini                  # Pytest configuration
├── .env.example                # Environment variables template
├── Dockerfile
├── docker-compose.yml          # Local development setup
└── README.md                   # Setup and development guide
```

---

## Implementation Milestones

### Milestone 1: Project Foundation (Week 1)
**Goal**: Set up project structure, database, and core infrastructure

#### Task 1.1: Initialize Project Scaffold
**Description**: Create FastAPI project structure with proper directory organization for models, schemas, services, and API routes. Set up virtual environment with Python 3.12.

**Acceptance Criteria**:
- Directory structure matches the defined layout
- Virtual environment created with Python 3.12
- Git repository initialized with proper .gitignore
- README.md with setup instructions

**Files to Create**:
- All directories and `__init__.py` files
- `requirements.txt` with initial dependencies
- `.env.example` with all required environment variables (see complete list below)
- `README.md` with project overview

**.env.example Template**:
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/english_practice

# Redis
REDIS_URL=redis://localhost:6379/0

# MinIO / S3 Storage
S3_ENDPOINT_URL=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET_NAME=english-practice-audio
S3_USE_SSL=false

# Azure Speech Services
AZURE_SPEECH_KEY=your_azure_speech_key
AZURE_SPEECH_REGION=eastus

# JWT Authentication
JWT_SECRET_KEY=your-secret-key-at-least-32-chars
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=10080  # 7 days

# OAuth Providers (for token validation)
GOOGLE_CLIENT_ID=your_google_client_id
APPLE_CLIENT_ID=your_apple_client_id
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret

# SQLAdmin Panel
ADMIN_USERNAME=admin
ADMIN_PASSWORD_HASH=bcrypt_hashed_password_here

# Application
ENVIRONMENT=development
DEBUG=true
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8081
```

**Note**: All OAuth validation is backend-direct (no Firebase Admin SDK). Mobile uses Firebase SDKs to acquire OAuth tokens, backend validates with provider APIs.

---

#### Task 1.2: Configure FastAPI Application
**Description**: Set up main FastAPI application with CORS, middleware, error handlers, and configuration management using Pydantic BaseSettings.

**Acceptance Criteria**:
- FastAPI app initializes successfully
- CORS middleware configured for allowed origins
- Global exception handlers for common errors
- Settings loaded from environment variables
- Health check endpoint (`GET /health`)

**Files to Create**:
- `app/main.py`: FastAPI application factory
- `app/config.py`: Settings class with Pydantic
- `app/dependencies.py`: Common dependencies (db session, current user)

---

#### Task 1.3: Set Up Database Connection
**Description**: Configure SQLAlchemy with PostgreSQL, implement session management, and set up connection pooling.

**Acceptance Criteria**:
- SQLAlchemy engine configured with connection pooling
- Session factory created
- Database session dependency for FastAPI
- Connection URL loaded from environment
- Database connection test on startup

**Files to Create**:
- `app/database.py`: Database engine and session
- Update `app/dependencies.py`: Add `get_db` dependency

**Dependencies**:
```
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
alembic>=1.13.0
```

---

#### Task 1.4: Initialize Alembic for Migrations
**Description**: Set up Alembic for database schema migrations with proper configuration to work with SQLAlchemy models.

**Acceptance Criteria**:
- Alembic initialized with `alembic init`
- `alembic.ini` configured with database URL from environment
- `env.py` configured to auto-import models
- Initial migration can be generated

**Files to Create/Modify**:
- `alembic/env.py`: Configure target metadata
- `alembic.ini`: Database URL configuration

**Commands**:
```bash
alembic init alembic
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

---

#### Task 1.5: Set Up Development Environment
**Description**: Create Docker Compose configuration for local development with PostgreSQL, Redis, and MinIO (S3-compatible storage).

**Acceptance Criteria**:
- `docker-compose.yml` with PostgreSQL, Redis, MinIO services
- Services start successfully with `docker-compose up`
- Database accessible on localhost:5432
- Redis accessible on localhost:6379
- **MinIO accessible on localhost:9000** (console at localhost:9001)
- **MinIO bucket auto-created**: `english-practice-audio`
- Environment variables configured for MinIO integration

**Files to Create**:
- `docker-compose.yml`
- `.dockerignore`

**Services**:
- **PostgreSQL 15**: Database for all structured data
- **Redis 7**: Cache and session store
- **MinIO (latest)**: S3-compatible storage for reference audio files
  - Default credentials: `minioadmin` / `minioadmin` (development only)
  - Bucket: `english-practice-audio`
  - Public read access for reference audio URLs

**MinIO Configuration** (docker-compose.yml):
```yaml
minio:
  image: minio/minio:latest
  ports:
    - "9000:9000"  # API
    - "9001:9001"  # Console
  environment:
    MINIO_ROOT_USER: minioadmin
    MINIO_ROOT_PASSWORD: minioadmin
  command: server /data --console-address ":9001"
  volumes:
    - minio_data:/data
```

**Environment Variables** (for backend app):
```
S3_ENDPOINT_URL=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET_NAME=english-practice-audio
S3_USE_SSL=false
```

**Note**: For production deployment, see backend.md deployment guide for MinIO security hardening.

---

### Milestone 2: Data Models & Database Schema (Week 1-2)
**Goal**: Implement all SQLAlchemy models and create database migrations

#### Task 2.1: Implement User Model
**Description**: Create SQLAlchemy model for User entity with all fields, indexes, and relationships as specified in backend.md.

**Acceptance Criteria**:
- User model with all required fields (id, email, name, avatar_url, auth_provider, auth_provider_id, created_at, updated_at)
- UUID primary key using `gen_random_uuid()`
- Unique index on email
- Composite index on (auth_provider, auth_provider_id)
- Enum for auth_provider (email, google, apple, facebook)
- Timestamps with auto-update

**Files to Create**:
- `app/models/user.py`

**Migration**:
```bash
alembic revision --autogenerate -m "Create users table"
```

---

#### Task 2.2: Implement Tag Model
**Description**: Create Tag model with proper indexes and preparation for many-to-many relationship with Speech.

**Acceptance Criteria**:
- Tag model with id, name, category, created_at
- Unique index on name
- Index on category
- UUID primary key

**Files to Create**:
- `app/models/tag.py`

**Migration**:
```bash
alembic revision --autogenerate -m "Create tags table"
```

---

#### Task 2.3: Implement Speech Model with SpeechTag Join Table
**Description**: Create Speech model and many-to-many relationship with Tag through speech_tags join table.

**Acceptance Criteria**:
- Speech model with id, audio_url, text, level, type, created_at, updated_at
- Enum for level (A1, A2, B1, B2, C1)
- Enum for type (question, answer) with default "answer"
- speech_tags join table with composite primary key
- Composite index on (level, type)
- Full-text search index on text (PostgreSQL GIN)
- Relationship configured with cascade delete

**Files to Create**:
- `app/models/speech.py`

**Migration**:
```bash
alembic revision --autogenerate -m "Create speeches and speech_tags tables"
```

---

#### Task 2.4: Implement GameSession Model
**Description**: Create GameSession model for storing completed practice sessions with statistics.

**Acceptance Criteria**:
- GameSession model with all fields from spec
- Foreign key to User with cascade delete
- Enum for mode (listen_only, listen_and_repeat)
- JSONB field for selected_tags array
- Index on (user_id, completed_at)
- Index on (mode, level)

**Files to Create**:
- `app/models/game_session.py`

**Migration**:
```bash
alembic revision --autogenerate -m "Create game_sessions table"
```

---

#### Task 2.5: Implement GameResult Model
**Description**: Create GameResult model for individual sentence results within sessions.

**Acceptance Criteria**:
- GameResult model with all fields from spec
- Foreign keys to GameSession and Speech
- Enum for user_response (correct, incorrect, skipped)
- Composite index on (session_id, sequence_number)
- Index on speech_id
- Cascade delete with session

**Files to Create**:
- `app/models/game_result.py`

**Migration**:
```bash
alembic revision --autogenerate -m "Create game_results table"
```

---

#### Task 2.6: Create Database Seed Script
**Description**: Create script to populate database with sample data for development and testing.

**Acceptance Criteria**:
- Seed script creates 20+ tags across categories (tense, topic)
- Creates 100+ sample speeches across all levels
- Creates 5+ test users
- Script is idempotent (can run multiple times)
- Tagged speeches properly associated

**Files to Create**:
- `scripts/seed_database.py`

**Run Command**:
```bash
python scripts/seed_database.py
```

---

### Milestone 3: Authentication & Security (Week 2)
**Goal**: Implement JWT authentication, password hashing, and security utilities

#### Task 3.1: Implement Security Utilities
**Description**: Create utility functions for password hashing (bcrypt), JWT token generation/validation, and authentication helpers.

**Acceptance Criteria**:
- Password hashing with bcrypt (cost factor 12)
- Password verification
- JWT access token generation (1-hour expiry)
- JWT refresh token generation (7-day expiry)
- Token validation and payload extraction
- Exception classes for auth errors

**Files to Create**:
- `app/utils/security.py`

**Dependencies**:
```
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.6
```

---

#### Task 3.2: Implement Auth Schemas
**Description**: Create Pydantic schemas for authentication requests and responses.

**Acceptance Criteria**:
- RegisterRequest schema (email, password, name validation)
- LoginRequest schema
- SocialAuthRequest schema (provider, token, name)
- TokenResponse schema (user, access_token, refresh_token, token_type)
- RefreshTokenRequest schema
- Email validation
- Password strength validation (min 8 chars)

**Files to Create**:
- `app/schemas/auth.py`

---

#### Task 3.3: Implement Auth Service
**Description**: Create JWT-based authentication business logic for registration, login, social OAuth validation, and token refresh. Backend directly validates OAuth tokens from providers (Google, Apple, Facebook) and issues JWT tokens.

**Acceptance Criteria**:
- User registration with email/password (bcrypt hashing)
- User login with credential validation
- **Social OAuth flow**:
  - Receive OAuth token from mobile app (acquired via Firebase SDKs)
  - Validate token with provider's API (Google: `https://oauth2.googleapis.com/tokeninfo`, Apple: verify JWT signature, Facebook: Graph API)
  - Extract user email and provider ID from verified token
  - Create or retrieve user account
  - Issue JWT access + refresh tokens
- Refresh token logic (validate refresh token, issue new access token)
- User lookup by email and (auth_provider, auth_provider_id)
- Create user with hashed password
- Validate credentials

**Files to Create**:
- `app/services/auth_service.py`

**OAuth Token Validation**:
```python
# Google: Verify ID token
import requests
response = requests.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={token}")
# Returns: email, sub (user ID), email_verified

# Apple: Verify JWT signature with Apple's public keys
# Facebook: Verify with Graph API
```

**Notes**:
- No Firebase Admin SDK dependency on backend
- Mobile app uses Firebase Authentication SDKs (google_sign_in, sign_in_with_apple) to acquire OAuth tokens
- Backend validates tokens directly with provider APIs and issues JWT tokens

---

#### Task 3.4: Implement Auth API Endpoints
**Description**: Create FastAPI routes for authentication endpoints (register, login, social, refresh).

**Acceptance Criteria**:
- POST /api/v1/auth/register (201 Created)
- POST /api/v1/auth/login (200 OK)
- POST /api/v1/auth/social (200 OK)
- POST /api/v1/auth/refresh (200 OK)
- Proper error responses (400, 401, 409)
- Request validation with Pydantic
- Response formatting per spec

**Files to Create**:
- `app/api/v1/auth.py`

---

#### Task 3.5: Implement Current User Dependency
**Description**: Create FastAPI dependency to extract and validate current authenticated user from JWT token.

**Acceptance Criteria**:
- `get_current_user` dependency extracts user from Bearer token
- Token validation with proper error handling
- User lookup from database
- Raises 401 for invalid/expired tokens
- Returns User model instance

**Files to Update**:
- `app/dependencies.py`

---

### Milestone 4: User Management (Week 2-3)
**Goal**: Implement user profile endpoints

#### Task 4.1: Implement User Schemas
**Description**: Create Pydantic schemas for user profile requests and responses.

**Acceptance Criteria**:
- UserResponse schema (id, email, name, avatar_url, auth_provider, created_at)
- UpdateUserRequest schema (name, avatar_url - both optional)
- Exclude sensitive fields (password hash) from responses

**Files to Create**:
- `app/schemas/user.py`

---

#### Task 4.2: Implement User Service
**Description**: Create user management business logic (get profile, update profile, delete account).

**Acceptance Criteria**:
- Get user profile by ID
- Update user profile (name, avatar_url)
- Delete user account (cascade delete sessions/results)
- Update updated_at timestamp on modification

**Files to Create**:
- `app/services/user_service.py`

---

#### Task 4.3: Implement User API Endpoints
**Description**: Create user management endpoints (get profile, update, delete).

**Acceptance Criteria**:
- GET /api/v1/users/me (200 OK)
- PUT /api/v1/users/me (200 OK)
- DELETE /api/v1/users/me (204 No Content)
- Requires authentication
- Proper error handling

**Files to Create**:
- `app/api/v1/users.py`

---

### Milestone 5: Tag Management (Week 3)
**Goal**: Implement tag endpoints for mobile app and admin

#### Task 5.1: Implement Tag Schemas
**Description**: Create Pydantic schemas for tag requests and responses.

**Acceptance Criteria**:
- TagResponse schema (id, name, category)
- TagListResponse schema (tags array)
- CreateTagRequest schema (name, category)
- UpdateTagRequest schema
- TagWithCountResponse (includes speech_count for admin)

**Files to Create**:
- `app/schemas/tag.py`

---

#### Task 5.2: Implement Tag Service
**Description**: Create tag management business logic.

**Acceptance Criteria**:
- List all tags (public endpoint)
- Get tag by ID
- Create tag with unique name validation
- Update tag
- Delete tag (only if speech_count = 0)
- Count speeches per tag for admin

**Files to Create**:
- `app/services/tag_service.py`

---

#### Task 5.3: Implement Public Tag Endpoint
**Description**: Create public tag listing endpoint for mobile app.

**Acceptance Criteria**:
- GET /api/v1/tags (200 OK)
- No authentication required
- Returns all tags sorted by name
- Cached for 1 hour (Redis)

**Files to Create**:
- `app/api/v1/tags.py`

---

### Milestone 6: Speech Content & Game API (Week 3-4)
**Goal**: Implement core game functionality - random speech selection and session management

#### Task 6.1: Implement Speech Schemas
**Description**: Create Pydantic schemas for speech and game session requests/responses.

**Acceptance Criteria**:
- SpeechResponse schema (id, audio_url, text, level, type, tags)
- RandomSpeechesRequest schema (level, type, tags, limit)
- RandomSpeechesResponse schema
- GameSessionCreateRequest schema (mode, level, sentence_type, selected_tags, results array)
- GameResultRequest schema
- GameSessionResponse and GameSessionDetailResponse
- Pagination schema

**Files to Create**:
- `app/schemas/speech.py`
- `app/schemas/game.py`
- `app/schemas/common.py` (pagination)

---

#### Task 6.2: Implement MinIO Storage Service
**Description**: Create MinIO (S3-compatible) storage service for audio file operations and signed URL generation. MinIO SDK provides native Python client optimized for S3-compatible storage.

**Acceptance Criteria**:
- MinIO client initialization with endpoint, access key, secret key
- Upload file to MinIO bucket with unique key
- Upload bytes directly (for in-memory audio data)
- Generate pre-signed URL with expiration (default 1 hour)
- Delete file from MinIO
- List files in bucket/prefix
- Handle duplicate filenames with suffix (_1, _2)
- Bucket auto-creation if not exists
- Support for both local MinIO (development) and production deployment

**Files to Create**:
- `app/services/storage_service.py`

**Dependencies**:
```
minio>=7.2.0
```

**Configuration** (from backend.md):
- Endpoint: `S3_ENDPOINT_URL` (e.g., `localhost:9000` for dev, `storage.englishapp.com` for prod)
- Bucket: `S3_BUCKET_NAME` (e.g., `englishapp-audio`)
- Credentials: `S3_ACCESS_KEY`, `S3_SECRET_KEY`
- SSL: `S3_USE_SSL` (false for dev, true for prod)

**Notes**: 
- User audio recordings for pronunciation scoring should NEVER be persisted to storage
- Only reference audio files (from admin uploads) are stored in MinIO
- Temporary user audio is kept in memory buffer only, passed directly to Azure Speech API

---

#### Task 6.3: Implement Speech Service
**Description**: Create speech content service with random selection algorithm and filtering.

**Acceptance Criteria**:
- Fetch random speeches with filters (level, type, tags)
- SQL query with proper joins and WHERE clause
- Random ordering: `ORDER BY RANDOM() LIMIT n`
- Generate signed URLs for audio files
- Validate at least 1 tag provided
- Return empty array if no matches (not 404)

**Files to Create**:
- `app/services/speech_service.py`

---

#### Task 6.4: Implement Game Service
**Description**: Create game session management service.

**Acceptance Criteria**:
- Create game session with results in transaction
- Validate results count matches total_sentences
- Validate speech_id references exist
- Get user's session history with pagination
- Filter by mode, level, date range
- Get session details with full speech data
- Verify session ownership before returning details

**Files to Create**:
- `app/services/game_service.py`

---

#### Task 6.5: Implement Game API Endpoints
**Description**: Create game endpoints for speech fetching and session management.

**Acceptance Criteria**:
- POST /api/v1/game/speeches/random (200 OK)
- POST /api/v1/game/sessions (201 Created)
- GET /api/v1/game/sessions (200 OK with pagination)
- GET /api/v1/game/sessions/{id} (200 OK)
- All require authentication
- Proper error handling (400, 403, 404)

**Files to Create**:
- `app/api/v1/game.py`

---

### Milestone 7: Speech-to-Text Integration (Week 4-5)
**Goal**: Implement Azure Speech Services for pronunciation scoring (MVP decision: Azure only)

#### Task 7.1: Implement Speech Provider Base Interface
**Description**: Create abstract base class for speech-to-text providers with result data classes. Architecture supports future providers, but MVP uses Azure only.

**Acceptance Criteria**:
- Abstract SpeechProvider class with `transcribe_and_score` method
- ScoringResult dataclass (recognized_text, pronunciation_score, accuracy_score, fluency_score, completeness_score, word_scores, confidence, provider_name, raw_response)
- WordScore dataclass (word, score, error_type)
- Custom exception classes (SpeechProviderError, TimeoutError, APIError, AudioQualityError)

**Files to Create**:
- `app/services/speech_provider/base.py`

**Note**: Abstract interface designed for extensibility, but MVP implementation focuses on Azure only.

---

#### Task 7.2: Implement Azure Speech Provider (MVP)
**Description**: Implement Azure Cognitive Services Speech SDK with built-in pronunciation assessment. This is the **only** speech provider for MVP.

**Acceptance Criteria**:
- Azure Speech SDK integration with pronunciation assessment
- PronunciationAssessmentConfig with reference text
- Audio format handling (MP3, WAV, M4A) - accepts bytes in memory
- **Audio lifecycle**: Accept audio bytes from memory buffer, NEVER write to filesystem
- Extract all scores (pronunciation, accuracy, fluency, completeness)
- Word-level scores with error types
- Error handling with custom exceptions
- 10-second timeout
- Async/await for non-blocking calls

**Files to Create**:
- `app/services/speech_provider/azure_provider.py`

**Dependencies**:
```
azure-cognitiveservices-speech>=1.34.0
```

**Configuration** (from backend.md):
```python
SPEECH_PROVIDER=azure  # MVP: Azure only
AZURE_SPEECH_KEY=<your_key>
AZURE_SPEECH_REGION=eastus  # or your region
SPEECH_API_TIMEOUT=10  # seconds
```

**Implementation Notes**:
- User audio recordings are ephemeral (exist only in request memory)
- Audio bytes passed directly to Azure SDK
- No temporary file creation
- Delete audio buffer immediately after Azure API returns
- Built-in pronunciation assessment eliminates need for custom scoring algorithms

---

#### Task 7.3: Implement Provider Factory (Azure MVP)
**Description**: Create factory pattern for speech provider instantiation. MVP always returns Azure provider, but architecture allows future expansion.

**Acceptance Criteria**:
- Factory creates Azure provider (hardcoded for MVP)
- Validate Azure credentials on startup
- Lazy initialization (create on first use)
- Settings validation (AZURE_SPEECH_KEY, AZURE_SPEECH_REGION required)
- Raise error if credentials missing

**Files to Create**:
- `app/services/speech_provider/factory.py`

**Files to Update**:
- `app/config.py`: Add Azure speech settings

**MVP Implementation**:
```python
def get_speech_provider() -> SpeechProvider:
    """Returns Azure provider for MVP. Future: support multiple providers."""
    return AzureSpeechProvider(
        key=settings.AZURE_SPEECH_KEY,
        region=settings.AZURE_SPEECH_REGION
    )
```

---

#### Task 7.4: Implement Speech Scoring Endpoint
**Description**: Create endpoint for pronunciation scoring with audio upload. Accepts audio bytes, scores immediately, returns result without persisting audio.

**Acceptance Criteria**:
- POST /api/v1/speech/score (200 OK)
- Accept multipart form data (audio file, reference_text, language)
- Validate audio format (MP3, WAV, M4A)
- File size limit (10MB)
- **Audio handling**: Read audio into memory buffer, pass to Azure, discard immediately
- Call speech provider service
- Return scoring result with all Azure pronunciation metrics
- Error handling (400, 422, 503)
- No audio persistence (security requirement)

**Files to Create**:
- `app/api/v1/speech.py`

**Request Flow**:
1. Mobile uploads audio bytes (multipart/form-data)
2. FastAPI reads into memory buffer
3. Validate format and size
4. Pass bytes to Azure Speech Provider
5. Azure processes and returns scores
6. Return scores to mobile
7. Memory buffer garbage collected (no file writes)

**Implementation Pattern (from Session 2025-12-10 clarifications)**:

**Context Manager for Buffer Cleanup**:
```python
class AudioBufferManager:
    """Context manager for guaranteed audio buffer cleanup (Clarification #7)"""
    def __init__(self):
        self.buffer = io.BytesIO()
    
    def __enter__(self):
        return self.buffer
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        # Guaranteed cleanup even on exception
        self.buffer.close()
        del self.buffer
        return False

@router.post("/score")
async def score_pronunciation(
    audio: UploadFile,
    reference_text: str,
    language: str,
):
    try:
        with AudioBufferManager() as buffer:
            # Read audio into managed buffer
            buffer.write(await audio.read())
            buffer.seek(0)
            
            # Process with Azure (may raise exceptions)
            result = await speech_service.score_pronunciation(
                buffer.read(), reference_text, language
            )
            # Buffer automatically deleted even if exception occurs
            
        return result
    except SpeechProcessingError as e:
        raise HTTPException(status_code=503, detail=str(e))
```

**Error Handling Pattern (Clarification #6)**:
Service methods raise typed exceptions, FastAPI handlers convert to HTTP responses:
```python
# Service layer - raise typed exceptions
class SpeechService:
    async def score_pronunciation(self, audio_bytes, ref_text, lang):
        try:
            result = await azure_provider.score(audio_bytes, ref_text, lang)
            return result
        except AzureAPIError as e:
            raise SpeechProcessingError(f"Azure API failed: {e}")
        except TimeoutError:
            raise SpeechProcessingError("Request timed out")

# API layer - convert to HTTP
@app.exception_handler(SpeechProcessingError)
async def speech_error_handler(request, exc):
    return JSONResponse(status_code=503, content={"detail": str(exc)})
```

---

#### Task 7.5: Alternative Providers (DEFERRED - Post-MVP)
**Description**: Future consideration for Google, AWS, Whisper providers. NOT included in MVP.

**Rationale**: 
- Azure provides built-in pronunciation assessment
- Fastest MVP implementation
- Other providers require custom scoring algorithms
- Can be added later if cost or accuracy requirements change

**Future Files** (not created in MVP):
- `app/services/speech_provider/google_provider.py`
- `app/services/speech_provider/aws_provider.py`
- `app/services/speech_provider/whisper_provider.py`

---
```
google-cloud-speech>=2.24.0
boto3>=1.34.0  # for AWS Transcribe
openai>=1.0.0  # for Whisper API
python-Levenshtein>=0.25.0  # for custom scoring
```

---

### Milestone 8: Admin Panel (Week 5)
**Goal**: Implement admin CRUD operations and web UI

#### Task 8.1: Implement Admin Speech CRUD Endpoints
**Description**: Create admin endpoints for speech content management.

**Acceptance Criteria**:
- GET /api/v1/admin/speeches (200 OK with pagination)
- GET /api/v1/admin/speeches/{id} (200 OK)
- POST /api/v1/admin/speeches (201 Created)
- PUT /api/v1/admin/speeches/{id} (200 OK)
- DELETE /api/v1/admin/speeches/{id} (204 No Content)
- Filters: level, type, tag_id, search query
- Require admin authentication
- Full-text search on text field

**Files to Create**:
- `app/api/v1/admin/speeches.py`

**Files to Update**:
- `app/services/speech_service.py`: Add admin CRUD methods

---

#### Task 8.2: Implement Admin Tag CRUD Endpoints
**Description**: Create admin endpoints for tag management.

**Acceptance Criteria**:
- GET /api/v1/admin/tags (200 OK with speech_count)
- POST /api/v1/admin/tags (201 Created)
- PUT /api/v1/admin/tags/{id} (200 OK)
- DELETE /api/v1/admin/tags/{id} (204 No Content)
- Delete only if speech_count = 0 (409 Conflict otherwise)
- Require admin authentication

**Files to Create**:
- `app/api/v1/admin/tags.py`

**Files to Update**:
- `app/services/tag_service.py`: Add admin CRUD methods

---

#### Task 8.3: Implement CSV/Audio Import - Audio Upload
**Description**: Create endpoint for bulk audio file upload with duplicate handling.

**Acceptance Criteria**:
- POST /api/v1/admin/import/audio (200 OK)
- Accept multiple audio files (multipart/form-data)
- Validate file formats (MP3, WAV, M4A)
- File size limit per file (10MB)
- Store in S3: `/audio/uploads/{session_id}/{filename}`
- Handle duplicates with suffix (_1, _2, etc.)
- Generate upload_session_id
- Return list of uploaded files with IDs and URLs

**Files to Create**:
- `app/api/v1/admin/imports.py`

**Files to Update**:
- `app/services/import_service.py`: Create with audio upload logic

---

#### Task 8.4: Implement CSV Import Processing
**Description**: Create endpoint for CSV upload and bulk speech creation.

**Acceptance Criteria**:
- POST /api/v1/admin/import/csv (200 OK)
- Accept CSV file and upload_session_id
- Parse CSV (audio_filename, text, level, type, tags)
- Validate ALL rows before creating ANY records
- Match audio_filename to uploaded files
- Auto-create tags if they don't exist
- Atomic transaction (all or nothing)
- Return detailed error report with row numbers
- Move files to permanent location on success

**Files to Update**:
- `app/api/v1/admin/imports.py`
- `app/services/import_service.py`: Add CSV processing logic

**Dependencies**:
```
pandas>=2.1.0  # for CSV parsing
```

---

#### Task 8.5: Set Up SQLAdmin Panel (MVP Admin Solution)
**Description**: Integrate SQLAdmin auto-generated admin panel for rapid content management. SQLAdmin provides automatic CRUD UI from SQLAlchemy models with zero frontend code.

**Acceptance Criteria**:
- SQLAdmin installed and configured with FastAPI app
- Admin authentication backend (bcrypt-hashed password from environment)
- **ModelView for Speech** with:
  - Columns: id, text, level, type, created_at, updated_at
  - Searchable: text field
  - Filters: level, type
  - Sortable: level, created_at
  - Full CRUD enabled (create, edit, delete)
- **ModelView for Tag** with:
  - Columns: id, name, category, speech_count (computed), created_at
  - Searchable: name
  - Filters: category
  - Full CRUD enabled
- **ModelView for User** (read-only):
  - Columns: id, email, name, auth_provider, created_at
  - Searchable: email, name
  - Filters: auth_provider
  - Can edit, can delete (no create - users created via API)
- **ModelView for GameSession** (read-only):
  - Columns: id, user_id, mode, level, completed_at
  - Filters: mode, level
  - Sortable: completed_at
  - Can delete only (no create/edit - sessions created via API)
- Access at `/admin` URL
- Admin credentials from environment (`ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`)
- Session-based authentication (separate from user JWT auth)

**Files to Create**:
- `app/admin/auth.py`: SQLAdmin authentication backend (bcrypt verification)
- `app/admin/views.py`: Admin model views (SpeechAdmin, TagAdmin, UserAdmin, GameSessionAdmin)

**Files to Update**:
- `app/main.py`: Mount admin panel with `admin.mount_to(app)`
- `app/config.py`: Add `ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`

**Dependencies**:
```
sqladmin>=0.16.0
passlib[bcrypt]>=1.7.4  # for admin password hashing
```

**Benefits** (from backend.md):
- Quick setup (< 1 day implementation)
- Automatic CRUD UI generation from SQLAlchemy models
- Built-in authentication support
- Zero frontend code to maintain
- Works directly with existing database models

**Future Enhancement**: Custom React admin panel for advanced UX (not included in MVP)

---

### Milestone 9: API Security & Rate Limiting (Week 5-6)
**Goal**: Implement security features and performance optimizations

#### Task 9.1: Implement Rate Limiting Middleware
**Description**: Add rate limiting to prevent API abuse using Redis.

**Acceptance Criteria**:
- Rate limiting middleware using slowapi
- Limits per endpoint category:
  - Auth endpoints: 10/min for login, 5/min for register
  - Game endpoints: 60/min per user
  - Speech scoring: 30/min per user
  - Admin endpoints: 200/min per admin
- Rate limit by IP for unauthenticated endpoints
- Rate limit by user ID for authenticated endpoints
- Return 429 Too Many Requests with Retry-After header

**Files to Create**:
- `app/middleware/rate_limit.py`

**Files to Update**:
- `app/main.py`: Add rate limiting middleware

**Dependencies**:
```
slowapi>=0.1.9
redis>=5.0.0
```

---

#### Task 9.2: Implement Request Logging & Tracing
**Description**: Add structured logging with request IDs for debugging and monitoring.

**Acceptance Criteria**:
- Generate unique request ID for each request
- Log all requests with: method, path, status, duration, user_id
- Log errors with full traceback
- JSON-formatted logs (structlog)
- Request ID in response headers
- Include request ID in all log entries

**Files to Create**:
- `app/middleware/logging.py`

**Files to Update**:
- `app/utils/logging.py`: Configure structlog

**Dependencies**:
```
structlog>=24.1.0
```

---

#### Task 9.3: Implement Caching Layer
**Description**: Add Redis caching for frequently accessed data.

**Acceptance Criteria**:
- Cache tag list for 1 hour
- Cache speech filter results for 5 minutes
- Cache key format: `speeches:{level}:{type}:{tag_ids_hash}`
- Cache invalidation on admin updates
- Redis connection from environment
- Graceful fallback if Redis unavailable

**Files to Create**:
- `app/services/cache_service.py`

**Files to Update**:
- `app/services/tag_service.py`: Add caching to list_tags
- `app/services/speech_service.py`: Add caching to random_speeches

---

#### Task 9.4: Implement Input Validation & Sanitization
**Description**: Enhance security with comprehensive input validation.

**Acceptance Criteria**:
- Email validation (regex + format check)
- Password strength validation (min 8 chars, complexity)
- Enum validation for all enum fields
- UUID validation for all ID parameters
- Text sanitization to prevent XSS
- File upload validation (magic bytes, not just extension)
- SQL injection prevention via ORM (already handled by SQLAlchemy)

**Files to Create**:
- `app/utils/validators.py`

**Files to Update**:
- All schema files: Add custom validators

---

#### Task 9.5: Implement Admin Action Audit Logging
**Description**: Log all admin content modifications for accountability.

**Acceptance Criteria**:
- Create audit_logs table (id, admin_user_id, action, resource_type, resource_id, changes, timestamp)
- Log all create/update/delete operations
- Store before/after values for updates
- Admin audit log viewer endpoint
- Include in admin panel

**Files to Create**:
- `app/models/audit_log.py`
- Migration for audit_logs table

**Files to Update**:
- All admin service methods: Add audit logging

---

### Milestone 10: Testing (Week 6-7)
**Goal**: Comprehensive test coverage for all components

#### Task 10.1: Set Up Testing Infrastructure
**Description**: Configure pytest with fixtures for database, auth, and test data.

**Acceptance Criteria**:
- Pytest configuration (pytest.ini)
- Test database setup (separate from development)
- Fixtures: test_db, test_client, test_user, auth_headers
- Factory pattern for test data (factory_boy)
- Coverage configuration (pytest-cov)
- Test command in README

**Files to Create**:
- `tests/conftest.py`
- `pytest.ini`
- `.coveragerc`

**Dependencies**:
```
pytest>=7.4.0
pytest-asyncio>=0.23.0
pytest-cov>=4.1.0
httpx>=0.27.0  # for TestClient
factory-boy>=3.3.0
faker>=22.0.0
```

---

#### Task 10.2: Write Unit Tests - Services Layer
**Description**: Unit tests for all service classes with mocked dependencies.

**Acceptance Criteria**:
- AuthService tests: register, login, social auth, refresh
- UserService tests: get, update, delete
- SpeechService tests: random selection, filtering
- GameService tests: create session, get history, get details
- TagService tests: CRUD operations
- ImportService tests: audio upload, CSV processing
- StorageService tests: upload, signed URLs
- Mock database and external dependencies

**Testing Strategy (from Session 2025-12-10 clarifications)**:

**Mocking Approach (Clarification #6)**:
- **Simple dependencies** (database, HTTP clients): Use `pytest-mock` or `unittest.mock`
- **Complex stateful services** (Azure Speech SDK): Create manual test doubles (fake implementations)

```python
# Example: pytest-mock for simple dependencies
def test_get_user(mocker):
    mock_db = mocker.patch('app.database.Session')
    mock_db.query.return_value.filter.return_value.first.return_value = User(id=1)
    
    result = user_service.get_user(1)
    assert result.id == 1

# Example: Manual test double for Azure Speech SDK (complex stateful)
class FakeAzureSpeechProvider(SpeechProvider):
    """Test double for Azure SDK - simpler than mocking SDK internals"""
    def __init__(self):
        self.call_count = 0
    
    async def score_pronunciation(self, audio, ref_text, lang):
        self.call_count += 1
        return ScoringResult(
            recognized_text=ref_text,
            pronunciation_score=85.0,
            provider_name="fake_azure"
        )

def test_speech_service_with_fake_provider():
    fake_provider = FakeAzureSpeechProvider()
    service = SpeechService(provider=fake_provider)
    
    result = await service.score("audio_bytes", "hello", "en-US")
    assert fake_provider.call_count == 1
    assert result.pronunciation_score == 85.0
```

**Exception Testing (Clarification #6)**:
All service methods should raise typed exceptions, test both success and error paths:
```python
def test_speech_service_raises_on_azure_error():
    # Fake provider that simulates Azure failure
    fake_provider = FakeAzureSpeechProvider(should_fail=True)
    service = SpeechService(provider=fake_provider)
    
    with pytest.raises(SpeechProcessingError) as exc_info:
        await service.score("invalid_audio", "text", "en-US")
    assert "Azure API failed" in str(exc_info.value)
```

**Buffer Cleanup Testing (Clarification #7)**:
Verify context manager guarantees cleanup even on exceptions:
```python
def test_audio_buffer_cleanup_on_exception():
    buffer_was_closed = False
    
    class TestableBufferManager(AudioBufferManager):
        def __exit__(self, exc_type, exc_val, exc_tb):
            nonlocal buffer_was_closed
            buffer_was_closed = True
            return super().__exit__(exc_type, exc_val, exc_tb)
    
    try:
        with TestableBufferManager() as buffer:
            buffer.write(b"test_audio")
            raise ValueError("Simulated error")
    except ValueError:
        pass
    
    assert buffer_was_closed, "Buffer must be cleaned up even on exception"
```

**Files to Create**:
- `tests/unit/services/test_auth_service.py`
- `tests/unit/services/test_user_service.py`
- `tests/unit/services/test_speech_service.py`
- `tests/unit/services/test_game_service.py`
- `tests/unit/services/test_tag_service.py`
- `tests/unit/services/test_import_service.py`
- `tests/unit/services/test_storage_service.py`
- `tests/unit/utils/test_audio_buffer_manager.py` (NEW - context manager tests)

**Target**: 80%+ coverage for services layer

---

#### Task 10.3: Write Unit Tests - Utilities
**Description**: Unit tests for security and validation utilities.

**Acceptance Criteria**:
- Security utils: password hashing, JWT generation/validation
- Validators: email, password strength, UUID, enum
- Mock external dependencies

**Files to Create**:
- `tests/unit/utils/test_security.py`
- `tests/unit/utils/test_validators.py`

---

#### Task 10.4: Write Integration Tests - API Endpoints
**Description**: Integration tests for all API endpoints with real database.

**Acceptance Criteria**:
- Auth endpoints: full flow (register → login → refresh → access)
- User endpoints: get, update, delete
- Tag endpoints: list public tags
- Game endpoints: random speeches, create session, get history
- Speech scoring endpoint: upload audio, get scores
- Admin endpoints: CRUD for speeches and tags
- Import endpoints: audio upload, CSV processing
- Test error cases (400, 401, 403, 404, 409, 422, 503)
- Use test database with fixtures

**Files to Create**:
- `tests/integration/api/test_auth.py`
- `tests/integration/api/test_users.py`
- `tests/integration/api/test_tags.py`
- `tests/integration/api/test_game.py`
- `tests/integration/api/test_speech.py`
- `tests/integration/api/test_admin_speeches.py`
- `tests/integration/api/test_admin_tags.py`
- `tests/integration/api/test_admin_imports.py`

**Target**: 70%+ coverage for API layer

---

#### Task 10.5: Write E2E Tests - Critical User Flows
**Description**: End-to-end tests for complete user journeys.

**Acceptance Criteria**:
- E2E: User registration → game session → view history
- E2E: Admin upload audio → CSV import → speeches available
- E2E: User login → pronunciation scoring → session saved
- Use real services (including speech provider if possible)
- Seed test data for each test
- Clean up after tests

**Files to Create**:
- `tests/e2e/test_user_journey.py`
- `tests/e2e/test_admin_import_flow.py`

---

#### Task 10.6: Write Tests - Speech Provider Abstraction
**Description**: Tests for speech provider interface and Azure implementation (MVP only).

**Acceptance Criteria**:
- Test provider factory (returns Azure provider)
- Mock tests for Azure provider
- Test error handling and timeouts
- Test fallback scoring algorithm
- Integration test with real Azure provider (if credentials available)

**Files to Create**:
- `tests/unit/services/speech_provider/test_factory.py`
- `tests/unit/services/speech_provider/test_azure_provider.py`

**Note**: Google/AWS/Whisper provider tests deferred post-MVP (no implementations in MVP).

---

### Milestone 11: Deployment & Documentation (Week 7-8)
**Goal**: Production-ready deployment configuration and comprehensive documentation

#### Task 11.1: Create Production Dockerfile
**Description**: Multi-stage Dockerfile for optimized production image.

**Acceptance Criteria**:
- Multi-stage build (builder + runtime)
- Python 3.12 base image
- Non-root user for security
- Poetry or pip-tools for dependencies
- Health check command
- Image size optimized (<500MB)
- Environment variables documented

**Files to Create**:
- `Dockerfile`
- `.dockerignore`

---

#### Task 11.2: Create Deployment Configurations
**Description**: Kubernetes manifests or docker-compose for production deployment.

**Acceptance Criteria**:
- Production docker-compose.yml (if using Compose)
- OR Kubernetes manifests (deployment, service, ingress, configmap, secrets)
- Environment-specific configs (staging, production)
- Database connection pooling configured
- Health checks configured
- Resource limits set (CPU, memory)

**Files to Create**:
- `deploy/docker-compose.prod.yml` OR
- `deploy/k8s/deployment.yaml`
- `deploy/k8s/service.yaml`
- `deploy/k8s/ingress.yaml`
- `deploy/k8s/configmap.yaml`

---

#### Task 11.3: Set Up CI/CD Pipeline
**Description**: GitHub Actions workflow for automated testing and deployment.

**Acceptance Criteria**:
- Workflow: lint, test, build, deploy
- Run on push to main and pull requests
- Lint with flake8/black/mypy
- Run all tests with coverage report
- Build Docker image
- Push to container registry
- Deploy to staging on merge to main
- Manual approval for production deploy

**Files to Create**:
- `.github/workflows/ci.yml`
- `.github/workflows/deploy.yml`

---

#### Task 11.4: Create Database Backup & Migration Scripts
**Description**: Scripts for database backup, restore, and production migrations.

**Acceptance Criteria**:
- Backup script (pg_dump with timestamp)
- Restore script
- Pre-migration backup check
- Migration rollback procedure
- Automated daily backups (cron job or K8s CronJob)

**Files to Create**:
- `scripts/backup_database.sh`
- `scripts/restore_database.sh`
- `scripts/migrate_production.sh`

---

#### Task 11.5: Write API Documentation
**Description**: Comprehensive API documentation with examples.

**Acceptance Criteria**:
- OpenAPI/Swagger automatically generated by FastAPI
- Custom descriptions for all endpoints
- Request/response examples
- Authentication documentation
- Error response documentation
- Interactive docs at /docs
- ReDoc at /redoc

**Files to Update**:
- All API route files: Add docstrings and examples
- `app/main.py`: Configure OpenAPI metadata

---

#### Task 11.6: Write Development & Deployment Guide
**Description**: Complete README with setup, development, and deployment instructions.

**Acceptance Criteria**:
- Prerequisites (Python 3.12, Docker, PostgreSQL)
- Local development setup (step-by-step)
- Environment variables documentation
- Database migrations guide
- Running tests
- API documentation link
- Deployment guide
- Troubleshooting section

**Files to Update**:
- `README.md`

**Files to Create**:
- `docs/DEVELOPMENT.md`
- `docs/DEPLOYMENT.md`
- `docs/API.md`
- `docs/ARCHITECTURE.md`

---

### Milestone 12: Monitoring & Production Readiness (Week 8)
**Goal**: Set up monitoring, logging, and production observability

#### Task 12.1: Integrate Application Monitoring
**Description**: Set up Prometheus metrics and Grafana dashboards.

**Acceptance Criteria**:
- Prometheus metrics endpoint (/metrics)
- Metrics: request count, latency (p50, p95, p99), error rate
- Database connection pool metrics
- Custom business metrics (sessions created, users registered)
- Grafana dashboard configuration

**Files to Create**:
- `app/middleware/metrics.py`
- `deploy/grafana/dashboard.json`

**Dependencies**:
```
prometheus-client>=0.19.0
prometheus-fastapi-instrumentator>=6.1.0
```

---

#### Task 12.2: Set Up Centralized Logging
**Description**: Configure structured logging with log aggregation.

**Acceptance Criteria**:
- JSON-formatted logs
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Request ID in all logs
- Error tracking with Sentry integration (optional)
- Log rotation configured
- Shipping logs to centralized system (e.g., ELK, CloudWatch)

**Files to Update**:
- `app/utils/logging.py`: Enhance with log shipping

**Dependencies**:
```
sentry-sdk>=1.40.0  # optional
```

---

#### Task 12.3: Implement Health Checks & Readiness Probes
**Description**: Comprehensive health check endpoints for orchestration.

**Acceptance Criteria**:
- GET /health: Basic liveness (200 OK)
- GET /health/ready: Readiness probe
  - Check database connection
  - Check Redis connection
  - Check S3 connection
  - Return 503 if any dependency unavailable
- Startup probe for slow initialization
- Kubernetes probe configuration

**Files to Update**:
- `app/main.py`: Add health check routes

---

#### Task 12.4: Performance Testing & Optimization
**Description**: Load testing and performance benchmarking.

**Acceptance Criteria**:
- Load test with Locust or k6
- Scenarios:
  - 1000 concurrent users fetching random speeches
  - 100 game sessions created per second
  - 50 concurrent speech scoring requests
- Identify bottlenecks
- Optimize slow queries (add indexes if needed)
- Document performance baselines

**Files to Create**:
- `tests/load/locustfile.py` or `tests/load/script.js` (for k6)
- `docs/PERFORMANCE.md`

**Dependencies**:
```
locust>=2.20.0
```

---

#### Task 12.5: Security Audit & Hardening
**Description**: Final security review and hardening.

**Acceptance Criteria**:
- Run security scanner (Bandit for Python)
- Dependency vulnerability scan (Safety)
- HTTPS/TLS configured
- CORS properly configured (no wildcards in production)
- Rate limiting tested
- SQL injection tests (should be prevented by ORM)
- XSS prevention verified
- Sensitive data not logged
- Security headers configured (CSP, X-Frame-Options, etc.)

**Files to Create**:
- `.github/workflows/security.yml`
- `docs/SECURITY.md`

**Dependencies**:
```
bandit>=1.7.0
safety>=3.0.0
```

---

## Summary of Deliverables

### Code Components
- ✅ 50+ Python modules (models, schemas, services, API routes)
- ✅ 5 database models with migrations
- ✅ 30+ REST API endpoints
- ✅ Speech provider abstraction with Azure implementation (MVP)
- ✅ CSV/audio import workflow
- ✅ Admin panel with SQLAdmin
- ✅ 100+ unit tests
- ✅ 50+ integration tests
- ✅ 10+ E2E tests

### Infrastructure
- ✅ Docker Compose for local development
- ✅ Production Dockerfile
- ✅ Kubernetes manifests or production docker-compose
- ✅ CI/CD pipeline (GitHub Actions)
- ✅ Database backup scripts
- ✅ Monitoring setup (Prometheus + Grafana)

### Documentation
- ✅ Comprehensive README
- ✅ API documentation (OpenAPI/Swagger)
- ✅ Development guide
- ✅ Deployment guide
- ✅ Architecture documentation
- ✅ Performance benchmarks
- ✅ Security documentation

---

## Estimated Timeline

- **Week 1**: Milestones 1-2 (Foundation + Database)
- **Week 2**: Milestones 3-4 (Auth + User Management)
- **Week 3**: Milestones 5-6 (Tags + Game API)
- **Week 4-5**: Milestones 7-8 (Speech-to-Text + Admin)
- **Week 5-6**: Milestone 9 (Security & Performance)
- **Week 6-7**: Milestone 10 (Testing)
- **Week 7-8**: Milestones 11-12 (Deployment + Monitoring)

**Total Estimated Time**: 8 weeks (1 developer, full-time)

---

## Getting Started

1. **Clone repository** and checkout a new feature branch:
   ```bash
   git checkout -b feature/backend-implementation
   ```

2. **Start with Milestone 1, Task 1.1**: Initialize project scaffold

3. **Use this plan to create GitHub issues**:
   - One issue per task
   - Label by milestone
   - Assign story points based on complexity
   - Link related tasks

4. **Track progress** using GitHub Projects or similar tool

5. **Run tests frequently** to catch issues early

6. **Deploy to staging** after each milestone for validation

---

## Dependencies Summary

```txt
# Core Framework
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
pydantic>=2.5.0
pydantic-settings>=2.1.0

# Database
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.0
alembic>=1.13.0

# Authentication & Security
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
python-multipart>=0.0.6

# Storage (MinIO for MVP - S3-compatible)
minio>=7.2.0

# Speech Providers (Azure only for MVP)
azure-cognitiveservices-speech>=1.34.0
python-Levenshtein>=0.25.0

# Caching & Rate Limiting
redis>=5.0.0
slowapi>=0.1.9

# Admin Panel
sqladmin>=0.16.0

# Utilities
pandas>=2.1.0
structlog>=24.1.0

# Monitoring
prometheus-client>=0.19.0
prometheus-fastapi-instrumentator>=6.1.0
sentry-sdk>=1.40.0

# Testing
pytest>=7.4.0
pytest-asyncio>=0.23.0
pytest-cov>=4.1.0
httpx>=0.27.0
factory-boy>=3.3.0
faker>=22.0.0
locust>=2.20.0

# Security
bandit>=1.7.0
safety>=3.0.0
```

**Key Dependency Notes (from backend.md clarifications)**:
- **Storage**: Using `minio` SDK (not `boto3`) for MinIO S3-compatible storage
- **Speech**: Only `azure-cognitiveservices-speech` for MVP (Google Cloud Speech and OpenAI deferred post-MVP)
- **Authentication**: No `firebase-admin` SDK - backend validates OAuth tokens directly with provider APIs
- **Admin Panel**: `sqladmin` with `passlib[bcrypt]` for quick MVP admin solution

---

**End of Implementation Plan**

This plan provides a comprehensive roadmap from project initialization to production deployment. Each task is designed to be independently achievable and can be converted into a GitHub issue for tracking and assignment.
