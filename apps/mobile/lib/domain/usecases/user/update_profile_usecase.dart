import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

/// Parameters for updating user profile
class UpdateProfileParams {
  final String? name;
  final String? avatarUrl;

  UpdateProfileParams({
    this.name,
    this.avatarUrl,
  });
}

/// Use case for updating user profile
class UpdateProfileUseCase {
  final UserRepository repository;

  UpdateProfileUseCase(this.repository);

  /// Execute update profile
  /// Returns updated [User] on success, [Failure] on error
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    // Validate at least one field is provided
    if (params.name == null && params.avatarUrl == null) {
      return const Left(
        ValidationFailure(message: 'At least one field must be provided'),
      );
    }

    // Validate name if provided
    if (params.name != null && params.name!.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'Name cannot be empty'),
      );
    }

    // Validate name length
    if (params.name != null && params.name!.length > 100) {
      return const Left(
        ValidationFailure(message: 'Name cannot exceed 100 characters'),
      );
    }

    return await repository.updateProfile(
      name: params.name,
      avatarUrl: params.avatarUrl,
    );
  }
}
