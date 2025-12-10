import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/game/get_sessions_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

/// BLoC for managing game history with pagination and filters
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetSessionsUseCase getSessionsUseCase;

  static const int _pageSize = 20;
  int _currentOffset = 0;

  HistoryBloc({
    required this.getSessionsUseCase,
  }) : super(const HistoryInitial()) {
    on<SessionsLoadRequested>(_onSessionsLoadRequested);
    on<SessionsLoadMoreRequested>(_onSessionsLoadMoreRequested);
    on<SessionsRefreshRequested>(_onSessionsRefreshRequested);
    on<ModeFilterChanged>(_onModeFilterChanged);
    on<LevelFilterChanged>(_onLevelFilterChanged);
    on<DateRangeFilterChanged>(_onDateRangeFilterChanged);
    on<FiltersClearedRequested>(_onFiltersClearedRequested);
  }

  Future<void> _onSessionsLoadRequested(
    SessionsLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    _currentOffset = 0;

    await _loadSessions(emit);
  }

  Future<void> _onSessionsLoadMoreRequested(
    SessionsLoadMoreRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (state is! HistoryLoaded) return;

    final currentState = state as HistoryLoaded;

    // Don't load if already loading or no more data
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    // Set loading more flag
    emit(currentState.copyWith(isLoadingMore: true));

    // Increment offset for next page
    _currentOffset += _pageSize;

    await _loadSessions(emit, append: true);
  }

  Future<void> _onSessionsRefreshRequested(
    SessionsRefreshRequested event,
    Emitter<HistoryState> emit,
  ) async {
    _currentOffset = 0;

    // Keep current filters
    final currentState = state is HistoryLoaded ? state as HistoryLoaded : null;

    await _loadSessions(
      emit,
      modeFilter: currentState?.modeFilter,
      levelFilter: currentState?.levelFilter,
      startDateFilter: currentState?.startDateFilter,
      endDateFilter: currentState?.endDateFilter,
    );
  }

  Future<void> _onModeFilterChanged(
    ModeFilterChanged event,
    Emitter<HistoryState> emit,
  ) async {
    _currentOffset = 0;

    final currentState = state is HistoryLoaded ? state as HistoryLoaded : null;

    emit(const HistoryLoading());

    await _loadSessions(
      emit,
      modeFilter: event.mode,
      levelFilter: currentState?.levelFilter,
      startDateFilter: currentState?.startDateFilter,
      endDateFilter: currentState?.endDateFilter,
    );
  }

  Future<void> _onLevelFilterChanged(
    LevelFilterChanged event,
    Emitter<HistoryState> emit,
  ) async {
    _currentOffset = 0;

    final currentState = state is HistoryLoaded ? state as HistoryLoaded : null;

    emit(const HistoryLoading());

    await _loadSessions(
      emit,
      modeFilter: currentState?.modeFilter,
      levelFilter: event.level,
      startDateFilter: currentState?.startDateFilter,
      endDateFilter: currentState?.endDateFilter,
    );
  }

  Future<void> _onDateRangeFilterChanged(
    DateRangeFilterChanged event,
    Emitter<HistoryState> emit,
  ) async {
    _currentOffset = 0;

    final currentState = state is HistoryLoaded ? state as HistoryLoaded : null;

    emit(const HistoryLoading());

    await _loadSessions(
      emit,
      modeFilter: currentState?.modeFilter,
      levelFilter: currentState?.levelFilter,
      startDateFilter: event.startDate,
      endDateFilter: event.endDate,
    );
  }

  Future<void> _onFiltersClearedRequested(
    FiltersClearedRequested event,
    Emitter<HistoryState> emit,
  ) async {
    _currentOffset = 0;

    emit(const HistoryLoading());

    await _loadSessions(emit);
  }

  Future<void> _loadSessions(
    Emitter<HistoryState> emit, {
    bool append = false,
    dynamic modeFilter,
    dynamic levelFilter,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
  }) async {
    final result = await getSessionsUseCase(
      mode: modeFilter,
      level: levelFilter,
      startDate: startDateFilter,
      endDate: endDateFilter,
      limit: _pageSize,
      offset: _currentOffset,
    );

    result.fold(
      (failure) {
        emit(HistoryError(failure.message));
      },
      (newSessions) {
        final hasMore = newSessions.length == _pageSize;

        if (append && state is HistoryLoaded) {
          final currentState = state as HistoryLoaded;
          final allSessions = [...currentState.sessions, ...newSessions];

          emit(HistoryLoaded(
            sessions: allSessions,
            hasMore: hasMore,
            isLoadingMore: false,
            modeFilter: currentState.modeFilter,
            levelFilter: currentState.levelFilter,
            startDateFilter: currentState.startDateFilter,
            endDateFilter: currentState.endDateFilter,
          ));
        } else {
          emit(HistoryLoaded(
            sessions: newSessions,
            hasMore: hasMore,
            modeFilter: modeFilter,
            levelFilter: levelFilter,
            startDateFilter: startDateFilter,
            endDateFilter: endDateFilter,
          ));
        }
      },
    );
  }
}
