import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ── Models
import '../models/task_model.dart';
import '../models/volunteer_model.dart';

// ── Services
import '../services/firestore_service.dart';

// ── Theme
import '../theme/app_theme.dart';

// ── Widgets
import '../widgets/header_bar.dart';
import '../widgets/stats_row.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_panel.dart';
import '../widgets/notification_banner.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';
import '../widgets/offline_banner.dart';

// ── Screens (Note: They are in the same folder now, so no path needed)
import 'volunteer_roster_screen.dart';

// Cloud Function URL (local emulator during development)
// ⚑ CHANGE THIS to your ngrok URL + function path before demo
const String DISPATCH_FUNCTION_URL =
    'https://anteater-tanned-delta.ngrok-free.dev/akankchaproject/us-central1/manualDispatch';

class CoordinatorDashboard extends StatefulWidget {
  const CoordinatorDashboard({super.key});

  @override
  State<CoordinatorDashboard> createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  final FirestoreService _service = FirestoreService();

  TaskModel? _selectedTask;
  List<TaskModel> _tasks = [];
  List<VolunteerModel> _volunteers = [];

  // Notification banner
  final List<TaskModel> _pendingNotifications = [];
  StreamSubscription? _taskSub;
  StreamSubscription? _volSub;
  Set<String> _seenTaskIds = {};

  // Filters
  String? _filterNeedType;
  int? _filterMinUrgency;

  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _startStreams();
  }

  void _startStreams() {
    _taskSub = _service.getActiveTasks().listen(
      (tasks) {
        // Detect new critical tasks for notification banner
        for (final t in tasks) {
          if (!_seenTaskIds.contains(t.taskId) && t.urgency >= 4) {
            setState(() => _pendingNotifications.add(t));
          }
          _seenTaskIds.add(t.taskId);
        }
        if (mounted)
          setState(() {
            _tasks = tasks;
            _isOffline = false;
          });
      },
      onError: (_) {
        if (mounted) setState(() => _isOffline = true);
      },
    );

    _volSub = _service.getAllVolunteers().listen((vols) {
      if (mounted) setState(() => _volunteers = vols);
    });
  }

  @override
  void dispose() {
    _taskSub?.cancel();
    _volSub?.cancel();
    super.dispose();
  }

  Future<void> _dispatchTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse(DISPATCH_FUNCTION_URL),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: jsonEncode({'taskId': taskId}),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispatch successful'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispatch failed: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _autoDispatchAll() async {
    final eligible =
        _tasks.where((t) => t.status == 'open' && t.canAutoDispatch).toList();
    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No eligible tasks for auto-dispatch')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Auto-dispatch all?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'This will dispatch all ${eligible.length} open task${eligible.length > 1 ? "s" : ""} to matched volunteers. Continue?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Dispatch all')),
        ],
      ),
    );

    if (confirmed == true) {
      for (final t in eligible) {
        await _dispatchTask(t.taskId);
      }
    }
  }

  List<TaskModel> get _filteredTasks {
    var filtered = List<TaskModel>.from(_tasks);
    if (_filterNeedType != null) {
      filtered = filtered.where((t) => t.needType == _filterNeedType).toList();
    }
    if (_filterMinUrgency != null) {
      filtered =
          filtered.where((t) => t.urgency >= _filterMinUrgency!).toList();
    }
    return filtered;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Filter Tasks',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need Type:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                null,
                'medical',
                'food_ration',
                'sanitation',
                'education',
                'disaster',
                'other'
              ]
                  .map((type) => GestureDetector(
                        onTap: () {
                          setState(() => _filterNeedType = type);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _filterNeedType == type
                                ? AppTheme.accentOrange
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            type == null ? 'All' : type.replaceAll('_', ' '),
                            style: TextStyle(
                              color: _filterNeedType == type
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            const Text('Min Urgency:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Row(
              children: [null, 3, 4, 5]
                  .map((u) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _filterMinUrgency = u);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _filterMinUrgency == u
                                  ? AppTheme.accentOrange
                                  : AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              u == null ? 'All' : '$u+',
                              style: TextStyle(
                                color: _filterMinUrgency == u
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterNeedType = null;
                _filterMinUrgency = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear all filters'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final newCount = filtered.where((t) => t.isNew).length;

    return Scaffold(
      endDrawer: const Drawer(
        width: 360,
        backgroundColor: AppTheme.surface,
        child: VolunteerRosterScreen(),
      ),
      body: Column(
        children: [
          // ── Header
          HeaderBar(),

          // ── Offline banner
          if (_isOffline) const OfflineBanner(),

          // ── Notification banners
          if (_pendingNotifications.isNotEmpty)
            NotificationBanner(
              task: _pendingNotifications.last,
              onDismiss: () =>
                  setState(() => _pendingNotifications.removeLast()),
              onDispatch: () {
                _dispatchTask(_pendingNotifications.last.taskId);
                setState(() => _pendingNotifications.removeLast());
              },
              onView: () {
                setState(() {
                  _selectedTask = _pendingNotifications.last;
                  _pendingNotifications.removeLast();
                });
              },
            ),

          // ── Stats row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLG, vertical: AppTheme.spacingSM),
            child: const StatsRow(),
          ),

          // ── Main content
          Expanded(
            child: Row(
              children: [
                // ── Task list (left)
                Expanded(
                  flex: _selectedTask != null ? 6 : 10,
                  child: Column(
                    children: [
                      // ── Section header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLG,
                          vertical: AppTheme.spacingSM,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Tasks',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: AppTheme.spacingSM),
                            Text(
                              '— sorted by urgency',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textMuted),
                            ),
                            if (newCount > 0) ...[
                              const SizedBox(width: AppTheme.spacingSM),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAmber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$newCount new since last check',
                                  style: const TextStyle(
                                      color: AppTheme.accentAmber,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _showFilterDialog,
                              icon: const Icon(Icons.filter_list,
                                  size: 14, color: AppTheme.textSecondary),
                              label: Text(
                                'Filter${_filterNeedType != null || _filterMinUrgency != null ? " ●" : ""}',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSM),
                            ElevatedButton.icon(
                              onPressed: _autoDispatchAll,
                              icon: const Icon(Icons.send, size: 14),
                              label: const Text('Auto-dispatch all ↗',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppTheme.accentOrange.withOpacity(0.8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Task list
                      Expanded(
                        child: _tasks.isEmpty
                            ? const SkeletonLoader(itemCount: 3)
                            : filtered.isEmpty
                                ? const EmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingLG,
                                      vertical: AppTheme.spacingSM,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (ctx, i) => TaskCard(
                                      task: filtered[i],
                                      isSelected: _selectedTask?.taskId ==
                                          filtered[i].taskId,
                                      onTap: () => setState(() {
                                        _selectedTask = _selectedTask?.taskId ==
                                                filtered[i].taskId
                                            ? null
                                            : filtered[i];
                                      }),
                                      onDispatch: _dispatchTask,
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),

                // ── Detail panel (right, slide-in)
                if (_selectedTask != null) ...[
                  Container(width: 1, color: AppTheme.border),
                  AnimatedContainer(
                    duration: AppTheme.animMedium,
                    width: 380,
                    child: TaskDetailPanel(
                      task: _selectedTask!,
                      allVolunteers: _volunteers,
                      onDispatch: _dispatchTask,
                      onClose: () => setState(() => _selectedTask = null),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
