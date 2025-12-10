import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case for getting currently authenticated user
class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  /// Get currently authenticated user from local storage
  /// Returns [User] if token valid, [AuthFailure] if not authenticated
  Future<Either<Failure, User>> call() async {
    return await repository.getCurrentUser();
  }
}
