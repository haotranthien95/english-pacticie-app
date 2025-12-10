# Backend Implementation Tasks

**Feature**: English Learning App - Backend API & Admin System  
**Version**: 1.2.0 (Updated with Session 2025-12-10 clarifications)  
**Date**: December 10, 2025  
**Tech Stack**: Python 3.12, FastAPI, PostgreSQL, MinIO, Azure Speech SDK  
**Based on**: specs/backend-implementation-plan.md v1.2.0

---

## Implementation Strategy

**MVP-First Approach**: Build features incrementally, ensuring each phase is independently testable and deployable.

**Phase Order**:
1. Setup & Foundation → Deploy skeleton API
2. Core Models & Auth → Enable user registration
3. User Stories (P1 → P2 → P3) → Deliver value progressively
4. Polish & Security → Production readiness

---

## Dependencies & Execution Order

### User Story Dependencies

```
Setup (Phase 1) ──┐
                  │
Foundation ───────┤
(Phase 2)         │
                  ├──→ US1: Authentication ──→ US2: Game Play ──→ US3: History
                  │         ↓                      ↓                    ↓
                  │    (All subsequent)      (Depends on US1)    (Depends on US2)
                  │    stories need auth)
                  │
                  └──→ US4: Admin Panel ──→ US5: Content Import
                         (Independent)        (Depends on US4)
```

**Critical Path**: Setup → Foundation → US1 → US2 → US3  
**Parallel Opportunities**: US4 and US5 can be developed alongside US2/US3

### Task Parallelization

**Within Setup Phase** (all [P]):
- T001, T002, T003 can run in parallel (different files)

**Within Foundation Phase**:
- T006 [P] and T007 [P] (different models)
- T008 [P], T009 [P], T010 [P] (different models)

**Within US1: Authentication**:
- T012 [P] and T013 [P] (schemas vs utilities)

**Within US2: Game Play**:
- T018 [P], T019 [P], T020 [P] (independent services)

**Within US4: Admin Panel**:
- T029 [P], T030 [P], T031 [P] (different CRUD endpoints)

---

## Phase 1: Setup & Infrastructure

**Goal**: Initialize project with proper structure, database, and dev environment.

**Test Criteria**: 
- ✅ Server starts without errors
- ✅ Health endpoint returns 200 OK
- ✅ Database connection successful
- ✅ Docker Compose services running

### Tasks

- [ ] T001 [P] Initialize project scaffold with directory structure, virtual environment, and dependencies in apps/backend/
- [ ] T002 [P] Configure FastAPI application with CORS, middleware, health check endpoint in app/main.py
- [ ] T003 [P] Set up SQLAlchemy database connection with session management in app/database.py
- [ ] T004 Initialize Alembic for database migrations in alembic/
- [ ] T005 [P] Create docker-compose.yml with PostgreSQL, Redis, MinIO services

---

## Phase 2: Foundational Data Layer

**Goal**: Implement all database models and migrations (blocking prerequisite for all user stories).

**Test Criteria**:
- ✅ All migrations run successfully
- ✅ Database schema matches spec
- ✅ Foreign key constraints work
- ✅ Indexes created correctly

### Tasks

- [ ] T006 [P] Implement User model with auth_provider enum and indexes in app/models/user.py
- [ ] T007 [P] Implement Tag model with unique name constraint in app/models/tag.py
- [ ] T008 [P] Implement Speech model with many-to-many Tag relationship through speech_tags join table in app/models/speech.py
- [ ] T009 [P] Implement GameSession model with foreign key to User in app/models/game_session.py
- [ ] T010 [P] Implement GameResult model with foreign keys to GameSession and Speech in app/models/game_result.py
- [ ] T011 Create database seed script with sample tags, speeches, and test users in scripts/seed_database.py

---

## Phase 3: US1 - User Authentication

**Goal**: Enable users to register, login, and authenticate via JWT tokens (email and OAuth providers).

**User Story**: As a learner, I want to create an account and login securely so I can save my progress.

