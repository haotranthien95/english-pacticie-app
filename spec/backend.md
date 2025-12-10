# Backend Specification

**Version**: 1.0.0  
**Last Updated**: December 10, 2025  
**Status**: Draft

## Overview

This document specifies the backend API and admin system for the English Learning App. The backend provides RESTful JSON APIs for mobile client operations, admin content management tools, and integrations with speech-to-text services for pronunciation scoring.

**Technology Stack**:
- **Framework**: FastAPI (Python 3.10+)
- **Database**: PostgreSQL 12+
- **Storage**: S3-compatible object storage for audio files
- **Authentication**: Firebase Auth or JWT-based custom implementation

---

## Data Models

### User

Represents a learner account in the system.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Unique user identifier |
| `email` | String | Unique, Not Null | User email address |
| `name` | String | Not Null | User display name |
| `avatar_url` | String | Nullable | URL to user profile image |
| `auth_provider` | Enum | Not Null | Authentication method: `email`, `google`, `apple`, `facebook` |
| `auth_provider_id` | String | Nullable | Provider-specific user ID for OAuth |
| `created_at` | Timestamp | Not Null | Account creation time |
| `updated_at` | Timestamp | Not Null | Last profile update time |

**Indexes**:
- Unique index on `email`
- Index on `auth_provider` + `auth_provider_id`

---

### Tag

Represents a categorization label for speech content (e.g., "Present Tense", "Food").

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Unique tag identifier |
| `name` | String | Unique, Not Null | Tag display name |
| `category` | String | Nullable | Tag grouping (e.g., "tense", "topic") |
| `created_at` | Timestamp | Not Null | Tag creation time |

**Indexes**:
- Unique index on `name`
- Index on `category`

---

### Speech

Represents a single English sentence with audio for learning practice.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Unique speech identifier |
| `audio_url` | String | Not Null | S3 URL to audio file |
| `text` | String | Not Null | English sentence text |
| `level` | Enum | Not Null | Difficulty: `A1`, `A2`, `B1`, `B2`, `C1` |
| `type` | Enum | Not Null, Default: `answer` | Sentence type: `question`, `answer` |
| `created_at` | Timestamp | Not Null | Record creation time |
| `updated_at` | Timestamp | Not Null | Last update time |

**Relationships**:
- Many-to-many with `Tag` through `speech_tags` join table

**Indexes**:
- Composite index on (`level`, `type`)
- Full-text index on `text` for search functionality

---

### SpeechTag (Join Table)

Links speeches to their associated tags.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `speech_id` | UUID | Foreign Key, Not Null | References `Speech.id` |
| `tag_id` | UUID | Foreign Key, Not Null | References `Tag.id` |

**Constraints**:
- Primary key: (`speech_id`, `tag_id`)
- Foreign key cascade on delete

**Indexes**:
- Index on `tag_id` for reverse lookups

---

### GameSession

Represents a completed practice session by a user.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Unique session identifier |
| `user_id` | UUID | Foreign Key, Not Null | References `User.id` |
| `mode` | Enum | Not Null | Game mode: `listen_only`, `listen_and_repeat` |
| `level` | Enum | Not Null | Selected difficulty level |
| `sentence_type` | Enum | Not Null | Selected type: `question`, `answer` |
| `selected_tags` | JSON Array | Not Null | Array of tag IDs used as filters |
| `total_sentences` | Integer | Not Null | Number of sentences in session |
| `correct_count` | Integer | Not Null | User's correct responses |
| `max_streak` | Integer | Not Null | Longest consecutive correct streak |
| `avg_pronunciation_score` | Float | Nullable | Average score (0-100), null for listen-only |
| `duration_seconds` | Integer | Not Null | Total session duration |
| `started_at` | Timestamp | Not Null | Session start time |
| `completed_at` | Timestamp | Not Null | Session completion time |

**Relationships**:
- One-to-many with `GameResult` (session contains multiple results)
- Many-to-one with `User`

**Indexes**:
- Index on `user_id` + `completed_at` for history queries
- Index on `mode`, `level` for analytics

---

### GameResult

Represents user's interaction with a single sentence within a game session.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `id` | UUID | Primary Key | Unique result identifier |
| `session_id` | UUID | Foreign Key, Not Null | References `GameSession.id` |
| `speech_id` | UUID | Foreign Key, Not Null | References `Speech.id` |
| `sequence_number` | Integer | Not Null | Order within session (1-based) |
| `user_response` | Enum | Not Null | User evaluation: `correct`, `incorrect`, `skipped` |
| `pronunciation_score` | Float | Nullable | Score 0-100, null for listen-only mode |
| `recognized_text` | String | Nullable | Speech-to-text output, null for listen-only |
| `response_time_ms` | Integer | Not Null | Time taken to respond in milliseconds |
| `created_at` | Timestamp | Not Null | Result timestamp |

**Relationships**:
- Many-to-one with `GameSession`
- Many-to-one with `Speech` (for reference, not ownership)

**Indexes**:
- Composite index on (`session_id`, `sequence_number`) for ordered retrieval
- Index on `speech_id` for analytics

---

## REST API Endpoints

### Base URL

```
Development: http://localhost:8000/api/v1
Production: https://api.englishapp.com/api/v1
```

### Authentication

Protected endpoints require `Authorization: Bearer <access_token>` header.

---

## Authentication Endpoints

### POST /auth/register

