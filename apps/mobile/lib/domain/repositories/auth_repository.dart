import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// Authentication repository contract
/// Defines all authentication-related operations
abstract class AuthRepository {
  /// Register a new user with email and password
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String username,
    String? displayName,
  });

  /// Login with email and password
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Authenticate with social provider (Google, Apple, Facebook)
  /// Acquires OAuth token from Firebase, exchanges for backend JWT
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> socialLogin({
    required AuthProvider provider,
  });

  /// Logout current user
  /// Clears local token and Firebase session
  /// Returns [Unit] on success, [Failure] on error
  Future<Either<Failure, Unit>> logout();

  /// Get currently authenticated user from local storage
  /// Returns [User] if token valid, [AuthFailure] if not authenticated
  Future<Either<Failure, User>> getCurrentUser();

  /// Check if user is currently authenticated
  /// Returns true if valid token exists in local storage
  Future<bool> isAuthenticated();

  /// Get stored authentication token
  /// Returns token string or null if not authenticated
  Future<String?> getToken();
}
