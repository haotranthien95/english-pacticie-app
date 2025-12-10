import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/entities/game_result.dart';
import '../../../domain/entities/game_session.dart';
import '../../../domain/entities/speech.dart';
import '../../../data/datasources/remote/speech_remote_datasource.dart';

/// States for Game BLoC
abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class GameInitial extends GameState {
  const GameInitial();
}

/// Loading speeches from backend
class GameLoading extends GameState {
  const GameLoading();
}

/// Game is ready with speeches loaded
class GameReady extends GameState {
  final List<Speech> speeches;
  final int currentIndex;
  final List<GameResult> results;
  final int streakCount;
  final GameMode mode;
  final bool isAudioPlaying;

  const GameReady({
    required this.speeches,
    required this.currentIndex,
    required this.results,
    required this.streakCount,
    required this.mode,
    this.isAudioPlaying = false,
  });

  /// Get current speech
  Speech get currentSpeech => speeches[currentIndex];

  /// Check if game is complete
  bool get isComplete => currentIndex >= speeches.length;

  /// Calculate accuracy percentage
  double get accuracy {
    if (results.isEmpty) return 0.0;
    final correctCount = results.where((r) => r.correct).length;
    return (correctCount / results.length) * 100;
  }

  @override
  List<Object?> get props => [
        speeches,
        currentIndex,
        results,
        streakCount,
        mode,
        isAudioPlaying,
      ];

  GameReady copyWith({
    List<Speech>? speeches,
    int? currentIndex,
    List<GameResult>? results,
    int? streakCount,
    GameMode? mode,
    bool? isAudioPlaying,
    bool? isRecording,
  }) {
    return GameReady(
      speeches: speeches ?? this.speeches,
      currentIndex: currentIndex ?? this.currentIndex,
      results: results ?? this.results,
      streakCount: streakCount ?? this.streakCount,
      mode: mode ?? this.mode,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
    );
  }
}

/// Recording audio for pronunciation scoring
class GameRecording extends GameState {
  final GameReady previousState;

  const GameRecording(this.previousState);

  @override
  List<Object?> get props => [previousState];
}

/// Uploading audio and waiting for pronunciation score
class GameTranscribing extends GameState {
  final GameReady previousState;

  const GameTranscribing(this.previousState);

  @override
  List<Object?> get props => [previousState];
}

/// Pronunciation score received and displayed
class GameScoreReady extends GameState {
  final GameReady previousState;
  final SpeechScoreResponse scoreResponse;

  const GameScoreReady({
    required this.previousState,
    required this.scoreResponse,
  });

  @override
  List<Object?> get props => [previousState, scoreResponse];
}


/// Game is paused
class GamePaused extends GameState {
  final GameReady previousState;

  const GamePaused(this.previousState);

  @override
  List<Object?> get props => [previousState];
}

/// Saving game session
class GameSaving extends GameState {
  final List<GameResult> results;

  const GameSaving(this.results);

  @override
  List<Object?> get props => [results];
}

/// Game completed and session saved
class GameCompleted extends GameState {
  final GameSession session;

  const GameCompleted(this.session);

  @override
  List<Object?> get props => [session];
}

/// Error occurred during game
class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}