Register new user with email/password.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "name": "Nguyen Van A"
}
```

**Response** (201 Created):
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Nguyen Van A",
    "avatar_url": null
  },
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token",
  "token_type": "Bearer"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid email format or weak password
- `409 Conflict`: Email already registered

---

### POST /auth/login

Authenticate user with email/password.

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Response** (200 OK):
```json
{
  "user": { ... },
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token",
  "token_type": "Bearer"
}
```

**Error Responses**:
- `401 Unauthorized`: Invalid credentials

---

### POST /auth/social

Login or register with social OAuth provider.

**Request Body**:
```json
{
  "provider": "google",
  "token": "oauth_token_from_provider",
  "name": "Nguyen Van A"
}
```

**Supported Providers**: `google`, `apple`, `facebook`

**Response** (200 OK):
```json
{
  "user": { ... },
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token",
  "token_type": "Bearer"
}
```

**Notes**: 
- If user doesn't exist, creates new account
- If user exists, returns existing account tokens

---

### POST /auth/refresh

Refresh access token using refresh token.

**Request Body**:
```json
{
  "refresh_token": "jwt_refresh_token"
}
```

**Response** (200 OK):
```json
{
  "access_token": "new_jwt_access_token",
  "token_type": "Bearer"
}
```

---

## User Endpoints

### GET /users/me

Get current authenticated user profile.

**Headers**: `Authorization: Bearer <token>`

**Response** (200 OK):
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "Nguyen Van A",
  "avatar_url": "https://storage.example.com/avatars/uuid.jpg",
  "auth_provider": "google",
  "created_at": "2025-12-10T10:00:00Z"
}
```

---

### PUT /users/me

Update current user profile.

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
  "name": "Nguyen Van B",
  "avatar_url": "https://storage.example.com/avatars/new.jpg"
}
```

**Response** (200 OK):
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "Nguyen Van B",
  "avatar_url": "https://storage.example.com/avatars/new.jpg",
  "updated_at": "2025-12-10T11:30:00Z"
}
```

---

### DELETE /users/me

Delete user account and all associated data (game history, results).

**Headers**: `Authorization: Bearer <token>`

**Response** (204 No Content)

---

## Tag Endpoints

### GET /tags

Get all available tags for filtering speeches.

**Query Parameters**: None

**Response** (200 OK):
```json
{
  "tags": [
    {
      "id": "uuid-1",
      "name": "Present Tense",
      "category": "tense"
    },
    {
      "id": "uuid-2",
      "name": "Food",
      "category": "topic"
    },
    {
      "id": "uuid-3",
      "name": "Travel",
      "category": "topic"
    }
  ]
}
```

**Notes**: This endpoint is public (no authentication required) for mobile app game configuration screen.

---

## Game Endpoints

### POST /game/speeches/random