**Priority**: P1 (Highest)

**Test Criteria**:
- ✅ Register with email/password returns JWT token
- ✅ Login with valid credentials succeeds
- ✅ Social OAuth (Google/Apple/Facebook) token validation works
- ✅ Invalid credentials return 401
- ✅ JWT token authenticates protected endpoints
- ✅ Refresh token flow works correctly

### Tasks

- [ ] T012 [P] [US1] Implement password hashing, JWT generation, and validation utilities in app/utils/security.py
- [ ] T013 [P] [US1] Create auth Pydantic schemas for register, login, social auth, token responses in app/schemas/auth.py
- [ ] T014 [US1] Implement AuthService with registration, login, OAuth validation (Google/Apple/Facebook), JWT issuance in app/services/auth_service.py
- [ ] T015 [US1] Create auth API endpoints: POST /auth/register, POST /auth/login, POST /auth/social, POST /auth/refresh in app/api/v1/auth.py
- [ ] T016 [US1] Implement get_current_user dependency for JWT token validation in app/dependencies.py

---

## Phase 4: US2 - Game Play & Speech Content

**Goal**: Enable users to fetch random speeches and play listening games with pronunciation scoring.

**User Story**: As a learner, I want to practice listening and pronunciation with filtered speech content matching my level.

**Priority**: P1 (Highest)

**Dependencies**: Requires US1 (authentication)

**Test Criteria**:
- ✅ Fetch random speeches with filters returns correct results
- ✅ Audio URLs are valid and accessible
- ✅ Game session creation saves to database
- ✅ Pronunciation scoring endpoint accepts audio and returns scores
- ✅ Azure Speech API integration works
- ✅ User audio never persisted (memory buffer only)

### Tasks

- [ ] T017 [US2] Create speech and game Pydantic schemas with validation in app/schemas/speech.py and app/schemas/game.py
- [ ] T018 [P] [US2] Implement MinIO storage service for audio upload, signed URLs, bucket operations in app/services/storage_service.py
- [ ] T019 [P] [US2] Implement SpeechService with random speech filtering (level, type, tags) and SQL queries in app/services/speech_service.py
- [ ] T020 [P] [US2] Implement GameService for session creation with results in transaction in app/services/game_service.py
- [ ] T021 [US2] Create speech provider base interface with ScoringResult and WordScore dataclasses in app/services/speech_provider/base.py
- [ ] T022 [P] [US2] Create custom exception classes (SpeechProcessingError, AuthenticationError, etc.) for typed error handling in app/core/exceptions.py
- [ ] T023 [P] [US2] Implement AudioBufferManager context manager for guaranteed buffer cleanup in app/utils/audio_buffer.py
- [ ] T024 [US2] Implement Azure Speech Provider with pronunciation assessment and memory buffer audio handling in app/services/speech_provider/azure_provider.py
- [ ] T025 [US2] Create speech provider factory that returns Azure provider for MVP in app/services/speech_provider/factory.py
- [ ] T026 [US2] Create game API endpoints: POST /game/speeches/random, POST /game/sessions in app/api/v1/game.py
- [ ] T027 [US2] Create speech scoring endpoint: POST /speech/score with multipart audio upload, AudioBufferManager for cleanup, and typed exception handling in app/api/v1/speech.py

---

## Phase 5: US3 - Game History & User Profile

**Goal**: Allow users to view past game sessions and manage their profile.

**User Story**: As a learner, I want to review my practice history and update my profile.

**Priority**: P2 (High)

**Dependencies**: Requires US1 (authentication) and US2 (game sessions)

**Test Criteria**:
- ✅ GET /users/me returns user profile
- ✅ PUT /users/me updates profile fields
- ✅ GET /game/sessions returns paginated history
- ✅ GET /game/sessions/{id} returns full session details
- ✅ Filters work (mode, level, date range)
- ✅ Pagination works correctly

### Tasks

