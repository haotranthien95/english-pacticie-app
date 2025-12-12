import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/enums.dart';
import '../../../data/datasources/local/audio_player_service.dart';
import '../../../data/datasources/local/audio_recorder_service.dart';
import '../../../data/datasources/remote/speech_remote_datasource.dart';
import '../../../domain/entities/game_result.dart';
import '../../../domain/entities/game_session.dart';
import '../../../domain/usecases/game/create_session_usecase.dart';
import '../../../domain/usecases/game/get_random_speeches_usecase.dart';
import 'game_event.dart';
import 'game_state.dart';

/// BLoC for managing game play (listen-only and listen-and-repeat modes)
class GameBloc extends Bloc<GameEvent, GameState> {
  final GetRandomSpeechesUseCase getRandomSpeechesUseCase;
  final CreateSessionUseCase createSessionUseCase;
  final AudioPlayerService audioPlayerService;
  final AudioRecorderService audioRecorderService;
  final SpeechRemoteDataSource speechRemoteDataSource;
  final String userId;

  StreamSubscription? _audioSubscription;
  Uint8List? _recordedAudioBytes;

  GameBloc({
    required this.getRandomSpeechesUseCase,
    required this.createSessionUseCase,
    required this.audioPlayerService,
    required this.audioRecorderService,
    required this.speechRemoteDataSource,
    required this.userId,
  }) : super(const GameInitial()) {
    on<GameStarted>(_onGameStarted);
    on<SwipeLeftRequested>(_onSwipeLeftRequested);
    on<SwipeRightRequested>(_onSwipeRightRequested);
    on<AudioReplayRequested>(_onAudioReplayRequested);
    on<GamePauseRequested>(_onGamePaused);
    on<GameResumed>(_onGameResumed);
    on<GameQuitRequested>(_onGameQuitRequested);
    on<GameCompletionRequested>(_onGameCompletionRequested);
    on<AudioPlaybackCompleted>(_onAudioPlaybackCompleted);
    on<RecordingStarted>(_onRecordingStarted);
    on<RecordingStopped>(_onRecordingStopped);
    on<ScoreReceived>(_onScoreReceived);
    on<ScoreAcknowledged>(_onScoreAcknowledged);
    on<RecordingCancelled>(_onRecordingCancelled);
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading());

    // Fetch speeches
    final result = await getRandomSpeechesUseCase(
      level: event.level,
      type: event.type,
      tagIds: event.tagIds.isEmpty ? null : event.tagIds,
      count: event.count,
    );

