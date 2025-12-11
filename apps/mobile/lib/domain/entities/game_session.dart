import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';
import 'game_result.dart';

/// GameSession entity representing a complete game session
/// Domain layer - pure business logic
class GameSession extends Equatable {
  final String id;
  final String userId;
  final GameMode mode;
  final SpeechLevel level;
  final SpeechType type;
  final List<String> tagIds;
  final List<GameResult> results;
  final int totalSpeeches;
  final int correctCount;
  final int incorrectCount;
  final double? averageScore;
  final int streakCount;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SyncStatus syncStatus;

  const GameSession({
    required this.id,
    required this.userId,
    required this.mode,
    required this.level,
    required this.type,
    required this.tagIds,
    required this.results,
    required this.totalSpeeches,
    required this.correctCount,
    required this.incorrectCount,
    this.averageScore,
    required this.streakCount,
    required this.startedAt,
    this.completedAt,
    required this.syncStatus,
  });

  /// Calculate accuracy percentage
  double get accuracy {
    if (totalSpeeches == 0) return 0.0;
    return (correctCount / totalSpeeches) * 100;
  }

  /// Check if session is complete
  bool get isComplete => completedAt != null;

  /// Get session duration
  Duration get duration {
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Get createdAt timestamp (alias for startedAt for compatibility)
  DateTime get createdAt => startedAt;

  /// Check if session needs sync
  bool get needsSync =>
      syncStatus == SyncStatus.pending || syncStatus == SyncStatus.failed;

  @override
  List<Object?> get props => [
        id,
        userId,
        mode,
        level,
        type,
        tagIds,
        results,
        totalSpeeches,
        correctCount,
        incorrectCount,
        averageScore,
        streakCount,
        startedAt,
        completedAt,
        syncStatus,
      ];

  @override
  String toString() {
    return 'GameSession(id: $id, mode: $mode, correct: $correctCount/$totalSpeeches, sync: $syncStatus)';
  }

  GameSession copyWith({
    String? id,
    String? userId,
    GameMode? mode,
    SpeechLevel? level,
    SpeechType? type,
    List<String>? tagIds,
    List<GameResult>? results,
    int? totalSpeeches,
    int? correctCount,
    int? incorrectCount,
    double? averageScore,
    int? streakCount,
    DateTime? startedAt,
    DateTime? completedAt,
    SyncStatus? syncStatus,
  }) {
    return GameSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      type: type ?? this.type,
      tagIds: tagIds ?? this.tagIds,
      results: results ?? this.results,
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
