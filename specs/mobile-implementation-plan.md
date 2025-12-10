# Mobile Implementation Plan

**Project**: English Learning App - Flutter Mobile Application  
**Date**: December 10, 2025  
**Technology Stack**: Flutter 3.24.5, Dart 3.5.4, BLoC, Hive, Firebase Auth  
**Based on**: [spec/mobile.md](../spec/mobile.md)

---

## Project Structure

```
apps/mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   ├── localization/
│   │   ├── errors/
│   │   └── utils/
│   │
│   ├── di/
│   │   └── injection.dart
│   │
│   ├── data/
│   │   ├── models/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   └── remote/
│   │   └── repositories/
│   │
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   │
│   └── presentation/
│       ├── blocs/
│       ├── screens/
│       └── widgets/
│
├── test/
├── integration_test/
├── android/
├── ios/
├── pubspec.yaml
├── l10n.yaml
└── analysis_options.yaml
```

---

## Milestone Overview

1. **Milestone 1: Project Foundation** (3-4 days)
2. **Milestone 2: Authentication Flow** (4-5 days)
3. **Milestone 3: Navigation & Backend Integration** (3-4 days)
4. **Milestone 4: Game Configuration Screen** (2-3 days)
5. **Milestone 5: Listen-Only Game Mode** (5-6 days)
6. **Milestone 6: Listen-and-Repeat Game Mode** (6-7 days)
7. **Milestone 7: Game History & Detail** (3-4 days)
8. **Milestone 8: Profile & Settings** (3-4 days)
9. **Milestone 9: Theming & Localization** (2-3 days)
10. **Milestone 10: Testing & Polish** (4-5 days)

**Total Estimated Duration**: 35-45 days

---

## Milestone 1: Project Foundation

**Goal**: Set up Flutter project with clean architecture structure, dependencies, and core utilities.

### Task 1.1: Initialize Flutter Project

**Description**: Create new Flutter project and configure basic settings.

**Acceptance Criteria**:
- Flutter project created in `apps/mobile/` directory
- Android minSdkVersion set to 26 (Android 8.0)
- iOS deployment target set to 14.0
- App name configured: "English Learning"
- Package name: `com.englishapp.mobile`

**Commands**:
```bash
cd apps/
flutter create --org com.englishapp --project-name english_learning_mobile mobile
cd mobile
flutter pub get
```

**Files to Modify**:
- `android/app/build.gradle` (minSdkVersion)
- `ios/Podfile` (platform version)
- `pubspec.yaml` (app name, description)

**Dependencies**: None

---

### Task 1.2: Add Core Dependencies

**Description**: Add all required packages to `pubspec.yaml`.

**Acceptance Criteria**:
- All packages from spec/mobile.md added
- Dependencies organized by category (comments)
- Version numbers match specification
- `flutter pub get` runs without errors

**Files to Create/Modify**:
- `pubspec.yaml`

**Dependencies**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7
  
  # Dependency Injection
  get_it: ^8.0.2
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Networking
  dio: ^5.7.0
  retrofit: ^4.4.1
  json_annotation: ^4.9.0
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  firebase_analytics: ^11.3.3
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^6.1.3
  
  # Media
  just_audio: ^0.9.41
  record: ^5.1.2
  permission_handler: ^11.3.1
  
  # UI/UX
  flutter_svg: ^2.0.14
  lottie: ^3.1.3
  flutter_card_swiper: ^7.0.1
  flutter_spinkit: ^5.2.1
  cached_network_image: ^3.4.1
  connectivity_plus: ^6.1.0
  
  # Utilities
  uuid: ^4.5.1
  logger: ^2.4.0
  dartz: ^0.10.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  retrofit_generator: ^9.1.4
  json_serializable: ^6.8.0
  
  # Testing
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  
  # Linting
  flutter_lints: ^5.0.0
```

**Commands**:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Task 1.3: Create Folder Structure

**Description**: Set up clean architecture folder structure with placeholder files.

**Acceptance Criteria**:
- All directories created following spec
- Each directory has `.gitkeep` or empty Dart file
- Project structure matches spec/mobile.md
- No build errors

**Files to Create**:
```
lib/
├── main.dart
├── app.dart
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
│   │   └── l10n/
│   │       └── app_vi.arb
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   └── utils/
│       ├── logger.dart
│       ├── validators.dart
│       └── extensions.dart
├── di/
│   └── injection.dart
├── data/
│   ├── models/
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│       ├── auth/
│       ├── game/
│       └── user/
└── presentation/
    ├── blocs/
    │   ├── auth/
    │   ├── game/
    │   ├── history/
    │   └── profile/
    ├── screens/
    │   ├── auth/
    │   ├── home/
    │   ├── game/
    │   └── profile/
    └── widgets/
        └── common/
