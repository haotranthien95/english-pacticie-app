/// App-wide configuration constants
class AppConfig {
  static const String appName = 'English Learning App';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String apiVersion = 'v1';
  static const String apiPrefix = '/api/$apiVersion';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Audio
  static const int maxAudioBufferBytes = 10 * 1024 * 1024; // 10MB
  static const int audioBitrate = 64000; // 64kbps
  static const int audioSampleRate = 44100;

  // Offline Sync
  static const int maxRetryAttempts = 4;
  static const List<int> retryDelaysMs = [
    1000,
    2000,
    4000,
    8000
  ]; // Exponential backoff

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCachedItems = 100;
}
