import 'package:flutter/material.dart';
import '../../../core/constants/enums.dart';
import '../../../domain/entities/game_session.dart';

/// Screen displaying game session summary and statistics
class GameSummaryScreen extends StatelessWidget {
  final GameSession session;

  const GameSummaryScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Completion message
            _buildCompletionMessage(context),
            const SizedBox(height: 24),

            // Score card
            _buildScoreCard(context),
            const SizedBox(height: 24),

            // Statistics grid
            _buildStatisticsGrid(context),
            const SizedBox(height: 24),

            // Session info
            _buildSessionInfo(context),
            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionMessage(BuildContext context) {
    final accuracy = session.accuracy;
    String message;
    IconData icon;
    Color color;

    if (accuracy >= 90) {
      message = 'Outstanding! 🎉';
      icon = Icons.emoji_events;
      color = Colors.amber;
    } else if (accuracy >= 70) {
      message = 'Great Job! 👏';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (accuracy >= 50) {
      message = 'Good Effort! 💪';
      icon = Icons.sentiment_satisfied;
      color = Colors.blue;
    } else {
      message = 'Keep Practicing! 📚';
      icon = Icons.school;
      color = Colors.orange;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final accuracy = session.accuracy;
    final color = _getAccuracyColor(accuracy);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Your Score',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: accuracy / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Text(
                      'Accuracy',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreDetail(
                  'Correct',
                  session.correctCount.toString(),
                  Colors.green,
                ),
                _buildScoreDetail(
                  'Incorrect',
                  session.incorrectCount.toString(),
                  Colors.red,
                ),
                _buildScoreDetail(
                  'Total',
                  session.totalSpeeches.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard(
              icon: Icons.local_fire_department,
              label: 'Best Streak',
              value: session.streakCount.toString(),
              color: Colors.orange,
            ),
            _buildStatCard(
              icon: Icons.timer,
              label: 'Duration',
              value: _formatDuration(),
              color: Colors.purple,
            ),
            if (session.averageScore != null)
              _buildStatCard(
                icon: Icons.mic,
                label: 'Avg Score',
                value: '${session.averageScore!.toStringAsFixed(0)}%',
                color: Colors.teal,
              ),
            _buildStatCard(
              icon: _getSyncIcon(),
              label: 'Sync Status',
              value: _getSyncLabel(),
              color: _getSyncColor(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Mode', _getModeLabel()),
            _buildInfoRow('Level', _getLevelLabel()),
            _buildInfoRow('Type', _getTypeLabel()),
            if (session.completedAt != null)
              _buildInfoRow(
                'Completed',
                _formatDateTime(session.completedAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Navigate back to game config for a new session
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.replay),
          label: const Text('Play Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // Navigate to history screen
            Navigator.of(context).popUntil((route) => route.isFirst);
            // TODO: Navigate to history screen
          },
          icon: const Icon(Icons.history),
          label: const Text('View History'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Text('Back to Home'),
        ),
      ],
    );
  }

  // Helper methods

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 90) return Colors.amber;
    if (accuracy >= 70) return Colors.green;
    if (accuracy >= 50) return Colors.blue;
    return Colors.orange;
  }

  String _formatDuration() {
    if (session.completedAt == null) return 'Incomplete';
    final duration = session.completedAt!.difference(session.startedAt);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  IconData _getSyncIcon() {
    switch (session.syncStatus) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.pending:
        return Icons.cloud_queue;
      case SyncStatus.failed:
        return Icons.cloud_off;
    }
  }

  String _getSyncLabel() {
    switch (session.syncStatus) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.pending:
        return 'Pending';
      case SyncStatus.failed:
        return 'Failed';
    }
  }

  Color _getSyncColor() {
    switch (session.syncStatus) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.failed:
        return Colors.red;
    }
  }

  String _getModeLabel() {
    switch (session.mode) {
      case GameMode.listenOnly:
        return 'Listen Only';
      case GameMode.listenAndRepeat:
        return 'Listen & Repeat';
      case GameMode.practice:
        return 'Practice';
      case GameMode.challenge:
        return 'Challenge';
    }
  }

  String _getLevelLabel() {
    switch (session.level) {
      case SpeechLevel.beginner:
        return 'Beginner';
      case SpeechLevel.intermediate:
        return 'Intermediate';
      case SpeechLevel.advanced:
        return 'Advanced';
    }
  }

  String _getTypeLabel() {
    switch (session.type) {
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
