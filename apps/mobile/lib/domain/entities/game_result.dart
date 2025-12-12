import 'package:equatable/equatable.dart';

/// GameResult entity representing a single speech result within a session
/// Domain layer - pure business logic
class GameResult extends Equatable {
  final String speechId;
  final bool correct;
  final double? pronunciationScore;
  final String? transcribedText;
  final Map<String, double>? wordScores;
  final DateTime timestamp;

  const GameResult({
    required this.speechId,
    required this.correct,
    this.pronunciationScore,
    this.transcribedText,
    this.wordScores,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        speechId,
        correct,
        pronunciationScore,
        transcribedText,
        wordScores,
        timestamp,
      ];

  @override
  String toString() {
    return 'GameResult(speechId: $speechId, correct: $correct, score: $pronunciationScore)';
  }

  GameResult copyWith({
    String? speechId,
    bool? correct,
    double? pronunciationScore,
    String? transcribedText,
    Map<String, double>? wordScores,
    DateTime? timestamp,
  }) {
    return GameResult(
      speechId: speechId ?? this.speechId,
      correct: correct ?? this.correct,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      transcribedText: transcribedText ?? this.transcribedText,
      wordScores: wordScores ?? this.wordScores,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
