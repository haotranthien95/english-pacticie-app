import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/entities/speech.dart';
import '../../../data/datasources/remote/speech_remote_datasource.dart';

/// Events for Game BLoC
abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start game with configuration
class GameStarted extends GameEvent {
  final GameMode mode;
  final SpeechLevel level;
  final SpeechType type;
  final List<String> tagIds;
  final int count;

  const GameStarted({
    required this.mode,
    required this.level,
    required this.type,
    required this.tagIds,
    required this.count,
  });

  @override
  List<Object?> get props => [mode, level, type, tagIds, count];
}

/// Event when user swipes left (incorrect)
class SwipeLeftRequested extends GameEvent {
  const SwipeLeftRequested();
}

/// Event when user swipes right (correct)
class SwipeRightRequested extends GameEvent {
  const SwipeRightRequested();
}

/// Event to replay current speech audio
class AudioReplayRequested extends GameEvent {
  const AudioReplayRequested();
}

/// Event to pause game
class GamePaused extends GameEvent {
  const GamePaused();
}

/// Event to resume game
class GameResumed extends GameEvent {
  const GameResumed();
}

/// Event to quit game early
class GameQuitRequested extends GameEvent {
  const GameQuitRequested();
}

/// Event to save and complete game session
class GameCompletionRequested extends GameEvent {
  const GameCompletionRequested();
}

/// Event when audio finishes playing
class AudioPlaybackCompleted extends GameEvent {
  const AudioPlaybackCompleted();
}

/// Event to start recording audio for pronunciation scoring
class RecordingStarted extends GameEvent {
  const RecordingStarted();
}

/// Event to stop recording and upload audio for scoring
class RecordingStopped extends GameEvent {
  const RecordingStopped();
}

/// Event when pronunciation score is received from API
class ScoreReceived extends GameEvent {
  final SpeechScoreResponse scoreResponse;

  const ScoreReceived({required this.scoreResponse});

  @override
  List<Object?> get props => [scoreResponse];
}

/// Event to acknowledge score and move to next speech
class ScoreAcknowledged extends GameEvent {
  const ScoreAcknowledged();
}

/// Event to cancel ongoing recording
class RecordingCancelled extends GameEvent {
  const RecordingCancelled();
}
