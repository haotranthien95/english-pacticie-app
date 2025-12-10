import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/enums.dart';
import '../../../data/datasources/local/audio_player_service.dart';
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
  final String userId;

  StreamSubscription? _audioSubscription;

  GameBloc({
    required this.getRandomSpeechesUseCase,
    required this.createSessionUseCase,
    required this.audioPlayerService,
    required this.userId,
  }) : super(const GameInitial()) {
    on<GameStarted>(_onGameStarted);
    on<SwipeLeftRequested>(_onSwipeLeftRequested);
    on<SwipeRightRequested>(_onSwipeRightRequested);
    on<AudioReplayRequested>(_onAudioReplayRequested);
    on<GamePaused>(_onGamePaused);
    on<GameResumed>(_onGameResumed);
    on<GameQuitRequested>(_onGameQuitRequested);
    on<GameCompletionRequested>(_onGameCompletionRequested);
    on<AudioPlaybackCompleted>(_onAudioPlaybackCompleted);
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(const GameLoading());

    // Fetch speeches
    final result = await getRandomSpeechesUseCase(
      GetRandomSpeechesParams(
        level: event.level,
        type: event.type,
        tagIds: event.tagIds.isEmpty ? null : event.tagIds,
        count: event.count,
      ),
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
    GamePaused event,
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
    final isComplete = currentState.currentIndex >= currentState.speeches.length;

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
      (failure) => emit(GameError('Failed to save session: ${failure.message}')),
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
      _audioSubscription = audioPlayerService.playerStateStream.listen((playerState) {
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
    return super.close();
  }
}
