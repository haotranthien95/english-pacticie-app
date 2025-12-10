# Mobile Implementation Tasks

**Feature**: English Learning App - Flutter Mobile Application  
**Version**: 1.2.0 (Updated with Session 2025-12-10 clarifications)  
**Date**: December 10, 2025  
**Tech Stack**: Flutter 3.24.5, Dart 3.5.4, BLoC, Hive, Firebase Auth  
**Based on**: specs/mobile-implementation-plan.md v1.2.0

---

## Implementation Strategy

**MVP-First Approach**: Build features incrementally with clean architecture, ensuring each phase delivers testable functionality.

**Phase Order**:
1. Foundation → Setup Flutter project with architecture
2. Authentication → Enable user login/registration
3. User Stories (P1 → P2 → P3) → Core gameplay → History → Settings
4. Polish → Responsive layouts, testing, optimization

---

## Dependencies & Execution Order

### User Story Dependencies

```
Foundation ──────┐
(Phase 1)        │
                 ├──→ US1: Authentication ──→ US2: Game Play ──→ US3: Game History
                 │         ↓                      ↓                    ↓
                 │    (All features)        (Listen modes)      (Session review)
                 │    need auth)
                 │
                 └──→ US4: Profile & Settings
                         (Independent after US1)
```

**Critical Path**: Foundation → US1 → US2 → US3  
**Parallel Opportunities**: US4 can be developed alongside US2/US3

### Task Parallelization

**Within Foundation Phase**:
- M001 [P], M002 [P], M003 [P] (different core utilities)

**Within US1: Authentication**:
- M008 [P], M009 [P], M010 [P] (entities, models, schemas)

**Within US2: Game Play**:
- M015 [P], M016 [P], M017 [P] (game entities, models, data sources)

**Within US3: History**:
- M026 [P], M027 [P] (domain and data layers)

---

## Phase 1: Project Foundation

**Goal**: Initialize Flutter project with clean architecture, dependencies, and core utilities.

**Test Criteria**:
- ✅ App runs on Android and iOS
- ✅ All dependencies installed
- ✅ Clean architecture folders created
- ✅ Hive storage initialized
- ✅ DI container configured

### Tasks

- [X] M001 [P] Initialize Flutter project in apps/mobile/ with package name com.englishapp.mobile
- [X] M002 [P] Add all dependencies to pubspec.yaml (BLoC, Hive, Dio, Firebase, audio packages)
- [X] M003 [P] Create clean architecture folder structure (core, data, domain, presentation, di)
- [X] M004 [P] Define app constants (API endpoints, storage keys, enums) in lib/core/constants/
- [X] M005 [P] Create custom exceptions and error classes in lib/core/errors/
- [X] M006 [P] Implement Failure classes for Either pattern in lib/core/errors/failures.dart
- [X] M007 Initialize Hive storage with boxes (auth, cache, game, settings) in lib/data/datasources/local/hive_storage.dart
- [X] M008 Set up GetIt dependency injection container in lib/di/injection.dart

---

## Phase 2: US1 - User Authentication

**Goal**: Enable users to register, login with email/password, and authenticate via Firebase OAuth (Google, Apple, Facebook).

**User Story**: As a learner, I want to create an account and login using email or social providers so I can access personalized features.

**Priority**: P1 (Highest)

**Test Criteria**:
- ✅ Email registration creates account and returns JWT
- ✅ Email login authenticates and stores token
- ✅ Google Sign-In acquires OAuth token and exchanges for JWT
- ✅ Apple Sign-In works on iOS
- ✅ Facebook Sign-In works
- ✅ Token persisted in Hive
- ✅ Auto-login on app restart if token valid
- ✅ Logout clears token

### Tasks