- [ ] T026 [P] [US3] Create user Pydantic schemas for profile responses in app/schemas/user.py
- [ ] T027 [P] [US3] Implement UserService with profile get/update/delete operations in app/services/user_service.py
- [ ] T028 [US3] Create user API endpoints: GET /users/me, PUT /users/me, DELETE /users/me in app/api/v1/users.py
- [ ] T029 [US3] Add game session history methods to GameService with pagination and filters in app/services/game_service.py
- [ ] T030 [US3] Add game history endpoints: GET /game/sessions, GET /game/sessions/{id} to app/api/v1/game.py

---

## Phase 6: US4 - Admin Content Management

**Goal**: Provide admin panel for managing speeches, tags, and viewing analytics.

**User Story**: As an admin, I want to manage speech content and tags through a web interface.

**Priority**: P2 (High)

**Dependencies**: Requires Phase 2 (models) - can be developed in parallel with US2/US3

**Test Criteria**:
- ✅ SQLAdmin panel accessible at /admin
- ✅ Admin can login with credentials
- ✅ Speech CRUD operations work
- ✅ Tag CRUD operations work
- ✅ Tag deletion blocked if speeches exist
- ✅ Full-text search on speeches works

### Tasks

- [ ] T031 [P] [US4] Create admin speech CRUD endpoints with pagination and filters in app/api/v1/admin/speeches.py
- [ ] T032 [P] [US4] Create admin tag CRUD endpoints with speech count in app/api/v1/admin/tags.py
- [ ] T033 [P] [US4] Implement SQLAdmin authentication backend with bcrypt password verification in app/admin/auth.py
- [ ] T034 [US4] Create SQLAdmin model views for Speech, Tag, User, GameSession in app/admin/views.py
- [ ] T035 [US4] Mount SQLAdmin panel to FastAPI app at /admin in app/main.py

---

## Phase 7: US5 - Bulk Content Import

**Goal**: Enable admins to import speech content via CSV with audio file uploads.

**User Story**: As an admin, I want to bulk import speeches from CSV files to populate content quickly.

**Priority**: P3 (Medium)

**Dependencies**: Requires US4 (admin endpoints) and US2 (storage service)

**Test Criteria**:
- ✅ Audio files upload successfully to MinIO
- ✅ CSV parsing validates all rows before import
- ✅ Import is atomic (all or nothing)
- ✅ Duplicate filenames handled with suffixes
- ✅ Tags auto-created if missing
- ✅ Error report shows row-level failures

### Tasks

- [ ] T036 [P] [US5] Create audio upload endpoint: POST /admin/import/audio with multipart handling in app/api/v1/admin/imports.py
- [ ] T037 [US5] Create CSV import endpoint: POST /admin/import/csv with validation and transaction in app/api/v1/admin/imports.py
- [ ] T038 [US5] Implement ImportService with audio upload, CSV parsing, and bulk creation logic in app/services/import_service.py

---

## Phase 8: Polish & Cross-Cutting Concerns

**Goal**: Add rate limiting, caching, monitoring, comprehensive testing, and security hardening.

**Test Criteria**:
- ✅ Rate limiting enforces limits correctly
- ✅ Redis caching reduces database load
- ✅ All tests pass (unit, integration, E2E)
- ✅ Security scan passes (Bandit, Safety)
- ✅ Load testing meets performance targets
- ✅ Prometheus metrics exposed

### Tasks

- [ ] T039 [P] Implement Redis caching decorator and cache invalidation in app/utils/cache.py
- [ ] T040 [P] Add rate limiting with SlowAPI to protect endpoints in app/main.py
- [ ] T041 [P] Set up logging with structlog for JSON output in app/utils/logging.py
- [ ] T042 [P] Add Prometheus metrics instrumentation in app/main.py
- [ ] T043 [P] Write unit tests for services (auth, speech, game, import) with pytest-mock for simple deps and manual test doubles for Azure SDK in tests/unit/
- [ ] T044 [P] Write unit tests for AudioBufferManager context manager ensuring cleanup on exceptions in tests/unit/utils/test_audio_buffer.py
- [ ] T045 [P] Write unit tests for typed exception handling (service raises, API converts to HTTP) in tests/unit/api/test_exception_handlers.py
- [ ] T046 [P] Write integration tests for API endpoints in tests/integration/
- [ ] T047 [P] Write E2E tests for complete user flows in tests/e2e/
- [ ] T048 Run security scans with Bandit and Safety
- [ ] T049 Create production Dockerfile with multi-stage build
- [ ] T050 Create deployment configuration (K8s manifests or docker-compose.prod.yml) in deploy/
- [ ] T051 Write API documentation and deployment guide in README.md and docs/

