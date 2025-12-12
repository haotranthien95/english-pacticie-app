import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case for user login with email and password
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Execute login with email and password
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) {
      return const Left(ValidationFailure(message: 'Email cannot be empty'));
    }
    if (password.isEmpty) {
      return const Left(ValidationFailure(message: 'Password cannot be empty'));
    }
    if (!_isValidEmail(email)) {
      return const Left(ValidationFailure(message: 'Invalid email format'));
    }

    return await repository.login(email: email, password: password);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
