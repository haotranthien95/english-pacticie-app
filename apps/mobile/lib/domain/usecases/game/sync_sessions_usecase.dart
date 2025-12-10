import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/game_repository.dart';

/// Use case for syncing pending sessions to backend
class SyncSessionsUseCase {
  final GameRepository repository;

  SyncSessionsUseCase(this.repository);

  /// Execute sync pending sessions
  /// Returns number of synced sessions on success, [Failure] on error
  Future<Either<Failure, int>> call() async {
    // Check connectivity first
    final isConnected = await repository.isConnected();
    if (!isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    return await repository.syncPendingSessions();
  }
}
