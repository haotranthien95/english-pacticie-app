import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/game_session.dart';
import '../../repositories/game_repository.dart';

/// Use case for fetching single session by ID
class GetSessionDetailUseCase {
  final GameRepository repository;

  GetSessionDetailUseCase(this.repository);

  /// Execute get session by ID
  /// Returns [GameSession] on success, [Failure] on error
  Future<Either<Failure, GameSession>> call(String id) async {
    if (id.isEmpty) {
      return const Left(
          ValidationFailure(message: 'Session ID cannot be empty'));
    }

    return await repository.getSessionById(id);
  }
}
