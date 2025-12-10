# Mobile App Specification - English Learning App

**Version:** 1.0.0  
**Date:** December 10, 2025  
**Platform:** Flutter (Android, iOS, Tablet)  
**Status:** Phase 1 (MVP)

---

## Table of Contents

1. [Overview](#overview)
2. [Technology Stack](#technology-stack)
3. [Architecture](#architecture)
4. [Navigation Map](#navigation-map)
5. [Screen Specifications](#screen-specifications)
6. [State Management (BLoC)](#state-management-bloc)
7. [Data Models](#data-models)
8. [Local Storage (Hive)](#local-storage-hive)
9. [API Integration](#api-integration)
10. [Error Handling](#error-handling)
11. [Offline Behavior](#offline-behavior)
12. [Themes & Localization](#themes--localization)

---

## Overview

### App Purpose
A Flutter-based English learning mobile application focused on listening comprehension and pronunciation practice through the "Listen and Repeat" game.

### Key Features
- Multi-provider authentication (Email, Google, Apple, Facebook)
- "Listen and Repeat" game with two modes (listen-only and listen-and-repeat)
- Swipe-based self-evaluation with streak tracking
- Auto-advancing gameplay with minimal user interaction
- Game history and detailed session reviews
- Vietnamese UI with English learning content
- Light/Dark theme support
- Tablet-optimized layouts

### Target Platforms
- **Android**: API 26+ (Android 8.0+)
- **iOS**: iOS 14.0+
- **Screen sizes**: Phone (4.7" - 6.7"), Tablet (7" - 12.8")

---

## Technology Stack

### Core Framework
- **Flutter**: 3.24.5 (Dart 3.5.4)
- **State Management**: flutter_bloc (^8.1.6)
- **Dependency Injection**: get_it (^8.0.2)

### Local Storage
- **Hive**: ^2.2.3 (NoSQL local database)
- **Hive Flutter**: ^1.1.0
- **Hive Generator**: ^2.0.1 (for type adapters)

### Backend Integration
- **HTTP Client**: dio (^5.7.0)
- **Networking**: retrofit (^4.4.1) + retrofit_generator (^9.1.4)
- **JSON Serialization**: json_serializable (^6.8.0)

### Firebase Services
- **Firebase Core**: firebase_core (^3.6.0)
- **Authentication**: firebase_auth (^5.3.1)
- **Google Sign-In**: google_sign_in (^6.2.2)
- **Apple Sign-In**: sign_in_with_apple (^6.1.3)
- **Analytics**: firebase_analytics (^11.3.3)

### Media & Audio
- **Audio Player**: just_audio (^0.9.41)
- **Audio Recorder**: record (^5.1.2)
- **Permission Handler**: permission_handler (^11.3.1)

### UI & UX
- **Icons**: flutter_svg (^2.0.14)
- **Animations**: lottie (^3.1.3)
- **Swipe Detection**: flutter_card_swiper (^7.0.1)
- **Loading**: flutter_spinkit (^5.2.1)
- **Cached Images**: cached_network_image (^3.4.1)
- **Connectivity**: connectivity_plus (^6.1.0)

### Localization
- **i18n**: flutter_localizations (SDK)
- **intl**: ^0.19.0

### Utilities
- **UUID**: uuid (^4.5.1)
- **Equatable**: equatable (^2.0.7) (for value comparison in BLoC)
- **Logger**: logger (^2.4.0)
- **Either**: dartz (^0.10.1) (for functional error handling)

---

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Screens   │  │   Widgets   │  │    Theme    │    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │
│         └─────────────────┴─────────────────┘           │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                    BLoC Layer                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ AuthBloc │ │ GameBloc │ │ProfileBloc│ │HistoryBloc│ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │
│       └────────────┴────────────┴────────────┘         │
└─────────────────────┬───────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────┐
│                 Repository Layer                        │
│  ┌────────────────┐ ┌────────────────┐ ┌─────────────┐ │
│  │ UserRepository │ │ GameRepository │ │TagRepository│ │
│  └────────┬───────┘ └────────┬───────┘ └──────┬──────┘ │
│           └──────────────────┴────────────────┘         │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
┌───────▼────────┐         ┌────────▼─────────┐
│  Local Storage │         │   Remote API     │
│  (Hive Boxes)  │         │  (Retrofit/Dio)  │
└────────────────┘         └──────────────────┘
```

### Folder Structure

```
lib/
├── main.dart
├── app.dart (MaterialApp setup)
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   └── storage_keys.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── localization/
│   │   ├── app_localizations.dart
│   │   └── l10n/ (arb files)
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   └── utils/
│       ├── logger.dart
│       ├── validators.dart
│       └── extensions.dart
│
├── di/
│   └── injection.dart (GetIt setup)
│
├── data/
│   ├── models/ (DTOs matching backend)
│   │   ├── user_model.dart
│   │   ├── speech_model.dart
│   │   ├── tag_model.dart
│   │   ├── game_session_model.dart
│   │   └── game_result_model.dart
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── hive_storage.dart
│   │   │   ├── auth_local_datasource.dart
│   │   │   ├── game_local_datasource.dart
│   │   │   └── cache_datasource.dart
│   │   └── remote/
│   │       ├── api_client.dart
│   │       ├── auth_remote_datasource.dart
│   │       ├── game_remote_datasource.dart
│   │       └── user_remote_datasource.dart
│   └── repositories/
│       ├── auth_repository_impl.dart
│       ├── game_repository_impl.dart
│       └── user_repository_impl.dart
│
├── domain/
│   ├── entities/
│   │   ├── user.dart
│   │   ├── speech.dart
│   │   ├── tag.dart
│   │   ├── game_session.dart
│   │   └── game_result.dart
│   ├── repositories/ (abstract interfaces)
│   │   ├── auth_repository.dart
│   │   ├── game_repository.dart
│   │   └── user_repository.dart
│   └── usecases/
│       ├── auth/
│       ├── game/
│       └── user/
│
└── presentation/
    ├── blocs/
    │   ├── auth/
    │   │   ├── auth_bloc.dart
    │   │   ├── auth_event.dart
    │   │   └── auth_state.dart
    │   ├── game/
    │   │   ├── game_bloc.dart
    │   │   ├── game_event.dart
    │   │   └── game_state.dart
    │   ├── profile/
    │   │   ├── profile_bloc.dart
    │   │   ├── profile_event.dart
    │   │   └── profile_state.dart
    │   └── history/
    │       ├── history_bloc.dart
    │       ├── history_event.dart
    │       └── history_state.dart
    ├── screens/
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   ├── register_screen.dart
    │   │   └── forgot_password_screen.dart
    │   ├── home/
    │   │   ├── home_screen.dart (bottom nav)
    │   │   ├── dashboard_tab.dart
    │   │   ├── games_tab.dart
    │   │   ├── skills_tab.dart
    │   │   └── profile_tab.dart
    │   ├── game/
    │   │   ├── game_config_screen.dart
    │   │   ├── game_play_screen.dart
    │   │   ├── game_end_screen.dart
    │   │   ├── game_history_screen.dart
    │   │   └── game_detail_screen.dart
    │   └── profile/
    │       ├── edit_profile_screen.dart
    │       └── settings_screen.dart
    └── widgets/
        ├── common/
        │   ├── loading_indicator.dart
        │   ├── error_view.dart
        │   └── custom_button.dart
        ├── game/
        │   ├── audio_player_widget.dart
        │   ├── swipe_card_widget.dart
        │   ├── streak_indicator.dart
        │   └── compliment_overlay.dart
        └── profile/
            └── avatar_picker.dart
```

---

## Navigation Map

### Route Structure

```
/
├── /splash (SplashScreen)
│
├── /auth
│   ├── /login (LoginScreen)
│   ├── /register (RegisterScreen)
│   └── /forgot-password (ForgotPasswordScreen)
│
├── /home (HomeScreen with BottomNavigationBar)
│   ├── Tab 0: /dashboard (DashboardTab - placeholder)
│   ├── Tab 1: /games (GamesTab)
│   ├── Tab 2: /skills (SkillsTab - placeholder)
│   └── Tab 3: /profile (ProfileTab)
│
├── /game
│   ├── /game/config (GameConfigScreen)
│   ├── /game/play (GamePlayScreen)
│   ├── /game/end (GameEndScreen)
│   ├── /game/history (GameHistoryScreen)
│   └── /game/detail/:id (GameDetailScreen)
│
└── /profile
    ├── /profile/edit (EditProfileScreen)
    └── /profile/settings (SettingsScreen)
```

### Navigation Flow Diagrams

#### Authentication Flow
```
SplashScreen
     │
     ├─→ [Has Auth Token] → HomeScreen
     │
     └─→ [No Auth Token] → LoginScreen
                             │
                             ├─→ [Login Success] → HomeScreen
                             │
                             ├─→ [Register] → RegisterScreen → [Success] → HomeScreen
                             │
                             └─→ [Social Login] → [OAuth Flow] → HomeScreen
```

#### Game Flow
```
GamesTab
    │
    └─→ "Listen and Repeat" Card
            │
            └─→ GameConfigScreen
                    │ (Select: mode, level, type, tags, count)
                    │
                    └─→ [Start] → GamePlayScreen
                                      │
                                      ├─→ [Playing] ←→ [Paused]
                                      │
                                      └─→ [Complete] → GameEndScreen
                                                            │
                                                            ├─→ [Play Again] → GameConfigScreen
                                                            ├─→ [View History] → GameHistoryScreen
                                                            └─→ [Back] → GamesTab
```

---

## Screen Specifications

### 1. Splash Screen
**Route**: `/splash`

**Purpose**: Initial app loading, check authentication status

**UI Elements**:
- App logo (center)
- Loading spinner
- App version (bottom)

**Logic**:
- Check if auth token exists in Hive
- Validate token with backend (if online)
- Navigate to HomeScreen or LoginScreen

---

### 2. Login Screen
**Route**: `/auth/login`

**UI Elements**:
- Email text field
- Password text field (with show/hide toggle)
- "Login" button
- "Forgot Password?" link
- Social login buttons (Google, Apple, Facebook)
- "Don't have an account? Register" link

**Validation**:
- Email format validation
- Password minimum length (8 chars)

**States**:
- Idle
- Loading (during login)
- Error (show error message)
- Success (navigate to home)

**BLoC**: `AuthBloc`

---

### 3. Register Screen
**Route**: `/auth/register`

**UI Elements**:
- Name text field
- Email text field
- Password text field
- Confirm password field
- "Register" button
- "Already have account? Login" link

**Validation**:
- Name not empty
- Email format
- Password requirements (min 8 chars, 1 uppercase, 1 number)
- Passwords match

**BLoC**: `AuthBloc`

---

### 4. Home Screen (Bottom Navigation)
**Route**: `/home`

**Structure**:
```dart
Scaffold(
  body: IndexedStack(
    index: _currentIndex,
    children: [
      DashboardTab(),
      GamesTab(),
      SkillsTab(),
      ProfileTab(),
    ],
  ),
  bottomNavigationBar: BottomNavigationBar(...),
)
```

**Bottom Navigation Items**:
1. Dashboard (home icon)
2. Games (game controller icon)
3. Skills (brain/lightbulb icon)
4. Profile (person icon)

**State Persistence**: Remember selected tab across app restarts (save to Hive)

---

### 5. Games Tab
**Route**: `/home` (tab index 1)

**UI Elements**:
- Title: "Games" (Vietnamese: "Trò chơi")
- Game card list (currently only one):
  - "Listen and Repeat" card
    - Icon/image
    - Title
    - Description
    - "Play" button

**Phase 1**: Only one game card. Phase 2+ will have more games.

**Action**: Tap card → Navigate to GameConfigScreen

---

### 6. Game Config Screen
**Route**: `/game/config`

**UI Elements**:
- **Mode Selector** (Radio buttons or segment control)
  - Listen Only
  - Listen and Repeat (with mic icon)

- **Level Selector** (Chip group or dropdown)
  - A1, A2, B1, B2, C1 (single select)

- **Sentence Type** (Toggle or radio)
  - Question
  - Answer

- **Tags** (Multi-select chips)
  - Fetched from backend
  - Display in scrollable wrap
  - Selected tags highlighted
  - Minimum 1 tag required

- **Number of Questions** (Stepper or dropdown)
  - Options: 10, 15, 20
  - Default: 10

- **Start Button** (Primary CTA)
  - Disabled if no tags selected

**State Management**:
- Cache last selected config in Hive
- Restore on next visit

**BLoC**: `GameBloc`
- Event: `LoadGameConfig`
- Event: `UpdateGameConfig`
- Event: `StartGame`

**Data Flow**:
1. On screen load: Load tags from backend
2. Restore cached config from Hive
3. User updates selections
4. Tap Start → Validate → Fetch speeches from API → Navigate to GamePlayScreen

---

### 7. Game Play Screen
**Route**: `/game/play`

**Layout**: Full screen (no app bar in game mode)

**UI Elements**:

**Top Bar**:
- Pause button (top-left)
- Progress indicator: "3 / 10" (top-center)
- Exit button (top-right, with confirmation)

**Main Area** (varies by state):

**Listen-Only Mode States**:

1. **Playing Audio (1st play)**
   - Large audio waveform animation
   - "Listening... (1/2)"
   - Text hidden

2. **Gap (2s between plays)**
   - Countdown: "2..."
   - Text hidden

3. **Playing Audio (2nd play)**
   - Large audio waveform animation
   - "Listening... (2/2)"
   - Text hidden

4. **Show Text (2s)**
   - Display sentence text (large, centered)
   - Previous sentence card shown below (swipeable)
   - Countdown: "2..."

5. **Auto-advance to next**

**Listen-and-Repeat Mode States**:

1. **Playing Audio (once)**
   - Audio waveform animation
   - "Listen carefully..."

2. **Recording Mic**
   - Mic icon (pulsing)
   - "Speak now..."
   - Recording timer: "0:05"
   - Waveform of user's speech

3. **Processing**
   - Loading spinner
   - "Analyzing your pronunciation..."

4. **Show Result**
   - Recognized text
   - Pronunciation score: "85%"
   - Comparison with reference text (highlight differences)
   - Previous sentence card (swipeable)

**Swipe Card** (Previous Sentence):
- Appears at bottom after first sentence
- Card shows previous sentence text
- Swipe left: "I got it wrong" → Red X animation + motivational message
- Swipe right: "I got it right" → Green checkmark + compliment (based on streak)

**Streak Indicator**:
- Top-right corner (or near progress)
- Shows current streak: "🔥 x3"

**Pause Overlay** (when paused):
- Semi-transparent background
- "Paused" text
- Resume button
- Exit button

**Compliment/Motivation Overlay**:
- Animate in after swipe
- Display for 1.5s
- Auto-dismiss

**State Machine** (simplified):
```
Initial → LoadingSpeeches → FirstSentence → PlayingAudio → 
  [Listen-Only: Gap → PlayingAudio2 → ShowText → NextSentence]
  [Listen-and-Repeat: Recording → Processing → ShowResult → NextSentence]
→ ... → LastSentence → GameEnd
```

**BLoC**: `GameBloc`
- State: `GamePlayingState`
  - currentSentenceIndex
  - sentences (list)
  - mode
  - isPlaying / isPaused / isRecording
  - currentStreak
  - results (list of user responses)
- Events:
  - `PlayAudio`
  - `AudioPlaybackComplete`
  - `StartRecording`
  - `StopRecording`
  - `SwipeLeft` / `SwipeRight`
  - `PauseGame` / `ResumeGame`
  - `ExitGame`

**Audio Player Management**:
- Use `just_audio` package
- Pre-cache next audio file
- Handle pause/resume at exact timestamp

**Microphone Management** (Listen-and-Repeat):
- Request permission on first use
- Use `record` package
- Send recorded audio to backend for speech-to-text

---

### 8. Game End Screen
**Route**: `/game/end`

**UI Elements**:
- Celebration animation (Lottie)
- Summary statistics:
  - Total sentences: 10
  - Correct: 8
  - Max streak: 5
  - [Listen-and-Repeat] Avg pronunciation score: 87%
  - Time: 5:23
- Compliment/motivation message (large text)
- Action buttons:
  - "Play Again" (primary)
  - "View History"
  - "Back to Games"

**BLoC**: `GameBloc`
- State: `GameCompletedState`
- Background task: Send results to backend

**Data Flow**:
1. Display summary immediately (from local state)
2. Background: POST game session to backend
3. If offline: Queue for later sync (save to Hive)

---

### 9. Game History Screen
**Route**: `/game/history`

**UI Elements**:
- App bar with title: "Game History"
- Filter/sort buttons (top):
  - Filter by mode
  - Filter by level
  - Sort by date (newest/oldest)
- List of game session cards:
  - Date/time
  - Mode icon + level badge
  - Score: "8/10 correct"
  - [Listen-and-Repeat] Avg pronunciation: "87%"
  - Max streak indicator
  - Tap to view details

**States**:
- Loading
- Empty (no history yet)
- Loaded (list)
- Error

**BLoC**: `HistoryBloc`
- Event: `LoadGameHistory`
- State: `HistoryLoadedState` with list of sessions

**Pagination**: Load 20 sessions at a time, infinite scroll

---

### 10. Game Detail Screen
**Route**: `/game/detail/:id`

**UI Elements**:
- App bar with back button
- Summary section:
  - Date/time
  - Mode, level, type
  - Tags
  - Total correct / total
  - Max streak
  - Duration
- Sentence-by-sentence results:
  - List of cards, each showing:
    - Sentence number
    - English text
    - Audio play button
    - User response: ✓ or ✗
    - [Listen-and-Repeat] Pronunciation score
    - [Listen-and-Repeat] Recognized text

**BLoC**: `HistoryBloc`
- Event: `LoadGameDetail(sessionId)`
- State: `GameDetailLoadedState`

---

### 11. Profile Tab
**Route**: `/home` (tab index 3)

**UI Elements**:
- Avatar (top, center, tappable)
- Name
- Email
- Sections:
  - **Account**
    - Edit Profile → navigate to EditProfileScreen
    - Settings → navigate to SettingsScreen
  - **Game Stats** (optional Phase 1, or Phase 2)
    - Total games played
    - Total time
    - Average score
  - **Actions**
    - Logout (with confirmation)
    - Delete Account (with double confirmation)

**BLoC**: `ProfileBloc`

---

### 12. Edit Profile Screen
**Route**: `/profile/edit`

**UI Elements**:
- Avatar picker (tap to change)
- Name text field
- Email (read-only, show info icon: "Email cannot be changed")
- Save button

**Validation**:
- Name not empty

**BLoC**: `ProfileBloc`
- Event: `UpdateProfile`
- State: `ProfileUpdateSuccess` / `ProfileUpdateError`

---

### 13. Settings Screen
**Route**: `/profile/settings`

**UI Elements**:
- Theme selection:
  - Light
  - Dark
  - System default (toggle)
- Language (Phase 1: Vietnamese only, show "More coming soon")
- Notifications (Phase 2)
- About:
  - Version
  - Terms of Service
  - Privacy Policy

---

## State Management (BLoC)

### BLoC Overview

We use **flutter_bloc** for predictable state management. Each feature has its own BLoC.

---

### 1. AuthBloc

**Purpose**: Handle authentication state across the app

**Events**:
```dart
abstract class AuthEvent extends Equatable {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
}

class AuthSocialLoginRequested extends AuthEvent {
  final SocialProvider provider; // google, apple, facebook
}

class AuthLogoutRequested extends AuthEvent {}

class AuthDeleteAccountRequested extends AuthEvent {}
```

**States**:
```dart
abstract class AuthState extends Equatable {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  final String token;
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
}
```

**State Transitions**:
```
AuthInitial → [AuthCheckRequested] → Authenticated | Unauthenticated
Unauthenticated → [AuthLoginRequested] → AuthLoading → Authenticated | AuthError
Authenticated → [AuthLogoutRequested] → Unauthenticated
```

**Persistence**:
- Store auth token in Hive: `authBox.put('token', token)`
- Store user data in Hive: `authBox.put('user', userModel.toJson())`

---

### 2. GameBloc

**Purpose**: Manage game configuration, gameplay, and results

**Events**:
```dart
abstract class GameEvent extends Equatable {}

class LoadGameConfig extends GameEvent {}

class UpdateGameMode extends GameEvent {
  final GameMode mode; // listenOnly, listenAndRepeat
}

class UpdateGameLevel extends GameEvent {
  final String level; // A1, A2, B1, B2, C1
}

class UpdateSentenceType extends GameEvent {
  final String type; // question, answer
}

class ToggleTag extends GameEvent {
  final String tagId;
}

class UpdateQuestionCount extends GameEvent {
  final int count; // 10, 15, 20
}

class StartGameRequested extends GameEvent {}

class AudioPlaybackStarted extends GameEvent {}

class AudioPlaybackCompleted extends GameEvent {}

class StartRecordingRequested extends GameEvent {}

class StopRecordingRequested extends GameEvent {}

class SwipeLeftPerformed extends GameEvent {} // wrong

class SwipeRightPerformed extends GameEvent {} // correct

class PauseGameRequested extends GameEvent {}

class ResumeGameRequested extends GameEvent {}

class ExitGameRequested extends GameEvent {}

class NextSentenceRequested extends GameEvent {}

class GameCompleted extends GameEvent {}
```

**States**:
```dart
abstract class GameState extends Equatable {}

class GameInitial extends GameState {}

class GameConfigLoading extends GameState {}

class GameConfigLoaded extends GameState {
  final GameConfig config;
  final List<Tag> availableTags;
}

class GameConfigError extends GameState {
  final String message;
}

class GameLoading extends GameState {} // Fetching speeches

class GameReady extends GameState {
  final List<Speech> speeches;
  final GameConfig config;
}

class GamePlaying extends GameState {
  final int currentIndex;
  final Speech currentSentence;
  final GamePlayState playState; // enum: playingAudio, gap, showingText, recording, processing, showingResult
  final int currentStreak;
  final List<GameResult> results;
  final GameConfig config;
  final bool isPaused;
}

class GamePaused extends GameState {
  final GamePlaying previousState;
  final PauseContext context; // audio timestamp, mic state, timer state
}

class GameCompleted extends GameState {
  final GameSession session;
  final String complimentMessage;
}

class GameError extends GameState {
  final String message;
}
```

**State Machine** (Playing States):
```dart
enum GamePlayState {
  playingAudio1,      // First audio play (listen-only)
  gap,                // 2s gap (listen-only)
  playingAudio2,      // Second audio play (listen-only)
  showingText,        // Showing text after audio (listen-only)
  playingAudioOnce,   // Single audio play (listen-and-repeat)
  recording,          // Mic open, recording (listen-and-repeat)
  processing,         // Sending to speech-to-text (listen-and-repeat)
  showingResult,      // Display score and recognized text
  waitingForSwipe,    // Waiting for user to swipe previous sentence
  transitioning,      // Moving to next sentence
}
```

**Complex Logic**:
- **Auto-advance**: Use timers with careful state management
- **Pause/Resume**: Store current playback position, mic state, timer countdown
- **Streak calculation**: Increment on swipe right, reset to 0 on swipe left (max 5)
- **Compliment selection**: Based on streak level (1-5), pick random from 5 hardcoded messages per level

---

### 3. HistoryBloc

**Purpose**: Load and display game history

**Events**:
```dart
abstract class HistoryEvent extends Equatable {}

class LoadGameHistory extends HistoryEvent {
  final int page;
  final HistoryFilter? filter;
}

class LoadGameDetail extends HistoryEvent {
  final String sessionId;
}

class RefreshHistory extends HistoryEvent {}
```

**States**:
```dart
abstract class HistoryState extends Equatable {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<GameSession> sessions;
  final bool hasMore;
  final int currentPage;
}

class HistoryError extends HistoryState {
  final String message;
}

class GameDetailLoading extends HistoryState {}

class GameDetailLoaded extends HistoryState {
  final GameSession session;
  final List<GameResult> results;
}

class GameDetailError extends HistoryState {
  final String message;
}
```

---

### 4. ProfileBloc

**Purpose**: Manage user profile data

**Events**:
```dart
abstract class ProfileEvent extends Equatable {}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String name;
  final String? avatarUrl;
}

class UpdateAvatar extends ProfileEvent {
  final File imageFile;
}

class ChangeTheme extends ProfileEvent {
  final ThemeMode mode;
}
```

**States**:
```dart
abstract class ProfileState extends Equatable {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  final ThemeMode themeMode;
}

class ProfileUpdateSuccess extends ProfileState {
  final User user;
}

class ProfileError extends ProfileState {
  final String message;
}
```

---

## Data Models

### DTOs (Data Transfer Objects)

These models match the backend API responses and are used for JSON serialization.

#### UserModel
```dart
@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String authProvider;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.authProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
```

#### TagModel
```dart
@JsonSerializable()
class TagModel {
  final String id;
  final String name;
  final String category;

  TagModel({
    required this.id,
    required this.name,
    required this.category,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);
  Map<String, dynamic> toJson() => _$TagModelToJson(this);
}
```

#### SpeechModel
```dart
@JsonSerializable()
class SpeechModel {
  final String id;
  final String audioUrl;
  final String text;
  final String level; // A1, A2, B1, B2, C1
  final String type; // question, answer
  final List<TagModel> tags;

  SpeechModel({
    required this.id,
    required this.audioUrl,
    required this.text,
    required this.level,
    required this.type,
    required this.tags,
  });

  factory SpeechModel.fromJson(Map<String, dynamic> json) =>
      _$SpeechModelFromJson(json);
  Map<String, dynamic> toJson() => _$SpeechModelToJson(this);
}
```

#### GameSessionModel
```dart
@JsonSerializable()
class GameSessionModel {
  final String id;
  final String userId;
  final String mode; // listen_only, listen_and_repeat
  final String level;
  final String sentenceType;
  final List<String> tags;
  final int totalSentences;
  final int correctCount;
  final int maxStreak;
  final double? avgPronunciationScore;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime completedAt;

  GameSessionModel({
    required this.id,
    required this.userId,
    required this.mode,
    required this.level,
    required this.sentenceType,
    required this.tags,
    required this.totalSentences,
    required this.correctCount,
    required this.maxStreak,
    this.avgPronunciationScore,
    required this.durationSeconds,
    required this.startedAt,
    required this.completedAt,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) =>
      _$GameSessionModelFromJson(json);
  Map<String, dynamic> toJson() => _$GameSessionModelToJson(this);
}
```

#### GameResultModel
```dart
@JsonSerializable()
class GameResultModel {
  final String id;
  final String sessionId;
  final String speechId;
  final int sequenceNumber;
  final String userResponse; // correct, incorrect, skipped
  final double? pronunciationScore; // 0-100
  final String? recognizedText;
  final int responseTimeMs;

  GameResultModel({
    required this.id,
    required this.sessionId,
    required this.speechId,
    required this.sequenceNumber,
    required this.userResponse,
    this.pronunciationScore,
    this.recognizedText,
    required this.responseTimeMs,
  });

  factory GameResultModel.fromJson(Map<String, dynamic> json) =>
      _$GameResultModelFromJson(json);
  Map<String, dynamic> toJson() => _$GameResultModelToJson(this);
}
```

### Domain Entities

Similar to models but used in the business logic layer. Convert from DTO to Entity in repositories.

Example:
```dart
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl];
}
```

---

## Local Storage (Hive)

### Hive Boxes

We use multiple Hive boxes for different data types:

```dart
// Box names
const String AUTH_BOX = 'auth_box';
const String CACHE_BOX = 'cache_box';
const String GAME_BOX = 'game_box';
const String SETTINGS_BOX = 'settings_box';
```

### Box Contents

#### 1. AUTH_BOX
**Purpose**: Store authentication data

```dart
// Keys
const String TOKEN_KEY = 'auth_token';
const String REFRESH_TOKEN_KEY = 'refresh_token';
const String USER_KEY = 'user';
const String TOKEN_EXPIRY_KEY = 'token_expiry';

// Data types
- token: String
- refresh_token: String
- user: Map<String, dynamic> (UserModel JSON)
- token_expiry: DateTime
```

#### 2. CACHE_BOX
**Purpose**: Cache API responses for offline access

```dart
// Keys
const String TAGS_KEY = 'tags';
const String LAST_GAME_CONFIG_KEY = 'last_game_config';

// Data types
- tags: List<Map<String, dynamic>> (List of TagModel JSON)
- last_game_config: Map<String, dynamic> (GameConfig JSON)
```

#### 3. GAME_BOX
**Purpose**: Store pending game results (for offline sync)

```dart
// Keys: Use UUID for each pending session
// Example: 'pending_session_<uuid>'

// Data types
- pending_session_<uuid>: Map<String, dynamic> (GameSessionModel JSON)
```

#### 4. SETTINGS_BOX
**Purpose**: Store app settings

```dart
// Keys
const String THEME_MODE_KEY = 'theme_mode';
const String LANGUAGE_KEY = 'language';
const String SELECTED_TAB_KEY = 'selected_tab';

// Data types
- theme_mode: String ('light', 'dark', 'system')
- language: String ('vi', 'en')
- selected_tab: int (0-3)
```

### Hive Type Adapters

For complex objects, create type adapters:

```dart
@HiveType(typeId: 0)
class GameConfigCache extends HiveObject {
  @HiveField(0)
  String mode;

  @HiveField(1)
  String level;

  @HiveField(2)
  String type;

  @HiveField(3)
  List<String> selectedTagIds;

  @HiveField(4)
  int questionCount;

  GameConfigCache({
    required this.mode,
    required this.level,
    required this.type,
    required this.selectedTagIds,
    required this.questionCount,
  });
}
```

### Initialization

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(GameConfigCacheAdapter());
  
  // Open boxes
  await Hive.openBox(AUTH_BOX);
  await Hive.openBox(CACHE_BOX);
  await Hive.openBox(GAME_BOX);
  await Hive.openBox(SETTINGS_BOX);
  
  // Setup DI
  setupDependencyInjection();
  
  runApp(MyApp());
}
```

---

## API Integration

### Retrofit API Client

```dart
@RestApi(baseUrl: 'https://api.englishapp.com/api/v1')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // Auth
  @POST('/auth/login')
  Future<AuthResponse> login(@Body() LoginRequest request);

  @POST('/auth/register')
  Future<AuthResponse> register(@Body() RegisterRequest request);

  @POST('/auth/social')
  Future<AuthResponse> socialLogin(@Body() SocialLoginRequest request);

  // User
  @GET('/users/me')
  Future<UserModel> getCurrentUser();

  @PUT('/users/me')
  Future<UserModel> updateUser(@Body() UpdateUserRequest request);

  @DELETE('/users/me')
  Future<void> deleteUser();

  // Tags
  @GET('/tags')
  Future<TagsResponse> getTags();

  // Game
  @POST('/game/speeches/random')
  Future<SpeechesResponse> getRandomSpeeches(@Body() RandomSpeechRequest request);

  @POST('/game/sessions')
  Future<SessionResponse> createGameSession(@Body() GameSessionModel session);

  @GET('/game/sessions')
  Future<SessionsResponse> getGameHistory(
    @Query('page') int page,
    @Query('limit') int limit,
    @Query('mode') String? mode,
    @Query('level') String? level,
  );

  @GET('/game/sessions/{id}')
  Future<SessionDetailResponse> getGameDetail(@Path('id') String sessionId);
}
```

### Dio Configuration

```dart
class DioFactory {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.BASE_URL,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(AuthInterceptor()); // Add auth token
    dio.interceptors.add(LogInterceptor(responseBody: true)); // Logging
    dio.interceptors.add(RetryInterceptor()); // Retry on network errors

    return dio;
  }
}
```

### Auth Interceptor

```dart
class AuthInterceptor extends Interceptor {
  final Box authBox = Hive.box(AUTH_BOX);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = authBox.get(TOKEN_KEY);
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired, try refresh
      _refreshToken().then((_) {
        // Retry request
        handler.resolve(err.response!);
      }).catchError((_) {
        // Refresh failed, logout
        _handleLogout();
        handler.next(err);
      });
    } else {
      handler.next(err);
    }
  }

  Future<void> _refreshToken() async {
    // Implement token refresh logic
  }

  void _handleLogout() {
    authBox.clear();
    // Navigate to login screen
  }
}
```

---

## Error Handling

### Error Types

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection');
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}
```

### Error Handling in BLoC

```dart
// In repository
Future<Either<Failure, List<Speech>>> getRandomSpeeches(...) async {
  try {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }

    final response = await apiClient.getRandomSpeeches(...);
    return Right(response.speeches);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      return Left(AuthenticationFailure('Session expired'));
    }
    return Left(ServerFailure(e.message ?? 'Server error'));
  } catch (e) {
    return Left(ServerFailure('Unexpected error: $e'));
  }
}

// In BLoC
on<StartGameRequested>((event, emit) async {
  emit(GameLoading());

  final result = await gameRepository.getRandomSpeeches(...);

  result.fold(
    (failure) => emit(GameError(failure.message)),
    (speeches) => emit(GameReady(speeches: speeches, ...)),
  );
});
```

### Error UI

```dart
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## Offline Behavior

### Strategy

1. **Authentication**: Require online for initial login, cache token for subsequent app launches
2. **Game Config**: Cache tags and last config, allow game start offline if cached data exists
3. **Game Play**: Require online (audio streaming, speech-to-text)
4. **Game Results**: Queue for upload if offline, sync when connection restored
5. **Game History**: Cache recent history, show cached data if offline

### Offline Indicators

```dart
class ConnectivityService {
  final connectivity = Connectivity();
  final _connectionStatus = StreamController<bool>.broadcast();

  Stream<bool> get connectionStream => _connectionStatus.stream;

  void initialize() {
    connectivity.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      _connectionStatus.add(isConnected);
    });
  }

  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

**UI Indicator**:
```dart
// Show banner at top of screen when offline
StreamBuilder<bool>(
  stream: connectivityService.connectionStream,
  builder: (context, snapshot) {
    if (snapshot.data == false) {
      return Container(
        color: Colors.red,
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white),
            SizedBox(width: 8),
            Text('Offline', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  },
)
```

### Sync Queue

```dart
class SyncService {
  final GameRepository gameRepository;
  final Box gameBox = Hive.box(GAME_BOX);

  Future<void> syncPendingSessions() async {
    final pendingKeys = gameBox.keys
        .where((key) => key.toString().startsWith('pending_session_'))
        .toList();

    for (final key in pendingKeys) {
      final sessionJson = gameBox.get(key) as Map<String, dynamic>;
      final session = GameSessionModel.fromJson(sessionJson);

      try {
        await gameRepository.createGameSession(session);
        await gameBox.delete(key); // Remove from queue on success
        Logger.info('Synced session: $key');
      } catch (e) {
        Logger.error('Failed to sync session: $key, error: $e');
        // Keep in queue, will retry later
      }
    }
  }

  void startAutoSync() {
    // Sync every 5 minutes when online
    Timer.periodic(Duration(minutes: 5), (_) async {
      if (await connectivityService.isConnected) {
        await syncPendingSessions();
      }
    });
  }
}
```

---

## Themes & Localization

### Theme

```dart
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.h1,
      displayMedium: AppTextStyles.h2,
      bodyLarge: AppTextStyles.body,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.h1.copyWith(color: Colors.white),
      displayMedium: AppTextStyles.h2.copyWith(color: Colors.white),
      bodyLarge: AppTextStyles.body.copyWith(color: Colors.white70),
    ),
  );
}
```

### Localization (i18n)

**Setup**:
```yaml
# pubspec.yaml
flutter:
  generate: true

# l10n.yaml
arb-dir: lib/core/localization/l10n
template-arb-file: app_vi.arb
output-localization-file: app_localizations.dart
```

**ARB Files**:

`lib/core/localization/l10n/app_vi.arb` (Vietnamese):
```json
{
  "@@locale": "vi",
  "appName": "Luyện Tiếng Anh",
  "login": "Đăng nhập",
  "register": "Đăng ký",
  "email": "Email",
  "password": "Mật khẩu",
  "forgotPassword": "Quên mật khẩu?",
  "dashboard": "Trang chủ",
  "games": "Trò chơi",
  "skills": "Kỹ năng",
  "profile": "Hồ sơ",
  "listenAndRepeat": "Nghe và Nhắc lại",
  "start": "Bắt đầu",
  "pause": "Tạm dừng",
  "resume": "Tiếp tục",
  "correctAnswer": "Đúng rồi! {streak, plural, =1{Tuyệt vời!} =2{Xuất sắc!} =3{Tuyệt vời quá!} =4{Bạn quá giỏi!} other{Hoàn hảo!}}",
  "@correctAnswer": {
    "placeholders": {
      "streak": {
        "type": "int"
      }
    }
  },
  "incorrectAnswer": "Đừng lo! Cố gắng lên nhé!",
  "gameComplete": "Hoàn thành trò chơi!",
  "playAgain": "Chơi lại",
  "viewHistory": "Xem lịch sử",
  "logout": "Đăng xuất",
  "deleteAccount": "Xóa tài khoản"
}
```

**Usage**:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In widget
Text(AppLocalizations.of(context)!.login)

// With parameters
Text(AppLocalizations.of(context)!.correctAnswer(currentStreak))
```

---

## Performance Considerations

### 1. Audio Optimization
- Pre-cache next audio file while current is playing
- Use `just_audio` with `CachingAudioSource`
- Compress audio files on backend (64kbps MP3)

```dart
class AudioManager {
  final AudioPlayer player = AudioPlayer();
  final Map<String, AudioSource> _cache = {};

  Future<void> preloadAudio(String url) async {
    if (!_cache.containsKey(url)) {
      _cache[url] = AudioSource.uri(Uri.parse(url));
      await player.setAudioSource(_cache[url]!);
    }
  }

  Future<void> playAudio(String url) async {
    if (_cache.containsKey(url)) {
      await player.setAudioSource(_cache[url]!);
    } else {
      await player.setUrl(url);
    }
    await player.play();
  }
}
```

### 2. Image Caching
```dart
CachedNetworkImage(
  imageUrl: user.avatarUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
  cacheManager: DefaultCacheManager(),
)
```

### 3. List Optimization
- Use `ListView.builder` for game history (lazy loading)
- Implement pagination for long lists
- Use `AutomaticKeepAliveClientMixin` for tab preservation

### 4. State Management Optimization
- Use `Equatable` for state comparison (avoid unnecessary rebuilds)
- Implement `buildWhen` in `BlocBuilder` to control rebuilds
- Use `BlocSelector` for granular UI updates

```dart
BlocSelector<GameBloc, GameState, int>(
  selector: (state) {
    if (state is GamePlaying) return state.currentStreak;
    return 0;
  },
  builder: (context, streak) {
    return Text('Streak: $streak');
  },
)
```

---

## Testing Strategy

### Unit Tests
- Test BLoCs (events → states)
- Test repositories (API calls, error handling)
- Test utilities and helpers

### Widget Tests
- Test individual widgets (buttons, cards, etc.)
- Test screen layouts
- Test user interactions (taps, swipes)

### Integration Tests
- Test complete user flows (login → game → history)
- Test offline behavior
- Test sync queue

**Example BLoC Test**:
```dart
blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, Authenticated] when login succeeds',
  build: () {
    when(() => authRepository.login('test@example.com', 'password'))
        .thenAnswer((_) async => Right(mockUser));
    return AuthBloc(authRepository);
  },
  act: (bloc) => bloc.add(AuthLoginRequested(
    email: 'test@example.com',
    password: 'password',
  )),
  expect: () => [
    AuthLoading(),
    Authenticated(user: mockUser, token: 'mock_token'),
  ],
);
```

---

## Deployment Checklist

### Pre-Release
- [ ] All BLoCs tested (>80% coverage)
- [ ] All screens tested (widget tests)
- [ ] Integration tests passing
- [ ] No console errors or warnings
- [ ] Performance profiling done (no jank)
- [ ] Memory leaks checked
- [ ] All localizations complete
- [ ] Icons and images optimized
- [ ] Offline mode tested thoroughly
- [ ] Firebase Analytics configured
- [ ] Crash reporting set up (Firebase Crashlytics)

### App Store Metadata
- [ ] App name: "Luyện Tiếng Anh" (or chosen name)
- [ ] Screenshots (phone + tablet, light + dark)
- [ ] App description (Vietnamese + English)
- [ ] Privacy policy URL
- [ ] Terms of service URL

### Android
- [ ] Signing key generated
- [ ] ProGuard rules configured
- [ ] Permissions documented in manifest
- [ ] Min SDK: 26 (Android 8.0)
- [ ] Target SDK: Latest stable

### iOS
- [ ] Apple Developer account provisioning
- [ ] App Store Connect setup
- [ ] Privacy manifest configured
- [ ] Deployment target: iOS 14.0
- [ ] Code signing certificates

---

**End of Mobile Specification**

*This document should be kept in sync with backend API changes and updated as features evolve.*
