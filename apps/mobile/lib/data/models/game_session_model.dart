import '../../core/constants/enums.dart';
import '../../domain/entities/game_session.dart';
import 'game_result_model.dart';

/// GameSession model for data layer with JSON serialization
class GameSessionModel extends GameSession {
  const GameSessionModel({
    required super.id,
    required super.userId,
    required super.mode,
    required super.level,
    required super.type,
    required super.tagIds,
    required super.results,
    required super.totalSpeeches,
    required super.correctCount,
    required super.incorrectCount,
    super.averageScore,
    required super.streakCount,
    required super.startedAt,
    super.completedAt,
    required super.syncStatus,
  });

  /// Create GameSessionModel from JSON response
  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mode: GameModeExtension.fromValue(json['mode'] as String),
      level: SpeechLevelExtension.fromValue(json['level'] as String),
      type: SpeechTypeExtension.fromValue(json['type'] as String),
      tagIds:
          (json['tag_ids'] as List<dynamic>).map((e) => e as String).toList(),
      results: (json['results'] as List<dynamic>)
          .map((e) => GameResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSpeeches: json['total_speeches'] as int,
      correctCount: json['correct_count'] as int,
      incorrectCount: json['incorrect_count'] as int,
      averageScore: json['average_score'] as double?,
      streakCount: json['streak_count'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      syncStatus: SyncStatusExtension.fromValue(
        json['sync_status'] as String? ?? 'pending',
      ),
    );
  }

  /// Convert GameSessionModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mode': mode.value,
      'level': level.value,
      'type': type.value,
      'tag_ids': tagIds,
      'results': results.map((r) => (r as GameResultModel).toJson()).toList(),
      'total_speeches': totalSpeeches,
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
      'average_score': averageScore,
      'streak_count': streakCount,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'sync_status': syncStatus.value,
    };
  }

  /// Create GameSessionModel from GameSession entity
  factory GameSessionModel.fromEntity(GameSession session) {
    return GameSessionModel(
      id: session.id,
      userId: session.userId,
      mode: session.mode,
      level: session.level,
      type: session.type,
      tagIds: session.tagIds,
      results:
          session.results.map((r) => GameResultModel.fromEntity(r)).toList(),
      totalSpeeches: session.totalSpeeches,
      correctCount: session.correctCount,
      incorrectCount: session.incorrectCount,
      averageScore: session.averageScore,
      streakCount: session.streakCount,
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      syncStatus: session.syncStatus,
    );
  }

  @override
  GameSessionModel copyWith({
    String? id,
    String? userId,
    GameMode? mode,
    SpeechLevel? level,
    SpeechType? type,
    List<String>? tagIds,
    List? results,
    int? totalSpeeches,
    int? correctCount,
    int? incorrectCount,
    double? averageScore,
    int? streakCount,
    DateTime? startedAt,
    DateTime? completedAt,
    SyncStatus? syncStatus,
  }) {
    return GameSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      type: type ?? this.type,
      tagIds: tagIds ?? this.tagIds,
      results: results as List<GameResultModel>? ??
          this.results as List<GameResultModel>,
      totalSpeeches: totalSpeeches ?? this.totalSpeeches,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      averageScore: averageScore ?? this.averageScore,
      streakCount: streakCount ?? this.streakCount,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