- [X] M009 [P] [US1] Create User entity in lib/domain/entities/user.dart
- [X] M010 [P] [US1] Create AuthRepository interface in lib/domain/repositories/auth_repository.dart
- [X] M011 [P] [US1] Create auth use cases (Login, Register, SocialLogin, Logout, GetCurrentUser) in lib/domain/usecases/auth/
- [X] M012 [P] [US1] Create UserModel with JSON serialization in lib/data/models/user_model.dart
- [X] M013 [P] [US1] Implement local auth data source (token storage in Hive) in lib/data/datasources/local/auth_local_datasource.dart
- [X] M014 [US1] Implement remote auth data source (API calls for register, login, social) in lib/data/datasources/remote/auth_remote_datasource.dart
- [X] M015 [US1] Implement Firebase Auth service for OAuth token acquisition (Google/Apple/Facebook) in lib/data/datasources/remote/firebase_auth_service.dart
- [X] M016 [US1] Implement AuthRepositoryImpl combining local and remote sources in lib/data/repositories/auth_repository_impl.dart
- [X] M017 [US1] Create AuthBloc with events (imperative naming: LoginRequested, not UserLoggedIn) and states for all auth flows in lib/presentation/blocs/auth/auth_bloc.dart
- [X] M018 [US1] Create Login screen with email/password form and social buttons in lib/presentation/screens/auth/login_screen.dart
- [X] M019 [US1] Create Register screen with email/password/name form in lib/presentation/screens/auth/register_screen.dart
- [X] M020 [US1] Create Splash screen with auto-login logic in lib/presentation/screens/auth/splash_screen.dart

---

## Phase 3: US2 - Game Play (Listen & Pronounce)

**Goal**: Implement core gameplay with two modes: listen-only (swipe evaluation) and listen-and-repeat (pronunciation scoring).

**User Story**: As a learner, I want to practice English listening and pronunciation with speeches matching my level and interests.

**Priority**: P1 (Highest)

**Dependencies**: Requires US1 (authentication)

**Test Criteria**:
- ✅ Game config screen filters by level, type, tags
- ✅ Fetch random speeches returns valid results
- ✅ Listen-only mode: swipe left (incorrect), swipe right (correct)
- ✅ Streak counter increments on correct answers
- ✅ Listen-and-repeat mode: record to memory buffer only
- ✅ Audio bytes stream to backend API (no file I/O)
- ✅ Pronunciation score displayed immediately per sentence
- ✅ User acknowledges score before advancing
- ✅ Session saves to Hive (offline queue)
- ✅ Auto-sync to backend when online

### Tasks

#### Game Configuration

- [X] M021 [P] [US2] Create Tag and Speech entities in lib/domain/entities/
- [X] M022 [P] [US2] Create GameSession and GameResult entities in lib/domain/entities/
- [X] M023 [P] [US2] Create GameRepository interface in lib/domain/repositories/game_repository.dart
- [X] M024 [P] [US2] Create game use cases (GetTags, GetRandomSpeeches, CreateSession, SyncSessions) in lib/domain/usecases/game/
- [X] M025 [P] [US2] Create TagModel, SpeechModel, GameSessionModel with JSON serialization in lib/data/models/
- [X] M026 [US2] Implement game local data source with offline queue and exponential backoff retry (1s, 2s, 4s, 8s) in lib/data/datasources/local/game_local_datasource.dart
- [X] M027 [US2] Implement game remote data source (tags, speeches, sessions APIs) in lib/data/datasources/remote/game_remote_datasource.dart
- [X] M028 [US2] Implement GameRepositoryImpl with offline-first strategy in lib/data/repositories/game_repository_impl.dart
- [X] M029 [US2] Create GameConfigBloc for game setup screen in lib/presentation/blocs/game/game_config_bloc.dart
- [X] M030 [US2] Create Game Config screen with level, type, tag selectors in lib/presentation/screens/game/game_config_screen.dart

#### Listen-Only Mode

- [X] M031 [P] [US2] Create audio player service using just_audio in lib/data/datasources/local/audio_player_service.dart
- [X] M032 [P] [US2] Create GameBloc for listen-only mode with imperative swipe events (SwipeLeftRequested, SwipeRightRequested) in lib/presentation/blocs/game/game_bloc.dart
- [ ] M033 [US2] Create Listen-Only game play screen with swipe cards and streak counter in lib/presentation/screens/game/listen_only_game_screen.dart
- [ ] M034 [US2] Create game result summary screen with statistics in lib/presentation/screens/game/game_summary_screen.dart