```

**Commands**:
```bash
mkdir -p lib/{core/{constants,theme,localization/l10n,errors,utils},di,data/{models,datasources/{local,remote},repositories},domain/{entities,repositories,usecases/{auth,game,user}},presentation/{blocs/{auth,game,history,profile},screens/{auth,home,game,profile},widgets/common}}
```

---

### Task 1.4: Configure Constants

**Description**: Define app-wide constants for API, storage, and app configuration.

**Acceptance Criteria**:
- API base URL configurable via environment
- Storage keys defined for Hive boxes
- App constants defined (name, version, timeouts)
- All constants are type-safe

**Files to Create**:

**`lib/core/constants/api_constants.dart`**:
```dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.englishapp.com/api/v1',
  );
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String meEndpoint = '/auth/me';
  static const String tagsEndpoint = '/tags';
  static const String randomSpeechesEndpoint = '/game/random-speeches';
  static const String gameSessionEndpoint = '/game/sessions';
  static const String gameHistoryEndpoint = '/game/sessions/history';
  static const String speechToTextEndpoint = '/game/speech-to-text';
}
```

**`lib/core/constants/storage_keys.dart`**:
```dart
class StorageKeys {
  // Box names
  static const String authBox = 'auth_box';
  static const String cacheBox = 'cache_box';
  static const String gameBox = 'game_box';
  static const String settingsBox = 'settings_box';
  
  // Auth box keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  static const String tokenExpiryKey = 'token_expiry';
  
  // Cache box keys
  static const String tagsKey = 'tags';
  static const String lastGameConfigKey = 'last_game_config';
  
  // Settings box keys
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String selectedTabKey = 'selected_tab';
}
```

**`lib/core/constants/app_constants.dart`**:
```dart
class AppConstants {
  static const String appName = 'English Learning';
  static const String appVersion = '1.0.0';
  
  // Game configuration
  static const List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1'];
  static const List<String> sentenceTypes = ['question', 'answer'];
  static const List<int> questionCounts = [10, 15, 20];
  static const int defaultQuestionCount = 10;
  
  // Gameplay
  static const Duration gapBetweenPlays = Duration(seconds: 2);
  static const Duration showTextDuration = Duration(seconds: 2);
  static const Duration complimentDuration = Duration(milliseconds: 1500);
  static const int maxStreak = 5;
  
  // Pagination
  static const int historyPageSize = 20;
  
  // Audio
  static const int audioQuality = 64; // kbps
}
```

**Dependencies**: Task 1.1

---

### Task 1.5: Setup Error Handling

**Description**: Create exception and failure classes for error handling throughout the app.

**Acceptance Criteria**:
- Exception classes for different error types
- Failure classes extend Equatable
- Clear separation between data layer exceptions and domain failures
- String messages for user display

**Files to Create**:

**`lib/core/errors/exceptions.dart`**:
```dart
/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;
  
  const AppException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'AppException: $message (code: $statusCode)';
}

class ServerException extends AppException {
  const ServerException(String message, [int? statusCode]) 
      : super(message, statusCode);
}

class NetworkException extends AppException {
  const NetworkException([String message = 'No internet connection']) 
      : super(message);
}

class CacheException extends AppException {
  const CacheException([String message = 'Cache error']) 
      : super(message);
}

class AuthenticationException extends AppException {
  const AuthenticationException([String message = 'Authentication failed']) 
      : super(message, 401);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, 400);
}

class NotFoundException extends AppException {
  const NotFoundException([String message = 'Resource not found']) 
      : super(message, 404);
}
```

**`lib/core/errors/failures.dart`**:
```dart
import 'package:equatable/equatable.dart';

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

