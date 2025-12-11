import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/enums.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/game_result.dart';
import '../../../domain/entities/game_session.dart';
import '../../../domain/usecases/game/get_session_detail_usecase.dart';

/// Screen for viewing detailed session statistics
class SessionDetailScreen extends StatelessWidget {
  final String sessionId;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: FutureBuilder<GameSession>(
        future: _loadSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load session',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Session not found'));
          }

          final session = snapshot.data!;
          return _SessionDetailView(session: session);
        },
      ),
    );
  }

  Future<GameSession> _loadSession() async {
    final useCase = getIt<GetSessionDetailUseCase>();
    final result = await useCase(sessionId);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (session) => session,
    );
  }
}

class _SessionDetailView extends StatelessWidget {
  final GameSession session;

  const _SessionDetailView({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d, y • h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session header card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Mode and level
                  Row(
                    children: [
                      Icon(
                        session.mode == GameMode.listenOnly
                            ? Icons.hearing
                            : Icons.mic,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.mode.value,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              session.level.value,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(session.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Sync status
                  Row(
                    children: [
                      Icon(_getSyncIcon(session.syncStatus),
                          size: 16, color: _getSyncColor(session.syncStatus)),
                      const SizedBox(width: 8),
                      Text(
                        _getSyncLabel(session.syncStatus),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getSyncColor(session.syncStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Statistics grid
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatisticsGrid(context),

          const SizedBox(height: 24),

          // Speech breakdown
          const Text(
            'Speech Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...session.results.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            return _buildResultCard(context, index + 1, result);
          }),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(BuildContext context) {
    final correctCount = session.results.where((r) => r.correct).length;
    final incorrectCount = session.results.where((r) => !r.correct).length;
    final totalCount = session.results.length;
    final avgScore = session.results.isEmpty
        ? 0.0
        : session.results.map((r) => r.pronunciationScore ?? 0).reduce((a, b) => a + b) /
            totalCount;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Accuracy',
          '${session.accuracy.toStringAsFixed(0)}%',
          Icons.percent,
          session.accuracy >= 70 ? Colors.green : Colors.orange,
        ),
        _buildStatCard(
          context,
          'Correct',
          '$correctCount / $totalCount',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Duration',
          '${session.duration}s',
          Icons.timer,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Avg Score',
          avgScore.toStringAsFixed(0),
          Icons.star,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context,
    int index,
    GameResult result,
  ) {
    final color = result.correct ? Colors.green : Colors.red;
    final icon = result.correct ? Icons.check_circle : Icons.cancel;
    final hasScore = result.pronunciationScore != null && result.pronunciationScore! > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Index
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Result info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 8),
                      Text(
                        result.correct ? 'Correct' : 'Incorrect',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  if (hasScore) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Score: ${result.pronunciationScore}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm:ss a').format(result.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Score badge (for listen-and-repeat mode)
            if (hasScore)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getScoreColor(result.pronunciationScore!.toInt()).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getScoreColor(result.pronunciationScore!.toInt()),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${result.pronunciationScore!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(result.pronunciationScore!.toInt()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getSyncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.pending:
        return Icons.cloud_upload;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.failed:
        return Icons.cloud_off;
    }
  }

  Color _getSyncColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.failed:
        return Colors.red;
    }
  }

  String _getSyncLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced to cloud';
      case SyncStatus.pending:
        return 'Pending sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.failed:
        return 'Sync failed';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
