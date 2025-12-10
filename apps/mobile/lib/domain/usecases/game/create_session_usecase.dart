import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/game_session.dart';
import '../../repositories/game_repository.dart';

/// Use case for creating a new game session
class CreateSessionUseCase {
  final GameRepository repository;

  CreateSessionUseCase(this.repository);

  /// Execute create session (saves locally first, then syncs)
  /// Returns created [GameSession] on success, [Failure] on error
  Future<Either<Failure, GameSession>> call(GameSession session) async {
    // Validate session
    if (session.results.isEmpty) {
      return const Left(
          ValidationFailure(message: 'Session must have at least one result'));
    }
    if (session.totalSpeeches != session.results.length) {
      return const Left(ValidationFailure(
          message: 'Total speeches must match results count'));
    }
    if (!session.isComplete) {
      return const Left(
          ValidationFailure(message: 'Session must be completed'));
    }

    return await repository.createSession(session);
  }
}
