import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/usecases/game/get_tags_usecase.dart';
import 'game_config_event.dart';
import 'game_config_state.dart';

/// BLoC for managing game configuration
class GameConfigBloc extends Bloc<GameConfigEvent, GameConfigState> {
  final GetTagsUseCase getTagsUseCase;

  GameConfigBloc({
    required this.getTagsUseCase,
  }) : super(const GameConfigInitial()) {
    on<TagsLoadRequested>(_onTagsLoadRequested);
    on<LevelChanged>(_onLevelChanged);
    on<TypeChanged>(_onTypeChanged);
    on<TagToggled>(_onTagToggled);
    on<SpeechCountChanged>(_onSpeechCountChanged);
    on<GameStartRequested>(_onGameStartRequested);
  }

  Future<void> _onTagsLoadRequested(
    TagsLoadRequested event,
    Emitter<GameConfigState> emit,
  ) async {
    emit(const GameConfigLoading());

    final result = await getTagsUseCase();

    result.fold(
      (failure) => emit(GameConfigError(failure.message)),
      (tags) => emit(
        GameConfigReady(
          availableTags: tags,
          selectedLevel: SpeechLevel.beginner,
          selectedType: SpeechType.word,
          selectedTagIds: [],
          speechCount: 10,
        ),
      ),
    );
  }

  void _onLevelChanged(
    LevelChanged event,
    Emitter<GameConfigState> emit,
  ) {
    if (state is GameConfigReady) {
      final currentState = state as GameConfigReady;
      emit(currentState.copyWith(selectedLevel: event.level));
    }
  }

  void _onTypeChanged(
    TypeChanged event,
    Emitter<GameConfigState> emit,
  ) {
    if (state is GameConfigReady) {
      final currentState = state as GameConfigReady;
      emit(currentState.copyWith(selectedType: event.type));
    }
  }

  void _onTagToggled(
    TagToggled event,
    Emitter<GameConfigState> emit,
  ) {
    if (state is GameConfigReady) {
      final currentState = state as GameConfigReady;
      final currentTags = List<String>.from(currentState.selectedTagIds);

      if (currentTags.contains(event.tagId)) {
        currentTags.remove(event.tagId);
      } else {
        currentTags.add(event.tagId);
      }

      emit(currentState.copyWith(selectedTagIds: currentTags));
    }
  }

  void _onSpeechCountChanged(
    SpeechCountChanged event,
    Emitter<GameConfigState> emit,
  ) {
    if (state is GameConfigReady) {
      final currentState = state as GameConfigReady;
      // Ensure count is within valid range (1-50)
      final validCount = event.count.clamp(1, 50);
      emit(currentState.copyWith(speechCount: validCount));
    }
  }

  void _onGameStartRequested(
    GameStartRequested event,
    Emitter<GameConfigState> emit,
  ) {
    if (state is GameConfigReady) {
      final currentState = state as GameConfigReady;
      emit(
        GameConfigStarting(
          mode: event.mode,
          level: currentState.selectedLevel,
          type: currentState.selectedType,
          tagIds: currentState.selectedTagIds,
          count: currentState.speechCount,
        ),
      );
    }
  }
}
