import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/enums.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/game_session.dart';
import '../../blocs/history/history_bloc.dart';
import '../../blocs/history/history_event.dart';
import '../../blocs/history/history_state.dart';
import 'session_detail_screen.dart';

/// Screen for viewing game session history with filters
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<HistoryBloc>()..add(const SessionsLoadRequested()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<HistoryBloc>().add(const SessionsLoadMoreRequested());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is HistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HistoryLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<HistoryBloc>()
                    .add(const SessionsRefreshRequested());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: Column(
                children: [
                  // Active filters chips
                  if (state.hasActiveFilters)
                    _buildActiveFilters(context, state),

                  // Sessions list
                  Expanded(
                    child: state.sessions.isEmpty
                        ? _buildEmptyState(context, state.hasActiveFilters)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: state.sessions.length +
                                (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.sessions.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              return _buildSessionCard(
                                context,
                                state.sessions[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('No sessions yet'));
        },
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context, HistoryLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (state.modeFilter != null)
            Chip(
              label: Text(state.modeFilter!.value),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                context.read<HistoryBloc>().add(const ModeFilterChanged(null));
              },
            ),
          if (state.levelFilter != null)
            Chip(
              label: Text(state.levelFilter!.value),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                context.read<HistoryBloc>().add(const LevelFilterChanged(null));
              },
            ),
          if (state.startDateFilter != null || state.endDateFilter != null)
            Chip(
              label: Text(_formatDateRange(
                state.startDateFilter,
                state.endDateFilter,
              )),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                context.read<HistoryBloc>().add(const DateRangeFilterChanged());
              },
            ),
          TextButton.icon(
            onPressed: () {
              context.read<HistoryBloc>().add(const FiltersClearedRequested());
            },
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No sessions match filters'
                  : 'No practice sessions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters'
                  : 'Start practicing to see your history',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, GameSession session) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final isCorrect = session.accuracy >= 70.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(sessionId: session.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Mode icon
                  Icon(
                    session.mode == GameMode.listenOnly
                        ? Icons.hearing
                        : Icons.mic,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),

                  // Mode and level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.mode.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          session.level.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Accuracy badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${session.accuracy.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _buildStatChip(
                    Icons.check_circle,
                    '${session.results.where((r) => r.correct).length} correct',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.cancel,
                    '${session.results.where((r) => !r.correct).length} incorrect',
                    Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.timer,
                    '${session.duration}s',
                    Colors.blue,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Date and sync status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(session.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  _buildSyncStatusBadge(session.syncStatus),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBadge(SyncStatus status) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'Synced';
        break;
      case SyncStatus.pending:
        icon = Icons.cloud_upload;
        color = Colors.orange;
        tooltip = 'Pending sync';
        break;
      case SyncStatus.syncing:
        icon = Icons.cloud_sync;
        color = Colors.blue;
        tooltip = 'Syncing...';
        break;
      case SyncStatus.failed:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = 'Sync failed';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 18, color: color),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final format = DateFormat('MMM d');
    if (start != null && end != null) {
      return '${format.format(start)} - ${format.format(end)}';
    } else if (start != null) {
      return 'From ${format.format(start)}';
    } else if (end != null) {
      return 'Until ${format.format(end)}';
    }
    return '';
  }

  void _showFilterDialog(BuildContext context) {
    final bloc = context.read<HistoryBloc>();
    final currentState =
        bloc.state is HistoryLoaded ? bloc.state as HistoryLoaded : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => _FilterSheet(
        initialMode: currentState?.modeFilter,
        initialLevel: currentState?.levelFilter,
        initialStartDate: currentState?.startDateFilter,
        initialEndDate: currentState?.endDateFilter,
        onApply: (mode, level, startDate, endDate) {
          if (mode != currentState?.modeFilter) {
            bloc.add(ModeFilterChanged(mode));
          }
          if (level != currentState?.levelFilter) {
            bloc.add(LevelFilterChanged(level));
          }
          if (startDate != currentState?.startDateFilter ||
              endDate != currentState?.endDateFilter) {
            bloc.add(DateRangeFilterChanged(
              startDate: startDate,
              endDate: endDate,
            ));
          }
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final GameMode? initialMode;
  final SpeechLevel? initialLevel;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(GameMode?, SpeechLevel?, DateTime?, DateTime?) onApply;

  const _FilterSheet({
    this.initialMode,
    this.initialLevel,
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  GameMode? _selectedMode;
  SpeechLevel? _selectedLevel;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _selectedLevel = widget.initialLevel;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Sessions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Mode filter
          const Text(
            'Game Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedMode == null,
                onSelected: (selected) {
                  setState(() => _selectedMode = null);
                },
              ),
              ...GameMode.values.map((mode) => ChoiceChip(
                    label: Text(mode.value),
                    selected: _selectedMode == mode,
                    onSelected: (selected) {
                      setState(() => _selectedMode = selected ? mode : null);
                    },
                  )),
            ],
          ),

          const SizedBox(height: 24),

          // Level filter
          const Text(
            'Speech Level',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedLevel == null,
                onSelected: (selected) {
                  setState(() => _selectedLevel = null);
                },
              ),
              ...SpeechLevel.values.map((level) => ChoiceChip(
                    label: Text(level.value),
                    selected: _selectedLevel == level,
                    onSelected: (selected) {
                      setState(() => _selectedLevel = selected ? level : null);
                    },
                  )),
            ],
          ),

          const SizedBox(height: 24),

          // Date range filter
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_startDate == null
                      ? 'Start Date'
                      : DateFormat('MMM d, y').format(_startDate!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_endDate == null
                      ? 'End Date'
                      : DateFormat('MMM d, y').format(_endDate!)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMode = null;
                      _selectedLevel = null;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _selectedMode,
                      _selectedLevel,
                      _startDate,
                      _endDate,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
