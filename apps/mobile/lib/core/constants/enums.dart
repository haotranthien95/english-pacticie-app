/// Application-wide enums

/// User authentication provider
enum AuthProvider {
  email,
  google,
  apple,
  facebook,
}

/// Speech difficulty level
enum SpeechLevel {
  beginner,
  intermediate,
  advanced,
}

/// Speech content type
enum SpeechType {
  word,
  phrase,
  sentence,
  paragraph,
}

/// Game play mode
enum GameMode {
  listenOnly,
  listenAndRepeat,
  practice,
  challenge,
}

/// Theme mode options
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Supported languages
enum AppLanguage {
  english,
  vietnamese,
}

/// Network connection status
enum ConnectionStatus {
  connected,
  disconnected,
  unknown,
}

/// Sync status for offline queue
enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
}

// Extension methods for enums
extension AuthProviderExtension on AuthProvider {
  String get value {
    switch (this) {
      case AuthProvider.email:
        return 'email';
      case AuthProvider.google:
        return 'google';
      case AuthProvider.apple:
        return 'apple';
      case AuthProvider.facebook:
        return 'facebook';
    }
  }

  static AuthProvider fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'email':
        return AuthProvider.email;
      case 'google':
        return AuthProvider.google;
      case 'apple':
        return AuthProvider.apple;
      case 'facebook':
        return AuthProvider.facebook;
      default:
        throw ArgumentError('Invalid AuthProvider value: $value');
    }
  }
}

extension SpeechLevelExtension on SpeechLevel {
  String get value {
    switch (this) {
      case SpeechLevel.beginner:
        return 'beginner';
      case SpeechLevel.intermediate:
        return 'intermediate';
      case SpeechLevel.advanced:
        return 'advanced';
    }
  }

  static SpeechLevel fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'beginner':
        return SpeechLevel.beginner;
      case 'intermediate':
        return SpeechLevel.intermediate;
      case 'advanced':
        return SpeechLevel.advanced;
      default:
        throw ArgumentError('Invalid SpeechLevel value: $value');
    }
  }
}

extension SpeechTypeExtension on SpeechType {
  String get value {
    switch (this) {
      case SpeechType.word:
        return 'word';
      case SpeechType.phrase:
        return 'phrase';
      case SpeechType.sentence:
        return 'sentence';
      case SpeechType.paragraph:
        return 'paragraph';
    }
  }

  static SpeechType fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'word':
        return SpeechType.word;
      case 'phrase':
        return SpeechType.phrase;
      case 'sentence':
        return SpeechType.sentence;
      case 'paragraph':
        return SpeechType.paragraph;
      default:
        throw ArgumentError('Invalid SpeechType value: $value');
    }
  }
}

extension GameModeExtension on GameMode {
  String get value {
    switch (this) {
      case GameMode.listenOnly:
        return 'listen_only';
      case GameMode.listenAndRepeat:
        return 'listen_and_repeat';
      case GameMode.practice:
        return 'practice';
      case GameMode.challenge:
        return 'challenge';
    }
  }

  static GameMode fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'listen_only':
        return GameMode.listenOnly;
      case 'listen_and_repeat':
        return GameMode.listenAndRepeat;
      case 'practice':
        return GameMode.practice;
      case 'challenge':
        return GameMode.challenge;
      default:
        throw ArgumentError('Invalid GameMode value: $value');
    }
  }
}

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.vietnamese:
        return 'vi';
    }
  }
}

extension SyncStatusExtension on SyncStatus {
  String get value {
    switch (this) {
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.syncing:
        return 'syncing';
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.failed:
        return 'failed';
    }
  }

  static SyncStatus fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return SyncStatus.pending;
      case 'syncing':
        return SyncStatus.syncing;
      case 'synced':
        return SyncStatus.synced;
      case 'failed':
        return SyncStatus.failed;
      default:
        throw ArgumentError('Invalid SyncStatus value: $value');
    }
  }
}
