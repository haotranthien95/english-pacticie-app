import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

/// Use case for fetching user profile
class GetProfileUseCase {
  final UserRepository repository;

  GetProfileUseCase(this.repository);

  /// Execute get profile
  /// Returns [User] on success, [Failure] on error
  Future<Either<Failure, User>> call() async {
    return await repository.getProfile();
  }
}
