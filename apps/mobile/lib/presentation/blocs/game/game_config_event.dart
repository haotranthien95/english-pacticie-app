import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/entities/tag.dart';

/// Events for GameConfig BLoC
abstract class GameConfigEvent extends Equatable {
  const GameConfigEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load available tags
class TagsLoadRequested extends GameConfigEvent {
  const TagsLoadRequested();
}

/// Event to update selected level
class LevelChanged extends GameConfigEvent {
  final SpeechLevel level;

  const LevelChanged(this.level);

  @override
  List<Object?> get props => [level];
}

/// Event to update selected type
class TypeChanged extends GameConfigEvent {
  final SpeechType type;

  const TypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

/// Event to toggle tag selection
class TagToggled extends GameConfigEvent {
  final String tagId;

  const TagToggled(this.tagId);

  @override
  List<Object?> get props => [tagId];
}

/// Event to update speech count
class SpeechCountChanged extends GameConfigEvent {
  final int count;

  const SpeechCountChanged(this.count);

  @override
  List<Object?> get props => [count];
}

/// Event to start game with current configuration
class GameStartRequested extends GameConfigEvent {
  final GameMode mode;

  const GameStartRequested(this.mode);

  @override
  List<Object?> get props => [mode];
}