class UnexpectedFailure extends Failure {
  const UnexpectedFailure() : super('An unexpected error occurred');
}
```

**Dependencies**: Task 1.2 (equatable package)

---

### Task 1.6: Setup Utilities

**Description**: Create utility classes for logging, validation, and extensions.

**Acceptance Criteria**:
- Logger configured with appropriate levels
- Validators for email, password, name
- Common Dart extensions for String, DateTime, etc.

**Files to Create**:

**`lib/core/utils/logger.dart`**:
```dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
```

**`lib/core/utils/validators.dart`**:
```dart
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }
  
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }
  
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
```

**`lib/core/utils/extensions.dart`**:
```dart
import 'package:intl/intl.dart';

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
  
  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
  
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }
}

extension DateTimeExtensions on DateTime {
  String toFormattedString() {
    return DateFormat('dd/MM/yyyy HH:mm').format(this);
  }
  
  String toDateString() {
    return DateFormat('dd/MM/yyyy').format(this);
  }
  
  String toTimeString() {
    return DateFormat('HH:mm').format(this);
  }
  
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else {
      return 'Just now';
    }
  }
}

extension DurationExtensions on Duration {
  String toFormattedString() {
    final minutes = inMinutes;
    final seconds = inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

extension ListExtensions<T> on List<T> {
  List<T> separatedBy(T separator) {
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(separator);
      }
    }
    return result;
  }
}
```

**Dependencies**: Task 1.2 (logger, intl packages)

---

### Task 1.7: Initialize Hive Storage

**Description**: Set up Hive initialization and create storage service.

**Acceptance Criteria**:
- Hive initialized in main.dart
- All boxes opened on app start
- Storage service wraps Hive operations
- Type-safe box access

**Files to Create**:

**`lib/data/datasources/local/hive_storage.dart`**:
```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/logger.dart';

class HiveStorage {
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Open all boxes
      await Future.wait([
        Hive.openBox(StorageKeys.authBox),
        Hive.openBox(StorageKeys.cacheBox),
        Hive.openBox(StorageKeys.gameBox),
        Hive.openBox(StorageKeys.settingsBox),
      ]);
      
      AppLogger.info('Hive storage initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Hive', e, stackTrace);
      rethrow;
    }
  }
  
  static Box getBox(String boxName) {
    return Hive.box(boxName);
  }
  
  static Box get authBox => getBox(StorageKeys.authBox);
  static Box get cacheBox => getBox(StorageKeys.cacheBox);
  static Box get gameBox => getBox(StorageKeys.gameBox);
  static Box get settingsBox => getBox(StorageKeys.settingsBox);
  
  static Future<void> clearAll() async {
    await Future.wait([
      authBox.clear(),
      cacheBox.clear(),
      gameBox.clear(),
      settingsBox.clear(),
    ]);
  }
  
  static Future<void> close() async {
    await Hive.close();
  }
}
```

**Update `lib/main.dart`**:
```dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'data/datasources/local/hive_storage.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive storage
    await HiveStorage.init();
    
    // TODO: Initialize Firebase
    // TODO: Setup dependency injection
    
    AppLogger.info('App initialization complete');
  } catch (e, stackTrace) {
    AppLogger.error('App initialization failed', e, stackTrace);
  }
  
  runApp(const MyApp());
}
```

**Create `lib/app.dart`**:
```dart
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Learning',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('English Learning App'),
        ),
      ),
    );
  }
}
```

**Dependencies**: Task 1.2 (hive packages), Task 1.4 (storage keys), Task 1.6 (logger)

---

## Milestone 1 Completion Checklist

- [ ] Task 1.1: Flutter project initialized
- [ ] Task 1.2: All dependencies added to pubspec.yaml
- [ ] Task 1.3: Clean architecture folder structure created
- [ ] Task 1.4: Constants configured (API, storage, app)
- [ ] Task 1.5: Error handling setup (exceptions, failures)
- [ ] Task 1.6: Utilities created (logger, validators, extensions)
- [ ] Task 1.7: Hive storage initialized

**Validation**:
```bash
flutter analyze
flutter test
flutter run
```

---

## Milestone 2: Authentication Flow

**Goal**: Implement complete authentication system with email/password and social login (Google, Apple, Facebook).

### Task 2.1: Create Domain Layer for Auth

**Description**: Define authentication entities, repository interfaces, and use cases.

**Acceptance Criteria**:
- User entity created with Equatable
- AuthRepository interface defined
- Use cases for login, register, logout, social login
- Clean separation between domain and data layers

**Files to Create**:

**`lib/domain/entities/user.dart`**:
```dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, createdAt, updatedAt];
  
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

