# Debug Logging Guide

## Overview

The English Learning App now includes a comprehensive logging system using the `logger` package. This system provides structured, colorized logging with different severity levels to help with debugging and monitoring.

## Features

- ✅ **Multiple Log Levels**: trace, debug, info, warning, error, fatal
- ✅ **Auto-configuration**: Debug mode shows all logs, Release mode only warnings and above
- ✅ **Color-coded Output**: Easy to distinguish different log levels
- ✅ **Timestamps**: Track when events occur
- ✅ **Stack Traces**: Automatic stack trace logging for errors
- ✅ **Context Tags**: Tag logs with component names for easy filtering

## Usage

### Basic Logging

```dart
import 'package:english_learning_app/core/utils/logger.dart';

// Info messages (general information)
AppLogger.info('User logged in successfully');

// Debug messages (detailed diagnostic info)
AppLogger.debug('API request payload: $data');

// Warning messages (potential issues)
AppLogger.warning('Network connection unstable');

// Error messages (errors that might allow app to continue)
AppLogger.error('Failed to load user profile', error: e);

// Fatal messages (severe errors)
AppLogger.fatal('Database connection lost', error: e, stackTrace: stackTrace);
```

### Logging with Errors and Stack Traces

```dart
try {
  // Some operation
} catch (e, stackTrace) {
  AppLogger.error(
    'Failed to process data',
    error: e,
    stackTrace: stackTrace,
  );
}
```

### Logging with Context/Tags

```dart
import 'package:english_learning_app/core/utils/logger.dart';
import 'package:logger/logger.dart';

// Use the extension for tagged logging
LoggerContext.logWithTag(
  'GameBloc',
  'Starting new game session',
  level: Level.info,
);

LoggerContext.logWithTag(
  'NetworkService',
  'Request failed',
  level: Level.error,
  error: exception,
);
```

## Current Implementation

### Initialized Components

The following components now have comprehensive logging:

1. **App Initialization** (`main.dart`)
   - Firebase initialization
   - Hive storage setup
   - Dependency injection configuration

2. **Authentication** (`auth_bloc.dart`)
   - Login attempts and results
   - Registration flows
   - Social login (Google, Apple)
   - Logout operations
   - Auth state changes

3. **Firebase Auth Service** (`firebase_auth_service.dart`)
   - OAuth flows (Google, Apple, Facebook)
   - Token acquisition
   - Sign-out operations

4. **Local Storage** (`hive_storage.dart`)
   - Storage initialization
   - Box opening operations
   - Storage errors

5. **Network Layer** (`injection.dart`)
   - HTTP requests and responses via Dio interceptor
   - API calls (headers, body, errors)

## Log Levels

### Debug Mode (Development)
All log levels are shown:
- `TRACE` - Very detailed diagnostic information
- `DEBUG` - Detailed diagnostic information
- `INFO` - General informational messages
- `WARNING` - Potentially harmful situations
- `ERROR` - Error events that might allow app to continue
- `FATAL` - Very severe errors that will prevent normal execution

### Release Mode (Production)
Only `WARNING`, `ERROR`, and `FATAL` are shown to reduce noise and improve performance.

## Configuration

### Changing Log Level

Edit `main.dart` to customize log level:

```dart
AppLogger.initialize(
  level: Level.debug,        // Change this for different verbosity
  printTime: true,            // Show timestamps
  printEmojis: true,          // Show emoji indicators
);
```

### Viewing Logs

#### VS Code / Android Studio
Logs appear in the Debug Console when running the app.

#### Terminal
```bash
# Run with logs
flutter run

# Filter logs by tag
flutter run | grep '\[AuthBloc\]'

# View only errors
flutter run | grep 'ERROR'
```

#### Device Logs

**Android:**
```bash
adb logcat | grep flutter
```

**iOS:**
```bash
# Using Console app or:
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
```

## Best Practices

### 1. Use Appropriate Log Levels
```dart
// ✅ Good
AppLogger.info('User logged in');
AppLogger.debug('Processing data: $details');
AppLogger.error('Failed to save', error: e);

// ❌ Avoid
AppLogger.error('User logged in');  // Not an error
AppLogger.debug('CRITICAL ERROR');  // Use error level
```

### 2. Include Context
```dart
// ✅ Good
AppLogger.info('[GameBloc] Starting game session for user: $userId');

// ❌ Less useful
AppLogger.info('Starting session');
```

