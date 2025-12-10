# Backend Implementation Plan

**Project**: English Learning App - Backend API & Admin System  
**Date**: December 10, 2025  
**Technology Stack**: Python 3.12, FastAPI, SQLAlchemy, PostgreSQL  
**Based on**: [spec/backend.md](../spec/backend.md)

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
│   │   ├── storage_service.py  # S3/object storage operations
│   │   └── speech_provider/    # Speech-to-text abstraction
│   │       ├── __init__.py
│   │       ├── base.py         # Abstract provider interface
│   │       ├── azure_provider.py
│   │       ├── google_provider.py
│   │       ├── aws_provider.py
│   │       ├── whisper_provider.py
│   │       └── factory.py      # Provider factory
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
- `.env.example` with all required environment variables
- `README.md` with project overview

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
**Description**: Create Docker Compose configuration for local development with PostgreSQL, Redis, and S3-compatible storage (MinIO).

**Acceptance Criteria**:
- `docker-compose.yml` with PostgreSQL, Redis, MinIO services
- Services start successfully with `docker-compose up`
- Database accessible on localhost:5432
- Redis accessible on localhost:6379
- MinIO accessible on localhost:9000

**Files to Create**:
- `docker-compose.yml`
- `.dockerignore`

**Services**:
- PostgreSQL 15
- Redis 7
- MinIO (S3-compatible)

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
**Description**: Create authentication business logic for registration, login, social auth, and token refresh.

**Acceptance Criteria**:
- User registration with email/password
- User login with credential validation
- Social auth (OAuth token verification placeholder)
- Refresh token logic
- User lookup by email
- Create user with hashed password
- Validate credentials

**Files to Create**:
- `app/services/auth_service.py`

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

#### Task 6.2: Implement Storage Service
**Description**: Create S3/object storage service for audio file operations and signed URL generation.

**Acceptance Criteria**:
- S3 client initialization (boto3)
- Upload file to S3 with unique key
- Generate signed URL with expiration (default 1 hour)
- Delete file from S3
- List files in bucket/prefix
- Handle duplicate filenames with suffix (_1, _2)
- Support MinIO for local development

**Files to Create**:
- `app/services/storage_service.py`

**Dependencies**:
```
boto3>=1.34.0
```

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
**Goal**: Implement speech provider abstraction layer with Azure as default

#### Task 7.1: Implement Speech Provider Base Interface
**Description**: Create abstract base class for speech-to-text providers with result data classes.

**Acceptance Criteria**:
- Abstract SpeechProvider class with `transcribe_and_score` method
- ScoringResult dataclass (recognized_text, pronunciation_score, accuracy_score, fluency_score, word_scores, confidence, provider_name)
- WordScore dataclass
- Custom exception classes (SpeechProviderError, TimeoutError, APIError, AudioQualityError)

**Files to Create**:
- `app/services/speech_provider/base.py`

---

#### Task 7.2: Implement Azure Speech Provider
**Description**: Implement Azure Speech Services provider with pronunciation assessment.

**Acceptance Criteria**:
- Azure Speech SDK integration
- Pronunciation assessment configuration
- Audio format handling (MP3, WAV, M4A)
- Extract all scores (pronunciation, accuracy, fluency, completeness)
- Word-level scores
- Error handling with custom exceptions
- 10-second timeout

**Files to Create**:
- `app/services/speech_provider/azure_provider.py`

**Dependencies**:
```
azure-cognitiveservices-speech>=1.34.0
```

---

#### Task 7.3: Implement Provider Factory
**Description**: Create factory pattern for speech provider instantiation based on configuration.

**Acceptance Criteria**:
- Factory creates provider based on SPEECH_PROVIDER env var
- Support: azure, google, aws, whisper
- Raise error for unknown provider
- Lazy initialization (create on first use)
- Settings validation on startup

**Files to Create**:
- `app/services/speech_provider/factory.py`

**Files to Update**:
- `app/config.py`: Add speech provider settings

---

#### Task 7.4: Implement Speech Scoring Endpoint
**Description**: Create endpoint for pronunciation scoring with audio upload.

**Acceptance Criteria**:
- POST /api/v1/speech/score (200 OK)
- Accept multipart form data (audio file, reference_text, language)
- Validate audio format (MP3, WAV, M4A)
- File size limit (10MB)
- Call speech provider service
- Return scoring result
- Error handling (400, 422, 503)

**Files to Create**:
- `app/api/v1/speech.py`

---

#### Task 7.5: Implement Additional Providers (Optional)
**Description**: Implement Google, AWS, and Whisper speech providers with fallback scoring algorithm.

**Acceptance Criteria**:
- Google Speech-to-Text integration
- AWS Transcribe integration
- Whisper (local or API) integration
- Custom pronunciation scoring using Levenshtein distance
- Consistent ScoringResult format
- Provider-specific error handling

**Files to Create**:
- `app/services/speech_provider/google_provider.py`
- `app/services/speech_provider/aws_provider.py`
- `app/services/speech_provider/whisper_provider.py`

**Dependencies**:
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

#### Task 8.5: Set Up SQLAdmin Panel
**Description**: Integrate SQLAdmin for web-based admin interface.

**Acceptance Criteria**:
- SQLAdmin installed and configured
- Admin authentication backend (username/password)
- ModelView for Speech with filters (level, type)
- ModelView for Tag
- ModelView for User (read-only)
- ModelView for GameSession (read-only)
- Access at /admin URL
- Admin credentials from environment variables

**Files to Create**:
- `app/admin/auth.py`: Admin authentication backend
- `app/admin/views.py`: Admin model views

**Files to Update**:
- `app/main.py`: Mount admin panel

**Dependencies**:
```
sqladmin>=0.16.0
```

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

**Files to Create**:
- `tests/unit/services/test_auth_service.py`
- `tests/unit/services/test_user_service.py`
- `tests/unit/services/test_speech_service.py`
- `tests/unit/services/test_game_service.py`
- `tests/unit/services/test_tag_service.py`
- `tests/unit/services/test_import_service.py`
- `tests/unit/services/test_storage_service.py`

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
**Description**: Tests for speech provider interface and implementations.

**Acceptance Criteria**:
- Test provider factory
- Mock tests for each provider (Azure, Google, AWS, Whisper)
- Test error handling and timeouts
- Test fallback scoring algorithm
- Integration test with real Azure provider (if credentials available)

**Files to Create**:
- `tests/unit/services/speech_provider/test_factory.py`
- `tests/unit/services/speech_provider/test_azure_provider.py`
- `tests/unit/services/speech_provider/test_providers.py`

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
- ✅ Speech provider abstraction with 4 implementations
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

# Storage
boto3>=1.34.0

# Speech Providers
azure-cognitiveservices-speech>=1.34.0
google-cloud-speech>=2.24.0
openai>=1.0.0
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

---

**End of Implementation Plan**

This plan provides a comprehensive roadmap from project initialization to production deployment. Each task is designed to be independently achievable and can be converted into a GitHub issue for tracking and assignment.
