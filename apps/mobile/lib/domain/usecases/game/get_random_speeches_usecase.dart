import 'package:dartz/dartz.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/failures.dart';
import '../../entities/speech.dart';
import '../../repositories/game_repository.dart';

/// Use case for fetching random speeches with filters
class GetRandomSpeechesUseCase {
  final GameRepository repository;

  GetRandomSpeechesUseCase(this.repository);

  /// Execute get random speeches with filters
  /// Returns list of [Speech] on success, [Failure] on error
  Future<Either<Failure, List<Speech>>> call({
    required SpeechLevel level,
    required SpeechType type,
    List<String>? tagIds,
    int count = 10,
  }) async {
    // Validate inputs
    if (count <= 0) {
      return const Left(
          ValidationFailure(message: 'Count must be greater than 0'));
    }
    if (count > 50) {
      return const Left(ValidationFailure(message: 'Count cannot exceed 50'));
    }

    return await repository.getRandomSpeeches(
      level: level,
      type: type,
      tagIds: tagIds,
      count: count,
    );
  }
}