#### Listen-and-Repeat Mode

- [ ] M035 [P] [US2] Request microphone permissions (Android/iOS) in AndroidManifest.xml and Info.plist
- [ ] M036 [US2] Create microphone recorder service with memory buffer (no file writes) and 10MB limit validation in lib/data/datasources/local/audio_recorder_service.dart
- [ ] M037 [US2] Implement speech-to-text remote data source (POST /speech/score with audio bytes, returns SpeechScoreResponse) in lib/data/datasources/remote/speech_remote_datasource.dart
- [ ] M038 [US2] Update GameBloc with imperative recording events (RecordingStarted, RecordingStopped, TranscriptionRequested) in lib/presentation/blocs/game/game_bloc.dart
- [ ] M039 [US2] Create Listen-and-Repeat game screen with record button and pronunciation feedback in lib/presentation/screens/game/listen_repeat_game_screen.dart
- [ ] M040 [US2] Create pronunciation feedback card with immediate per-sentence scoring display in lib/presentation/widgets/game/pronunciation_feedback_card.dart

---

## Phase 4: US3 - Game History & Session Review

**Goal**: Allow users to view past game sessions with filters and detailed statistics.

**User Story**: As a learner, I want to review my practice history to track progress and identify areas for improvement.

**Priority**: P2 (High)

**Dependencies**: Requires US1 (authentication) and US2 (game sessions)

**Test Criteria**:
- ✅ History screen shows paginated sessions
- ✅ Filters work (mode, level, date range)
- ✅ Detail screen shows full session statistics
- ✅ Speech-by-speech breakdown displayed
- ✅ Pronunciation scores visible (for listen-and-repeat)

### Tasks

- [ ] M041 [P] [US3] Create history use cases (GetSessions, GetSessionDetail) in lib/domain/usecases/game/
- [ ] M042 [P] [US3] Add session history methods to GameRepositoryImpl in lib/data/repositories/game_repository_impl.dart
- [ ] M043 [US3] Create HistoryBloc for session list with pagination in lib/presentation/blocs/history/history_bloc.dart
- [ ] M044 [US3] Create History screen with filter chips and session cards in lib/presentation/screens/history/history_screen.dart
- [ ] M045 [US3] Create Session Detail screen with statistics and speech breakdown in lib/presentation/screens/history/session_detail_screen.dart

---

## Phase 5: US4 - User Profile & Settings

**Goal**: Enable users to view/edit profile and configure app settings (theme, language).

**User Story**: As a learner, I want to customize my profile and app preferences for a personalized experience.

**Priority**: P2 (High)

**Dependencies**: Requires US1 (authentication)

**Test Criteria**:
- ✅ Profile screen shows user info
- ✅ Edit profile updates name and avatar
- ✅ Settings toggle theme (light/dark)
- ✅ Settings change language (English/Vietnamese)
- ✅ Logout clears token and navigates to login

### Tasks

- [ ] M046 [P] [US4] Create user use cases (GetProfile, UpdateProfile, DeleteAccount) in lib/domain/usecases/user/
- [ ] M047 [P] [US4] Create UserRepository interface and implementation in lib/domain/repositories/ and lib/data/repositories/
- [ ] M048 [US4] Create ProfileBloc for profile management in lib/presentation/blocs/profile/profile_bloc.dart
- [ ] M049 [US4] Create SettingsBloc for theme and language in lib/presentation/blocs/profile/settings_bloc.dart
- [ ] M050 [US4] Create Profile screen with user info and edit button in lib/presentation/screens/profile/profile_screen.dart
- [ ] M051 [US4] Create Edit Profile screen with form in lib/presentation/screens/profile/edit_profile_screen.dart
- [ ] M052 [US4] Create Settings screen with theme toggle and language selector in lib/presentation/screens/profile/settings_screen.dart

---

## Phase 6: Navigation & Routing

**Goal**: Implement navigation with go_router and deep linking.

**Test Criteria**:
- ✅ Navigation between all screens works
- ✅ Auth guard redirects unauthenticated users
- ✅ Bottom navigation on home/history/profile
- ✅ Deep links handled correctly

### Tasks

