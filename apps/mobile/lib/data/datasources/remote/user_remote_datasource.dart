import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

/// Remote data source for user profile operations
abstract class UserRemoteDataSource {
  /// Get current user profile from API
  Future<UserModel> getProfile();

  /// Update user profile
  Future<UserModel> updateProfile({
    String? name,
    String? avatarUrl,
  });

  /// Delete user account
  Future<void> deleteAccount();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final Dio dio;

  UserRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiEndpoints.profile);

      if (response.statusCode == 200) {
        return UserModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to load profile: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await dio.put(
        ApiEndpoints.profile,
        data: data,
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to update profile: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await dio.delete(ApiEndpoints.profile);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete account: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] as String?;

        if (statusCode == 401) {
          return UnauthorizedException(
            message: message ?? 'Unauthorized access',
          );
        } else if (statusCode == 404) {
          return ServerException(message: message ?? 'User not found');
        } else if (statusCode == 422) {
          return ValidationException(
            message: message ?? 'Invalid profile data',
          );
        } else {
          return ServerException(
            message: message ?? 'Server error: $statusCode',
          );
        }

      case DioExceptionType.cancel:
        return NetworkException(message: 'Request cancelled');

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return NetworkException(message: 'No internet connection');
        }
        return NetworkException(message: 'Network error: ${error.message}');

      default:
        return ServerException(message: 'Unexpected error: ${error.message}');
    }
  }
}