Fetch random speeches matching filters for a game session.

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
  "level": "A1",
  "type": "question",
  "tags": ["uuid-1", "uuid-2"],
  "limit": 10
}
```

**Field Constraints**:
- `level`: Required, one of `A1`, `A2`, `B1`, `B2`, `C1`
- `type`: Required, one of `question`, `answer`
- `tags`: Required, array of tag UUIDs (at least 1)
- `limit`: Optional, integer 1-50, default 10

**Response** (200 OK):
```json
{
  "speeches": [
    {
      "id": "speech-uuid-1",
      "audio_url": "https://cdn.example.com/audio/A1/speech1.mp3?signature=...",
      "text": "What is your name?",
      "level": "A1",
      "type": "question",
      "tags": [
        { "id": "uuid-1", "name": "Present Tense" },
        { "id": "uuid-2", "name": "Food" }
      ]
    },
    {
      "id": "speech-uuid-2",
      "audio_url": "https://cdn.example.com/audio/A1/speech2.mp3?signature=...",
      "text": "Where do you live?",
      "level": "A1",
      "type": "question",
      "tags": [
        { "id": "uuid-1", "name": "Present Tense" }
      ]
    }
  ]
}
```

**Business Logic**:
- Filter speeches by level AND type AND (any of the selected tags)
- SQL: `level = ? AND type = ? AND EXISTS (SELECT 1 FROM speech_tags WHERE speech_id = speeches.id AND tag_id IN (?))`
- Randomize results: `ORDER BY RANDOM() LIMIT ?`
- Return signed URLs for audio files with 1-hour expiration

**Error Responses**:
- `400 Bad Request`: Invalid parameters or empty tags array
- `404 Not Found`: No speeches match the filters

---

### POST /game/sessions

Save completed game session results.

**Headers**: `Authorization: Bearer <token>`

**Request Body**:
```json
{
  "mode": "listen_only",
  "level": "A1",
  "sentence_type": "question",
  "selected_tags": ["uuid-1", "uuid-2"],
  "total_sentences": 10,
  "correct_count": 8,
  "max_streak": 5,
  "avg_pronunciation_score": null,
  "duration_seconds": 300,
  "started_at": "2025-12-10T10:00:00Z",
  "completed_at": "2025-12-10T10:05:00Z",
  "results": [
    {
      "speech_id": "speech-uuid-1",
      "sequence_number": 1,
      "user_response": "correct",
      "pronunciation_score": null,
      "recognized_text": null,
      "response_time_ms": 5000
    },
    {
      "speech_id": "speech-uuid-2",
      "sequence_number": 2,
      "user_response": "incorrect",
      "pronunciation_score": null,
      "recognized_text": null,
      "response_time_ms": 4500
    }
  ]
}
```

**Field Notes**:
- `mode`: `listen_only` or `listen_and_repeat`
- `avg_pronunciation_score`: null for listen_only, float 0-100 for listen_and_repeat
- `results`: Array of individual sentence results, must match `total_sentences` count

**Response** (201 Created):
```json
{
  "session_id": "session-uuid",
  "message": "Session saved successfully"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid data or results count mismatch
- `404 Not Found`: One or more speech_id references don't exist

---

### GET /game/sessions

Get user's game session history.

**Headers**: `Authorization: Bearer <token>`

**Query Parameters**:
- `page`: Integer, default 1
- `limit`: Integer, default 20, max 100
- `mode`: Optional filter, `listen_only` or `listen_and_repeat`
- `level`: Optional filter, one of `A1`, `A2`, `B1`, `B2`, `C1`
- `from_date`: Optional ISO date, filter sessions after this date
- `to_date`: Optional ISO date, filter sessions before this date

**Example Request**:
```
GET /game/sessions?page=1&limit=20&mode=listen_only&level=A1
```

**Response** (200 OK):
```json
{
  "sessions": [
    {
      "id": "session-uuid-1",
      "mode": "listen_only",
      "level": "A1",
      "sentence_type": "question",
      "total_sentences": 10,
      "correct_count": 8,
      "max_streak": 5,
      "duration_seconds": 300,
      "completed_at": "2025-12-10T10:05:00Z"
    },
    {
      "id": "session-uuid-2",
      "mode": "listen_only",
      "level": "A1",
      "sentence_type": "answer",
      "total_sentences": 15,
      "correct_count": 12,
      "max_streak": 7,
      "duration_seconds": 420,
      "completed_at": "2025-12-09T15:20:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "total_pages": 3
  }
}
```

**Business Logic**:
- Filter by `user_id` (from authentication token)
- Apply optional filters (mode, level, date range)
- Order by `completed_at DESC`
- Paginate results

---

### GET /game/sessions/{session_id}

Get detailed results for a specific game session.

**Headers**: `Authorization: Bearer <token>`

**Response** (200 OK):
```json
{
  "id": "session-uuid-1",
  "mode": "listen_only",
  "level": "A1",
  "sentence_type": "question",
  "selected_tags": ["Present Tense", "Food"],
  "total_sentences": 10,
  "correct_count": 8,
  "max_streak": 5,
  "avg_pronunciation_score": null,
  "duration_seconds": 300,
  "started_at": "2025-12-10T10:00:00Z",
  "completed_at": "2025-12-10T10:05:00Z",
  "results": [
    {
      "sequence_number": 1,
      "speech": {
        "id": "speech-uuid-1",
        "audio_url": "https://cdn.example.com/audio/A1/speech1.mp3?signature=...",
        "text": "What is your name?",
        "level": "A1",
        "type": "question",
        "tags": [
          { "id": "uuid-1", "name": "Present Tense" }
        ]
      },
      "user_response": "correct",
      "pronunciation_score": null,
      "recognized_text": null,
      "response_time_ms": 5000
    },
    {
      "sequence_number": 2,
      "speech": {
        "id": "speech-uuid-2",
        "audio_url": "https://cdn.example.com/audio/A1/speech2.mp3?signature=...",
        "text": "Where do you live?",
        "level": "A1",
        "type": "question",
        "tags": [
          { "id": "uuid-1", "name": "Present Tense" }
        ]
      },
      "user_response": "incorrect",
      "pronunciation_score": null,
      "recognized_text": null,
      "response_time_ms": 4500
    }
  ]
}
```

**Business Logic**:
- Verify `session_id` belongs to authenticated user
- Join with speech data and tags for full context
- Generate signed URLs for audio files
- Order results by `sequence_number`

**Error Responses**:
- `403 Forbidden`: Session belongs to different user
- `404 Not Found`: Session doesn't exist

---

## Speech-to-Text Integration

### POST /speech/score

Score user pronunciation by comparing recorded audio with reference text.

**Headers**: `Authorization: Bearer <token>`

**Request Body** (multipart/form-data):
- `audio`: Audio file (MP3, WAV, M4A)
- `reference_text`: String, the correct sentence text
- `language`: String, default "en-US"

**Example**:
```
POST /speech/score
Content-Type: multipart/form-data

audio=<binary_audio_data>
reference_text=What is your name?
language=en-US
```

**Response** (200 OK):
```json
{
  "recognized_text": "What is your name",
  "pronunciation_score": 87.5,
  "accuracy_score": 95.0,
  "fluency_score": 80.0,
  "completeness_score": 90.0,
  "word_scores": [
    { "word": "What", "score": 95.0 },
    { "word": "is", "score": 90.0 },
    { "word": "your", "score": 85.0 },
    { "word": "name", "score": 80.0 }
  ],
  "provider": "azure"
}
```

**Field Descriptions**:
- `recognized_text`: Transcription from speech-to-text
- `pronunciation_score`: Overall pronunciation accuracy (0-100)
- `accuracy_score`: Phoneme-level accuracy (optional, provider-dependent)
- `fluency_score`: Speech fluency metric (optional)
- `completeness_score`: How complete the utterance was (optional)
- `word_scores`: Per-word pronunciation scores (optional)
- `provider`: Which speech provider was used

**Error Responses**:
- `400 Bad Request`: Invalid audio format or missing parameters
- `422 Unprocessable Entity`: Audio quality too poor to process
- `503 Service Unavailable`: Speech provider temporarily unavailable

---

## Admin Endpoints

All admin endpoints require admin role authentication.

### GET /admin/speeches

List all speeches with pagination and filters.

**Headers**: `Authorization: Bearer <admin_token>`

**Query Parameters**:
- `page`: Integer, default 1
- `limit`: Integer, default 50, max 200
- `level`: Optional filter
- `type`: Optional filter
- `tag_id`: Optional filter by tag UUID
- `search`: Optional text search in speech text

**Response** (200 OK):
```json
{
  "speeches": [
    {
      "id": "uuid",
      "audio_url": "https://...",
      "text": "What is your name?",
      "level": "A1",
      "type": "question",
      "tags": [
        { "id": "uuid-1", "name": "Present Tense" }
      ],
      "created_at": "2025-12-10T10:00:00Z",
      "updated_at": "2025-12-10T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 500,
    "total_pages": 10
  }
}
```

---

### GET /admin/speeches/{speech_id}

Get single speech by ID.

**Headers**: `Authorization: Bearer <admin_token>`

**Response** (200 OK): Single speech object with all fields and tags.

---

### POST /admin/speeches

Create new speech item.

**Headers**: `Authorization: Bearer <admin_token>`

**Request Body**:
```json
{
  "audio_url": "https://storage.example.com/audio/new.mp3",
  "text": "How are you today?",
  "level": "A1",
  "type": "question",
  "tag_ids": ["uuid-1", "uuid-2"]
}
```

**Response** (201 Created):
```json
{
  "id": "new-uuid",
  "audio_url": "https://storage.example.com/audio/new.mp3",
  "text": "How are you today?",
  "level": "A1",
  "type": "question",
  "tags": [
    { "id": "uuid-1", "name": "Present Tense" },
    { "id": "uuid-2", "name": "Greetings" }
  ],
  "created_at": "2025-12-10T12:00:00Z",
  "updated_at": "2025-12-10T12:00:00Z"
}
```

---

### PUT /admin/speeches/{speech_id}

Update existing speech item.

**Headers**: `Authorization: Bearer <admin_token>`

**Request Body**: Same as POST, all fields optional
```json
{
  "text": "How are you doing today?",
  "tag_ids": ["uuid-1", "uuid-3"]
}
```

**Response** (200 OK): Updated speech object

---

### DELETE /admin/speeches/{speech_id}

Delete speech item.

**Headers**: `Authorization: Bearer <admin_token>`

**Response** (204 No Content)

**Notes**: 
- Deletes speech and removes associations in `speech_tags` table
- Does NOT delete historical game results that reference this speech (preserves data integrity)

---

### GET /admin/tags

List all tags.

**Headers**: `Authorization: Bearer <admin_token>`

**Response** (200 OK):
```json
{
  "tags": [
    {
      "id": "uuid-1",
      "name": "Present Tense",
      "category": "tense",
      "speech_count": 45,
      "created_at": "2025-12-01T10:00:00Z"
    },
    {
      "id": "uuid-2",
      "name": "Food",
      "category": "topic",
      "speech_count": 32,
      "created_at": "2025-12-01T10:00:00Z"
    }
  ]
}
```

**Notes**: Includes `speech_count` showing how many speeches use each tag.

---

### POST /admin/tags

Create new tag.

**Headers**: `Authorization: Bearer <admin_token>`

**Request Body**:
```json
{
  "name": "Past Tense",
  "category": "tense"
}
```

**Response** (201 Created):
```json
{
  "id": "new-uuid",
  "name": "Past Tense",
  "category": "tense",
  "speech_count": 0,
  "created_at": "2025-12-10T12:00:00Z"
}
```

---

### PUT /admin/tags/{tag_id}

Update tag.

**Headers**: `Authorization: Bearer <admin_token>`

**Request Body**:
```json
{
  "name": "Simple Past Tense",
  "category": "tense"
}
```

**Response** (200 OK): Updated tag object

---

### DELETE /admin/tags/{tag_id}

Delete tag.

**Headers**: `Authorization: Bearer <admin_token>`

**Response** (204 No Content)

**Notes**:
- Only allows deletion if `speech_count = 0`
- Returns `409 Conflict` if tag is still associated with speeches

---

## CSV Import Workflow

The CSV import process is a two-step workflow:

### Step 1: Upload Audio Files

### POST /admin/import/audio

Upload multiple audio files that will be referenced in the CSV.

**Headers**: 
- `Authorization: Bearer <admin_token>`
- `Content-Type: multipart/form-data`

**Request Body**:
```
files: [audio1.mp3, audio2.mp3, audio3.mp3, ...]
```

**Implementation Notes**:
- Accept multiple files in single request
- Store files in S3 with path: `/audio/uploads/{session_id}/{original_filename}`
- If duplicate filename exists, append suffix: `filename_1.mp3`, `filename_2.mp3`
- Generate UUID for each uploaded file
- Return mapping of original filename → storage URL

**Response** (200 OK):
```json
{
  "upload_session_id": "session-uuid",
  "uploaded_files": [
    {
      "id": "file-uuid-1",
      "original_filename": "sentence_001.mp3",
      "storage_url": "https://storage.example.com/audio/uploads/session-uuid/sentence_001.mp3",
      "size_bytes": 45678
    },
    {
      "id": "file-uuid-2",
      "original_filename": "sentence_002.mp3",
      "storage_url": "https://storage.example.com/audio/uploads/session-uuid/sentence_002.mp3",
      "size_bytes": 52341
    },
    {
      "id": "file-uuid-3",
      "original_filename": "question_001.mp3",
      "storage_url": "https://storage.example.com/audio/uploads/session-uuid/question_001_1.mp3",
      "size_bytes": 38900
    }
  ]
}
```

**Error Responses**:
- `400 Bad Request`: Invalid file format (only MP3, WAV, M4A allowed)
- `413 Payload Too Large`: File size exceeds limit (e.g., 10MB per file)

---

### Step 2: Upload CSV and Create Speeches

### POST /admin/import/csv

Upload CSV file to create speech records, matching audio filenames to uploaded files.

**Headers**: 
- `Authorization: Bearer <admin_token>`
- `Content-Type: multipart/form-data`

**Request Body**:
```
file: speeches.csv
upload_session_id: session-uuid
```

**CSV Format**:
```csv
audio_filename,text,level,type,tags
sentence_001.mp3,"What is your name?",A1,question,"Present Tense,Basics"
sentence_002.mp3,"My name is John.",A1,answer,"Present Tense,Basics"
question_001.mp3,"Where do you live?",A1,question,"Present Tense,Location"
```

**CSV Column Specifications**:
- `audio_filename` (required): Must match an uploaded filename from Step 1
- `text` (required): English sentence text
- `level` (required): One of `A1`, `A2`, `B1`, `B2`, `C1`
- `type` (optional): `question` or `answer`, defaults to `answer`
- `tags` (optional): Comma-separated tag names, creates tags if they don't exist

**Validation Rules**:
1. All rows must have required fields
2. `audio_filename` must exist in the upload session
3. `level` must be valid enum value
4. `type` must be valid enum value if provided
5. No duplicate `audio_filename` within the same CSV

**Processing Logic**:
1. Parse entire CSV file
2. Validate ALL rows before creating ANY records (atomic transaction)
3. For each row:
   - Match `audio_filename` to uploaded file storage_url
   - Parse and validate `level`, `type`
   - Split `tags` by comma, trim whitespace
   - Create or retrieve tag records by name
4. If all valid, create all speech records in bulk
5. Move audio files from `/uploads/` to permanent location `/audio/{level}/`

**Response** (200 OK):
```json
{
  "success_count": 98,
  "error_count": 2,
  "created_speeches": [
    {
      "row": 1,
      "speech_id": "uuid-1",
      "text": "What is your name?"
    }
  ],
  "errors": [
    {
      "row": 15,
      "error": "Audio file 'missing.mp3' not found in upload session"
    },
    {
      "row": 23,
      "error": "Invalid level 'D1'. Must be one of: A1, A2, B1, B2, C1"
    }
  ]
}
```

**Error Responses**:
- `400 Bad Request`: Invalid CSV format, missing required columns
- `404 Not Found`: `upload_session_id` doesn't exist or expired
- `422 Unprocessable Entity`: Validation errors in CSV data (returned with detailed error list)

---

### Import Workflow Example

```bash
# Step 1: Upload audio files
curl -X POST http://localhost:8000/api/v1/admin/import/audio \
  -H "Authorization: Bearer <admin_token>" \
  -F "files=@audio1.mp3" \
  -F "files=@audio2.mp3" \
  -F "files=@audio3.mp3"

# Response: {"upload_session_id": "abc-123", "uploaded_files": [...]}

# Step 2: Upload CSV
curl -X POST http://localhost:8000/api/v1/admin/import/csv \
  -H "Authorization: Bearer <admin_token>" \
  -F "file=@speeches.csv" \
  -F "upload_session_id=abc-123"

# Response: {"success_count": 3, "error_count": 0, ...}
```

---

## Speech-to-Text Provider Integration Design

### Architecture

The speech-to-text integration uses an **Abstract Provider Interface** to allow switching between different vendors (Azure, Google, AWS, OpenAI) without changing application code.

```python
# Abstract interface
class SpeechProvider(ABC):
    @abstractmethod
    async def transcribe_and_score(
        self, 
        audio_data: bytes, 
        reference_text: str,
        language: str = "en-US"
    ) -> ScoringResult:
        """
        Transcribe audio and score pronunciation against reference text.
        
        Args:
            audio_data: Raw audio bytes
            reference_text: Expected correct sentence
            language: Language code (e.g., "en-US")
            
        Returns:
            ScoringResult with transcription and scores
        """
        pass

# Result data class
@dataclass
class ScoringResult:
    recognized_text: str
    pronunciation_score: float  # 0-100
    accuracy_score: Optional[float] = None
    fluency_score: Optional[float] = None
    completeness_score: Optional[float] = None
    word_scores: Optional[List[WordScore]] = None
    confidence: float = 0.0
    provider_name: str = ""
    raw_response: Optional[Dict] = None  # For debugging

@dataclass
class WordScore:
    word: str
    score: float
    error_type: Optional[str] = None  # "mispronunciation", "omission", etc.
```

### Provider Implementations

#### 1. Azure Speech Services Provider

```python
class AzureSpeechProvider(SpeechProvider):
    """
    Uses Azure Cognitive Services Speech SDK.
    Best option: built-in pronunciation assessment API.
    """
    
    async def transcribe_and_score(
        self,
        audio_data: bytes,
        reference_text: str,
        language: str = "en-US"
    ) -> ScoringResult:
        # Configure pronunciation assessment
        pronunciation_config = PronunciationAssessmentConfig(
            reference_text=reference_text,
            grading_system=GradingSystem.HundredMark,
            granularity=Granularity.Word
        )
        
        # Call Azure API
        result = await speech_recognizer.recognize_once_async(audio_data)
        
        # Extract scores from result
        return ScoringResult(
            recognized_text=result.text,
            pronunciation_score=result.pronunciation_score,
            accuracy_score=result.accuracy_score,
            fluency_score=result.fluency_score,
            completeness_score=result.completeness_score,
            word_scores=[...],
            provider_name="azure"
        )
```

**Configuration**:
```env
SPEECH_PROVIDER=azure
AZURE_SPEECH_KEY=your_key
AZURE_SPEECH_REGION=eastus
```

---

#### 2. Google Cloud Speech-to-Text Provider

```python
class GoogleSpeechProvider(SpeechProvider):
    """
    Uses Google Cloud Speech-to-Text API.
    Note: No built-in pronunciation scoring, uses custom algorithm.
    """
    
    async def transcribe_and_score(
        self,
        audio_data: bytes,
        reference_text: str,
        language: str = "en-US"
    ) -> ScoringResult:
        # Call Google Speech API for transcription
        client = speech.SpeechClient()
        audio = speech.RecognitionAudio(content=audio_data)
        config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.MP3,
            language_code=language
        )
        
        response = await client.recognize(config=config, audio=audio)
        recognized = response.results[0].alternatives[0].transcript
        
        # Calculate pronunciation score using similarity algorithm
        score = self._calculate_similarity_score(
            recognized, 
            reference_text
        )
        
        return ScoringResult(
            recognized_text=recognized,
            pronunciation_score=score,
            confidence=response.results[0].alternatives[0].confidence,
            provider_name="google"
        )
    
    def _calculate_similarity_score(self, recognized: str, reference: str) -> float:
        """
        Uses Levenshtein distance or Jaro-Winkler similarity.
        Score = 100 * (1 - normalized_distance)
        """
        from Levenshtein import distance
        
        normalized = distance(recognized.lower(), reference.lower()) / max(len(recognized), len(reference))
        return max(0, 100 * (1 - normalized))
```

**Configuration**:
```env
SPEECH_PROVIDER=google
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

---

#### 3. AWS Transcribe Provider

```python
class AWSTranscribeProvider(SpeechProvider):
    """
    Uses AWS Transcribe for speech-to-text.
    Custom pronunciation scoring algorithm.
    """
    
    async def transcribe_and_score(
        self,
        audio_data: bytes,
        reference_text: str,
        language: str = "en-US"
    ) -> ScoringResult:
        # Upload audio to S3
        s3_client.put_object(Bucket=bucket, Key=key, Body=audio_data)
        
        # Start transcription job
        transcribe_client.start_transcription_job(...)
        
        # Wait for completion (async)
        result = await self._wait_for_job(job_name)
        
        recognized = result['Transcript']
        score = self._calculate_similarity_score(recognized, reference_text)
        
        return ScoringResult(
            recognized_text=recognized,
            pronunciation_score=score,
            provider_name="aws"
        )
```

**Configuration**:
```env
SPEECH_PROVIDER=aws
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
```

---

#### 4. Whisper (OpenAI) Provider

```python
class WhisperProvider(SpeechProvider):
    """
    Uses OpenAI Whisper model (can be self-hosted or API).
    Custom pronunciation scoring.
    """
    
    async def transcribe_and_score(
        self,
        audio_data: bytes,
        reference_text: str,
        language: str = "en-US"
    ) -> ScoringResult:
        # Call Whisper API or local model
        if self.use_api:
            response = await openai.Audio.transcribe(
                model="whisper-1",
                file=audio_data
            )
            recognized = response['text']
        else:
            # Use local Whisper model
            model = whisper.load_model("base")
            result = model.transcribe(audio_data)
            recognized = result['text']
        
        score = self._calculate_similarity_score(recognized, reference_text)
        
        return ScoringResult(
            recognized_text=recognized,
            pronunciation_score=score,
            provider_name="whisper"
        )
```

**Configuration**:
```env
SPEECH_PROVIDER=whisper
WHISPER_MODE=api  # or "local"
OPENAI_API_KEY=your_key  # if using API
```

---

### Provider Factory

```python
class SpeechProviderFactory:
    """Factory to create speech provider based on configuration."""
    
    @staticmethod
    def create(provider_name: str) -> SpeechProvider:
        providers = {
            "azure": AzureSpeechProvider,
            "google": GoogleSpeechProvider,
            "aws": AWSTranscribeProvider,
            "whisper": WhisperProvider
        }
        
        if provider_name not in providers:
            raise ValueError(f"Unknown provider: {provider_name}")
        
        return providers[provider_name]()

# Usage in endpoint
provider = SpeechProviderFactory.create(settings.SPEECH_PROVIDER)
result = await provider.transcribe_and_score(audio_data, reference_text)
```

---

### Configuration Management

```python
# settings.py or config.py
from pydantic import BaseSettings

class Settings(BaseSettings):
    # Speech Provider Selection
    SPEECH_PROVIDER: str = "azure"  # azure, google, aws, whisper
    
    # Azure Settings
    AZURE_SPEECH_KEY: Optional[str] = None
    AZURE_SPEECH_REGION: Optional[str] = None
    
    # Google Settings
    GOOGLE_APPLICATION_CREDENTIALS: Optional[str] = None
    
    # AWS Settings
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None
    AWS_REGION: Optional[str] = None
    
    # Whisper Settings
    WHISPER_MODE: str = "api"  # api or local
    OPENAI_API_KEY: Optional[str] = None
    
    # Timeouts
    SPEECH_API_TIMEOUT: int = 10  # seconds
    
    class Config:
        env_file = ".env"

settings = Settings()
```

---

### Error Handling

```python
class SpeechProviderError(Exception):
    """Base exception for speech provider errors."""
    pass

class SpeechProviderTimeoutError(SpeechProviderError):
    """Provider API timeout."""
    pass

class SpeechProviderAPIError(SpeechProviderError):
    """Provider API returned error."""
    pass

class AudioQualityError(SpeechProviderError):
    """Audio quality too poor to process."""
    pass

# In endpoint
try:
    result = await provider.transcribe_and_score(audio, text)
except SpeechProviderTimeoutError:
    raise HTTPException(503, "Speech service timeout")
except AudioQualityError:
    raise HTTPException(422, "Audio quality too low")
except SpeechProviderError as e:
    logger.error(f"Speech provider error: {e}")
    raise HTTPException(503, "Speech service unavailable")
```

---

### Provider Comparison

| Provider | Built-in Pronunciation Scoring | Cost (per 60s) | Accuracy | Setup Complexity |
|----------|-------------------------------|----------------|----------|------------------|
| **Azure** | ✅ Yes | ~$0.024 | Excellent | Low |
| **Google** | ❌ No (custom) | ~$0.024 | Excellent | Low |
| **AWS** | ❌ No (custom) | ~$0.024 | Very Good | Medium |
| **Whisper API** | ❌ No (custom) | ~$0.006 | Very Good | Low |
| **Whisper Local** | ❌ No (custom) | Free | Good | High |

**Recommendation**: Start with **Azure Speech Services** for MVP due to built-in pronunciation assessment. The abstraction layer allows easy switching if cost or accuracy requirements change.

---

## Admin Panel Implementation

### Technology Options

#### Option 1: FastAPI + SQLAdmin (Recommended for MVP)

**Pros**:
- Quick setup (plug-and-play)
- Automatic CRUD UI generation
- Built-in authentication
- Works directly with SQLAlchemy models

**Setup**:
```python
from sqladmin import Admin, ModelView
from fastapi import FastAPI

app = FastAPI()
admin = Admin(app, engine)

class SpeechAdmin(ModelView, model=Speech):
    column_list = [Speech.id, Speech.text, Speech.level, Speech.type]
    column_searchable_list = [Speech.text]
    column_filters = [Speech.level, Speech.type]

class TagAdmin(ModelView, model=Tag):
    column_list = [Tag.id, Tag.name, Tag.category]

admin.add_view(SpeechAdmin)
admin.add_view(TagAdmin)
```

**Access**: `http://localhost:8000/admin`

---

#### Option 2: Custom React Admin Panel (Future Phase)

**Pros**:
- Full UI/UX control
- Better user experience for complex workflows
- Can integrate advanced features (bulk operations, analytics dashboards)

**Stack**:
- Frontend: React + React Admin or Refine framework
- Backend: FastAPI provides JSON APIs (already defined above)

---

### Admin Authentication

```python
from sqladmin.authentication import AuthenticationBackend
from fastapi import Request

class AdminAuth(AuthenticationBackend):
    async def login(self, request: Request) -> bool:
        form = await request.form()
        username = form.get("username")
        password = form.get("password")
        
        # Verify against admin user table
        admin = await verify_admin_credentials(username, password)
        if admin:
            request.session["admin_id"] = admin.id
            return True
        return False
    
    async def logout(self, request: Request) -> bool:
        request.session.clear()
        return True
    
    async def authenticate(self, request: Request) -> bool:
        return "admin_id" in request.session

admin = Admin(app, engine, authentication_backend=AdminAuth("secret-key"))
```

---

## Database Indexes Summary

For optimal query performance:

```sql
-- User table
CREATE UNIQUE INDEX idx_user_email ON users(email);
CREATE INDEX idx_user_auth_provider ON users(auth_provider, auth_provider_id);

-- Tag table
CREATE UNIQUE INDEX idx_tag_name ON tags(name);
CREATE INDEX idx_tag_category ON tags(category);

-- Speech table
CREATE INDEX idx_speech_level_type ON speeches(level, type);
CREATE INDEX idx_speech_text_fts ON speeches USING gin(to_tsvector('english', text));

-- SpeechTag join table
CREATE INDEX idx_speech_tags_tag_id ON speech_tags(tag_id);

-- GameSession table
CREATE INDEX idx_game_session_user_completed ON game_sessions(user_id, completed_at DESC);
CREATE INDEX idx_game_session_mode_level ON game_sessions(mode, level);

-- GameResult table
CREATE INDEX idx_game_result_session_seq ON game_results(session_id, sequence_number);
CREATE INDEX idx_game_result_speech_id ON game_results(speech_id);
```

---

## Security Considerations

### Authentication & Authorization
- Use JWT tokens with short expiration (1 hour access, 7 day refresh)
- Hash passwords with bcrypt (cost factor 12) or Argon2
- Implement rate limiting: 100 requests/minute per user, 10 requests/minute for login attempts
- Separate admin authentication with distinct role verification

### Input Validation
- Validate all request bodies against Pydantic schemas
- Sanitize text inputs to prevent XSS
- Use parameterized queries (SQLAlchemy ORM) to prevent SQL injection
- Validate audio file types and sizes before upload

### API Security
- Enforce HTTPS/TLS in production
- Set CORS policies to allow only mobile app domains
- Implement request signing for critical operations
- Add audit logging for all admin actions (who, what, when)

### Data Privacy
- Do NOT store user audio recordings after processing (privacy requirement)
- Implement user data deletion within 30 days of account deletion request
- Encrypt sensitive data at rest (database encryption)
- Use signed URLs with expiration for audio file access

---

## Performance Considerations

### Caching Strategy
- Cache tag list (public endpoint) for 1 hour
- Cache speech filtering queries for 5 minutes with cache key: `speeches:{level}:{type}:{tag_ids_hash}`
- Use Redis for session data and rate limiting

### Database Optimization
- Implement connection pooling (SQLAlchemy pool_size=20, max_overflow=10)
- Use read replicas for game history queries (read-heavy)
- Paginate all list endpoints (max 200 items per page)
- Use database-level randomization for speech selection (`ORDER BY RANDOM()`)

### Audio Delivery
- Use CDN (CloudFront, Cloudflare) for audio files
- Generate signed URLs on-demand with 1-hour expiration
- Store audio in optimized format: MP3 64kbps (sufficient for speech)
- Implement pre-signed URL caching to reduce S3 API calls

### Speech Provider Optimization
- Set timeout: 10 seconds max for speech-to-text calls
- Implement retry logic (3 attempts with exponential backoff)
- Use async/await for non-blocking API calls
- Consider caching pronunciation scores for identical audio (optional)

---

## Deployment Architecture

```
┌─────────────────┐
│  Mobile Apps    │
│ (iOS/Android)   │
└────────┬────────┘
         │
         │ HTTPS
         ▼
┌─────────────────┐      ┌──────────────┐
│   Load Balancer │─────▶│   CDN        │
│    (ALB/Nginx)  │      │ (Audio Files)│
└────────┬────────┘      └──────────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────┐
│  FastAPI App    │─────▶│  PostgreSQL  │
│  (Container)    │      │  (Primary)   │
│                 │      └──────────────┘
│  - REST API     │      
│  - Admin Panel  │      ┌──────────────┐
│  - Speech Proxy │─────▶│  Redis       │
└────────┬────────┘      │  (Cache)     │
         │               └──────────────┘
         │
         ▼
┌─────────────────┐
│  Speech Provider│
│  (Azure/Google) │
└─────────────────┘
```

**Deployment Options**:
- **Container**: Docker + Kubernetes or AWS ECS
- **Platform**: AWS (Elastic Beanstalk), Google Cloud Run, or DigitalOcean App Platform
- **Database**: Managed PostgreSQL (AWS RDS, Google Cloud SQL)
- **Storage**: AWS S3, DigitalOcean Spaces, or Cloudflare R2

---

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/englishapp

# Authentication
JWT_SECRET_KEY=your_secret_key_here
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=7

# Storage
S3_BUCKET_NAME=englishapp-audio
S3_ENDPOINT_URL=https://s3.amazonaws.com
S3_ACCESS_KEY=your_access_key
S3_SECRET_KEY=your_secret_key
S3_REGION=us-east-1

# Speech Provider
SPEECH_PROVIDER=azure
AZURE_SPEECH_KEY=your_azure_key
AZURE_SPEECH_REGION=eastus

# Admin
ADMIN_USERNAME=admin
ADMIN_PASSWORD_HASH=bcrypt_hashed_password

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=false
ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com

# Rate Limiting
RATE_LIMIT_PER_MINUTE=100
RATE_LIMIT_REDIS_URL=redis://localhost:6379/0
```

---

## API Rate Limits

| Endpoint | Rate Limit | Notes |
|----------|------------|-------|
| `POST /auth/login` | 10/minute per IP | Prevent brute force |
| `POST /auth/register` | 5/minute per IP | Prevent spam accounts |
| `POST /game/speeches/random` | 60/minute per user | Normal gameplay |
| `POST /game/sessions` | 60/minute per user | Session completion |
| `GET /game/sessions` | 100/minute per user | History browsing |
| `POST /speech/score` | 30/minute per user | Pronunciation scoring |
| Admin endpoints | 200/minute per admin | Content management |

---

## Testing Strategy

### Unit Tests
- Repository layer (CRUD operations)
- Business logic (speech filtering, score calculation)
- Speech provider implementations (mocked APIs)

### Integration Tests
- API endpoint tests (request/response validation)
- Database operations with test database
- Authentication flow
- CSV import workflow

### Load Tests
- 10,000 concurrent users requesting speeches
- 100 game sessions submitted per second
- Speech scoring under load (100 concurrent requests)

### Test Data
- Seed script with 1000 sample speeches
- Multiple levels (A1-C1) and types (question/answer)
- 20+ tags covering various categories

---

## Monitoring & Logging

### Application Metrics
- Request rate and latency (p50, p95, p99)
- Error rate by endpoint
- Database connection pool usage
- Speech provider API latency and error rate

### Business Metrics
- New user registrations per day
- Active users (DAU, WAU, MAU)
- Game sessions completed per day
- Average session duration
- Pronunciation score distribution

### Logging
- Structure logs in JSON format
- Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
- Include request ID for tracing
- Log all admin actions (audit trail)

### Tools
- **Logging**: Structlog or Python logging
- **Monitoring**: Prometheus + Grafana or Datadog
- **Error Tracking**: Sentry
- **APM**: New Relic or Datadog APM

---

## Appendix: Sample Database Schema (SQL)

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    auth_provider VARCHAR(50) NOT NULL CHECK (auth_provider IN ('email', 'google', 'apple', 'facebook')),
    auth_provider_id VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tags table
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Speeches table
CREATE TABLE speeches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    audio_url TEXT NOT NULL,
    text TEXT NOT NULL,
    level VARCHAR(2) NOT NULL CHECK (level IN ('A1', 'A2', 'B1', 'B2', 'C1')),
    type VARCHAR(10) NOT NULL DEFAULT 'answer' CHECK (type IN ('question', 'answer')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Speech-Tag join table
CREATE TABLE speech_tags (
    speech_id UUID NOT NULL REFERENCES speeches(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (speech_id, tag_id)
);

-- Game Sessions table
CREATE TABLE game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mode VARCHAR(20) NOT NULL CHECK (mode IN ('listen_only', 'listen_and_repeat')),
    level VARCHAR(2) NOT NULL,
    sentence_type VARCHAR(10) NOT NULL,
    selected_tags JSONB NOT NULL,
    total_sentences INTEGER NOT NULL,
    correct_count INTEGER NOT NULL,
    max_streak INTEGER NOT NULL,
    avg_pronunciation_score FLOAT,
    duration_seconds INTEGER NOT NULL,
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP NOT NULL
);

-- Game Results table
CREATE TABLE game_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES game_sessions(id) ON DELETE CASCADE,
    speech_id UUID NOT NULL REFERENCES speeches(id),
    sequence_number INTEGER NOT NULL,
    user_response VARCHAR(10) NOT NULL CHECK (user_response IN ('correct', 'incorrect', 'skipped')),
    pronunciation_score FLOAT,
    recognized_text TEXT,
    response_time_ms INTEGER NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_user_email ON users(email);
CREATE INDEX idx_tag_name ON tags(name);
CREATE INDEX idx_speech_level_type ON speeches(level, type);
CREATE INDEX idx_speech_tags_tag_id ON speech_tags(tag_id);
CREATE INDEX idx_game_session_user_completed ON game_sessions(user_id, completed_at DESC);
CREATE INDEX idx_game_result_session_seq ON game_results(session_id, sequence_number);
```

---

**End of Backend Specification**

This document provides a comprehensive guide for implementing the backend system. For questions or clarifications, refer to the main [spec_codebase.md](./spec_codebase.md) or contact the technical lead.