- [ ] M053 [P] Create app router with go_router in lib/core/router/app_router.dart
- [ ] M054 [P] Implement auth guard for protected routes in lib/core/router/auth_guard.dart
- [ ] M055 Create home screen with bottom navigation in lib/presentation/screens/home/home_screen.dart

---

## Phase 7: Theming, Responsive Layouts & Localization

**Goal**: Add light/dark themes, tablet-responsive layouts, and multi-language support.

**Test Criteria**:
- ✅ Theme toggles between light and dark
- ✅ Theme persists across sessions
- ✅ Tablet layouts use breakpoints (600dp/840dp)
- ✅ All screens adapt to tablet sizes
- ✅ English and Vietnamese translations complete
- ✅ Language changes reflect immediately

### Tasks

- [ ] M056 [P] Create theme system with light and dark ThemeData in lib/core/theme/app_theme.dart
- [ ] M057 [P] Create responsive utils with Material Design breakpoints (≥600dp for tablet, ≥840dp for large tablet) in lib/core/utils/responsive_utils.dart
- [ ] M058 [P] Create responsive builder widget for adaptive layouts using MediaQuery.of(context).size.width in lib/presentation/widgets/common/responsive_builder.dart
- [ ] M059 [P] Update all screens with responsive layouts for tablets (phone <600dp, tablet ≥600dp) in lib/presentation/screens/
- [ ] M060 [P] Set up localization with ARB files in lib/l10n/
- [ ] M061 Create Vietnamese translations in lib/l10n/app_vi.arb
- [ ] M062 Create English translations in lib/l10n/app_en.arb

---

## Phase 8: Testing & Polish

**Goal**: Comprehensive testing, performance optimization, and production readiness.

**Test Criteria**:
- ✅ All unit tests pass (>80% coverage)
- ✅ Widget tests cover critical flows
- ✅ Integration tests validate E2E scenarios
- ✅ No memory leaks
- ✅ Smooth animations (60 FPS)
- ✅ App size optimized
- ✅ Crash-free on test devices

### Tasks

- [ ] M063 [P] Write unit tests for BLoCs (auth, game, history, profile) in test/unit/
- [ ] M064 [P] Write unit tests for repositories and data sources in test/unit/
- [ ] M065 [P] Write widget tests for screens and widgets in test/widget/
- [ ] M066 [P] Write integration tests for complete user flows in integration_test/
- [ ] M067 Profile app performance and fix bottlenecks
- [ ] M068 Optimize image and asset sizes
- [ ] M069 Test on physical devices (Android and iOS)
- [ ] M070 Test offline sync functionality thoroughly
- [ ] M071 Test memory buffer audio recording (no file writes)
- [ ] M072 Test responsive layouts on tablets (7" and 10"+)
- [ ] M073 Configure Firebase Analytics and Crashlytics
- [ ] M074 Prepare app icons and splash screens
- [ ] M075 Configure app signing for Android and iOS
- [ ] M076 Create release builds and test on devices
- [ ] M077 Write README with setup and development guide

---

## Task Summary

**Total Tasks**: 77

### By Phase:
- Phase 1 (Foundation): 8 tasks
- Phase 2 (US1 - Auth): 12 tasks
- Phase 3 (US2 - Game Play): 20 tasks
- Phase 4 (US3 - History): 5 tasks
- Phase 5 (US4 - Profile): 7 tasks
- Phase 6 (Navigation): 3 tasks
- Phase 7 (Theming & Localization): 7 tasks
- Phase 8 (Testing & Polish): 15 tasks

### By Priority:
- P1 (Highest): 32 tasks (US1 + US2)
- P2 (High): 12 tasks (US3 + US4)
- Foundation/Polish: 33 tasks

### Parallelizable Tasks:
- **39 tasks marked [P]** can run in parallel with others in same phase
- **38 tasks** are sequential within their user story

---

## Suggested MVP Scope

**Minimum Viable Product** (5-6 weeks):
- ✅ Phase 1: Foundation (Week 1)
- ✅ Phase 2: US1 - Authentication (Week 2)
- ✅ Phase 3: US2 - Game Play (Week 3-4)
- ✅ Phase 4: US3 - Game History (Week 5)
- ✅ Phase 6: Navigation (Week 5)
- ✅ Phase 8: Basic Testing (Week 6)