**`lib/domain/repositories/auth_repository.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

enum SocialProvider { google, apple, facebook }

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> register(String name, String email, String password);
  Future<Either<Failure, User>> socialLogin(SocialProvider provider);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> deleteAccount();
  Future<bool> isAuthenticated();
}
```

**`lib/domain/usecases/auth/login_usecase.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, User>> call(String email, String password) {
    return repository.login(email, password);
  }
}
```

**`lib/domain/usecases/auth/register_usecase.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call(String name, String email, String password) {
    return repository.register(name, email, password);
  }
}
```

**`lib/domain/usecases/auth/social_login_usecase.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class SocialLoginUseCase {
  final AuthRepository repository;

  SocialLoginUseCase(this.repository);

  Future<Either<Failure, User>> call(SocialProvider provider) {
    return repository.socialLogin(provider);
  }
}
```

**`lib/domain/usecases/auth/logout_usecase.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}
```

**`lib/domain/usecases/auth/get_current_user_usecase.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, User>> call() {
    return repository.getCurrentUser();
  }
}
```

**Dependencies**: Milestone 1 (errors, dartz package)

---

### Task 2.2: Create Data Models for Auth

**Description**: Implement UserModel with JSON serialization for API communication.

**Acceptance Criteria**:
- UserModel with @JsonSerializable annotation
- toJson() and fromJson() methods generated
- toEntity() method for domain conversion
- API response models (LoginResponse, RegisterResponse)

**Files to Create**:

**`lib/data/models/user_model.dart`**:
```dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String name;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      avatarUrl: avatarUrl,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt != null ? DateTime.parse(updatedAt!) : null,
    );
  }
  
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt.toIso8601String(),
      updatedAt: user.updatedAt?.toIso8601String(),
    );
  }
}

@JsonSerializable()
class LoginResponse {
  final String token;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final UserModel user;

  const LoginResponse({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class RegisterResponse {
  final String token;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  final UserModel user;

  const RegisterResponse({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}
```

**Commands**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Dependencies**: Task 2.1, Milestone 1 Task 1.2 (json_annotation)

---

### Task 2.3: Implement Remote Data Source

**Description**: Create Retrofit API client and auth remote data source.

**Acceptance Criteria**:
- Retrofit API client with auth endpoints
- Auth remote data source implementation
- Proper error handling with exceptions
- Token management in requests

**Files to Create**:

**`lib/data/datasources/remote/api_client.dart`**:
```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../core/constants/api_constants.dart';
import '../../models/user_model.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  // Auth endpoints
  @POST(ApiConstants.loginEndpoint)
  Future<LoginResponse> login(@Body() Map<String, dynamic> body);

  @POST(ApiConstants.registerEndpoint)
  Future<RegisterResponse> register(@Body() Map<String, dynamic> body);

  @POST(ApiConstants.logoutEndpoint)
  Future<void> logout();

  @GET(ApiConstants.meEndpoint)
  Future<UserModel> getCurrentUser();
}
```

**`lib/data/datasources/remote/auth_remote_datasource.dart`**:
```dart
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../models/user_model.dart';
import 'api_client.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(String email, String password);
  Future<RegisterResponse> register(String name, String email, String password);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await apiClient.login({
        'email': email,
        'password': password,
      });
      AppLogger.info('Login successful for email: $email');
      return response;
    } catch (e) {
      AppLogger.error('Login failed', e);
      throw _handleError(e);
    }
  }

  @override
  Future<RegisterResponse> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await apiClient.register({
        'name': name,
        'email': email,
        'password': password,
      });
      AppLogger.info('Registration successful for email: $email');
      return response;
    } catch (e) {
      AppLogger.error('Registration failed', e);
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.logout();
      AppLogger.info('Logout successful');
    } catch (e) {
      AppLogger.error('Logout failed', e);
      throw _handleError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final user = await apiClient.getCurrentUser();
      AppLogger.info('Fetched current user: ${user.email}');
      return user;
    } catch (e) {
      AppLogger.error('Failed to fetch current user', e);
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const NetworkException('Connection timeout');
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data['message'] ?? 'Server error';
          
          if (statusCode == 401) {
            return AuthenticationException(message);
          } else if (statusCode == 404) {
            return NotFoundException(message);
          } else if (statusCode == 400) {
            return ValidationException(message);
          }
          return ServerException(message, statusCode);
        
        case DioExceptionType.cancel:
          return const AppException('Request cancelled');
        
        default:
          return const NetworkException();
      }
    }
    return AppException(error.toString());
  }
}
```

