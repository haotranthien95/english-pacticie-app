# English Practice App - Flutter Mobile

A Flutter mobile application for English language learning with interactive listening and pronunciation practice.

## 📱 Features

### Core Functionality
- **Authentication**: Email/password and social login (Google, Apple, Facebook)
- **Game Modes**:
  - **Listen-Only**: Swipe to evaluate speech understanding
  - **Listen-and-Repeat**: Record pronunciation and get instant feedback
- **Offline-First**: Game sessions saved locally and synced when online
- **Game History**: Review past sessions with detailed statistics
- **User Profile**: Manage profile and preferences
- **Multi-Language**: English and Vietnamese support
- **Theming**: Light, dark, and system themes

## 🏗️ Architecture

### Clean Architecture Layers

```
lib/
├── core/                   # Core utilities and configuration
│   ├── constants/         # API endpoints, storage keys, enums
│   ├── errors/            # Custom exceptions and failures
│   ├── router/            # Navigation with go_router
│   ├── theme/             # Material Design 3 themes
│   └── utils/             # Responsive utilities
├── data/                  # Data layer
│   ├── datasources/       # Local (Hive) and remote (API) data sources
│   ├── models/            # JSON serializable models
│   └── repositories/      # Repository implementations
├── domain/                # Domain layer
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Business logic use cases
├── presentation/          # Presentation layer
│   ├── blocs/             # BLoC state management
│   ├── screens/           # UI screens
│   └── widgets/           # Reusable widgets
└── di/                    # Dependency injection (GetIt)
```

### Key Design Patterns
- **BLoC Pattern**: State management with imperative event naming
- **Repository Pattern**: Abstract data sources
- **Use Case Pattern**: Single responsibility business logic
- **Dependency Injection**: GetIt for loose coupling
- **Either Pattern**: Functional error handling with dartz

## 🚀 Getting Started

### Prerequisites

- Flutter SDK: 3.24.5 or higher
- Dart SDK: 3.5.4 or higher
- Android Studio / Xcode for mobile development
- Firebase project for OAuth configuration

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd english-pacticie-app/apps/mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Configure OAuth providers in Firebase Console

4. **Set up environment**
   - Update API endpoints in `lib/core/constants/api_endpoints.dart`
   - Configure storage keys in `lib/core/constants/storage_keys.dart`

5. **Run the app**
   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

## 🔧 Development

### Project Structure

```
apps/mobile/
├── android/               # Android native code
├── ios/                   # iOS native code
├── lib/                   # Dart source code
├── test/                  # Unit and widget tests
├── integration_test/      # E2E integration tests
├── assets/                # Images, fonts, localization
├── l10n.yaml             # Localization configuration
└── pubspec.yaml          # Dependencies
```

### Key Dependencies

**State Management & Architecture**
- `flutter_bloc: ^8.1.6` - BLoC pattern implementation
- `get_it: ^7.7.0` - Dependency injection
- `dartz: ^0.10.1` - Functional programming (Either)

**Storage & Networking**
- `hive: ^2.2.3` - Local storage
- `dio: ^5.4.3+1` - HTTP client
- `connectivity_plus: ^6.0.5` - Network monitoring

**Authentication**
- `firebase_auth: ^5.3.1` - Firebase authentication
- `google_sign_in: ^6.2.1` - Google OAuth
- `sign_in_with_apple: ^6.1.3` - Apple OAuth

**Audio**
- `just_audio: ^0.9.40` - Audio playback
- `record: ^5.1.2` - Audio recording (memory buffer)

**UI & Navigation**
- `go_router: ^14.3.0` - Declarative routing
- `flutter_svg: ^2.0.10+1` - SVG support

**Localization**
- `flutter_localizations` - i18n support
- ARB files in `lib/l10n/` (English and Vietnamese)

### Running Tests

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget/

# Integration tests
flutter test integration_test/
```

### Code Generation

```bash
# Generate JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization
flutter gen-l10n
```

## 🎨 Theming

The app uses Material Design 3 with custom color schemes:

- **Light Theme**: Purple primary (#6750A4)
- **Dark Theme**: Light purple primary (#D0BCFF)
- **System Theme**: Follows device settings

Theme switching available in Settings screen.

## 🌍 Localization

Supported languages:
- **English** (en)
- **Vietnamese** (vi)

Translation files: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`

