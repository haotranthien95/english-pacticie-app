import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/data/datasources/local/audio_player_service.dart';
import 'package:english_learning_app/data/datasources/local/audio_recorder_service.dart';
import 'package:english_learning_app/data/datasources/remote/speech_remote_datasource.dart';
import 'package:english_learning_app/domain/entities/game_result.dart';
import 'package:english_learning_app/domain/entities/game_session.dart';
import 'package:english_learning_app/domain/entities/speech.dart';
import 'package:english_learning_app/domain/usecases/game/create_session_usecase.dart';
import 'package:english_learning_app/domain/usecases/game/get_random_speeches_usecase.dart';
import 'package:english_learning_app/presentation/blocs/game/game_bloc.dart';
import 'package:english_learning_app/presentation/blocs/game/game_event.dart';
import 'package:english_learning_app/presentation/blocs/game/game_state.dart';

import 'game_bloc_test.mocks.dart';

// Generate mocks
@GenerateMocks([
  GetRandomSpeechesUseCase,
  CreateSessionUseCase,
  AudioPlayerService,
  AudioRecorderService,
  SpeechRemoteDataSource,
])
void main() {
  late GameBloc gameBloc;
  late MockGetRandomSpeechesUseCase mockGetRandomSpeechesUseCase;
  late MockCreateSessionUseCase mockCreateSessionUseCase;
  late MockAudioPlayerService mockAudioPlayerService;
  late MockAudioRecorderService mockAudioRecorderService;
  late MockSpeechRemoteDataSource mockSpeechRemoteDataSource;

  // Test data
  const tUserId = 'user123';
  const tSpeechLevel = SpeechLevel.beginner;
  const tSpeechType = SpeechType.word;
  const tGameMode = GameMode.listenOnly;
  final tTagIds = ['tag1', 'tag2'];
  const tCount = 10;

  final tSpeeches = [
    Speech(
      id: 'speech1',
      text: 'Hello, how are you?',
      audioUrl: 'https://example.com/audio1.mp3',
      level: SpeechLevel.beginner,
      type: SpeechType.word,
      tagIds: ['tag1'],
      createdAt: DateTime(2024, 1, 1),
    ),
    Speech(
      id: 'speech2',
      text: 'Good morning!',
      audioUrl: 'https://example.com/audio2.mp3',
      level: SpeechLevel.beginner,
      type: SpeechType.word,
      tagIds: ['tag2'],
      createdAt: DateTime(2024, 1, 2),
    ),
    Speech(
      id: 'speech3',
      text: 'Thank you very much.',
      audioUrl: 'https://example.com/audio3.mp3',
      level: SpeechLevel.beginner,
      type: SpeechType.word,
      tagIds: ['tag1', 'tag2'],
      createdAt: DateTime(2024, 1, 3),
    ),
  ];

  const tNetworkFailure = NetworkFailure(
    message: 'No internet connection',
    code: 'network/no-connection',
  );

  const tServerFailure = ServerFailure(
    message: 'Server error',
    code: 'server/error',
  );

  setUp(() {
    mockGetRandomSpeechesUseCase = MockGetRandomSpeechesUseCase();
    mockCreateSessionUseCase = MockCreateSessionUseCase();
    mockAudioPlayerService = MockAudioPlayerService();
    mockAudioRecorderService = MockAudioRecorderService();
    mockSpeechRemoteDataSource = MockSpeechRemoteDataSource();

    gameBloc = GameBloc(
      getRandomSpeechesUseCase: mockGetRandomSpeechesUseCase,
      createSessionUseCase: mockCreateSessionUseCase,
      audioPlayerService: mockAudioPlayerService,
      audioRecorderService: mockAudioRecorderService,
      speechRemoteDataSource: mockSpeechRemoteDataSource,
      userId: tUserId,
    );
  });

  tearDown(() {
    gameBloc.close();
  });

  group('GameBloc', () {
    test('initial state should be GameInitial', () {
      expect(gameBloc.state, equals(const GameInitial()));
    });

    group('GameStarted', () {
      blocTest<GameBloc, GameState>(
        'emits [GameLoading, GameReady] when speeches are fetched successfully',
        build: () {
          when(mockGetRandomSpeechesUseCase.call(
                  level: anyNamed('level'),
                  type: anyNamed('type'),
                  tagIds: anyNamed('tagIds'),
                  count: anyNamed('count')))
              .thenAnswer((_) async => Right(tSpeeches));
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        act: (bloc) => bloc.add(
          const GameStarted(
            mode: tGameMode,
            level: tSpeechLevel,
            type: tSpeechType,
            tagIds: [],
            count: tCount,
          ),
        ),
        expect: () => [
          const GameLoading(),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.speeches.length == 3 &&
                state.currentIndex == 0 &&
                state.results.isEmpty &&
                state.mode == tGameMode &&
                state.isAudioPlaying == false;
          }),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.speeches.length == 3 &&
                state.currentIndex == 0 &&
                state.results.isEmpty &&
                state.mode == tGameMode &&
                state.isAudioPlaying == true;
          }),
        ],
        verify: (_) {
          verify(mockGetRandomSpeechesUseCase.call(
                  level: anyNamed('level'),
                  type: anyNamed('type'),
                  tagIds: anyNamed('tagIds'),
                  count: anyNamed('count')))
              .called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'emits [GameLoading, GameReady] with filtered speeches by tags',
        build: () {
          when(mockGetRandomSpeechesUseCase.call(
                  level: anyNamed('level'),
                  type: anyNamed('type'),
                  tagIds: anyNamed('tagIds'),
                  count: anyNamed('count')))
              .thenAnswer((_) async => Right(tSpeeches));
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        act: (bloc) => bloc.add(
          GameStarted(
            mode: tGameMode,
            level: tSpeechLevel,
            type: tSpeechType,
            tagIds: tTagIds,
            count: tCount,
          ),
        ),
        expect: () => [
          const GameLoading(),
          isA<GameReady>(),
          isA<GameReady>(),
        ],
        verify: (_) {
          verify(
            mockGetRandomSpeechesUseCase.call(
                level: anyNamed('level'),
                type: anyNamed('type'),
                tagIds: anyNamed('tagIds'),
                count: anyNamed('count')),
          ).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'emits [GameLoading, GameError] when fetching speeches fails',
        build: () {
          when(mockGetRandomSpeechesUseCase.call(
                  level: anyNamed('level'),
                  type: anyNamed('type'),
                  tagIds: anyNamed('tagIds'),
                  count: anyNamed('count')))
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return gameBloc;
        },
        act: (bloc) => bloc.add(
          const GameStarted(
            mode: tGameMode,
            level: tSpeechLevel,
            type: tSpeechType,
            tagIds: [],
            count: tCount,
          ),
        ),
        expect: () => [
          const GameLoading(),
          const GameError('No internet connection'),
        ],
      );

      blocTest<GameBloc, GameState>(
        'emits [GameLoading, GameError] when server error occurs',
        build: () {
          when(mockGetRandomSpeechesUseCase.call(
                  level: anyNamed('level'),
                  type: anyNamed('type'),
                  tagIds: anyNamed('tagIds'),
                  count: anyNamed('count')))
              .thenAnswer((_) async => const Left(tServerFailure));
          return gameBloc;
        },
        act: (bloc) => bloc.add(
          const GameStarted(
            mode: tGameMode,
            level: tSpeechLevel,
            type: tSpeechType,
            tagIds: [],
            count: tCount,
          ),
        ),
        expect: () => [
          const GameLoading(),
          const GameError('Server error'),
        ],
      );
    });

    group('SwipeRightRequested', () {
      final tInitialState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 0,
        mode: tGameMode,
      );

      blocTest<GameBloc, GameState>(
        'moves to next speech when answer is correct',
        build: () {
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => tInitialState,
        act: (bloc) => bloc.add(const SwipeRightRequested()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 1 &&
                state.results.length == 1 &&
                state.results[0].correct == true &&
                state.streakCount == 1 &&
                state.isAudioPlaying == false;
          }),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 1 &&
                state.results.length == 1 &&
                state.results[0].correct == true &&
                state.streakCount == 1 &&
                state.isAudioPlaying == true;
          }),
        ],
      );

      blocTest<GameBloc, GameState>(
        'increases streak count on consecutive correct answers',
        build: () {
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => tInitialState.copyWith(
          currentIndex: 1,
          results: [
            GameResult(
              speechId: 'speech1',
              correct: true,
              timestamp: DateTime(2024, 1, 1),
            ),
          ],
          streakCount: 1,
        ),
        act: (bloc) => bloc.add(const SwipeRightRequested()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 2 &&
                state.results.length == 2 &&
                state.streakCount == 2 &&
                state.isAudioPlaying == false;
          }),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 2 &&
                state.results.length == 2 &&
                state.streakCount == 2 &&
                state.isAudioPlaying == true;
          }),
        ],
      );
    });

    group('SwipeLeftRequested', () {
      final tInitialState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 3,
        mode: tGameMode,
      );

      blocTest<GameBloc, GameState>(
        'moves to next speech when answer is incorrect',
        build: () {
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => tInitialState,
        act: (bloc) => bloc.add(const SwipeLeftRequested()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 1 &&
                state.results.length == 1 &&
                state.results[0].correct == false &&
                state.streakCount == 0 && // Reset streak on incorrect answer
                state.isAudioPlaying == false;
          }),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 1 &&
                state.results.length == 1 &&
                state.results[0].correct == false &&
                state.streakCount == 0 && // Reset streak on incorrect answer
                state.isAudioPlaying == true;
          }),
        ],
      );

      blocTest<GameBloc, GameState>(
        'resets streak count on incorrect answer',
        build: () {
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => tInitialState,
        act: (bloc) => bloc.add(const SwipeLeftRequested()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.streakCount == 0 && state.isAudioPlaying == false;
          }),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.streakCount == 0 && state.isAudioPlaying == true;
          }),
        ],
      );
    });

    group('AudioReplayRequested', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 0,
        mode: tGameMode,
      );

      blocTest<GameBloc, GameState>(
        'replays current speech audio',
        build: () {
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => tGameState,
        act: (bloc) => bloc.add(const AudioReplayRequested()),
        verify: (_) {
          verify(mockAudioPlayerService.play(tSpeeches[0].audioUrl)).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'updates audio playing state when replay is requested',
        build: () {
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => tGameState,
        act: (bloc) => bloc.add(const AudioReplayRequested()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.isAudioPlaying == true;
          }),
        ],
      );
    });

    group('GamePaused', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 1,
        results: [
          GameResult(
            speechId: 'speech1',
            correct: true,
            timestamp: DateTime(2024, 1, 1),
          ),
        ],
        streakCount: 1,
        mode: tGameMode,
      );

      blocTest<GameBloc, GameState>(
        'emits GamePaused state',
        build: () => gameBloc,
        seed: () => tGameState,
        act: (bloc) => bloc.add(const GamePauseRequested()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GamePaused) return false;
            return state.previousState.currentIndex == 1 && state.previousState.results.length == 1;
          }),
        ],
      );
    });

    group('GameResumed', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 1,
        results: [
          GameResult(
            speechId: 'speech1',
            correct: true,
            timestamp: DateTime(2024, 1, 1),
          ),
        ],
        streakCount: 1,
        mode: tGameMode,
      );

      blocTest<GameBloc, GameState>(
        'resumes to previous GameReady state',
        build: () => gameBloc,
        seed: () => GamePaused(tGameState),
        act: (bloc) => bloc.add(const GameResumed()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 1 && state.results.length == 1;
          }),
        ],
      );
    });

    group('RecordingStarted', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 0,
        mode: GameMode.listenAndRepeat,
      );

      blocTest<GameBloc, GameState>(
        'emits GameRecording state when recording starts',
        build: () {
          when(mockAudioRecorderService.hasPermission()).thenAnswer((_) async => true);
          when(mockAudioRecorderService.startRecording()).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => tGameState,
        act: (bloc) => bloc.add(const RecordingStarted()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameRecording) return false;
            return state.previousState.currentIndex == 0;
          }),
        ],
        verify: (_) {
          verify(mockAudioRecorderService.startRecording()).called(1);
        },
      );
    });

    group('RecordingStopped', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 0,
        mode: GameMode.listenAndRepeat,
      );

      final tRecordedBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      blocTest<GameBloc, GameState>(
        'emits GameTranscribing when recording stops',
        build: () {
          when(mockAudioRecorderService.stopRecording()).thenAnswer((_) async => tRecordedBytes);
          when(mockSpeechRemoteDataSource.scorePronunciation(
            audioBytes: anyNamed('audioBytes'),
            referenceText: anyNamed('referenceText'),
            language: anyNamed('language'),
          )).thenAnswer((_) async => SpeechScoreResponse(
                transcribedText: 'Hello, how are you?',
                pronunciationScore: 85.5,
                wordScores: {},
              ));
          return gameBloc;
        },
        seed: () => GameRecording(tGameState),
        act: (bloc) => bloc.add(const RecordingStopped()),
        expect: () => [
          predicate<GameState>((state) {
            return state is GameTranscribing;
          }),
          predicate<GameState>((state) {
            return state is GameScoreReady;
          }),
        ],
        verify: (_) {
          verify(mockAudioRecorderService.stopRecording()).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'emits GameError when recording fails',
        build: () {
          when(mockAudioRecorderService.stopRecording()).thenThrow(Exception('Recording failed'));
          return gameBloc;
        },
        seed: () => GameRecording(tGameState),
        act: (bloc) => bloc.add(const RecordingStopped()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameError) return false;
            return state.message.contains('Recording failed');
          }),
        ],
      );
    });

    group('RecordingCancelled', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 0,
        mode: GameMode.listenAndRepeat,
      );

      blocTest<GameBloc, GameState>(
        'returns to previous GameReady state when recording is cancelled',
        build: () {
          when(mockAudioRecorderService.cancelRecording()).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => GameRecording(tGameState),
        act: (bloc) => bloc.add(const RecordingCancelled()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 0 && state.results.isEmpty;
          }),
        ],
        verify: (_) {
          verify(mockAudioRecorderService.cancelRecording()).called(1);
        },
      );
    });

    group('ScoreAcknowledged', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 0,
        mode: GameMode.listenAndRepeat,
      );

      final tScoreResponse = SpeechScoreResponse(
        transcribedText: 'Hello, how are you?',
        pronunciationScore: 85.5,
        wordScores: {
          'Hello': 90.0,
          'how': 85.0,
          'are': 80.0,
          'you': 88.0,
        },
      );

      blocTest<GameBloc, GameState>(
        'moves to next speech after score is acknowledged',
        build: () {
          when(mockAudioPlayerService.play(any)).thenAnswer((_) async => {});
          return gameBloc;
        },
        seed: () => GameScoreReady(
          previousState: tGameState,
          scoreResponse: tScoreResponse,
        ),
        act: (bloc) => bloc.add(const ScoreAcknowledged()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 1 &&
                state.results.length == 1 &&
                state.results[0].pronunciationScore == 85.5 &&
                state.isAudioPlaying == false;
          }),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.currentIndex == 1 &&
                state.results.length == 1 &&
                state.results[0].pronunciationScore == 85.5 &&
                state.isAudioPlaying == true;
          }),
        ],
      );
    });

    group('GameQuitRequested', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 1,
        results: [
          GameResult(
            speechId: 'speech1',
            correct: true,
            timestamp: DateTime(2024, 1, 1),
          ),
        ],
        streakCount: 1,
        mode: tGameMode,
      );

      blocTest<GameBloc, GameState>(
        'emits GameCompleted when quit is requested',
        build: () {
          when(mockCreateSessionUseCase(any)).thenAnswer((_) async => Right(GameSession(
                id: 'session1',
                userId: tUserId,
                mode: tGameMode,
                level: tSpeechLevel,
                type: tSpeechType,
                tagIds: const [],
                results: const [],
                totalSpeeches: 1,
                correctCount: 1,
                incorrectCount: 0,
                streakCount: 1,
                startedAt: DateTime(2024, 1, 1),
                completedAt: DateTime(2024, 1, 1, 0, 5),
                syncStatus: SyncStatus.pending,
              )));
          return gameBloc;
        },
        seed: () => tGameState,
        act: (bloc) => bloc.add(const GameQuitRequested()),
        expect: () => [
          predicate<GameState>((state) => state is GameSaving),
          predicate<GameState>((state) => state is GameCompleted),
        ],
      );
    });

    group('GameCompletionRequested', () {
      final tCompletedGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 3, // All speeches completed
        results: [
          GameResult(
            speechId: 'speech1',
            correct: true,
            timestamp: DateTime(2024, 1, 1),
          ),
          GameResult(
            speechId: 'speech2',
            correct: true,
            timestamp: DateTime(2024, 1, 1, 0, 1),
          ),
          GameResult(
            speechId: 'speech3',
            correct: false,
            timestamp: DateTime(2024, 1, 1, 0, 2),
          ),
        ],
        streakCount: 0,
        mode: tGameMode,
      );

      blocTest<GameBloc, GameState>(
        'emits [GameSaving, GameCompleted] when game is saved successfully',
        build: () {
          when(mockCreateSessionUseCase(any)).thenAnswer((_) async => Right(GameSession(
                id: 'session1',
                userId: tUserId,
                mode: tGameMode,
                level: tSpeechLevel,
                type: tSpeechType,
                tagIds: const [],
                results: const [],
                totalSpeeches: 3,
                correctCount: 2,
                incorrectCount: 1,
                streakCount: 2,
                startedAt: DateTime(2024, 1, 1),
                completedAt: DateTime(2024, 1, 1, 0, 10),
                syncStatus: SyncStatus.pending,
              )));
          return gameBloc;
        },
        seed: () => tCompletedGameState,
        act: (bloc) => bloc.add(const GameCompletionRequested()),
        expect: () => [
          predicate<GameState>((state) => state is GameSaving),
          predicate<GameState>((state) => state is GameCompleted),
        ],
        verify: (_) {
          verify(mockCreateSessionUseCase(any)).called(1);
        },
      );

      blocTest<GameBloc, GameState>(
        'emits [GameSaving, GameError] when saving fails',
        build: () {
          when(mockCreateSessionUseCase(any)).thenAnswer((_) async => const Left(tNetworkFailure));
          return gameBloc;
        },
        seed: () => tCompletedGameState,
        act: (bloc) => bloc.add(const GameCompletionRequested()),
        expect: () => [
          predicate<GameState>((state) => state is GameSaving),
          const GameError('Failed to save session: No internet connection'),
        ],
      );
    });

    group('AudioPlaybackCompleted', () {
      final tGameState = GameReady(
        speeches: tSpeeches,
        currentIndex: 0,
        results: const [],
        streakCount: 0,
        mode: tGameMode,
        isAudioPlaying: true,
      );

      blocTest<GameBloc, GameState>(
        'sets isAudioPlaying to false when audio finishes',
        build: () => gameBloc,
        seed: () => tGameState,
        act: (bloc) => bloc.add(const AudioPlaybackCompleted()),
        expect: () => [
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.isAudioPlaying == false;
          }),
        ],
      );
    });

    group('Edge cases', () {
      blocTest<GameBloc, GameState>(
        'handles empty speeches list',
        build: () {
          when(mockGetRandomSpeechesUseCase.call(
                  level: anyNamed('level'),
                  type: anyNamed('type'),
                  tagIds: anyNamed('tagIds'),
                  count: anyNamed('count')))
              .thenAnswer((_) async => const Right([]));
          return gameBloc;
        },
        act: (bloc) => bloc.add(
          const GameStarted(
            mode: tGameMode,
            level: tSpeechLevel,
            type: tSpeechType,
            tagIds: [],
            count: tCount,
          ),
        ),
        expect: () => [
          const GameLoading(),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.speeches.isEmpty && state.isComplete && state.isAudioPlaying == false;
          }),
          predicate<GameState>((state) {
            if (state is! GameReady) return false;
            return state.speeches.isEmpty && state.isComplete && state.isAudioPlaying == true;
          }),
        ],
      );

      blocTest<GameBloc, GameState>(
        'ignores swipe events when not in GameReady state',
        build: () => gameBloc,
        seed: () => const GameLoading(),
        act: (bloc) {
          bloc.add(const SwipeRightRequested());
          bloc.add(const SwipeLeftRequested());
        },
        expect: () => [], // No state changes
      );
    });
  });
}