    await result.fold(
      (failure) async {
        emit(GameError(failure.message));
      },
      (speeches) async {
        // Start game with first speech
        final gameState = GameReady(
          speeches: speeches,
          currentIndex: 0,
          results: [],
          streakCount: 0,
          mode: event.mode,
        );

        emit(gameState);

        // Auto-play first speech
        await _playCurrentSpeech(gameState);
        emit(gameState.copyWith(isAudioPlaying: true));
      },
    );
  }

  Future<void> _onSwipeLeftRequested(
    SwipeLeftRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GameReady) return;

    final currentState = state as GameReady;
    await _handleAnswer(currentState, false, emit);
  }

  Future<void> _onSwipeRightRequested(
    SwipeRightRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GameReady) return;

    final currentState = state as GameReady;
    await _handleAnswer(currentState, true, emit);
  }

  Future<void> _handleAnswer(
    GameReady currentState,
    bool correct,
    Emitter<GameState> emit,
  ) async {
    // Create result for current speech
    final result = GameResult(
      speechId: currentState.currentSpeech.id,
      correct: correct,
      timestamp: DateTime.now(),
    );

    final newResults = List<GameResult>.from(currentState.results)..add(result);

    // Update streak count
    final newStreakCount = correct ? currentState.streakCount + 1 : 0;

    // Move to next speech
    final nextIndex = currentState.currentIndex + 1;

    if (nextIndex >= currentState.speeches.length) {
      // Game complete, save session
      add(const GameCompletionRequested());
      return;
    }

    // Update state with new results and move to next speech
    final newState = currentState.copyWith(
      currentIndex: nextIndex,
      results: newResults,
      streakCount: newStreakCount,
      isAudioPlaying: false,
    );

    emit(newState);

    // Auto-play next speech
    await _playCurrentSpeech(newState);
    emit(newState.copyWith(isAudioPlaying: true));
  }

  Future<void> _onAudioReplayRequested(
    AudioReplayRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GameReady) return;

    final currentState = state as GameReady;
    await _playCurrentSpeech(currentState);
    emit(currentState.copyWith(isAudioPlaying: true));
  }

  void _onGamePaused(
    GamePauseRequested event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      audioPlayerService.pause();
      emit(GamePaused(state as GameReady));
    }
  }

  void _onGameResumed(
    GameResumed event,
    Emitter<GameState> emit,
  ) {
    if (state is GamePaused) {
      final pausedState = state as GamePaused;
      emit(pausedState.previousState);
    }
  }

  Future<void> _onGameQuitRequested(
    GameQuitRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state is GameReady) {
      final currentState = state as GameReady;

      if (currentState.results.isEmpty) {
        // No progress to save, just exit
        emit(const GameInitial());
        return;
      }

      // Save incomplete session
      add(const GameCompletionRequested());
    }
  }

  Future<void> _onGameCompletionRequested(
    GameCompletionRequested event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GameReady) return;

    final currentState = state as GameReady;
    emit(GameSaving(currentState.results));

    // Stop audio playback
    await audioPlayerService.stop();

    // Calculate statistics
    final correctCount = currentState.results.where((r) => r.correct).length;
    final incorrectCount = currentState.results.length - correctCount;
    final isComplete =
        currentState.currentIndex >= currentState.speeches.length;

    // Create game session
    final session = GameSession(
      id: const Uuid().v4(),
      userId: userId,
      mode: currentState.mode,
      level: currentState.speeches.first.level,
      type: currentState.speeches.first.type,
      tagIds: currentState.speeches.first.tagIds,
      results: currentState.results,
      totalSpeeches: currentState.speeches.length,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      streakCount: currentState.streakCount,
      startedAt: DateTime.now().subtract(
        Duration(seconds: currentState.results.length * 10),
      ), // Estimate
      completedAt: isComplete ? DateTime.now() : null,
      syncStatus: SyncStatus.pending,
    );

    // Save session (offline-first)
    final result = await createSessionUseCase(session);

    result.fold(
      (failure) =>
          emit(GameError('Failed to save session: ${failure.message}')),
      (savedSession) => emit(GameCompleted(savedSession)),
    );
  }

  void _onAudioPlaybackCompleted(
    AudioPlaybackCompleted event,
    Emitter<GameState> emit,
  ) {
    if (state is GameReady) {
      final currentState = state as GameReady;
      emit(currentState.copyWith(isAudioPlaying: false));
    }
  }

  /// Play audio for current speech
  Future<void> _playCurrentSpeech(GameReady state) async {
    try {
      await audioPlayerService.play(state.currentSpeech.audioUrl);

      // Listen for playback completion
      _audioSubscription?.cancel();
      _audioSubscription =
          audioPlayerService.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          add(const AudioPlaybackCompleted());
        }
      });
    } catch (e) {
      // Audio playback error, continue game anyway
    }
  }

  @override
  Future<void> close() {
    _audioSubscription?.cancel();
    audioPlayerService.dispose();
    audioRecorderService.dispose();
    return super.close();
  }

  /// Handle recording start event
  Future<void> _onRecordingStarted(
    RecordingStarted event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GameReady) return;

    final currentState = state as GameReady;

    // Check microphone permission
    final hasPermission = await audioRecorderService.hasPermission();
    if (!hasPermission) {
      final granted = await audioRecorderService.requestPermission();
      if (!granted) {
        emit(const GameError('Microphone permission required for recording'));
        return;
      }
    }

    try {
      // Start recording
      await audioRecorderService.startRecording();
      emit(GameRecording(currentState));
    } catch (e) {
      emit(GameError('Failed to start recording: $e'));
    }
  }

  /// Handle recording stop event
  Future<void> _onRecordingStopped(
    RecordingStopped event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GameRecording) return;

    final previousState = (state as GameRecording).previousState;

    try {
      // Stop recording and get audio bytes
      final audioBytes = await audioRecorderService.stopRecording();
      _recordedAudioBytes = audioBytes;

      // Emit transcribing state
      emit(GameTranscribing(previousState));

      // Upload audio for scoring
      final currentSpeech = previousState.currentSpeech;
      final scoreResponse = await speechRemoteDataSource.scorePronunciation(
        audioBytes: audioBytes,
        referenceText: currentSpeech.text,
        language: 'en', // TODO: Get from app settings
      );

      // Emit score received event
      add(ScoreReceived(scoreResponse: scoreResponse));
    } catch (e) {
      emit(GameError('Failed to score pronunciation: $e'));
    }
  }

  /// Handle score received event
  void _onScoreReceived(
    ScoreReceived event,
    Emitter<GameState> emit,
  ) {
    if (state is! GameTranscribing) return;

    final previousState = (state as GameTranscribing).previousState;

    // Emit score ready state to display feedback
    emit(GameScoreReady(
      previousState: previousState,
      scoreResponse: event.scoreResponse,
    ));
  }

  /// Handle score acknowledged event (user continues to next speech)
  Future<void> _onScoreAcknowledged(
    ScoreAcknowledged event,
    Emitter<GameState> emit,
  ) async {
    if (state is! GameScoreReady) return;

    final scoreState = state as GameScoreReady;
    final previousState = scoreState.previousState;
    final scoreResponse = scoreState.scoreResponse;

    // Determine if the pronunciation was correct based on score threshold
    final isCorrect = scoreResponse.pronunciationScore >= 70.0;

    // Create game result
    final result = GameResult(
      speechId: previousState.currentSpeech.id,
      correct: isCorrect,
      pronunciationScore: scoreResponse.pronunciationScore,
      timestamp: DateTime.now(),
    );

    // Update state with result
    final newResults = List<GameResult>.from(previousState.results)
      ..add(result);
    final newStreakCount = isCorrect ? previousState.streakCount + 1 : 0;
    final newIndex = previousState.currentIndex + 1;

    // Check if game is complete
    if (newIndex >= previousState.speeches.length) {
      // Game complete, save session
      add(const GameCompletionRequested());
      return;
    }

    // Continue to next speech
    final newState = previousState.copyWith(
      currentIndex: newIndex,
      results: newResults,
      streakCount: newStreakCount,
    );

    emit(newState);

    // Auto-play next speech
    await _playCurrentSpeech(newState);
    emit(newState.copyWith(isAudioPlaying: true));
  }

  /// Handle recording cancelled event
  void _onRecordingCancelled(
    RecordingCancelled event,
    Emitter<GameState> emit,
  ) {
    if (state is! GameRecording) return;

    final previousState = (state as GameRecording).previousState;

    try {
      audioRecorderService.cancelRecording();
      emit(previousState);
    } catch (e) {
      emit(GameError('Failed to cancel recording: $e'));
    }
  }
}
