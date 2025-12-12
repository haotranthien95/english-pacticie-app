import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case for user registration with email and password
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Execute registration with email, password, and username
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    // Validate inputs
    if (email.isEmpty) {
      return const Left(ValidationFailure(message: 'Email cannot be empty'));
    }
    if (password.isEmpty) {
      return const Left(ValidationFailure(message: 'Password cannot be empty'));
    }
    if (username.isEmpty) {
      return const Left(ValidationFailure(message: 'Username cannot be empty'));
    }
    if (!_isValidEmail(email)) {
      return const Left(ValidationFailure(message: 'Invalid email format'));
    }
    if (password.length < 8) {
      return const Left(
        ValidationFailure(message: 'Password must be at least 8 characters'),
      );
    }
    if (username.length < 3) {
      return const Left(
        ValidationFailure(message: 'Username must be at least 3 characters'),
      );
    }

    return await repository.register(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
