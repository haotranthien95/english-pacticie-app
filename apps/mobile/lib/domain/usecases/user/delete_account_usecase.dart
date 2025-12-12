import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/user_repository.dart';

/// Use case for deleting user account
class DeleteAccountUseCase {
  final UserRepository repository;

  DeleteAccountUseCase(this.repository);

  /// Execute delete account
  /// Returns [void] on success, [Failure] on error
  /// This is a destructive action and should require confirmation
  Future<Either<Failure, void>> call() async {
    return await repository.deleteAccount();
  }
}
