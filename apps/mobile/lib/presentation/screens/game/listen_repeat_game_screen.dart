import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/enums.dart';
import '../../../di/injection.dart';
import '../../blocs/game/game_bloc.dart';
import '../../blocs/game/game_event.dart';
import '../../blocs/game/game_state.dart';
import '../../widgets/pronunciation_feedback_card.dart';
import 'game_summary_screen.dart';

/// Screen for Listen-and-Repeat game mode with pronunciation scoring
class ListenRepeatGameScreen extends StatelessWidget {
  final GameMode mode;
  final SpeechLevel level;
  final SpeechType type;
  final List<String> tagIds;
  final int count;

  const ListenRepeatGameScreen({
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
      child: const _ListenRepeatGameView(),
    );
  }
}

class _ListenRepeatGameView extends StatelessWidget {
  const _ListenRepeatGameView();

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
            title: const Text('Listen & Repeat'),
            actions: [
              if (state is GameReady || state is GameRecording) ...[
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {
                    // Cancel recording if in progress
                    if (state is GameRecording) {
                      context.read<GameBloc>().add(const RecordingCancelled());
                    }
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
      return _buildGameReady(context, state);
    }

    if (state is GameRecording) {
      return _buildGameRecording(context, state);
    }

    if (state is GameTranscribing) {
      return _buildGameTranscribing(context, state);
    }

    if (state is GameScoreReady) {
      return _buildGameScoreReady(context, state);
    }

    if (state is GamePaused) {
      return _buildGameReady(context, state.previousState);
    }

    return const Center(child: Text('Ready to start'));
  }

  Widget _buildGameReady(BuildContext context, GameReady state) {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(state),

        // Stats bar
        _buildStatsBar(state),

        // Speech card with record button
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Speech text card
                  _buildSpeechCard(context, state),

                  const SizedBox(height: 32),

                  // Audio replay button
                  IconButton(
                    icon: Icon(
                      state.isAudioPlaying ? Icons.volume_up : Icons.replay,
                      size: 40,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      context
                          .read<GameBloc>()
                          .add(const AudioReplayRequested());
                    },
                  ),

                  const SizedBox(height: 48),

                  // Record button
                  _buildRecordButton(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameRecording(BuildContext context, GameRecording state) {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(state.previousState),

        // Stats bar
        _buildStatsBar(state.previousState),

        // Recording indicator
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing microphone icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.mic,
                        size: 100,
                        color: Colors.red,
                      ),
                    );
                  },
                  onEnd: () {
                    // Repeat animation
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Recording...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 48),

                // Stop recording button
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<GameBloc>().add(const RecordingStopped());
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel button
                TextButton(
                  onPressed: () {
                    context.read<GameBloc>().add(const RecordingCancelled());
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameTranscribing(
    BuildContext context,
    GameTranscribing state,
  ) {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(state.previousState),

        // Stats bar
        _buildStatsBar(state.previousState),

        // Processing indicator
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'Processing pronunciation...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameScoreReady(BuildContext context, GameScoreReady state) {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(state.previousState),

        // Stats bar
        _buildStatsBar(state.previousState),

        // Pronunciation feedback
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                PronunciationFeedbackCard(
                  scoreResponse: state.scoreResponse,
                  referenceText: state.previousState.currentSpeech.text,
                ),
                const SizedBox(height: 24),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<GameBloc>().add(const ScoreAcknowledged());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(GameReady state) {
    final progress = (state.currentIndex + 1) / state.speeches.length;

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey[300],
      minHeight: 8,
    );
  }

  Widget _buildStatsBar(GameReady state) {
    final correctCount = state.results.where((r) => r.correct).length;
    final incorrectCount = state.results.where((r) => !r.correct).length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
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
            value: '${state.accuracy.toStringAsFixed(0)}%',
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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

  Widget _buildSpeechCard(BuildContext context, GameReady state) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Speech ${state.currentIndex + 1} of ${state.speeches.length}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.currentSpeech.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<GameBloc>().add(const RecordingStarted());
      },
      icon: const Icon(Icons.mic, size: 32),
      label: const Text(
        'Start Recording',
        style: TextStyle(fontSize: 20),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 48,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Game Paused'),
        content: const Text('Would you like to resume or quit?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GameBloc>().add(const GameQuitRequested());
              Navigator.of(context).pop();
            },
            child: const Text('Quit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<GameBloc>().add(const GameResumed());
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}
