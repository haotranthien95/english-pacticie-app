import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/entities/game_session.dart';

/// States for History BLoC
abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

/// Loading first page of sessions
class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

/// Sessions loaded successfully
class HistoryLoaded extends HistoryState {
  final List<GameSession> sessions;
  final bool hasMore;
  final bool isLoadingMore;
  final GameMode? modeFilter;
  final SpeechLevel? levelFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;

  const HistoryLoaded({
    required this.sessions,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.modeFilter,
    this.levelFilter,
    this.startDateFilter,
    this.endDateFilter,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      modeFilter != null ||
      levelFilter != null ||
      startDateFilter != null ||
      endDateFilter != null;

  @override
  List<Object?> get props => [
        sessions,
        hasMore,
        isLoadingMore,
        modeFilter,
        levelFilter,
        startDateFilter,
        endDateFilter,
      ];

  HistoryLoaded copyWith({
    List<GameSession>? sessions,
    bool? hasMore,
    bool? isLoadingMore,
    GameMode? modeFilter,
    SpeechLevel? levelFilter,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
    bool clearModeFilter = false,
    bool clearLevelFilter = false,
    bool clearDateFilters = false,
  }) {
    return HistoryLoaded(
      sessions: sessions ?? this.sessions,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      modeFilter: clearModeFilter ? null : (modeFilter ?? this.modeFilter),
      levelFilter: clearLevelFilter ? null : (levelFilter ?? this.levelFilter),
      startDateFilter:
          clearDateFilters ? null : (startDateFilter ?? this.startDateFilter),
      endDateFilter:
          clearDateFilters ? null : (endDateFilter ?? this.endDateFilter),
    );
  }
}

/// Error loading sessions
class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
