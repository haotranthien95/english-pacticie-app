import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';

/// Manages Hive local storage initialization and box access
class HiveStorage {
  static bool _initialized = false;

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    if (_initialized) {
      AppLogger.debug('[HiveStorage] Already initialized, skipping...');
      return;
    }

    try {
      AppLogger.debug('[HiveStorage] Initializing Hive Flutter...');
      await Hive.initFlutter();

      // Register type adapters here when models are created
      // Example: Hive.registerAdapter(UserModelAdapter());
      AppLogger.debug('[HiveStorage] Registering type adapters...');

      // Open required boxes
      AppLogger.debug('[HiveStorage] Opening storage boxes...');
      await Future.wait([
        Hive.openBox(StorageKeys.authBox),
        Hive.openBox(StorageKeys.cacheBox),
        Hive.openBox(StorageKeys.gameBox),
        Hive.openBox(StorageKeys.settingsBox),
      ]);

      _initialized = true;
      AppLogger.info(
          '[HiveStorage] Successfully initialized with boxes: ${StorageKeys.authBox}, ${StorageKeys.cacheBox}, ${StorageKeys.gameBox}, ${StorageKeys.settingsBox}');
    } catch (e, stackTrace) {
      AppLogger.error('[HiveStorage] Failed to initialize',
          error: e, stackTrace: stackTrace);
      throw StorageException(
        message: 'Failed to initialize Hive storage: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get auth box for token and user data
  static Box getAuthBox() {
    if (!_initialized) {
      throw const StorageException(
        message: 'Hive not initialized. Call initialize() first.',
      );
    }
    return Hive.box(StorageKeys.authBox);
  }

  /// Get cache box for temporary data
  static Box getCacheBox() {
    if (!_initialized) {
      throw const StorageException(
        message: 'Hive not initialized. Call initialize() first.',
      );
    }
    return Hive.box(StorageKeys.cacheBox);
  }

  /// Get game box for offline game sessions
  static Box getGameBox() {
    if (!_initialized) {
      throw const StorageException(
        message: 'Hive not initialized. Call initialize() first.',
      );
    }
    return Hive.box(StorageKeys.gameBox);
  }

  /// Get settings box for user preferences
  static Box getSettingsBox() {
    if (!_initialized) {
      throw const StorageException(
        message: 'Hive not initialized. Call initialize() first.',
      );
    }
    return Hive.box(StorageKeys.settingsBox);
  }

  /// Clear all data from a specific box
  static Future<void> clearBox(String boxName) async {
    try {
      final box = Hive.box(boxName);
      await box.clear();
    } catch (e) {
      throw StorageException(
        message: 'Failed to clear box $boxName: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Clear all data from all boxes
  static Future<void> clearAll() async {
    try {
      await Future.wait([
        clearBox(StorageKeys.authBox),
        clearBox(StorageKeys.cacheBox),
        clearBox(StorageKeys.gameBox),
        clearBox(StorageKeys.settingsBox),
      ]);
    } catch (e) {
      throw StorageException(
        message: 'Failed to clear all boxes: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Close all boxes and cleanup
  static Future<void> dispose() async {
    try {
      await Hive.close();
      _initialized = false;
    } catch (e) {
      throw StorageException(
        message: 'Failed to dispose Hive: ${e.toString()}',
        details: e,
      );
    }
  }
}
