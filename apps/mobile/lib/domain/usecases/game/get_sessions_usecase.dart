import 'package:dartz/dartz.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/failures.dart';
import '../../entities/game_session.dart';
import '../../repositories/game_repository.dart';

/// Use case for fetching game sessions with filters
class GetSessionsUseCase {
  final GameRepository repository;

  GetSessionsUseCase(this.repository);

  /// Execute get sessions with filters
  /// Returns list of [GameSession] on success, [Failure] on error
  Future<Either<Failure, List<GameSession>>> call({
    GameMode? mode,
    SpeechLevel? level,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    // Validate inputs
    if (limit <= 0) {
      return const Left(
          ValidationFailure(message: 'Limit must be greater than 0'));
    }
    if (offset < 0) {
      return const Left(
          ValidationFailure(message: 'Offset cannot be negative'));
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      return const Left(
          ValidationFailure(message: 'Start date must be before end date'));
    }

    return await repository.getSessions(
      mode: mode,
      level: level,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }
}
