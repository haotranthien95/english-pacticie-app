import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/enums.dart';
import '../../../di/injection.dart';
import '../../blocs/game/game_bloc.dart';
import '../../blocs/game/game_event.dart';
import '../../blocs/game/game_state.dart';
import 'game_summary_screen.dart';

/// Screen for Listen-Only game mode with swipe cards
class ListenOnlyGameScreen extends StatelessWidget {
  final GameMode mode;
  final SpeechLevel level;
  final SpeechType type;
  final List<String> tagIds;
  final int count;

  const ListenOnlyGameScreen({
    super.key,
    required this.mode,
    required this.level,
    required this.type,
    required this.tagIds,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<GameBloc>()
        ..add(GameStarted(
          mode: mode,
          level: level,
          type: type,
          tagIds: tagIds,
          count: count,
        )),
      child: const _ListenOnlyGameView(),
    );
  }
}

class _ListenOnlyGameView extends StatelessWidget {
  const _ListenOnlyGameView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameCompleted) {
          // Navigate to summary screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GameSummaryScreen(session: state.session),
            ),
          );
        } else if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Listen & Answer'),
            actions: [
              if (state is GameReady) ...[
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {
                    context.read<GameBloc>().add(const GamePauseRequested());
                    _showPauseDialog(context);
                  },
                ),
              ],
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GameState state) {
    if (state is GameLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading speeches...'),
          ],
        ),
      );
    }

    if (state is GameReady) {
      return _GamePlayContent(state: state);
    }

    if (state is GameSaving) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Saving your progress...'),
          ],
        ),
      );
    }

    if (state is GameError) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('Initializing...'));
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Game Paused'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GameBloc>().add(const GameResumed());
            },
            child: const Text('Resume'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GameBloc>().add(const GameQuitRequested());
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}

class _GamePlayContent extends StatelessWidget {
  final GameReady state;

  const _GamePlayContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(context),

        // Stats section
        _buildStatsSection(context),

        // Main card area
        Expanded(
          child: Center(
            child: _buildSpeechCard(context),
          ),
        ),

        // Control buttons
        _buildControlButtons(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = (state.currentIndex + 1) / state.speeches.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${state.currentIndex + 1}/${state.speeches.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final correctCount = state.results.where((r) => r.correct).length;
    final incorrectCount = state.results.length - correctCount;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.check_circle,
            label: 'Correct',
            value: correctCount.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.cancel,
            label: 'Incorrect',
            value: incorrectCount.toString(),
            color: Colors.red,
          ),
          _buildStatItem(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: state.streakCount.toString(),
            color: Colors.orange,
          ),
          _buildStatItem(
            icon: Icons.percent,
            label: 'Accuracy',
            value: state.results.isEmpty
                ? '0%'
                : '${state.accuracy.toStringAsFixed(0)}%',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildSpeechCard(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -500) {
            // Swipe left (incorrect)
            context.read<GameBloc>().add(const SwipeLeftRequested());
          } else if (details.primaryVelocity! > 500) {
            // Swipe right (correct)
            context.read<GameBloc>().add(const SwipeRightRequested());
          }
        }
      },
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio icon with playing indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  if (state.isAudioPlaying)
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  Icon(
                    state.isAudioPlaying ? Icons.volume_up : Icons.headphones,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Speech text
              Text(
                state.currentSpeech.text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Replay button
              OutlinedButton.icon(
                onPressed: () {
                  context.read<GameBloc>().add(const AudioReplayRequested());
                },
                icon: const Icon(Icons.replay),
                label: const Text('Replay Audio'),
              ),
              const SizedBox(height: 16),

              // Swipe instruction
              const Text(
                'Swipe left if incorrect, right if correct',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Incorrect button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<GameBloc>().add(const SwipeLeftRequested());
              },
              icon: const Icon(Icons.close, size: 32),
              label: const Text('Incorrect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Correct button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<GameBloc>().add(const SwipeRightRequested());
              },
              icon: const Icon(Icons.check, size: 32),
              label: const Text('Correct'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
