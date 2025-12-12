import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:english_learning_app/core/constants/enums.dart';
import 'package:english_learning_app/core/errors/failures.dart';
import 'package:english_learning_app/domain/entities/game_session.dart';
import 'package:english_learning_app/domain/usecases/game/get_sessions_usecase.dart';
import 'package:english_learning_app/presentation/blocs/history/history_bloc.dart';
import 'package:english_learning_app/presentation/blocs/history/history_event.dart';
import 'package:english_learning_app/presentation/blocs/history/history_state.dart';

import 'history_bloc_test.mocks.dart';

// Generate mocks
@GenerateMocks([GetSessionsUseCase])
void main() {
  late HistoryBloc historyBloc;
  late MockGetSessionsUseCase mockGetSessionsUseCase;

  // Test data
  final tSessions = List.generate(
    20,
    (index) => GameSession(
      id: 'session$index',
      userId: 'user123',
      mode: GameMode.listenOnly,
      level: SpeechLevel.beginner,
      startedAt: DateTime(2024, 1, 1).add(Duration(days: index)),
      completedAt: DateTime(2024, 1, 1).add(Duration(days: index, hours: 1)),
      totalSpeeches: 10,
      correctAnswers: 8,
      accuracy: 80.0,
      averageTimePerSpeech: const Duration(seconds: 5),
      streakCount: 3,
      syncStatus: SyncStatus.synced,
    ),
  );

  final tMoreSessions = List.generate(
    20,
    (index) => GameSession(
      id: 'session${index + 20}',
      userId: 'user123',
      mode: GameMode.listenAndRepeat,
      level: SpeechLevel.intermediate,
      startedAt: DateTime(2024, 2, 1).add(Duration(days: index)),
      completedAt: DateTime(2024, 2, 1).add(Duration(days: index, hours: 1)),
      totalSpeeches: 15,
      correctAnswers: 12,
      accuracy: 80.0,
      averageTimePerSpeech: const Duration(seconds: 6),
      streakCount: 5,
      syncStatus: SyncStatus.synced,
    ),
  );

  const tNetworkFailure = NetworkFailure(
    message: 'No internet connection',
    code: 'network/no-connection',
  );

  setUp(() {
    mockGetSessionsUseCase = MockGetSessionsUseCase();
    historyBloc = HistoryBloc(getSessionsUseCase: mockGetSessionsUseCase);
  });

  tearDown(() {
    historyBloc.close();
  });

  group('HistoryBloc', () {
    test('initial state should be HistoryInitial', () {
      expect(historyBloc.state, equals(const HistoryInitial()));
    });

    group('SessionsLoadRequested', () {
      blocTest<HistoryBloc, HistoryState>(
        'emits [HistoryLoading, HistoryLoaded] when sessions are loaded successfully',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        act: (bloc) => bloc.add(const SessionsLoadRequested()),
        expect: () => [
          const HistoryLoading(),
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.sessions.length == 20 &&
                state.hasMore == true &&
                state.isLoadingMore == false;
          }),
        ],
        verify: (_) {
          verify(mockGetSessionsUseCase(any)).called(1);
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [HistoryLoading, HistoryLoaded] with hasMore=false when less than page size',
        build: () {
          final shortList = tSessions.take(10).toList();
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(shortList));
          return historyBloc;
        },
        act: (bloc) => bloc.add(const SessionsLoadRequested()),
        expect: () => [
          const HistoryLoading(),
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.sessions.length == 10 && state.hasMore == false;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [HistoryLoading, HistoryError] when loading fails',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => const Left(tNetworkFailure));
          return historyBloc;
        },
        act: (bloc) => bloc.add(const SessionsLoadRequested()),
        expect: () => [
          const HistoryLoading(),
          const HistoryError('No internet connection'),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [HistoryLoading, HistoryLoaded] with empty list when no sessions',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => const Right([]));
          return historyBloc;
        },
        act: (bloc) => bloc.add(const SessionsLoadRequested()),
        expect: () => [
          const HistoryLoading(),
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.sessions.isEmpty && state.hasMore == false;
          }),
        ],
      );
    });

    group('SessionsLoadMoreRequested', () {
      final tInitialState = HistoryLoaded(
        sessions: tSessions,
        hasMore: true,
        isLoadingMore: false,
      );

      blocTest<HistoryBloc, HistoryState>(
        'loads more sessions and appends to existing list',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tMoreSessions));
          return historyBloc;
        },
        seed: () => tInitialState,
        act: (bloc) => bloc.add(const SessionsLoadMoreRequested()),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.isLoadingMore == true;
          }),
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.sessions.length == 40 &&
                state.isLoadingMore == false &&
                state.hasMore == true;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'sets hasMore to false when receiving less than page size',
        build: () {
          final shortList = tMoreSessions.take(10).toList();
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(shortList));
          return historyBloc;
        },
        seed: () => tInitialState,
        act: (bloc) => bloc.add(const SessionsLoadMoreRequested()),
        expect: () => [
          predicate<HistoryState>((state) => state is HistoryLoaded),
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.sessions.length == 30 && state.hasMore == false;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'does not load more when already loading',
        build: () => historyBloc,
        seed: () => tInitialState.copyWith(isLoadingMore: true),
        act: (bloc) => bloc.add(const SessionsLoadMoreRequested()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockGetSessionsUseCase(any));
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'does not load more when no more data available',
        build: () => historyBloc,
        seed: () => tInitialState.copyWith(hasMore: false),
        act: (bloc) => bloc.add(const SessionsLoadMoreRequested()),
        expect: () => [],
        verify: (_) {
          verifyNever(mockGetSessionsUseCase(any));
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'ignores load more when not in HistoryLoaded state',
        build: () => historyBloc,
        seed: () => const HistoryInitial(),
        act: (bloc) => bloc.add(const SessionsLoadMoreRequested()),
        expect: () => [],
      );
    });

    group('SessionsRefreshRequested', () {
      final tLoadedState = HistoryLoaded(
        sessions: tSessions,
        hasMore: true,
        modeFilter: GameMode.listenOnly,
        levelFilter: SpeechLevel.beginner,
      );

      blocTest<HistoryBloc, HistoryState>(
        'refreshes sessions with current filters',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const SessionsRefreshRequested()),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.sessions.length == 20 &&
                state.modeFilter == GameMode.listenOnly &&
                state.levelFilter == SpeechLevel.beginner;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'resets pagination offset on refresh',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const SessionsRefreshRequested()),
        verify: (_) {
          final captured = verify(mockGetSessionsUseCase(captureAny)).captured;
          expect(captured.length, 1);
          final params = captured[0] as GetSessionsParams;
          expect(params.offset, 0);
        },
      );
    });

    group('ModeFilterChanged', () {
      final tLoadedState = HistoryLoaded(sessions: tSessions);

      blocTest<HistoryBloc, HistoryState>(
        'filters sessions by game mode',
        build: () {
          final filteredSessions = tSessions
              .where((s) => s.mode == GameMode.listenAndRepeat)
              .toList();
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(filteredSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) =>
            bloc.add(const ModeFilterChanged(GameMode.listenAndRepeat)),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.modeFilter == GameMode.listenAndRepeat;
          }),
        ],
        verify: (_) {
          final captured = verify(mockGetSessionsUseCase(captureAny)).captured;
          final params = captured[0] as GetSessionsParams;
          expect(params.mode, GameMode.listenAndRepeat);
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'clears mode filter when null is passed',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState.copyWith(modeFilter: GameMode.listenOnly),
        act: (bloc) => bloc.add(const ModeFilterChanged(null)),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.modeFilter == null;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'resets pagination offset when filter changes',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const ModeFilterChanged(GameMode.listenOnly)),
        verify: (_) {
          final captured = verify(mockGetSessionsUseCase(captureAny)).captured;
          final params = captured[0] as GetSessionsParams;
          expect(params.offset, 0);
        },
      );
    });

    group('LevelFilterChanged', () {
      final tLoadedState = HistoryLoaded(sessions: tSessions);

      blocTest<HistoryBloc, HistoryState>(
        'filters sessions by speech level',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) =>
            bloc.add(const LevelFilterChanged(SpeechLevel.intermediate)),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.levelFilter == SpeechLevel.intermediate;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'clears level filter when null is passed',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState.copyWith(levelFilter: SpeechLevel.advanced),
        act: (bloc) => bloc.add(const LevelFilterChanged(null)),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.levelFilter == null;
          }),
        ],
      );
    });

    group('DateRangeFilterChanged', () {
      final tLoadedState = HistoryLoaded(sessions: tSessions);
      final tStartDate = DateTime(2024, 1, 1);
      final tEndDate = DateTime(2024, 1, 31);

      blocTest<HistoryBloc, HistoryState>(
        'filters sessions by date range',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(
          DateRangeFilterChanged(startDate: tStartDate, endDate: tEndDate),
        ),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.startDateFilter == tStartDate &&
                state.endDateFilter == tEndDate;
          }),
        ],
        verify: (_) {
          final captured = verify(mockGetSessionsUseCase(captureAny)).captured;
          final params = captured[0] as GetSessionsParams;
          expect(params.startDate, tStartDate);
          expect(params.endDate, tEndDate);
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'clears date filters when both are null',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState.copyWith(
          startDateFilter: tStartDate,
          endDateFilter: tEndDate,
        ),
        act: (bloc) => bloc.add(const DateRangeFilterChanged()),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.startDateFilter == null && state.endDateFilter == null;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'allows partial date range (only start date)',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(DateRangeFilterChanged(startDate: tStartDate)),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.startDateFilter == tStartDate &&
                state.endDateFilter == null;
          }),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'allows partial date range (only end date)',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(DateRangeFilterChanged(endDate: tEndDate)),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.startDateFilter == null &&
                state.endDateFilter == tEndDate;
          }),
        ],
      );
    });

    group('FiltersClearedRequested', () {
      final tFilteredState = HistoryLoaded(
        sessions: tSessions,
        modeFilter: GameMode.listenOnly,
        levelFilter: SpeechLevel.beginner,
        startDateFilter: DateTime(2024, 1, 1),
        endDateFilter: DateTime(2024, 1, 31),
      );

      blocTest<HistoryBloc, HistoryState>(
        'clears all filters and reloads sessions',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tFilteredState,
        act: (bloc) => bloc.add(const FiltersClearedRequested()),
        expect: () => [
          predicate<HistoryState>((state) {
            if (state is! HistoryLoaded) return false;
            return state.modeFilter == null &&
                state.levelFilter == null &&
                state.startDateFilter == null &&
                state.endDateFilter == null &&
                state.hasActiveFilters == false;
          }),
        ],
        verify: (_) {
          final captured = verify(mockGetSessionsUseCase(captureAny)).captured;
          final params = captured[0] as GetSessionsParams;
          expect(params.mode, null);
          expect(params.level, null);
          expect(params.startDate, null);
          expect(params.endDate, null);
        },
      );
    });

    group('Multiple filters', () {
      final tLoadedState = HistoryLoaded(sessions: tSessions);

      blocTest<HistoryBloc, HistoryState>(
        'applies multiple filters simultaneously',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) async {
          bloc.add(const ModeFilterChanged(GameMode.listenOnly));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const LevelFilterChanged(SpeechLevel.beginner));
        },
        verify: (_) {
          verify(mockGetSessionsUseCase(any)).called(2);
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'hasActiveFilters returns true when any filter is set',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        seed: () => tLoadedState,
        act: (bloc) => bloc.add(const ModeFilterChanged(GameMode.listenOnly)),
        verify: (bloc) {
          final state = bloc.state;
          if (state is HistoryLoaded) {
            expect(state.hasActiveFilters, true);
          }
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'hasActiveFilters returns false when no filters are set',
        build: () => historyBloc,
        seed: () => tLoadedState,
        verify: (bloc) {
          final state = bloc.state;
          if (state is HistoryLoaded) {
            expect(state.hasActiveFilters, false);
          }
        },
      );
    });

    group('Edge cases', () {
      blocTest<HistoryBloc, HistoryState>(
        'handles rapid successive load requests',
        build: () {
          when(mockGetSessionsUseCase(any))
              .thenAnswer((_) async => Right(tSessions));
          return historyBloc;
        },
        act: (bloc) {
          bloc.add(const SessionsLoadRequested());
          bloc.add(const SessionsLoadRequested());
          bloc.add(const SessionsLoadRequested());
        },
        verify: (_) {
          // Should handle all requests
          verify(mockGetSessionsUseCase(any)).called(greaterThan(0));
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'handles server error gracefully',
        build: () {
          when(mockGetSessionsUseCase(any)).thenAnswer(
            (_) async => const Left(
              ServerFailure(message: 'Internal server error'),
            ),
          );
          return historyBloc;
        },
        act: (bloc) => bloc.add(const SessionsLoadRequested()),
        expect: () => [
          const HistoryLoading(),
          const HistoryError('Internal server error'),
        ],
      );
    });
  });
}
