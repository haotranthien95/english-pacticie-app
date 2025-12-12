import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';

/// Events for History BLoC
abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial sessions
class SessionsLoadRequested extends HistoryEvent {
  const SessionsLoadRequested();
}

/// Event to load more sessions (pagination)
class SessionsLoadMoreRequested extends HistoryEvent {
  const SessionsLoadMoreRequested();
}

/// Event to refresh sessions list
class SessionsRefreshRequested extends HistoryEvent {
  const SessionsRefreshRequested();
}

/// Event to filter by game mode
class ModeFilterChanged extends HistoryEvent {
  final GameMode? mode;

  const ModeFilterChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// Event to filter by speech level
class LevelFilterChanged extends HistoryEvent {
  final SpeechLevel? level;

  const LevelFilterChanged(this.level);

  @override
  List<Object?> get props => [level];
}

/// Event to filter by date range
class DateRangeFilterChanged extends HistoryEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateRangeFilterChanged({
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Event to clear all filters
class FiltersClearedRequested extends HistoryEvent {
  const FiltersClearedRequested();
}