**Post-MVP Enhancements**:
- Phase 5: US4 - Profile & Settings (Week 7)
- Phase 7: Theming & Responsive Layouts (Week 8)
- Phase 8: Advanced Testing & Polish (Week 9)

---

## Parallel Execution Examples

### Foundation Phase (Week 1, Day 1-3)
```
Developer A: M001 (Flutter init) + M004 (constants)
Developer B: M002 (dependencies) + M005 (errors)
Developer C: M007 (Hive) + M008 (DI)
```

### US1: Authentication (Week 2)
```
Developer A: M009-M011 (domain layer)
Developer B: M012-M016 (data layer)
Developer C: M017-M020 (presentation layer)
```

### US2: Game Play (Week 3-4)
```
Developer A: M021-M025 (entities & models) → M031-M034 (listen-only)
Developer B: M026-M028 (repositories) → M035-M037 (recording setup)
Developer C: M029-M030 (config screen) → M038-M040 (listen-and-repeat)
```

### US3: History (Week 5)
```
Developer A: M041-M042 (domain & data)
Developer B: M043-M045 (presentation)
```

---

## Key Architectural Decisions

**From mobile.md clarifications (updated Session 2025-12-10)**:

### Original Clarifications (Session 2025-12-09):

1. **Firebase SDKs for OAuth**: Use google_sign_in and sign_in_with_apple packages to acquire tokens on mobile, send to backend /auth/social for JWT issuance (no Firebase Admin SDK on backend)

2. **Memory Buffer Audio Recording**: Record audio to memory buffer only using record package, stream bytes to backend API via multipart upload, never write to filesystem (maximum security, no cleanup needed)

3. **Offline-First Game Sessions**: Always save completed sessions to Hive first (guarantees no data loss), attempt immediate backend sync if online, automatically sync pending sessions on reconnect using connectivity_plus

4. **Responsive Tablet Layouts**: Use MediaQuery with breakpoints (600dp for small tablets, 840dp for large tablets), adaptive layouts per screen (single column → two-column grid, portrait → landscape)

5. **Immediate Pronunciation Feedback**: Show pronunciation score immediately after each sentence with word-by-word breakdown, require user acknowledgment before advancing to next sentence (best learning feedback loop)

### New Clarifications (Session 2025-12-10):

6. **BLoC Event Naming Convention**: Use imperative (command) style - LoginRequested, GameStarted, RecordingStarted (NOT past tense: UserLoggedIn, GameWasStarted). Events represent user intent/commands.

7. **Offline Sync Retry Strategy**: When sync fails after reconnection, use exponential backoff - retry at 1s, 2s, 4s, 8s intervals then fail. Balances persistence with UX, failed sessions logged but don't block gameplay.

8. **Tablet Breakpoint Standard**: Use ≥600dp for tablet layout switch (Material Design standard). Implement with `MediaQuery.of(context).size.width >= 600`.

9. **Audio Buffer Limit**: Enforce 10MB maximum buffer size. Sufficient for ~2 minutes at 64kbps, provides 10x safety margin for per-sentence recording (typical sentences <12 seconds). Auto-stop if exceeded.

10. **Pronunciation API Endpoint**: POST /speech/score with multipart upload (audio file + reference_text + language), returns SpeechScoreResponse with pronunciationScore, wordScores array, and detailed metrics.

---

## Next Steps

1. **Initialize Flutter project** with proper package name and dependencies
2. **Set up architecture** with clean architecture folders and DI
3. **Implement authentication** as prerequisite for all features
4. **Build game modes** with offline queue and memory buffer recording
5. **Add history and profile** for complete user experience
6. **Test on devices** including tablets with responsive layouts
7. **Polish and optimize** for production release
8. **Deploy to stores** (Google Play and App Store)

---

**Implementation Note**: Each task includes specific file paths and acceptance criteria in the mobile-implementation-plan.md. Refer to that document for detailed implementation guidance including code examples and architectural patterns.
