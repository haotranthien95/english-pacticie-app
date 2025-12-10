import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';

/// Use case for user logout
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// Execute logout
  /// Clears local token and Firebase session
  /// Returns [Unit] on success, [Failure] on error
  Future<Either<Failure, Unit>> call() async {
    return await repository.logout();
  }
}