**Commands**:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Dependencies**: Task 2.2, Milestone 1 Task 1.4 (API constants)

---

### Task 2.4: Implement Local Data Source

**Description**: Create local data source for caching auth data in Hive.

**Acceptance Criteria**:
- Save/retrieve auth token and user data
- Token expiry management
- Clear auth data on logout
- Type-safe operations

**Files to Create**:

**`lib/data/datasources/local/auth_local_datasource.dart`**:
```dart
import 'package:hive/hive.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token, {String? refreshToken});
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> clearAuthData();
  Future<bool> hasToken();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box box;

  AuthLocalDataSourceImpl(this.box);

  @override
  Future<void> saveToken(String token, {String? refreshToken}) async {
    try {
      await box.put(StorageKeys.tokenKey, token);
      if (refreshToken != null) {
        await box.put(StorageKeys.refreshTokenKey, refreshToken);
      }
      // Set expiry to 7 days from now
      final expiry = DateTime.now().add(const Duration(days: 7));
      await box.put(StorageKeys.tokenExpiryKey, expiry.toIso8601String());
      
      AppLogger.info('Auth token saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save auth token', e);
      throw CacheException('Failed to save auth token');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      // Check if token is expired
      final expiryStr = box.get(StorageKeys.tokenExpiryKey) as String?;
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          AppLogger.warning('Auth token expired');
          await clearAuthData();
          return null;
        }
      }
      
      return box.get(StorageKeys.tokenKey) as String?;
    } catch (e) {
      AppLogger.error('Failed to get auth token', e);
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    return box.get(StorageKeys.refreshTokenKey) as String?;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await box.put(StorageKeys.userKey, user.toJson());
      AppLogger.info('User data saved: ${user.email}');
    } catch (e) {
      AppLogger.error('Failed to save user data', e);
      throw CacheException('Failed to save user data');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      final userJson = box.get(StorageKeys.userKey) as Map<dynamic, dynamic>?;
      if (userJson != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(userJson));
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get user data', e);
      return null;
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await box.delete(StorageKeys.tokenKey);
      await box.delete(StorageKeys.refreshTokenKey);
      await box.delete(StorageKeys.userKey);
      await box.delete(StorageKeys.tokenExpiryKey);
      AppLogger.info('Auth data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear auth data', e);
      throw CacheException('Failed to clear auth data');
    }
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

**Dependencies**: Task 2.2, Milestone 1 Task 1.7 (Hive storage)

---

### Task 2.5: Implement Firebase Auth Service

**Description**: Create Firebase authentication service for social login (Google, Apple, Facebook).

**Acceptance Criteria**:
- Google Sign-In integration
- Apple Sign-In integration (iOS)
- Facebook Sign-In integration
- Error handling for each provider
- Firebase token exchange with backend

**Files to Create**:

**`lib/data/datasources/remote/firebase_auth_service.dart`**:
```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/repositories/auth_repository.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<String> signInWithGoogle() async {
    try {
      // Sign out from previous session
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw const AuthenticationException('Google sign-in cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = 
          await _firebaseAuth.signInWithCredential(credential);
      
      // Get Firebase ID token to send to backend
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw const AuthenticationException('Failed to get Firebase token');
      }

      AppLogger.info('Google sign-in successful: ${googleUser.email}');
      return idToken;
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Google sign-in failed', e);
      throw AuthenticationException(e.message ?? 'Google sign-in failed');
    } catch (e) {
      AppLogger.error('Google sign-in error', e);
      if (e is AuthenticationException) rethrow;
      throw const AuthenticationException('Google sign-in failed');
    }
  }

  Future<String> signInWithApple() async {
    try {
      // Request Apple ID credential
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential for Firebase
      final oAuthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = 
          await _firebaseAuth.signInWithCredential(oAuthCredential);
      
      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw const AuthenticationException('Failed to get Firebase token');
      }

      AppLogger.info('Apple sign-in successful');
      return idToken;
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Apple sign-in failed', e);
      throw AuthenticationException(e.message ?? 'Apple sign-in failed');
    } on SignInWithAppleAuthorizationException catch (e) {
      AppLogger.error('Apple authorization failed', e);
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthenticationException('Apple sign-in cancelled');
      }
      throw AuthenticationException('Apple sign-in failed: ${e.code}');
    } catch (e) {
      AppLogger.error('Apple sign-in error', e);
      if (e is AuthenticationException) rethrow;
      throw const AuthenticationException('Apple sign-in failed');
    }
  }

  // Note: Facebook login requires additional setup with flutter_facebook_auth package
  // For now, placeholder for future implementation
  Future<String> signInWithFacebook() async {
    throw const AuthenticationException('Facebook sign-in not yet implemented');
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      AppLogger.info('Firebase sign-out successful');
    } catch (e) {
      AppLogger.error('Firebase sign-out failed', e);
    }
  }
}
```

**Update `pubspec.yaml` Firebase configuration**:
```yaml
# Add to android/app/build.gradle
android {
    defaultConfig {
        minSdkVersion 21  # Required for Firebase
    }
}
```

**Create Firebase config files**:
- `android/app/google-services.json` (from Firebase console)
- `ios/Runner/GoogleService-Info.plist` (from Firebase console)

**Initialize Firebase in main.dart**:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive storage
  await HiveStorage.init();
  
  runApp(const MyApp());
}
```

