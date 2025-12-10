import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../data/datasources/remote/speech_remote_datasource.dart';

/// Widget to display pronunciation scoring feedback
class PronunciationFeedbackCard extends StatefulWidget {
  final SpeechScoreResponse scoreResponse;
  final String referenceText;

  const PronunciationFeedbackCard({
    super.key,
    required this.scoreResponse,
    required this.referenceText,
  });

  @override
  State<PronunciationFeedbackCard> createState() =>
      _PronunciationFeedbackCardState();
}

class _PronunciationFeedbackCardState
    extends State<PronunciationFeedbackCard> {
  bool _showDetailedMetrics = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Pronunciation Score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Overall score with circular progress
            _buildOverallScore(),

            const SizedBox(height: 24),

            // Feedback message
            _buildFeedbackMessage(),

            const SizedBox(height: 24),

            // Word-by-word breakdown
            _buildWordBreakdown(),

            const SizedBox(height: 16),

            // Transcribed text comparison
            _buildTranscriptionComparison(),

            // Detailed metrics (expandable)
            if (widget.scoreResponse.detailedMetrics != null) ...[
              const SizedBox(height: 16),
              _buildDetailedMetrics(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallScore() {
    final score = widget.scoreResponse.pronunciationScore;
    final color = _getScoreColor(score);

    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress indicator
          SizedBox(
            width: 150,
            height: 150,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 24,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackMessage() {
    final score = widget.scoreResponse.pronunciationScore;
    String message;
    IconData icon;
    Color color;

    if (score >= 90) {
      message = 'Excellent! 🎉';
      icon = Icons.star;
      color = Colors.green;
    } else if (score >= 80) {
      message = 'Great job! 👍';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (score >= 70) {
      message = 'Good pronunciation ✓';
      icon = Icons.check_circle;
      color = Colors.lightGreen;
    } else if (score >= 60) {
      message = 'Keep practicing 💪';
      icon = Icons.trending_up;
      color = Colors.orange;
    } else {
      message = 'Try again 📚';
      icon = Icons.replay;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordBreakdown() {
    final words = widget.referenceText.split(' ');
    final wordScores = widget.scoreResponse.wordScores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Word-by-Word Analysis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: words.map((word) {
            final cleanWord = word.toLowerCase().replaceAll(
                  RegExp(r'[^\w\s]'),
                  '',
                ); // Remove punctuation
            final score = wordScores[cleanWord] ?? wordScores[word] ?? 0.0;
            final color = _getScoreColor(score);

            return Tooltip(
              message: '${score.toStringAsFixed(0)}%',
              child: Chip(
                label: Text(
                  word,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: color.withOpacity(0.2),
                side: BorderSide(color: color),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTranscriptionComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What you said:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.scoreResponse.transcribedText,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Reference:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.referenceText,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedMetrics() {
    return Column(
      children: [
        const Divider(),
        InkWell(
          onTap: () {
            setState(() {
              _showDetailedMetrics = !_showDetailedMetrics;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showDetailedMetrics
                      ? 'Hide Detailed Metrics'
                      : 'Show Detailed Metrics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _showDetailedMetrics
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (_showDetailedMetrics) ...[
          const SizedBox(height: 12),
          _buildMetricsGrid(),
        ],
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final metrics = widget.scoreResponse.detailedMetrics!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: metrics.entries.map((entry) {
          final key = entry.key;
          final value = entry.value;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMetricKey(key),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _formatMetricValue(value),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _formatMetricKey(String key) {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatMetricValue(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }
}