### 3. Log Errors with Stack Traces
```dart
// ✅ Good
try {
  await riskyOperation();
} catch (e, stackTrace) {
  AppLogger.error('Operation failed', error: e, stackTrace: stackTrace);
}

// ❌ Missing details
catch (e) {
  AppLogger.error('Error');
}
```

### 4. Don't Log Sensitive Data
```dart
// ❌ NEVER do this
AppLogger.debug('Password: ${user.password}');
AppLogger.debug('Token: $authToken');

// ✅ Safe
AppLogger.debug('User authenticated: ${user.email}');
AppLogger.debug('Token received (length: ${authToken.length})');
```

### 5. Use Tags for Component Identification
```dart
// BLoCs
AppLogger.info('[AuthBloc] Login successful');
AppLogger.info('[GameBloc] Game session started');

// Services
AppLogger.debug('[ApiService] GET /users/me');
AppLogger.debug('[StorageService] Saving to cache');

// Repositories
AppLogger.debug('[AuthRepository] Fetching user data');
```

## Adding Logging to New Components

### Example: Adding Logging to a New BLoC

```dart
import 'package:english_learning_app/core/utils/logger.dart';

class MyNewBloc extends Bloc<MyEvent, MyState> {
  MyNewBloc() : super(MyInitialState()) {
    on<MyEvent>(_onMyEvent);
  }
  
  Future<void> _onMyEvent(MyEvent event, Emitter<MyState> emit) async {
    AppLogger.info('[MyNewBloc] Processing event: ${event.runtimeType}');
    
    try {
      // Your logic
      AppLogger.debug('[MyNewBloc] Operation successful');
      emit(MySuccessState());
    } catch (e, stackTrace) {
      AppLogger.error(
        '[MyNewBloc] Operation failed',
        error: e,
        stackTrace: stackTrace,
      );
      emit(MyErrorState());
    }
  }
}
```

### Example: Adding Logging to a Repository

```dart
import 'package:english_learning_app/core/utils/logger.dart';

class MyRepository {
  Future<Either<Failure, Data>> getData() async {
    AppLogger.debug('[MyRepository] Fetching data...');
    
    try {
      final result = await dataSource.get();
      AppLogger.info('[MyRepository] Data fetched successfully');
      return Right(result);
    } catch (e, stackTrace) {
      AppLogger.error(
        '[MyRepository] Failed to fetch data',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure());
    }
  }
}
```

## Troubleshooting

### Logs Not Appearing

1. **Check if logger is initialized**
   - Verify `AppLogger.initialize()` is called in `main.dart`

2. **Check log level**
   - Debug logs won't show in release mode
   - Verify the level in initialization

3. **Check filters**
   - Some IDEs filter logs by default
   - Check your IDE's filter settings

### Too Many Logs

1. **Increase log level**
   ```dart
   AppLogger.initialize(level: Level.info);  // Skip debug logs
   ```

2. **Filter by tag**
   ```bash
   flutter run | grep '\[AuthBloc\]'
   ```

### Performance Impact

- Logging has minimal performance impact in debug mode
- In release mode, only critical logs are shown
- Use `kDebugMode` checks for expensive log operations:

```dart
if (kDebugMode) {
  AppLogger.debug('Expensive operation result: ${computeExpensiveData()}');
}
```

## Next Steps

### Components to Add Logging To:

1. **Game BLoC** - Game session management and scoring
2. **History BLoC** - History viewing and filtering
3. **Profile BLoC** - Profile updates
4. **Settings BLoC** - Settings changes
5. **API Services** - Network request/response logging
6. **Audio Services** - Recording and playback events

### Recommended Tags:

- `[AuthBloc]` - Authentication logic
- `[GameBloc]` - Game logic
- `[HistoryBloc]` - History logic
- `[ProfileBloc]` - Profile logic
- `[SettingsBloc]` - Settings logic
- `[ApiService]` - API calls
- `[AudioService]` - Audio operations
- `[StorageService]` - Local storage
- `[FirebaseAuth]` - Firebase authentication

## Resources

- [Logger Package Documentation](https://pub.dev/packages/logger)
- [Flutter Logging Best Practices](https://docs.flutter.dev/testing/debugging)
- [Dart Logging Guide](https://dart.dev/guides/libraries/library-tour#logging)
