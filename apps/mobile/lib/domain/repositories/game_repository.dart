import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/failures.dart';
import '../entities/tag.dart';
import '../entities/speech.dart';
import '../entities/game_session.dart';

/// Game repository contract
/// Defines all game-related operations
abstract class GameRepository {
  /// Get all available tags
  /// Returns list of [Tag] on success, [Failure] on error
  Future<Either<Failure, List<Tag>>> getTags();

  /// Get random speeches based on filters
  /// Returns list of [Speech] on success, [Failure] on error
  Future<Either<Failure, List<Speech>>> getRandomSpeeches({
    required SpeechLevel level,
    required SpeechType type,
    List<String>? tagIds,
    int count = 10,
  });

  /// Create a new game session (saves locally first, then syncs)
  /// Returns created [GameSession] on success, [Failure] on error
  Future<Either<Failure, GameSession>> createSession(GameSession session);

  /// Sync pending sessions to backend
  /// Returns number of synced sessions on success, [Failure] on error
  Future<Either<Failure, int>> syncPendingSessions();

  /// Get all game sessions (from local storage)
  /// Returns list of [GameSession] on success, [Failure] on error
  Future<Either<Failure, List<GameSession>>> getSessions({
    GameMode? mode,
    SpeechLevel? level,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  });

  /// Get single session detail by ID
  /// Returns [GameSession] on success, [Failure] on error
  Future<Either<Failure, GameSession>> getSessionById(String id);

  /// Check connectivity status
  /// Returns true if connected, false otherwise
  Future<bool> isConnected();
}