**Dependencies**: Task 2.3, Milestone 1 Task 1.2 (Firebase packages)

---

### Task 2.6: Implement Auth Repository

**Description**: Implement AuthRepository combining remote and local data sources.

**Acceptance Criteria**:
- Implements AuthRepository interface from domain
- Combines remote API and local storage
- Handles Firebase social auth integration
- Proper error mapping from exceptions to failures
- Token management and persistence

**Files to Create**:

**`lib/data/repositories/auth_repository_impl.dart`**:
```dart
import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/remote/firebase_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final FirebaseAuthService firebaseAuthService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.firebaseAuthService,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await remoteDataSource.login(email, password);
      
      // Save token and user data locally
      await localDataSource.saveToken(
        response.token,
        refreshToken: response.refreshToken,
      );
      await localDataSource.saveUser(response.user);
      
      AppLogger.info('Login successful');
      return Right(response.user.toEntity());
    } on AuthenticationException catch (e) {
      AppLogger.error('Login authentication failed', e);
      return Left(AuthenticationFailure(e.message));
    } on NetworkException catch (e) {
      AppLogger.error('Login network error', e);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      AppLogger.error('Login server error', e);
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Login unexpected error', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.register(name, email, password);
      
      // Save token and user data locally
      await localDataSource.saveToken(
        response.token,
        refreshToken: response.refreshToken,
      );
      await localDataSource.saveUser(response.user);
      
      AppLogger.info('Registration successful');
      return Right(response.user.toEntity());
    } on ValidationException catch (e) {
      AppLogger.error('Registration validation failed', e);
      return Left(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      AppLogger.error('Registration network error', e);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      AppLogger.error('Registration server error', e);
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Registration unexpected error', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> socialLogin(SocialProvider provider) async {
    try {
      // Get Firebase ID token
      String firebaseToken;
      
      switch (provider) {
        case SocialProvider.google:
          firebaseToken = await firebaseAuthService.signInWithGoogle();
          break;
        case SocialProvider.apple:
          firebaseToken = await firebaseAuthService.signInWithApple();
          break;
        case SocialProvider.facebook:
          firebaseToken = await firebaseAuthService.signInWithFacebook();
          break;
      }
      
      // Send Firebase token to backend for verification and user creation
      final response = await remoteDataSource.socialLogin(
        provider.name,
        firebaseToken,
      );
      
      // Save token and user data locally
      await localDataSource.saveToken(
        response.token,
        refreshToken: response.refreshToken,
      );
      await localDataSource.saveUser(response.user);
      
      AppLogger.info('Social login successful: ${provider.name}');
      return Right(response.user.toEntity());
    } on AuthenticationException catch (e) {
      AppLogger.error('Social login authentication failed', e);
      return Left(AuthenticationFailure(e.message));
    } on NetworkException catch (e) {
      AppLogger.error('Social login network error', e);
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      AppLogger.error('Social login server error', e);
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('Social login unexpected error', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Logout from backend (optional - invalidate token)
      try {
        await remoteDataSource.logout();
      } catch (e) {
        // Continue even if backend logout fails
        AppLogger.warning('Backend logout failed, continuing', e);
      }
      
      // Sign out from Firebase
      await firebaseAuthService.signOut();
      
      // Clear local auth data
      await localDataSource.clearAuthData();
      
      AppLogger.info('Logout successful');
      return const Right(null);
    } catch (e) {
      AppLogger.error('Logout failed', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Try to get cached user first
      final cachedUser = await localDataSource.getUser();
      if (cachedUser != null) {
        AppLogger.info('Retrieved cached user');
        return Right(cachedUser.toEntity());
      }
      
      // If no cached user, fetch from backend
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(user);
      
      AppLogger.info('Fetched current user from backend');
      return Right(user.toEntity());
    } on AuthenticationException catch (e) {
      AppLogger.error('Get current user authentication failed', e);
      return Left(AuthenticationFailure(e.message));
    } on NetworkException catch (e) {
      AppLogger.error('Get current user network error', e);
      return const Left(NetworkFailure());
    } catch (e) {
      AppLogger.error('Get current user unexpected error', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();
      await localDataSource.clearAuthData();
      await firebaseAuthService.signOut();
      
      AppLogger.info('Account deleted successfully');
      return const Right(null);
    } on AuthenticationException catch (e) {
      AppLogger.error('Delete account authentication failed', e);
      return Left(AuthenticationFailure(e.message));
    } on NetworkException catch (e) {
      AppLogger.error('Delete account network error', e);
      return const Left(NetworkFailure());
    } catch (e) {
      AppLogger.error('Delete account unexpected error', e);
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await localDataSource.hasToken();
  }
}
```

