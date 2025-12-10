import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';

/// Remote data source for authentication API operations
abstract class AuthRemoteDataSource {
  /// Register a new user with email and password
  /// Returns [UserModel] and access token
  /// Throws [ServerException] on API error
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  });

  /// Login with email and password
  /// Returns [UserModel] and access token
  /// Throws [ServerException] on API error
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  /// Authenticate with social provider OAuth token
  /// Sends Firebase OAuth token to backend, receives JWT
  /// Returns [UserModel] and access token
  /// Throws [ServerException] on API error
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  });

  /// Get current user profile
  /// Requires authentication token in headers
  /// Returns [UserModel]
  /// Throws [ServerException] on API error
  Future<UserModel> getCurrentUser(String token);
}

/// Implementation of AuthRemoteDataSource using Dio
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'username': username,
          if (displayName != null) 'display_name': displayName,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
          'token': data['access_token'] as String,
        };
      } else {
        throw ServerException(
          message: 'Registration failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error during registration: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
          'token': data['access_token'] as String,
        };
      } else {
        throw ServerException(
          message: 'Login failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error during login: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.socialAuth,
        data: {
          'provider': provider,
          'token': token,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return {
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
          'token': data['access_token'] as String,
        };
      } else {
        throw ServerException(
          message: 'Social login failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error during social login: $e');
    }
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    try {
      final response = await dio.get(
        ApiEndpoints.profile,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Get user failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error getting user: $e');
    }
  }

  /// Handle Dio errors and convert to appropriate exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Request timeout');
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['detail'] as String? ??
            error.response?.data?['message'] as String? ??
            'Server error';

        if (statusCode == 401) {
          return AuthException(message: message);
        } else if (statusCode == 400) {
          return ValidationException(message: message);
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(message: message);
        } else {
          return ServerException(message: message);
        }
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request cancelled');
      default:
        return ServerException(message: 'Unexpected error: ${error.message}');
    }
  }
}
