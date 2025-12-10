import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/tag.dart';
import '../../repositories/game_repository.dart';

/// Use case for fetching all available tags
class GetTagsUseCase {
  final GameRepository repository;

  GetTagsUseCase(this.repository);

  /// Execute get tags
  /// Returns list of [Tag] on success, [Failure] on error
  Future<Either<Failure, List<Tag>>> call() async {
    return await repository.getTags();
  }
}
