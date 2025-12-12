import '../../domain/entities/game_result.dart';

/// GameResult model for data layer with JSON serialization
class GameResultModel extends GameResult {
  const GameResultModel({
    required super.speechId,
    required super.correct,
    super.pronunciationScore,
    super.transcribedText,
    super.wordScores,
    required super.timestamp,
  });

  /// Create GameResultModel from JSON response
  factory GameResultModel.fromJson(Map<String, dynamic> json) {
    return GameResultModel(
      speechId: json['speech_id'] as String,
      correct: json['correct'] as bool,
      pronunciationScore: json['pronunciation_score'] as double?,
      transcribedText: json['transcribed_text'] as String?,
      wordScores: json['word_scores'] != null
          ? Map<String, double>.from(json['word_scores'] as Map)
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert GameResultModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'speech_id': speechId,
      'correct': correct,
      'pronunciation_score': pronunciationScore,
      'transcribed_text': transcribedText,
      'word_scores': wordScores,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create GameResultModel from GameResult entity
  factory GameResultModel.fromEntity(GameResult result) {
    return GameResultModel(
      speechId: result.speechId,
      correct: result.correct,
      pronunciationScore: result.pronunciationScore,
      transcribedText: result.transcribedText,
      wordScores: result.wordScores,
      timestamp: result.timestamp,
    );
  }

  @override
  GameResultModel copyWith({
    String? speechId,
    bool? correct,
    double? pronunciationScore,
    String? transcribedText,
    Map<String, double>? wordScores,
    DateTime? timestamp,
  }) {
    return GameResultModel(
      speechId: speechId ?? this.speechId,
      correct: correct ?? this.correct,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      transcribedText: transcribedText ?? this.transcribedText,
      wordScores: wordScores ?? this.wordScores,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