**Update `lib/data/datasources/remote/auth_remote_datasource.dart`** to add social login method:
```dart
Future<LoginResponse> socialLogin(String provider, String firebaseToken) async {
  try {
    final response = await apiClient.socialLogin({
      'provider': provider,
      'firebase_token': firebaseToken,
    });
    AppLogger.info('Social login successful: $provider');
    return response;
  } catch (e) {
    AppLogger.error('Social login failed', e);
    throw _handleError(e);
  }
}

Future<void> deleteAccount() async {
  try {
    await apiClient.deleteAccount();
    AppLogger.info('Account deletion successful');
  } catch (e) {
    AppLogger.error('Account deletion failed', e);
    throw _handleError(e);
  }
}
```

**Dependencies**: Tasks 2.1-2.5

---

### Task 2.7: Create AuthBloc

**Description**: Implement BLoC for authentication state management.

**Acceptance Criteria**:
- All auth events handled (login, register, social login, logout)
- Proper state transitions
- Error handling and user feedback
- Token persistence
- Auto-authentication check on app start

**Files to Create**:

**`lib/presentation/blocs/auth/auth_event.dart`**:
```dart
import 'package:equatable/equatable.dart';
import '../../../domain/repositories/auth_repository.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class AuthSocialLoginRequested extends AuthEvent {
  final SocialProvider provider;

  const AuthSocialLoginRequested(this.provider);

  @override
  List<Object?> get props => [provider];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}
```

**`lib/presentation/blocs/auth/auth_state.dart`**:
```dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
```