---

## Task Summary

**Total Tasks**: 51 (was 49, added 2 for Session 2025-12-10 clarifications)

### By Phase:
- Phase 1 (Setup): 5 tasks
- Phase 2 (Foundation): 6 tasks  
- Phase 3 (US1 - Auth): 5 tasks
- Phase 4 (US2 - Game Play): 11 tasks (was 9, added 2 for error handling + buffer cleanup)
- Phase 5 (US3 - History): 5 tasks
- Phase 6 (US4 - Admin): 5 tasks
- Phase 7 (US5 - Import): 3 tasks
- Phase 8 (Polish): 13 tasks (was 11, added 2 for context manager + exception testing)

### By Priority:
- P1 (Highest): 16 tasks (US1 + US2, increased from 14)
- P2 (High): 10 tasks (US3 + US4)
- P3 (Medium): 3 tasks (US5)
- Foundation/Polish: 22 tasks

### Parallelizable Tasks:
- **27 tasks marked [P]** can run in parallel with others in same phase
- **22 tasks** are sequential within their user story

---

## Suggested MVP Scope

**Minimum Viable Product** (4-5 weeks):
- ✅ Phase 1: Setup & Infrastructure (Week 1)
- ✅ Phase 2: Foundational Data Layer (Week 1)
- ✅ Phase 3: US1 - User Authentication (Week 2)
- ✅ Phase 4: US2 - Game Play & Speech Content (Week 3-4)
- ✅ Phase 5: US3 - Game History (Week 4)
- ✅ Phase 8: Basic Testing & Security (Week 5)

**Post-MVP Enhancements**:
- Phase 6: US4 - Admin Panel (Week 6)
- Phase 7: US5 - Bulk Import (Week 7)
- Phase 8: Advanced Polish (Week 8)

---

## Parallel Execution Examples

### Setup Phase (Week 1, Day 1-2)
```
Developer A: T001 (scaffold) + T004 (Alembic)
Developer B: T002 (FastAPI) + T003 (database)
Developer C: T005 (docker-compose)
```

### Foundation Phase (Week 1, Day 3-5)
```
Developer A: T006 (User) + T007 (Tag)
Developer B: T008 (Speech) + T009 (GameSession)
Developer C: T010 (GameResult) + T011 (seed script)
```

### US1: Authentication (Week 2)
```
Developer A: T012 (security utils) + T013 (schemas)
Developer B: T014 (AuthService) → T015 (auth endpoints)
Developer C: T016 (current_user dependency)
```

### US2: Game Play (Week 3)
```
Developer A: T017 (schemas) → T021-T023 (speech providers)
Developer B: T018 (storage) + T019 (SpeechService)
Developer C: T020 (GameService) → T024-T025 (endpoints)
```

---

## Next Steps

1. **Start with Phase 1**: Initialize project structure and dev environment
2. **Complete Phase 2**: Build all models before feature work
3. **Implement US1**: Authentication is prerequisite for all user features
4. **Build US2**: Core game functionality
5. **Add US3**: History and profile
6. **Test continuously**: Write tests alongside feature development
7. **Deploy to staging**: After each phase for validation
8. **Iterate**: Gather feedback and refine

---

**Implementation Note**: Each task includes specific file paths and acceptance criteria in the backend-implementation-plan.md. Refer to that document for detailed implementation guidance.
