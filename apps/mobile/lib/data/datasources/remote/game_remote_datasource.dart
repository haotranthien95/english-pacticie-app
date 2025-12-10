import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/enums.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/game_session_model.dart';
import '../../models/speech_model.dart';
import '../../models/tag_model.dart';

/// Remote data source for game data using REST API
abstract class GameRemoteDataSource {
  /// Fetch all available tags
  Future<List<TagModel>> getTags();

  /// Fetch random speeches based on filters
  Future<List<SpeechModel>> getRandomSpeeches({
    required SpeechLevel level,
    required SpeechType type,
    List<String>? tagIds,
    int count = 10,
  });

  /// Create a new game session on the backend
  Future<String> createSession(GameSessionModel session);

  /// Sync multiple sessions to the backend
  Future<int> syncSessions(List<GameSessionModel> sessions);
}

class GameRemoteDataSourceImpl implements GameRemoteDataSource {
  final Dio dio;

  GameRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<TagModel>> getTags() async {
    try {
      final response = await dio.get(ApiEndpoints.tags);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data
            .map((json) => TagModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch tags: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error fetching tags: $e');
    }
  }

  @override
  Future<List<SpeechModel>> getRandomSpeeches({
    required SpeechLevel level,
    required SpeechType type,
    List<String>? tagIds,
    int count = 10,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.randomSpeeches,
        data: {
          'level': level.value,
          'type': type.value,
          if (tagIds != null && tagIds.isNotEmpty) 'tag_ids': tagIds,
          'count': count,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] as List;
        return data
            .map((json) => SpeechModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch speeches: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error fetching speeches: $e');
    }
  }

  @override
  Future<String> createSession(GameSessionModel session) async {
    try {
      final response = await dio.post(
        ApiEndpoints.createSession,
        data: session.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data']['id'] as String;
      } else {
        throw ServerException(
          message: 'Failed to create session: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Unexpected error creating session: $e');
    }
  }

  @override
  Future<int> syncSessions(List<GameSessionModel> sessions) async {
    int syncedCount = 0;
    final List<String> failedSessionIds = [];

    for (final session in sessions) {
      try {
        await _syncSessionWithRetry(session);
        syncedCount++;
      } catch (e) {
        failedSessionIds.add(session.id);
      }
    }

    if (failedSessionIds.isNotEmpty) {
      throw ServerException(
        message: 'Failed to sync ${failedSessionIds.length} sessions: '
            '${failedSessionIds.join(", ")}',
      );
    }

    return syncedCount;
  }

  /// Sync a single session with exponential backoff retry (1s, 2s, 4s, 8s)
  Future<void> _syncSessionWithRetry(GameSessionModel session) async {
    const retryDelays = [1, 2, 4, 8]; // Exponential backoff in seconds
    int attempt = 0;

    while (attempt < retryDelays.length) {
      try {
        await createSession(session);
        return; // Success, exit retry loop
      } catch (e) {
        attempt++;
        if (attempt >= retryDelays.length) {
          rethrow; // Max retries reached, throw the error
        }
        // Wait before next retry
        await Future.delayed(Duration(seconds: retryDelays[attempt - 1]));
      }
    }

    // If we reach here, all retries failed
    throw ServerException(
      message: 'Failed to sync session after ${retryDelays.length} attempts',
    );
  }

  /// Handle Dio errors and convert to appropriate exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Connection timeout');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] as String?;

        if (statusCode == 401) {
          return UnauthorizedException(
            message: message ?? 'Unauthorized access',
          );
        } else if (statusCode == 404) {
          return ServerException(message: message ?? 'Resource not found');
        } else if (statusCode == 422) {
          return ValidationException(
            message: message ?? 'Validation failed',
          );
        } else {
          return ServerException(
            message: message ?? 'Server error: $statusCode',
          );
        }

      case DioExceptionType.cancel:
        return NetworkException(message: 'Request cancelled');

      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          return NetworkException(message: 'No internet connection');
        }
        return NetworkException(message: 'Network error: ${error.message}');

      default:
        return ServerException(message: 'Unexpected error: ${error.message}');
    }
  }
}
