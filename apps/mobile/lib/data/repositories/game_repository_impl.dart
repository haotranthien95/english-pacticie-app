import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import '../../core/constants/enums.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/speech.dart';
import '../../domain/entities/tag.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/local/game_local_datasource.dart';
import '../datasources/remote/game_remote_datasource.dart';
import '../models/game_session_model.dart';
import '../models/speech_model.dart';
import '../models/tag_model.dart';

/// Implementation of GameRepository with offline-first strategy
class GameRepositoryImpl implements GameRepository {
  final GameLocalDataSource localDataSource;
  final GameRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  GameRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  @override
  Future<Either<Failure, List<Tag>>> getTags() async {
    try {
      // Try to fetch from remote first
      if (await isConnected()) {
        final tags = await remoteDataSource.getTags();
        // Cache for offline use
        await localDataSource.cacheTags(tags);
        return Right(tags);
      } else {
        // Fallback to cached tags
        final cachedTags = await localDataSource.getCachedTags();
        if (cachedTags.isEmpty) {
          return Left(NetworkFailure(message: 'No internet and no cached tags'));
        }
        return Right(cachedTags);
      }
    } on NetworkException catch (e) {
      // Try cached tags on network error
      try {
        final cachedTags = await localDataSource.getCachedTags();
        if (cachedTags.isEmpty) {
          return Left(NetworkFailure(message: e.message));
        }
        return Right(cachedTags);
      } catch (_) {
        return Left(NetworkFailure(message: e.message));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get tags: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Speech>>> getRandomSpeeches({
    required SpeechLevel level,
    required SpeechType type,
    List<String>? tagIds,
    int count = 10,
  }) async {
    try {
      // Try to fetch from remote first
      if (await isConnected()) {
        final speeches = await remoteDataSource.getRandomSpeeches(
          level: level,
          type: type,
          tagIds: tagIds,
          count: count,
        );
        // Cache for offline use
        await localDataSource.cacheSpeeches(speeches);
        return Right(speeches);
      } else {
        // Fallback to cached speeches
        final cachedSpeeches = await localDataSource.getCachedSpeeches(
          level: level,
          type: type,
          tagIds: tagIds,
        );
        if (cachedSpeeches.isEmpty) {
          return Left(
            NetworkFailure(message: 'No internet and no cached speeches'),
          );
        }
        // Return up to 'count' random speeches from cache
        final shuffled = List<SpeechModel>.from(cachedSpeeches)..shuffle();
        final result = shuffled.take(count).toList();
        return Right(result);
      }
    } on NetworkException catch (e) {
      // Try cached speeches on network error
      try {
        final cachedSpeeches = await localDataSource.getCachedSpeeches(
          level: level,
          type: type,
          tagIds: tagIds,
        );
        if (cachedSpeeches.isEmpty) {
          return Left(NetworkFailure(message: e.message));
        }
        final shuffled = List<SpeechModel>.from(cachedSpeeches)..shuffle();
        final result = shuffled.take(count).toList();
        return Right(result);
      } catch (_) {
        return Left(NetworkFailure(message: e.message));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get speeches: $e'));
    }
  }

  @override
  Future<Either<Failure, GameSession>> createSession(
    GameSession session,
  ) async {
    try {
      // Convert to model
      final sessionModel = GameSessionModel.fromEntity(session);

      // Always save locally first (offline-first strategy)
      final savedSession = await localDataSource.saveSession(
        sessionModel.copyWith(syncStatus: SyncStatus.pending),
      );

      // Try to sync immediately if online
      if (await isConnected()) {
        try {
          await remoteDataSource.createSession(savedSession);
          // Update sync status to synced
          await localDataSource.updateSessionSyncStatus(
            savedSession.id,
            SyncStatus.synced,
          );
          return Right(
            savedSession.copyWith(syncStatus: SyncStatus.synced),
          );
        } catch (e) {
          // Sync failed, but session is saved locally
          // Will be synced later automatically
          return Right(savedSession);
        }
      } else {
        // Offline, return saved session with pending status
        return Right(savedSession);
      }
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to create session: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> syncPendingSessions() async {
    try {
      if (!await isConnected()) {
        return Left(
          NetworkFailure(message: 'Cannot sync: no internet connection'),
        );
      }

      // Get all pending sessions
      final pendingSessions = await localDataSource.getPendingSessions();

      if (pendingSessions.isEmpty) {
        return const Right(0);
      }

      // Update all to syncing status
      for (final session in pendingSessions) {
        await localDataSource.updateSessionSyncStatus(
          session.id,
          SyncStatus.syncing,
        );
      }

      // Attempt to sync all sessions
      try {
        final syncedCount = await remoteDataSource.syncSessions(
          pendingSessions,
        );

        // Update all synced sessions
        for (final session in pendingSessions) {
          await localDataSource.updateSessionSyncStatus(
            session.id,
            SyncStatus.synced,
          );
        }

        return Right(syncedCount);
      } catch (e) {
        // Mark failed sessions
        for (final session in pendingSessions) {
          await localDataSource.updateSessionSyncStatus(
            session.id,
            SyncStatus.failed,
          );
        }
        return Left(ServerFailure(message: 'Failed to sync sessions: $e'));
      }
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to sync sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<GameSession>>> getSessions({
    String? userId,
    GameMode? mode,
    SpeechLevel? level,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final sessions = await localDataSource.getSessions(
        userId: userId,
        mode: mode,
        level: level,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      return Right(sessions);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, GameSession>> getSessionById(String id) async {
    try {
      final session = await localDataSource.getSessionById(id);
      return Right(session);
    } on StorageException catch (e) {
      return Left(StorageFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: 'Failed to get session: $e'));
    }
  }

  @override
  Future<bool> isConnected() async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet,
    );
  }
}
