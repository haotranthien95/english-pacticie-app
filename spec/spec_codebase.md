# English Learning App - Technical Specification

**Version:** 1.0.0  
**Date:** December 10, 2025  
**Status:** Draft - Phase 1 (MVP)

---

## Table of Contents

1. [Product Overview](#product-overview)
2. [User Personas](#user-personas)
3. [Use Cases](#use-cases)
4. [Functional Requirements](#functional-requirements)
5. [Non-Functional Requirements](#non-functional-requirements)
6. [Technical Architecture](#technical-architecture)
7. [Data Models](#data-models)
8. [API Specifications](#api-specifications)
9. [Open Questions](#open-questions)
10. [Future Work](#future-work)

---

## Product Overview

### Vision
An English learning mobile application focused on listening comprehension and pronunciation practice through interactive, gamified exercises. The app provides an automated, self-paced learning experience with minimal user interaction required during gameplay.

### Key Features (Phase 1 MVP)
- **Authentication**: Email, Google, Apple, Facebook sign-in
- **Listen and Repeat Game**: Two modes (listen-only and listen-and-repeat with scoring)
- **Self-Evaluation System**: Swipe-based feedback with streak tracking
- **Game History**: Persistent storage and review of past sessions
- **Multi-platform**: Android, iOS, tablet support
- **Localization**: Vietnamese UI with English learning content
- **Theming**: Light and dark mode support

### Technology Stack

#### Mobile App
- **Framework**: Flutter
- **State Management**: BLoC (Business Logic Component)
- **Local Storage**: Hive (for offline data and caching)
- **Backend Services**: Firebase (Auth, optional Analytics)
- **Platforms**: Android, iOS (phone and tablet)

#### Backend
- **Language**: Python
- **Framework**: FastAPI (preferred) or Django
- **Database**: PostgreSQL (recommended) or MySQL
- **Storage**: S3-compatible object storage for audio files
- **Authentication**: Firebase Auth integration or custom JWT

#### Admin Panel
- **Framework**: Simple web interface (Django Admin, FastAPI + React, or similar)
- **Purpose**: Content management, CSV import, analytics

---

## User Personas

### Persona 1: The Self-Learner
- **Age**: 18-35
- **Background**: Vietnamese native speaker, intermediate English level
- **Goal**: Improve listening comprehension and pronunciation through daily practice
- **Motivation**: Career advancement, travel preparation
- **Pain Points**: Limited time, needs flexible self-paced learning
- **Device**: Primarily mobile phone, occasional tablet use

### Persona 2: The Student
- **Age**: 15-22
- **Background**: High school or university student preparing for English exams
- **Goal**: Practice specific sentence types and grammar tenses
- **Motivation**: Academic requirements, test preparation
- **Pain Points**: Needs structured practice by level (A1-C1)
- **Device**: Mobile phone, sometimes tablet for study sessions

### Persona 3: The Working Professional
- **Age**: 25-45
- **Background**: Uses English in workplace, wants to improve fluency
- **Goal**: Practice real-world questions and answers
- **Motivation**: Professional communication, confidence building
- **Pain Points**: Limited practice time, needs efficient learning
- **Device**: Mobile phone during commute, tablet at home

---

## Use Cases

### UC1: User Registration and Authentication
**Actor**: New User  
**Precondition**: User has installed the app  
**Flow**:
1. User opens app and sees welcome/login screen
2. User selects authentication method (Email/Google/Apple/Facebook)
3. For email: User enters email and password, confirms email
4. For social: User completes OAuth flow
5. System creates user profile
6. User is redirected to Dashboard

**Postcondition**: User is authenticated and has a profile

---

### UC2: Start Listen-Only Game Session
**Actor**: Authenticated User  
**Precondition**: User is on Games tab  
**Flow**:
1. User taps "Listen and Repeat" game card
2. Game configuration screen appears
3. User selects:
   - Mode: "Listen Only"
   - Level: A1, A2, B1, B2, or C1
   - Sentence Type: Question or Answer
   - Tags: Multiple selection (e.g., Present Tense, Food, Travel)
4. User taps "Start" button
5. System calls backend API to fetch 10-20 random speech items matching filters
6. Game begins with first sentence

**Postcondition**: Game session is active with loaded sentences

---

### UC3: Play Listen-Only Game
**Actor**: User in active game session  
**Precondition**: Game session started with listen-only mode  
**Flow**:
1. **For each sentence (auto-loop)**:
   - Audio plays automatically (1st play)
   - 2-second gap
   - Audio plays again (2nd play)
   - Text appears on screen after 2nd play
   - 2-second display time
   - Previous sentence result remains visible
   - User can swipe left (wrong) or right (correct) on previous sentence
     - Swipe left: App shows motivational message
     - Swipe right: App shows compliment based on current streak (1-5)
   - Auto-advance to next sentence
2. **After all sentences**:
   - End game screen with summary statistics
   - Compliment or motivation message
   - Options: Review History, Play Again, Back to Games
3. System sends game results to backend for storage

**Postcondition**: Game results saved, user can review in history

---

### UC4: Play Listen-and-Repeat Game (with Scoring)
**Actor**: User in active game session  
**Precondition**: Game session started with listen-and-repeat mode  
**Flow**:
1. App requests microphone permission (if not granted)
2. **For each sentence (auto-loop)**:
   - Audio plays once
   - Microphone opens automatically
   - Visual indicator shows "Speak now..."
   - User speaks the sentence
   - System captures audio
   - System sends audio to speech-to-text + pronunciation scoring service
   - System compares result with reference text
   - Score/feedback displayed
   - Previous sentence result remains visible (swipeable)
   - Auto-advance to next sentence after brief display
3. **After all sentences**:
   - End game screen with summary and scores
   - System sends detailed results to backend

**Postcondition**: Game results with pronunciation scores saved

---

### UC5: Pause and Resume Game
**Actor**: User in active game session  
**Precondition**: Game is running  
**Flow**:
1. User taps "Pause" button
2. **System behavior based on current state**:
   - **If audio is playing**: Pause at current timestamp
   - **If waiting for user speech**: Stop microphone recording
   - **If in gap/transition**: Stop timer
3. Game screen shows "Paused" overlay with "Resume" button
4. User taps "Resume"
5. **System behavior based on paused state**:
   - **If audio was playing**: Resume from paused timestamp
   - **If mic was open**: Reopen microphone
   - **If timer was running**: Continue timer countdown
6. Game continues

**Postcondition**: Game state preserved and resumed correctly

---

### UC6: Review Game History
**Actor**: Authenticated User  
**Precondition**: User has completed at least one game session  
**Flow**:
1. User navigates to Game History (from Profile or Games tab)
2. System displays list of past game sessions with:
   - Date/time
   - Mode (listen-only or listen-and-repeat)
   - Level
   - Score/results summary
3. User taps on a session to view details
4. Detailed view shows:
   - All sentences played
   - User's response for each (swipe result or pronunciation score)
   - Audio playback option
   - Text for each sentence

**Postcondition**: User can review past performance

---

### UC7: Edit User Profile
**Actor**: Authenticated User  
**Precondition**: User is on Profile tab  
**Flow**:
1. User taps "Edit Profile"
2. Form displays current: Name, Email, Avatar
3. User updates desired fields
4. User taps "Save"
5. System validates and updates profile
6. Confirmation message displayed

**Postcondition**: Profile updated

---

### UC8: Admin - Import Speech Content via CSV
**Actor**: Admin User  
**Precondition**: Admin is logged into admin panel  
**Flow**:
1. Admin navigates to "Import Content" page
2. **Step 1: Upload Audio Files**
   - Admin selects multiple audio files (.mp3, .wav, etc.)
   - System uploads and stores files with original filenames
   - If duplicate filename exists, append "_1", "_2", etc.
   - System displays uploaded files list with generated IDs
3. **Step 2: Upload CSV**
   - Admin uploads CSV file with columns:
     - `audio_filename` (required): matches uploaded file
     - `text` (required): English sentence text
     - `level` (required): A1, A2, B1, B2, C1
     - `type` (optional): question, answer (default: answer)
     - `tags` (optional): comma-separated list
   - System validates CSV format
   - System matches audio_filename to uploaded files
   - System creates speech items in database
4. System displays import summary (success/failures)

**Postcondition**: Speech content available for games

---

## Functional Requirements

### Mobile App Requirements

#### FR-M1: Authentication & Authorization
- **FR-M1.1**: Support email/password registration with email verification
- **FR-M1.2**: Support Google Sign-In (OAuth 2.0)
- **FR-M1.3**: Support Apple Sign-In
- **FR-M1.4**: Support Facebook Login
- **FR-M1.5**: Maintain authentication state across app restarts
- **FR-M1.6**: Provide logout functionality
- **FR-M1.7**: Support account deletion with confirmation

#### FR-M2: Navigation & UI Structure
- **FR-M2.1**: Bottom tab bar with 4 tabs: Dashboard, Games, Skills, Profile
- **FR-M2.2**: Dashboard tab (placeholder for Phase 1)
- **FR-M2.3**: Games tab displays list of available games
- **FR-M2.4**: Skills tab (placeholder for Phase 1)
- **FR-M2.5**: Profile tab with user info and settings

#### FR-M3: Game Selection & Configuration
- **FR-M3.1**: Display "Listen and Repeat" game card on Games tab
- **FR-M3.2**: Game configuration screen with:
  - Mode selector: Listen-Only / Listen-and-Repeat
  - Level selector: A1, A2, B1, B2, C1 (single select)
  - Type selector: Question / Answer (single select)
  - Tag selector: Multi-select checkboxes/chips (tags from backend)
- **FR-M3.3**: "Start" button to begin game with selected configuration
- **FR-M3.4**: Validate at least one tag is selected before starting

#### FR-M4: Listen-Only Mode
- **FR-M4.1**: Fetch 10-20 random sentences from backend based on filters
- **FR-M4.2**: For each sentence:
  - Play audio twice with 2-second gap
  - Display text after 2nd play
  - Auto-advance after 2 seconds
- **FR-M4.3**: Display previous sentence result while current sentence plays
- **FR-M4.4**: Support swipe gestures:
  - Swipe left: Mark as "incorrect", show motivational message
  - Swipe right: Mark as "correct", show compliment
- **FR-M4.5**: Track correct streak (1-5 consecutive correct swipes)
- **FR-M4.6**: Display streak-based compliments (5 levels hardcoded)
- **FR-M4.7**: Motivational messages for incorrect swipes (hardcoded)
- **FR-M4.8**: After all sentences, show end game summary

#### FR-M5: Listen-and-Repeat Mode
- **FR-M5.1**: Request microphone permission before first use
- **FR-M5.2**: For each sentence:
  - Play audio once
  - Auto-open microphone with visual indicator
  - Record user speech
  - Send audio to speech-to-text service
  - Display recognized text and pronunciation score
  - Auto-advance to next sentence
- **FR-M5.3**: Support same swipe evaluation and streak system as listen-only
- **FR-M5.4**: Display pronunciation accuracy percentage
- **FR-M5.5**: End game summary with average pronunciation score

#### FR-M6: Game Pause/Resume
- **FR-M6.1**: Display "Pause" button during active game
- **FR-M6.2**: On pause:
  - If audio playing: pause at current timestamp
  - If mic recording: stop recording
  - If gap timer: pause timer
- **FR-M6.3**: Show "Resume" button on pause overlay
- **FR-M6.4**: On resume: restore exact previous state

#### FR-M7: Game Results Storage
- **FR-M7.1**: After game completion, send results to backend:
  - Session metadata (mode, level, type, tags, timestamp)
  - Sentence-by-sentence results (sentence ID, user response, score)
  - Summary statistics (total correct, streak max, avg score)
- **FR-M7.2**: Handle offline scenarios: queue results for sync when online

#### FR-M8: Game History
- **FR-M8.1**: Display list of past game sessions with summary
- **FR-M8.2**: Support filtering/sorting by date, mode, level
- **FR-M8.3**: Detailed view of each session with all sentences and results
- **FR-M8.4**: Allow audio playback of sentences from history

#### FR-M9: Profile Management
- **FR-M9.1**: Display user profile: name, email, avatar
- **FR-M9.2**: Edit profile functionality
- **FR-M9.3**: Logout button
- **FR-M9.4**: Delete account button with confirmation dialog

#### FR-M10: Localization & Theming
- **FR-M10.1**: Support Vietnamese as primary UI language
- **FR-M10.2**: Support i18n framework for future language additions
- **FR-M10.3**: Light theme (default)
- **FR-M10.4**: Dark theme with system sync option
- **FR-M10.5**: Theme toggle in Profile settings

#### FR-M11: Offline Support
- **FR-M11.1**: Cache game configuration options (levels, tags)
- **FR-M11.2**: Queue game results for upload when offline
- **FR-M11.3**: Display offline indicator when network unavailable
- **FR-M11.4**: Sync queued data when connection restored

---

### Backend Requirements

#### FR-B1: Authentication
- **FR-B1.1**: Integrate with Firebase Authentication or implement JWT-based auth
- **FR-B1.2**: Validate authentication tokens on all protected endpoints
- **FR-B1.3**: Support user registration, login, password reset
- **FR-B1.4**: Provide endpoint for account deletion

#### FR-B2: User Management
- **FR-B2.1**: Store user profiles (ID, email, name, avatar URL, created date)
- **FR-B2.2**: Endpoint: `GET /api/users/me` - Get current user profile
- **FR-B2.3**: Endpoint: `PUT /api/users/me` - Update user profile
- **FR-B2.4**: Endpoint: `DELETE /api/users/me` - Delete user account and all data

#### FR-B3: Speech Content Management
- **FR-B3.1**: Store speech items with:
  - ID (UUID)
  - Audio file URL
  - Text (English sentence)
  - Level (A1, A2, B1, B2, C1)
  - Type (question, answer)
  - Tags (many-to-many relationship)
  - Created/updated timestamps
- **FR-B3.2**: Endpoint: `GET /api/speeches` - List all speeches (admin only)
- **FR-B3.3**: Endpoint: `POST /api/speeches` - Create speech item (admin only)
- **FR-B3.4**: Endpoint: `PUT /api/speeches/{id}` - Update speech item (admin only)
- **FR-B3.5**: Endpoint: `DELETE /api/speeches/{id}` - Delete speech item (admin only)

#### FR-B4: Tag Management
- **FR-B4.1**: Store tags (ID, name, category, created date)
- **FR-B4.2**: Endpoint: `GET /api/tags` - List all available tags
- **FR-B4.3**: Endpoint: `POST /api/tags` - Create tag (admin only)
- **FR-B4.4**: Endpoint: `PUT /api/tags/{id}` - Update tag (admin only)
- **FR-B4.5**: Endpoint: `DELETE /api/tags/{id}` - Delete tag (admin only)

#### FR-B5: Game Session Management
- **FR-B5.1**: Endpoint: `POST /api/game/speeches/random` - Get random speeches
  - Request body: `{ level, type, tags[], limit }`
  - Response: List of speech items (ID, audio URL, text, tags, type)
  - Implements random selection algorithm
- **FR-B5.2**: Endpoint: `POST /api/game/sessions` - Create game session
  - Request body: Session metadata + results
  - Store session with all sentence-level details
- **FR-B5.3**: Endpoint: `GET /api/game/sessions` - List user's game history
  - Query params: `page`, `limit`, `mode`, `level`, `from_date`, `to_date`
  - Response: Paginated list of sessions with summaries
- **FR-B5.4**: Endpoint: `GET /api/game/sessions/{id}` - Get session details
  - Response: Full session data including all sentences and results

#### FR-B6: Admin Panel
- **FR-B6.1**: Web-based admin interface (Django Admin or custom)
- **FR-B6.2**: Authentication for admin users
- **FR-B6.3**: CRUD interface for speech items
- **FR-B6.4**: CRUD interface for tags
- **FR-B6.5**: View game sessions with filtering

#### FR-B7: CSV Import
- **FR-B7.1**: Endpoint: `POST /api/admin/import/audio` - Upload audio files
  - Accept multiple files
  - Store with original filenames, handle duplicates with "_1", "_2" suffix
  - Return list of uploaded files with IDs and filenames
- **FR-B7.2**: Endpoint: `POST /api/admin/import/csv` - Upload CSV and create speeches
  - Parse CSV with required fields: audio_filename, text, level
  - Optional fields: type, tags
  - Match audio_filename to previously uploaded files
  - Validate all rows before creating
  - Return import summary (success count, errors list)

#### FR-B8: Audio Storage
- **FR-B8.1**: Store audio files in S3-compatible object storage
- **FR-B8.2**: Generate signed URLs for audio access with expiration
- **FR-B8.3**: Support audio formats: MP3, WAV, M4A
- **FR-B8.4**: Optimize audio delivery (CDN integration recommended)

---

## Non-Functional Requirements

### NFR1: Performance
- **NFR1.1**: API response time < 500ms for 95th percentile
- **NFR1.2**: Game start (fetch speeches) < 2 seconds
- **NFR1.3**: Audio playback starts within 1 second of trigger
- **NFR1.4**: App launch time < 3 seconds (cold start)
- **NFR1.5**: Smooth 60fps UI animations

### NFR2: Scalability
- **NFR2.1**: Support 10,000 concurrent users
- **NFR2.2**: Database design supports millions of speech items
- **NFR2.3**: Handle 100+ game sessions created per minute

### NFR3: Reliability
- **NFR3.1**: 99.5% uptime SLA
- **NFR3.2**: Graceful degradation when services unavailable
- **NFR3.3**: Automatic retry for failed API calls (3 attempts)
- **NFR3.4**: Data persistence: no data loss for saved game results

### NFR4: Security
- **NFR4.1**: All API endpoints use HTTPS/TLS
- **NFR4.2**: Authentication tokens expire after 1 hour
- **NFR4.3**: Refresh tokens valid for 7 days
- **NFR4.4**: Rate limiting: 100 requests per minute per user
- **NFR4.5**: Input validation and sanitization on all endpoints
- **NFR4.6**: Secure storage of user credentials (bcrypt/argon2)

### NFR5: Usability
- **NFR5.1**: Minimal taps required during game (auto-advance design)
- **NFR5.2**: Clear visual feedback for all user actions
- **NFR5.3**: Support for accessibility features (screen readers, font scaling)
- **NFR5.4**: Intuitive swipe gestures with visual guides
- **NFR5.5**: Error messages in user's language (Vietnamese)

### NFR6: Compatibility
- **NFR6.1**: Android 6.0+ (API level 23+)
- **NFR6.2**: iOS 12.0+
- **NFR6.3**: Tablet layouts optimized (7" - 12" screens)
- **NFR6.4**: Backend compatible with Python 3.10+

### NFR7: Maintainability
- **NFR7.1**: Code coverage > 70% for backend
- **NFR7.2**: Code coverage > 60% for mobile (unit + widget tests)
- **NFR7.3**: Comprehensive API documentation (OpenAPI/Swagger)
- **NFR7.4**: Modular architecture for easy feature additions
- **NFR7.5**: Logging for all critical operations

### NFR8: Data Privacy
- **NFR8.1**: Comply with GDPR for EU users
- **NFR8.2**: User data deletion within 30 days of request
- **NFR8.3**: No sharing of user data with third parties
- **NFR8.4**: Audio recordings for speech-to-text processed and discarded (not stored)

---

## Technical Architecture

### Mobile App Architecture

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│  (Flutter Widgets + Theme + i18n)       │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│          BLoC Layer                     │
│  (Business Logic Components)            │
│  - AuthBloc                             │
│  - GameBloc                             │
│  - ProfileBloc                          │
│  - HistoryBloc                          │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│       Repository Layer                  │
│  - UserRepository                       │
│  - GameRepository                       │
│  - SpeechRepository                     │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼─────┐      ┌──────▼──────┐
│  Hive   │      │   API       │
│  (Local)│      │  (Remote)   │
└─────────┘      └──────┬──────┘
                        │
                 ┌──────▼──────┐
                 │   Backend   │
                 │   (FastAPI) │
                 └─────────────┘
```

### Backend Architecture

```
┌─────────────────────────────────────────┐
│          API Layer (FastAPI)            │
│  - Authentication Middleware            │
│  - Request Validation                   │
│  - Rate Limiting                        │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│          Service Layer                  │
│  - UserService                          │
│  - GameService                          │
│  - SpeechService                        │
│  - ImportService                        │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│       Repository/ORM Layer              │
│  - SQLAlchemy Models                    │
│  - Database Queries                     │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
┌───▼────────┐   ┌──────▼──────┐
│ PostgreSQL │   │ S3 Storage  │
│ (Database) │   │   (Audio)   │
└────────────┘   └─────────────┘
```

---

## Data Models

### User
```python
{
  "id": "uuid",
  "email": "string",
  "name": "string",
  "avatar_url": "string (nullable)",
  "auth_provider": "email | google | apple | facebook",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### Tag
```python
{
  "id": "uuid",
  "name": "string",
  "category": "string (e.g., 'tense', 'topic')",
  "created_at": "timestamp"
}
```

### Speech
```python
{
  "id": "uuid",
  "audio_url": "string",
  "text": "string",
  "level": "A1 | A2 | B1 | B2 | C1",
  "type": "question | answer",
  "tags": ["Tag"],
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### GameSession
```python
{
  "id": "uuid",
  "user_id": "uuid (FK)",
  "mode": "listen_only | listen_and_repeat",
  "level": "A1 | A2 | B1 | B2 | C1",
  "sentence_type": "question | answer",
  "tags": ["string"],
  "total_sentences": "integer",
  "correct_count": "integer",
  "max_streak": "integer",
  "avg_pronunciation_score": "float (nullable)",
  "duration_seconds": "integer",
  "started_at": "timestamp",
  "completed_at": "timestamp",
  "results": ["GameResult"]
}
```

### GameResult
```python
{
  "id": "uuid",
  "session_id": "uuid (FK)",
  "speech_id": "uuid (FK)",
  "sequence_number": "integer",
  "user_response": "correct | incorrect | skipped",
  "pronunciation_score": "float (nullable, 0-100)",
  "recognized_text": "string (nullable)",
  "response_time_ms": "integer",
  "created_at": "timestamp"
}
```

---

## API Specifications

### Base URL
```
Development: http://localhost:8000/api/v1
Production: https://api.englishapp.com/api/v1
```

### Authentication
All authenticated endpoints require `Authorization: Bearer <token>` header.

---

### Auth Endpoints

#### POST /auth/register
Register new user with email/password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "name": "Nguyen Van A"
}
```

**Response (201):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Nguyen Van A"
  },
  "access_token": "jwt_token",
  "refresh_token": "jwt_refresh_token"
}
```

#### POST /auth/login
Login with email/password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123"
}
```

**Response (200):**
```json
{
  "user": { ... },
  "access_token": "jwt_token",
  "refresh_token": "jwt_refresh_token"
}
```

#### POST /auth/social
Login/register with social provider.

**Request:**
```json
{
  "provider": "google | apple | facebook",
  "token": "oauth_token_from_provider"
}
```

**Response (200):**
```json
{
  "user": { ... },
  "access_token": "jwt_token",
  "refresh_token": "jwt_refresh_token"
}
```

---

### User Endpoints

#### GET /users/me
Get current user profile.

**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "Nguyen Van A",
  "avatar_url": "https://...",
  "created_at": "2025-12-10T10:00:00Z"
}
```

#### PUT /users/me
Update user profile.

**Request:**
```json
{
  "name": "Nguyen Van B",
  "avatar_url": "https://..."
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "Nguyen Van B",
  "avatar_url": "https://...",
  "updated_at": "2025-12-10T11:00:00Z"
}
```

#### DELETE /users/me
Delete user account and all associated data.

**Response (204):** No content

---

### Tag Endpoints

#### GET /tags
Get all available tags.

**Response (200):**
```json
{
  "tags": [
    {
      "id": "uuid",
      "name": "Present Tense",
      "category": "tense"
    },
    {
      "id": "uuid",
      "name": "Food",
      "category": "topic"
    }
  ]
}
```

---

### Game Endpoints

#### POST /game/speeches/random
Get random speeches for game session.

**Request:**
```json
{
  "level": "A1",
  "type": "question",
  "tags": ["uuid1", "uuid2"],
  "limit": 10
}
```

**Response (200):**
```json
{
  "speeches": [
    {
      "id": "uuid",
      "audio_url": "https://cdn.../audio1.mp3",
      "text": "What is your name?",
      "level": "A1",
      "type": "question",
      "tags": [
        { "id": "uuid", "name": "Basics" }
      ]
    }
  ]
}
```

#### POST /game/sessions
Save game session results.

**Request:**
```json
{
  "mode": "listen_only",
  "level": "A1",
  "sentence_type": "question",
  "tags": ["uuid1", "uuid2"],
  "total_sentences": 10,
  "correct_count": 8,
  "max_streak": 5,
  "duration_seconds": 300,
  "started_at": "2025-12-10T10:00:00Z",
  "completed_at": "2025-12-10T10:05:00Z",
  "results": [
    {
      "speech_id": "uuid",
      "sequence_number": 1,
      "user_response": "correct",
      "response_time_ms": 5000
    }
  ]
}
```

**Response (201):**
```json
{
  "session_id": "uuid",
  "message": "Session saved successfully"
}
```

#### GET /game/sessions
Get user's game history.

**Query Params:**
- `page` (default: 1)
- `limit` (default: 20)
- `mode` (optional): filter by mode
- `level` (optional): filter by level
- `from_date` (optional): ISO date
- `to_date` (optional): ISO date

**Response (200):**
```json
{
  "sessions": [
    {
      "id": "uuid",
      "mode": "listen_only",
      "level": "A1",
      "total_sentences": 10,
      "correct_count": 8,
      "max_streak": 5,
      "completed_at": "2025-12-10T10:05:00Z"
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

#### GET /game/sessions/{id}
Get detailed session results.

**Response (200):**
```json
{
  "id": "uuid",
  "mode": "listen_only",
  "level": "A1",
  "sentence_type": "question",
  "tags": ["Present Tense", "Food"],
  "total_sentences": 10,
  "correct_count": 8,
  "max_streak": 5,
  "duration_seconds": 300,
  "started_at": "2025-12-10T10:00:00Z",
  "completed_at": "2025-12-10T10:05:00Z",
  "results": [
    {
      "sequence_number": 1,
      "speech": {
        "id": "uuid",
        "audio_url": "https://...",
        "text": "What is your name?",
        "level": "A1",
        "type": "question"
      },
      "user_response": "correct",
      "response_time_ms": 5000
    }
  ]
}
```

---

### Admin Endpoints

#### POST /admin/import/audio
Upload audio files for speech content.

**Request:** `multipart/form-data`
- `files`: array of audio files

**Response (200):**
```json
{
  "uploaded_files": [
    {
      "id": "uuid",
      "filename": "sentence_001.mp3",
      "url": "https://storage.../sentence_001.mp3"
    },
    {
      "id": "uuid",
      "filename": "sentence_002_1.mp3",
      "url": "https://storage.../sentence_002_1.mp3"
    }
  ]
}
```

#### POST /admin/import/csv
Import speech items from CSV.

**Request:** `multipart/form-data`
- `file`: CSV file

**CSV Format:**
```csv
audio_filename,text,level,type,tags
sentence_001.mp3,"What is your name?",A1,question,"Basics,Greetings"
sentence_002.mp3,"My name is John.",A1,answer,"Basics,Greetings"
```

**Response (200):**
```json
{
  "success_count": 98,
  "error_count": 2,
  "errors": [
    {
      "row": 15,
      "error": "Audio file 'missing.mp3' not found"
    },
    {
      "row": 23,
      "error": "Invalid level 'D1'"
    }
  ]
}
```

#### GET /admin/speeches
List all speeches (paginated).

**Query Params:** `page`, `limit`, `level`, `type`

**Response (200):**
```json
{
  "speeches": [ ... ],
  "pagination": { ... }
}
```

#### POST /admin/speeches
Create new speech item.

**Request:**
```json
{
  "audio_url": "https://...",
  "text": "How are you?",
  "level": "A1",
  "type": "question",
  "tags": ["uuid1", "uuid2"]
}
```

#### PUT /admin/speeches/{id}
Update speech item.

#### DELETE /admin/speeches/{id}
Delete speech item.

---

## Open Questions

### Q1: Speech-to-Text & Pronunciation Scoring Service
**Question**: Which service should we use for speech-to-text and pronunciation scoring in listen-and-repeat mode?

**Options**:
1. **Google Cloud Speech-to-Text + Custom scoring**
   - Pros: Accurate, supports Vietnamese
   - Cons: More expensive (~$0.006/15s)
   
2. **Azure Speech Services**
   - Pros: Built-in pronunciation assessment, accurate
   - Cons: Similar cost to Google
   
3. **AWS Transcribe + AWS Polly (for comparison)**
   - Pros: AWS ecosystem integration
   - Cons: No built-in pronunciation scoring
   
4. **Open-source (Whisper by OpenAI)**
   - Pros: Free, can self-host
   - Cons: Need separate pronunciation scoring, infrastructure overhead

**Recommendation**: Start with Azure Speech Services for MVP (integrated pronunciation assessment). Design abstraction layer to allow switching providers later.

---

### Q2: Audio File Storage Strategy
**Question**: How should we organize and optimize audio file storage?

**Considerations**:
- File naming convention
- CDN usage for faster delivery
- Audio format optimization (bitrate, compression)
- Backup strategy

**Recommendation**: 
- Use S3-compatible storage (AWS S3, DigitalOcean Spaces, Cloudflare R2)
- Enable CDN (CloudFront, Cloudflare CDN)
- Store audio in MP3 format, 64kbps (sufficient for speech)
- Organize by level: `/audio/{level}/{uuid}.mp3`

---

### Q3: Offline Game Play Support
**Question**: Should users be able to play games completely offline in Phase 1?

**Considerations**:
- Requires pre-downloading audio files
- Local storage size limits
- Sync complexity

**Recommendation**: Phase 1 requires internet connection. Add offline mode in Phase 2 with:
- Download packs by level
- Background sync for results

---

### Q4: Speech Item Randomization Algorithm
**Question**: How to ensure good variety in random sentence selection?

**Options**:
1. Pure random from filtered set
2. Weighted random (avoid recently played)
3. Exclude user's recently completed sentences (last 50)

**Recommendation**: Phase 1 use pure random. Phase 2 add user history exclusion.

---

### Q5: Game Session Duration
**Question**: Should there be a maximum time limit for game sessions?

**Considerations**:
- User engagement (optimal session length)
- Data integrity (abandoned sessions)
- Resource management

**Recommendation**: 
- No hard time limit
- Track abandoned sessions (started but not completed)
- Provide option to "Save Progress" if user needs to pause long-term

---

### Q6: Admin Panel Technology
**Question**: Should we use Django Admin, build custom React admin, or use admin generator?

**Options**:
1. Django Admin (if using Django)
2. FastAPI + React Admin / Refine
3. FastAPI + Admin generator (SQLAdmin, FastAPI-Admin)

**Recommendation**: Phase 1 use FastAPI + SQLAdmin (simple, fast setup). Can migrate to custom React admin in Phase 2 if needed.

---

### Q7: User Analytics & Tracking
**Question**: What analytics should we track in Phase 1?

**Proposed Metrics**:
- Daily/Weekly/Monthly Active Users
- Game completion rate
- Average session duration
- Most common error patterns
- Retention (D1, D7, D30)

**Implementation**: Firebase Analytics + custom backend events

---

### Q8: Compliment/Motivation Message Management
**Question**: Should compliment messages be hardcoded or managed via backend?

**Phase 1**: Hardcoded in app (5 messages per streak level)
**Phase 2**: Move to backend for easy updates and A/B testing

---

## Future Work (Post-MVP)

### Phase 2: Enhanced Features
1. **Offline Mode**
   - Download audio packs by level
   - Background sync for game results
   - Offline game history access

2. **Advanced Pronunciation Scoring**
   - Word-level pronunciation feedback
   - Phoneme accuracy visualization
   - Specific improvement suggestions

3. **Personalized Learning**
   - AI-recommended practice based on weak areas
   - Adaptive difficulty adjustment
   - Custom learning paths

4. **Social Features**
   - Leaderboards (daily/weekly)
   - Friend challenges
   - Share achievements

5. **Additional Game Modes**
   - Speed mode (rapid-fire sentences)
   - Survival mode (lives system)
   - Multiplayer race

### Phase 3: Content Expansion
1. **Dashboard Implementation**
   - Progress tracking visualization
   - Streak calendar
   - Achievement showcase
   - Daily goals

2. **Skills Tab**
   - Skill-based practice (grammar, vocabulary, pronunciation)
   - Custom drills
   - Spaced repetition system

3. **More Games**
   - Fill in the blank
   - Sentence construction
   - Conversation simulation
   - Vocabulary matching

### Phase 4: Advanced Features
1. **AI Conversation Partner**
   - Free-form conversation practice
   - Context-aware responses
   - Real-time feedback

2. **Speech Recognition Improvements**
   - Accent adaptation
   - Background noise filtering
   - Dialect support

3. **Content Creation Tools**
   - User-generated content
   - Community contributions
   - Peer review system

4. **Certification & Achievements**
   - Level completion certificates
   - Skill badges
   - Progress reports for teachers

### Infrastructure Improvements
1. **Performance Optimization**
   - Audio pre-loading/caching
   - CDN optimization
   - Database query optimization
   - API response caching

2. **Monitoring & Analytics**
   - Real-time error tracking (Sentry)
   - Performance monitoring (New Relic, Datadog)
   - User behavior analytics (Mixpanel, Amplitude)
   - A/B testing framework

3. **DevOps**
   - CI/CD pipelines
   - Automated testing
   - Blue-green deployments
   - Auto-scaling infrastructure

---

## Appendix

### Technology Decision Matrix

| Aspect | Technology | Rationale |
|--------|-----------|-----------|
| Mobile Framework | Flutter | Cross-platform, great performance, single codebase |
| State Management | BLoC | Predictable, testable, scales well |
| Local Storage | Hive | Fast, NoSQL, minimal boilerplate |
| Backend Framework | FastAPI | Modern, async, automatic OpenAPI docs |
| Database | PostgreSQL | Reliable, JSON support, full-text search |
| Audio Storage | S3 + CDN | Scalable, cost-effective, global delivery |
| Authentication | Firebase Auth | Quick integration, supports social login |
| Speech-to-Text | Azure Speech | Built-in pronunciation assessment |

### Glossary

- **Streak**: Number of consecutive correct swipes in a game session
- **Speech Item**: A single audio file + text + metadata for practice
- **Game Session**: One complete playthrough of 10-20 sentences
- **Listen-Only Mode**: User listens and self-evaluates understanding
- **Listen-and-Repeat Mode**: User speaks and receives pronunciation score
- **Phase 1/MVP**: Initial release with core functionality
- **Tags**: Categorization labels (tenses, topics) for speech items

---

**End of Specification Document**

*This is a living document and will be updated as decisions are made and requirements evolve.*
