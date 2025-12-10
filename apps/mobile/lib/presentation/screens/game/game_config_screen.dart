import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/enums.dart';
import '../../../di/injection.dart';
import '../../blocs/game/game_config_bloc.dart';
import '../../blocs/game/game_config_event.dart';
import '../../blocs/game/game_config_state.dart';

/// Screen for configuring game settings before starting
class GameConfigScreen extends StatelessWidget {
  const GameConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<GameConfigBloc>()..add(const TagsLoadRequested()),
      child: const _GameConfigView(),
    );
  }
}

class _GameConfigView extends StatelessWidget {
  const _GameConfigView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
      ),
      body: BlocBuilder<GameConfigBloc, GameConfigState>(
        builder: (context, state) {
          if (state is GameConfigLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GameConfigError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<GameConfigBloc>().add(
                            const TagsLoadRequested(),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is GameConfigReady) {
            return _GameConfigForm(state: state);
          }

          if (state is GameConfigStarting) {
            // Navigate to game screen (will be implemented in M033/M039)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // TODO: Navigate to game screen based on mode
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Starting ${state.mode.value} game...'),
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          return const Center(child: Text('Initializing...'));
        },
      ),
    );
  }
}

class _GameConfigForm extends StatelessWidget {
  final GameConfigReady state;

  const _GameConfigForm({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Level Selection
          _buildSectionTitle('Difficulty Level'),
          const SizedBox(height: 8),
          _buildLevelSelector(context),
          const SizedBox(height: 24),

          // Type Selection
          _buildSectionTitle('Speech Type'),
          const SizedBox(height: 8),
          _buildTypeSelector(context),
          const SizedBox(height: 24),

          // Tag Selection
          _buildSectionTitle('Topics (Optional)'),
          const SizedBox(height: 8),
          _buildTagSelector(context),
          const SizedBox(height: 24),

          // Speech Count
          _buildSectionTitle('Number of Speeches'),
          const SizedBox(height: 8),
          _buildSpeechCountSelector(context),
          const SizedBox(height: 32),

          // Start Buttons
          _buildStartButton(
            context,
            'Listen Only',
            GameMode.listenOnly,
            Icons.headphones,
          ),
          const SizedBox(height: 12),
          _buildStartButton(
            context,
            'Listen & Repeat',
            GameMode.listenAndRepeat,
            Icons.mic,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLevelSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: SpeechLevel.values.map((level) {
        final isSelected = state.selectedLevel == level;
        return ChoiceChip(
          label: Text(_getLevelLabel(level)),
          selected: isSelected,
          onSelected: (_) {
            context.read<GameConfigBloc>().add(LevelChanged(level));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: SpeechType.values.map((type) {
        final isSelected = state.selectedType == type;
        return ChoiceChip(
          label: Text(_getTypeLabel(type)),
          selected: isSelected,
          onSelected: (_) {
            context.read<GameConfigBloc>().add(TypeChanged(type));
          },
        );
      }).toList(),
    );
  }

  Widget _buildTagSelector(BuildContext context) {
    if (state.availableTags.isEmpty) {
      return const Text(
        'No topics available',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      children: state.availableTags.map((tag) {
        final isSelected = state.selectedTagIds.contains(tag.id);
        return FilterChip(
          label: Text(tag.name),
          selected: isSelected,
          onSelected: (_) {
            context.read<GameConfigBloc>().add(TagToggled(tag.id));
          },
        );
      }).toList(),
    );
  }

  Widget _buildSpeechCountSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: state.speechCount.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            label: state.speechCount.toString(),
            onChanged: (value) {
              context.read<GameConfigBloc>().add(
                    SpeechCountChanged(value.toInt()),
                  );
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 48,
          child: Text(
            '${state.speechCount}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(
    BuildContext context,
    String label,
    GameMode mode,
    IconData icon,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<GameConfigBloc>().add(GameStartRequested(mode));
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
  }

  String _getLevelLabel(SpeechLevel level) {
    switch (level) {
      case SpeechLevel.beginner:
        return 'Beginner';
      case SpeechLevel.intermediate:
        return 'Intermediate';
      case SpeechLevel.advanced:
        return 'Advanced';
    }
  }

  String _getTypeLabel(SpeechType type) {
    switch (type) {
      case SpeechType.word:
        return 'Word';
      case SpeechType.phrase:
        return 'Phrase';
      case SpeechType.sentence:
        return 'Sentence';
      case SpeechType.paragraph:
        return 'Paragraph';
    }
  }
}
