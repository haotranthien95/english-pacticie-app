import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';
import 'hive_storage.dart';

/// Local data source for authentication operations
/// Handles token and user data storage in Hive
abstract class AuthLocalDataSource {
  /// Save authentication token to local storage
  Future<void> saveToken(String token);

  /// Get stored authentication token
  /// Returns token string or null if not found
  Future<String?> getToken();

  /// Delete authentication token from local storage
  Future<void> deleteToken();

  /// Save user data to local storage
  Future<void> saveUser(UserModel user);

  /// Get stored user data
  /// Throws [CacheException] if user data not found
  Future<UserModel> getUser();

  /// Delete user data from local storage
  Future<void> deleteUser();

  /// Check if user is authenticated (token exists)
  Future<bool> isAuthenticated();
}

/// Implementation of AuthLocalDataSource using Hive
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final HiveStorage hiveStorage;

  AuthLocalDataSourceImpl(this.hiveStorage);

  @override
  Future<void> saveToken(String token) async {
    try {
      final box = HiveStorage.getAuthBox();
      await box.put(StorageKeys.accessToken, token);
    } catch (e) {
      throw StorageException(
        message: 'Failed to save token: $e',
      );
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final box = HiveStorage.getAuthBox();
      return box.get(StorageKeys.accessToken) as String?;
    } catch (e) {
      throw StorageException(
        message: 'Failed to get token: $e',
      );
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      final box = HiveStorage.getAuthBox();
      await box.delete(StorageKeys.accessToken);
    } catch (e) {
      throw StorageException(
        message: 'Failed to delete token: $e',
      );
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      final box = HiveStorage.getAuthBox();
      final userJson = user.toJson();
      await box.put(StorageKeys.userProfile, userJson);
    } catch (e) {
      throw StorageException(
        message: 'Failed to save user: $e',
      );
    }
  }

  @override
  Future<UserModel> getUser() async {
    try {
      final box = HiveStorage.getAuthBox();
      final userJson = box.get(StorageKeys.userProfile);
      if (userJson == null) {
        throw const CacheException(
          message: 'User data not found',
        );
      }
      return UserModel.fromJson(Map<String, dynamic>.from(userJson as Map));
    } catch (e) {
      if (e is CacheException) {
        rethrow;
      }
      throw StorageException(
        message: 'Failed to get user: $e',
      );
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      final box = HiveStorage.getAuthBox();
      await box.delete(StorageKeys.userProfile);
    } catch (e) {
      throw StorageException(
        message: 'Failed to delete user: $e',
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
