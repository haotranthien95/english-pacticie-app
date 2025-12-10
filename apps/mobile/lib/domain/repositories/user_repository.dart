import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

/// Repository interface for user profile operations
abstract class UserRepository {
  /// Get current user profile
  Future<Either<Failure, User>> getProfile();

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? avatarUrl,
  });

  /// Delete user account (destructive action)
  Future<Either<Failure, void>> deleteAccount();
}
