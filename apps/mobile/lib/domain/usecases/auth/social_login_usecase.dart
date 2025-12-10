import 'package:dartz/dartz.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case for social authentication (Google, Apple, Facebook)
class SocialLoginUseCase {
  final AuthRepository repository;

  SocialLoginUseCase(this.repository);

  /// Execute social login with specified provider
  /// Acquires OAuth token from Firebase, exchanges for backend JWT
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> call({
    required AuthProvider provider,
  }) async {
    // Validate provider is a social provider
    if (provider == AuthProvider.email) {
      return const Left(
        ValidationFailure(
            message: 'Email provider is not valid for social login'),
      );
    }

    return await repository.socialLogin(provider: provider);
  }
}