**`lib/presentation/blocs/auth/auth_bloc.dart`**:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import '../../../domain/usecases/auth/register_usecase.dart';
import '../../../domain/usecases/auth/social_login_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final SocialLoginUseCase socialLoginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.socialLoginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthSocialLoginRequested>(_onAuthSocialLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthDeleteAccountRequested>(_onAuthDeleteAccountRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      AppLogger.info('Checking authentication status');
      
      final isAuthenticated = await authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final result = await getCurrentUserUseCase();
        
        result.fold(
          (failure) {
            AppLogger.warning('Auth check failed: ${failure.message}');
            emit(const Unauthenticated());
          },
          (user) {
            AppLogger.info('User authenticated: ${user.email}');
            emit(Authenticated(user));
          },
        );
      } else {
        AppLogger.info('User not authenticated');
        emit(const Unauthenticated());
      }
    } catch (e) {
      AppLogger.error('Auth check error', e);
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await loginUseCase(event.email, event.password);
    
    result.fold(
      (failure) {
        AppLogger.error('Login failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        AppLogger.info('Login successful: ${user.email}');
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await registerUseCase(
      event.name,
      event.email,
      event.password,
    );
    
    result.fold(
      (failure) {
        AppLogger.error('Registration failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        AppLogger.info('Registration successful: ${user.email}');
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onAuthSocialLoginRequested(
    AuthSocialLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await socialLoginUseCase(event.provider);
    
    result.fold(
      (failure) {
        AppLogger.error('Social login failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        AppLogger.info('Social login successful: ${user.email}');
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await logoutUseCase();
    
    result.fold(
      (failure) {
        AppLogger.error('Logout failed: ${failure.message}');
        // Still emit Unauthenticated even if logout fails
        emit(const Unauthenticated());
      },
      (_) {
        AppLogger.info('Logout successful');
        emit(const Unauthenticated());
      },
    );
  }

  Future<void> _onAuthDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await authRepository.deleteAccount();
    
    result.fold(
      (failure) {
        AppLogger.error('Account deletion failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (_) {
        AppLogger.info('Account deleted successfully');
        emit(const Unauthenticated());
      },
    );
  }
}
```

**Dependencies**: Task 2.1 (use cases), Task 2.6 (repository)

---

### Task 2.8: Setup Dependency Injection

**Description**: Configure GetIt for dependency injection across the app.

**Acceptance Criteria**:
- All dependencies registered (repositories, use cases, BLoCs, data sources)
- Singleton vs factory patterns used appropriately
- Easy to add new dependencies
- Type-safe injections

**Files to Create**:

**`lib/di/injection.dart`**:
```dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/storage_keys.dart';
import '../data/datasources/local/auth_local_datasource.dart';
import '../data/datasources/local/hive_storage.dart';
import '../data/datasources/remote/api_client.dart';
import '../data/datasources/remote/auth_remote_datasource.dart';
import '../data/datasources/remote/firebase_auth_service.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/auth/get_current_user_usecase.dart';
import '../domain/usecases/auth/login_usecase.dart';
import '../domain/usecases/auth/logout_usecase.dart';
import '../domain/usecases/auth/register_usecase.dart';
import '../domain/usecases/auth/social_login_usecase.dart';
import '../presentation/blocs/auth/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // ========== Core ==========
  
  // Dio
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Add auth interceptor
    dio.interceptors.add(_AuthInterceptor());
    
    // Add logging in debug mode
    if (const bool.fromEnvironment('DEBUG', defaultValue: false)) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
    
    return dio;
  });
  
  // API Client
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl<Dio>()));
  
  // Firebase Auth Service
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  
  // Hive Boxes
  sl.registerLazySingleton<Box>(
    () => HiveStorage.authBox,
    instanceName: 'authBox',
  );
  
  // ========== Data Sources ==========
  
  // Remote Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<ApiClient>()),
  );
  
  // Local Data Sources
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<Box>(instanceName: 'authBox')),
  );
  
  // ========== Repositories ==========
  
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      firebaseAuthService: sl<FirebaseAuthService>(),
    ),
  );
  
  // ========== Use Cases ==========
  
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SocialLoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  
  // ========== BLoCs ==========
  
  // Register as factory so new instance is created each time
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      socialLoginUseCase: sl<SocialLoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
}

// Auth Interceptor to add token to requests
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final authBox = HiveStorage.authBox;
    final token = authBox.get(StorageKeys.tokenKey);
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
}
```

**Update `lib/main.dart`**:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/utils/logger.dart';
import 'data/datasources/local/hive_storage.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialized');
    
    // Initialize Hive storage
    await HiveStorage.init();
    AppLogger.info('Hive storage initialized');
    
    // Setup dependency injection
    await setupDependencyInjection();
    AppLogger.info('Dependency injection configured');
    
    AppLogger.info('App initialization complete');
  } catch (e, stackTrace) {
    AppLogger.error('App initialization failed', e, stackTrace);
  }
  
  runApp(const MyApp());
}
```

**Dependencies**: All previous Milestone 2 tasks

---

## Milestone 2 Completion Checklist

- [ ] Task 2.1: Domain layer for auth created
- [ ] Task 2.2: Data models with JSON serialization
- [ ] Task 2.3: Remote data source with Retrofit
- [ ] Task 2.4: Local data source with Hive
- [ ] Task 2.5: Firebase auth service implemented
- [ ] Task 2.6: Auth repository implementation
- [ ] Task 2.7: AuthBloc created
- [ ] Task 2.8: Dependency injection setup

**Validation**:
```bash
flutter analyze
flutter test
# Test auth flow manually
```

---

