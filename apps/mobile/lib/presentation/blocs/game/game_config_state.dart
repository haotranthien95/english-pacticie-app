import 'package:equatable/equatable.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/entities/tag.dart';

/// States for GameConfig BLoC
abstract class GameConfigState extends Equatable {
  const GameConfigState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class GameConfigInitial extends GameConfigState {
  const GameConfigInitial();
}

/// Loading tags
class GameConfigLoading extends GameConfigState {
  const GameConfigLoading();
}

/// Tags loaded, user can configure game
class GameConfigReady extends GameConfigState {
  final List<Tag> availableTags;
  final SpeechLevel selectedLevel;
  final SpeechType selectedType;
  final List<String> selectedTagIds;
  final int speechCount;

  const GameConfigReady({
    required this.availableTags,
    required this.selectedLevel,
    required this.selectedType,
    required this.selectedTagIds,
    required this.speechCount,
  });

  @override
  List<Object?> get props => [
        availableTags,
        selectedLevel,
        selectedType,
        selectedTagIds,
        speechCount,
      ];

  GameConfigReady copyWith({
    List<Tag>? availableTags,
    SpeechLevel? selectedLevel,
    SpeechType? selectedType,
    List<String>? selectedTagIds,
    int? speechCount,
  }) {
    return GameConfigReady(
      availableTags: availableTags ?? this.availableTags,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      selectedType: selectedType ?? this.selectedType,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      speechCount: speechCount ?? this.speechCount,
    );
  }
}

/// Starting game with configuration
class GameConfigStarting extends GameConfigState {
  final GameMode mode;
  final SpeechLevel level;
  final SpeechType type;
  final List<String> tagIds;
  final int count;

  const GameConfigStarting({
    required this.mode,
    required this.level,
    required this.type,
    required this.tagIds,
    required this.count,
  });

  @override
  List<Object?> get props => [mode, level, type, tagIds, count];
}

/// Error loading tags
class GameConfigError extends GameConfigState {
  final String message;

  const GameConfigError(this.message);

  @override
  List<Object?> get props => [message];
}
