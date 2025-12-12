import 'dart:async';
import 'package:hive/hive.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/game_session_model.dart';
import '../../models/tag_model.dart';
import '../../models/speech_model.dart';

/// Local data source for game data using Hive storage
abstract class GameLocalDataSource {
  /// Save a game session to local storage
  Future<GameSessionModel> saveSession(GameSessionModel session);

  /// Get all sessions with optional filters
  Future<List<GameSessionModel>> getSessions({
    String? userId,
    GameMode? mode,
    SpeechLevel? level,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  });

  /// Get a specific session by ID
  Future<GameSessionModel> getSessionById(String id);

  /// Get all pending sessions that need to be synced
  Future<List<GameSessionModel>> getPendingSessions();

  /// Update session sync status
  Future<void> updateSessionSyncStatus(String id, SyncStatus status);

  /// Delete a session
  Future<void> deleteSession(String id);

  /// Cache tags locally
  Future<void> cacheTags(List<TagModel> tags);

  /// Get cached tags
  Future<List<TagModel>> getCachedTags();

  /// Cache speeches locally
  Future<void> cacheSpeeches(List<SpeechModel> speeches);

  /// Get cached speeches
  Future<List<SpeechModel>> getCachedSpeeches({
    SpeechLevel? level,
    SpeechType? type,
    List<String>? tagIds,
  });
}

class GameLocalDataSourceImpl implements GameLocalDataSource {
  final Box<dynamic> gameBox;
  final Box<dynamic> cacheBox;

  // Storage keys
  static const String _sessionsKey = 'sessions';
  static const String _tagsKey = 'tags';
  static const String _speechesKey = 'speeches';

  GameLocalDataSourceImpl({
    required this.gameBox,
    required this.cacheBox,
  });

  @override
  Future<GameSessionModel> saveSession(GameSessionModel session) async {
    try {
      final sessions = await _getAllSessionsMap();
      sessions[session.id] = session.toJson();
      await gameBox.put(_sessionsKey, sessions);
      return session;
    } catch (e) {
      throw StorageException(message: 'Failed to save session: $e');
    }
  }

  @override
  Future<List<GameSessionModel>> getSessions({
    String? userId,
    GameMode? mode,
    SpeechLevel? level,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final sessions = await _getAllSessions();

      // Apply filters
      var filtered = sessions.where((session) {
        if (userId != null && session.userId != userId) return false;
        if (mode != null && session.mode != mode) return false;
        if (level != null && session.level != level) return false;
        if (startDate != null && session.startedAt.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && session.startedAt.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();

      // Sort by started date (newest first)
      filtered.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      // Apply pagination
      final start = offset;
      final end = (offset + limit).clamp(0, filtered.length);

      if (start >= filtered.length) return [];

      return filtered.sublist(start, end);
    } catch (e) {
      throw StorageException(message: 'Failed to get sessions: $e');
    }
  }

  @override
  Future<GameSessionModel> getSessionById(String id) async {
    try {
      final sessions = await _getAllSessionsMap();
      final sessionData = sessions[id];

      if (sessionData == null) {
        throw StorageException(message: 'Session not found: $id');
      }

      return GameSessionModel.fromJson(
        Map<String, dynamic>.from(sessionData as Map),
      );
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(message: 'Failed to get session: $e');
    }
  }

  @override
  Future<List<GameSessionModel>> getPendingSessions() async {
    try {
      final sessions = await _getAllSessions();
      return sessions
          .where((session) => session.syncStatus == SyncStatus.pending)
          .toList();
    } catch (e) {
      throw StorageException(message: 'Failed to get pending sessions: $e');
    }
  }

  @override
  Future<void> updateSessionSyncStatus(String id, SyncStatus status) async {
    try {
      final sessions = await _getAllSessionsMap();
      final sessionData = sessions[id];

      if (sessionData == null) {
        throw StorageException(message: 'Session not found: $id');
      }

      final session = GameSessionModel.fromJson(
        Map<String, dynamic>.from(sessionData as Map),
      );

      final updatedSession = session.copyWith(syncStatus: status);
      sessions[id] = updatedSession.toJson();
      await gameBox.put(_sessionsKey, sessions);
    } catch (e) {
      throw StorageException(message: 'Failed to update sync status: $e');
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      final sessions = await _getAllSessionsMap();
      sessions.remove(id);
      await gameBox.put(_sessionsKey, sessions);
    } catch (e) {
      throw StorageException(message: 'Failed to delete session: $e');
    }
  }

  @override
  Future<void> cacheTags(List<TagModel> tags) async {
    try {
      final tagsList = tags.map((tag) => tag.toJson()).toList();
      await cacheBox.put(_tagsKey, tagsList);
    } catch (e) {
      throw StorageException(message: 'Failed to cache tags: $e');
    }
  }

  @override
  Future<List<TagModel>> getCachedTags() async {
    try {
      final tagsData = cacheBox.get(_tagsKey);
      if (tagsData == null) return [];

      final tagsList = List<Map<String, dynamic>>.from(
        (tagsData as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      return tagsList.map((json) => TagModel.fromJson(json)).toList();
    } catch (e) {
      throw StorageException(message: 'Failed to get cached tags: $e');
    }
  }

  @override
  Future<void> cacheSpeeches(List<SpeechModel> speeches) async {
    try {
      final speechesList = speeches.map((speech) => speech.toJson()).toList();
      await cacheBox.put(_speechesKey, speechesList);
    } catch (e) {
      throw StorageException(message: 'Failed to cache speeches: $e');
    }
  }

  @override
  Future<List<SpeechModel>> getCachedSpeeches({
    SpeechLevel? level,
    SpeechType? type,
    List<String>? tagIds,
  }) async {
    try {
      final speechesData = cacheBox.get(_speechesKey);
      if (speechesData == null) return [];

      final speechesList = List<Map<String, dynamic>>.from(
        (speechesData as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );

      var speeches =
          speechesList.map((json) => SpeechModel.fromJson(json)).toList();

      // Apply filters
      if (level != null) {
        speeches = speeches.where((speech) => speech.level == level).toList();
      }
      if (type != null) {
        speeches = speeches.where((speech) => speech.type == type).toList();
      }
      if (tagIds != null && tagIds.isNotEmpty) {
        speeches = speeches.where((speech) {
          return speech.tagIds.any((tagId) => tagIds.contains(tagId));
        }).toList();
      }

      return speeches;
    } catch (e) {
      throw StorageException(message: 'Failed to get cached speeches: $e');
    }
  }

  // Helper methods

  Future<Map<String, dynamic>> _getAllSessionsMap() async {
    final sessionsData = gameBox.get(_sessionsKey);
    if (sessionsData == null) return {};
    return Map<String, dynamic>.from(sessionsData as Map);
  }

  Future<List<GameSessionModel>> _getAllSessions() async {
    final sessionsMap = await _getAllSessionsMap();
    return sessionsMap.values
        .map((data) => GameSessionModel.fromJson(
              Map<String, dynamic>.from(data as Map),
            ))
        .toList();
  }
}