Language switching available in Settings screen.

## 📱 Responsive Design

Material Design breakpoints:
- **Phone**: < 600dp (single column)
- **Tablet**: ≥ 600dp (two columns)
- **Large Tablet**: ≥ 840dp (three columns)

Responsive utilities in `lib/core/utils/responsive_utils.dart`.

## 🔐 Security

### Audio Recording
- **Memory Buffer Only**: No filesystem writes
- **10MB Buffer Limit**: Auto-stop on exceed
- **Stream Upload**: Direct multipart to backend API

### Authentication
- **JWT Tokens**: Stored in encrypted Hive box
- **OAuth Flow**: Firebase SDK → Backend JWT exchange
- **Auto-Logout**: Token expiration handling

### Offline Storage
- **Hive Encryption**: Sensitive data encrypted
- **Exponential Backoff**: 1s, 2s, 4s, 8s retry intervals
- **Data Validation**: Size limits and integrity checks

## 📊 Performance

### Optimization Strategies
- **Lazy Loading**: Pagination for history
- **Image Optimization**: Cached network images
- **Offline-First**: Immediate local save, background sync
- **Memory Management**: Dispose controllers and streams

### Target Metrics
- **App Size**: < 30MB
- **Cold Start**: < 3 seconds
- **Frame Rate**: 60 FPS
- **Memory**: < 150MB average

## 🐛 Troubleshooting

### Common Issues

**Build Errors**
```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

**Firebase Configuration**
- Verify `google-services.json` and `GoogleService-Info.plist` are present
- Check Firebase Console for correct app registration
- Ensure SHA-1 fingerprint added (Android)

**Audio Permissions**
- Android: Check `AndroidManifest.xml` for microphone permission
- iOS: Check `Info.plist` for microphone usage description

**Offline Sync Issues**
- Check network connectivity
- Verify API endpoint configuration
- Review Hive storage for pending sessions

## 🚢 Deployment

### Android

1. **Configure signing**
   - Create `android/key.properties`
   - Generate keystore: `keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key`

2. **Build release APK**
   ```bash
   flutter build apk --release
   ```

3. **Build release AAB**
   ```bash
   flutter build appbundle --release
   ```

### iOS

1. **Configure signing in Xcode**
   - Open `ios/Runner.xcworkspace`
   - Set team and bundle identifier

2. **Build release IPA**
   ```bash
   flutter build ipa --release
   ```

## 📝 Development Guidelines

### BLoC Event Naming
Use imperative (command) style:
- ✅ `LoginRequested`, `GameStarted`, `RecordingStarted`
- ❌ `UserLoggedIn`, `GameWasStarted`

### Error Handling
```dart
// Use Either pattern
final result = await repository.getData();
result.fold(
  (failure) => emit(ErrorState(failure.message)),
  (data) => emit(LoadedState(data)),
);
```

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` before commits
- Format code with `flutter format .`

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/amazing-feature`
2. Commit changes: `git commit -m 'feat: add amazing feature'`
3. Push to branch: `git push origin feature/amazing-feature`
4. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 📞 Support

For issues and questions:
- Create an issue in the repository
- Contact development team

## 🎯 Roadmap

### Completed (v1.0)
- ✅ User authentication (email + social OAuth)
- ✅ Listen-Only and Listen-and-Repeat game modes
- ✅ Offline-first game sessions
- ✅ Pronunciation scoring with memory buffer
- ✅ Game history with filters
- ✅ User profile management
- ✅ Theme switching (light/dark/system)
- ✅ Multi-language support (EN/VI)
- ✅ Responsive layouts (phone/tablet)

### Future Enhancements (v2.0)
- [ ] Vocabulary builder
- [ ] Streak tracking and achievements
- [ ] Social features (leaderboards, friends)
- [ ] Spaced repetition algorithm
- [ ] Custom word lists
- [ ] Progress analytics dashboard
- [ ] Push notifications
- [ ] Widget for quick practice

---

**Version**: 1.0.0  
**Last Updated**: December 10, 2025  
**Tech Stack**: Flutter 3.24.5, Dart 3.5.4, BLoC, Hive, Firebase
