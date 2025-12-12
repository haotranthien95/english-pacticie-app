/// Local storage keys for Hive boxes and preferences
class StorageKeys {
  // Hive Box Names
  static const String authBox = 'auth_box';
  static const String cacheBox = 'cache_box';
  static const String gameBox = 'game_box';
  static const String settingsBox = 'settings_box';

  // Auth Keys
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String userProfile = 'user_profile';

  // Settings Keys
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String soundEnabled = 'sound_enabled';
  static const String vibrationEnabled = 'vibration_enabled';

  // Game Keys
  static const String pendingSessionsQueue = 'pending_sessions_queue';
  static const String lastSyncTimestamp = 'last_sync_timestamp';
  static const String gameConfigLevel = 'game_config_level';
  static const String gameConfigType = 'game_config_type';
  static const String gameConfigTagIds = 'game_config_tag_ids';

  // Cache Keys
  static const String cachedTags = 'cached_tags';
  static const String cachedSpeeches = 'cached_speeches';
  static const String cacheTimestamp = 'cache_timestamp';
}
