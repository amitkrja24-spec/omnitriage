import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/volunteer_model.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(String) onDispatch;
  final List<VolunteerModel> allVolunteers;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onDispatch,
    this.allVolunteers = const [],
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 seconds so "time ago" label stays current
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeAgo {
    if (widget.task.createdAt == null) return '';
    final diff = DateTime.now().difference(widget.task.createdAt!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Returns display names of assigned volunteers from the master list
  // Returns display names of assigned volunteers from the master list
  List<String> get _assignedNames {
    if (widget.task.assignedVolunteers.isEmpty) return [];
    return widget.task.assignedVolunteers.map((id) {
      final match = widget.allVolunteers
          // CRITICAL FIX: Match by EITHER Firestore ID or Telegram ID
          .where((v) => v.volunteerId == id || v.telegramId == id)
          .toList();
      return match.isNotEmpty ? match.first.name : id;
    }).toList();
  }

  // Timer-style urgency pulse color (used in border when selected + critical)
  Color get _borderColor {
    if (!widget.isSelected) return AppTheme.border;
    if (widget.task.urgency >= 4)
      return AppTheme.urgencyColor(widget.task.urgency);
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final urgencyColor = AppTheme.urgencyColor(task.urgency);
    final needColor = AppTheme.needTypeColor(task.needType);
    final needIcon = AppTheme.needTypeIcon(task.needType);
    final names = _assignedNames;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.accentRed.withOpacity(0.03)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: _borderColor,
            width: widget.isSelected ? 1.5 : 1.0,
          ),
          boxShadow: widget.isSelected
              ? AppTheme.cardShadowElevated
              : AppTheme.cardShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left urgency strip ─────────────────────────────
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMD),
                    bottomLeft: Radius.circular(AppTheme.radiusMD),
                  ),
                ),
              ),

              // ── Card content ───────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── ROW 1: Type badge + urgency + NEW/REVIEW flags + time ──
                      Row(
                        children: [
                          // Need type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: needColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: needColor.withOpacity(0.30)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(needIcon,
                                    style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                Text(
                                  task.needTypeDisplay,
                                  style: TextStyle(
                                    color: needColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 5),

                          // Urgency badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: urgencyColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'U${task.urgency}',
                              style: TextStyle(
                                color: urgencyColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),

                          if (task.needsReview) ...[
                            const SizedBox(width: 5),
                            _MicroBadge(
                              label: '⚠ REVIEW',
                              color: AppTheme.accentAmber,
                            ),
                          ],

                          if (task.isNew) ...[
                            const SizedBox(width: 5),
                            _MicroBadge(
                              label: 'NEW',
                              color: AppTheme.accentGreen,
                            ),
                          ],

                          if (task.dispatchTimeout) ...[
                            const SizedBox(width: 5),
                            _MicroBadge(
                              label: '⏱ TIMEOUT',
                              color: AppTheme.accentRed,
                            ),
                          ],

                          const Spacer(),

                          // Live time ago
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time,
                                    size: 10, color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Text(
                                  _timeAgo,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingSM),

                      // ── ROW 2: Location ────────────────────────
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 12, color: AppTheme.accentRed),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              task.locationText,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Brief description (if present)
                      if (task.briefDescription.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.briefDescription,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingSM),

                      // ── ROW 3: Sender → Assigned → Dispatch ───
                      Row(
                        children: [
                          // Source type icon + sender name
                          Flexible(
                            flex: 3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task.sourceIcon,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    task.sourceNgoUser.isNotEmpty
                                        ? task.sourceNgoUser
                                        : 'Unknown sender',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Arrow + assigned volunteers
                          if (names.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(Icons.arrow_forward,
                                  size: 10, color: AppTheme.textMuted),
                            ),
                            Flexible(
                              flex: 3,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person,
                                      size: 11, color: AppTheme.accentGreen),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      names.take(2).join(', ') +
                                          (names.length > 2
                                              ? ' +${names.length - 2}'
                                              : ''),
                                      style: const TextStyle(
                                        color: AppTheme.accentGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (task.status == 'open') ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Unassigned',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10),
                            ),
                          ],

                          const Spacer(),

                          // Dispatch button or status chip
                          if (task.status == 'open')
                            _DispatchButton(
                                onTap: () => widget.onDispatch(task.taskId))
                          else
                            _StatusChip(status: task.status),
                        ],
                      ),

                      // ── ROW 4: People affected + volunteers needed + AI confidence ──
                      if (task.estimatedPeopleAffected != null ||
                          task.countNeeded > 1) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (task.estimatedPeopleAffected != null) ...[
                              const Icon(Icons.people_outline,
                                  size: 11, color: AppTheme.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                '~${task.estimatedPeopleAffected} affected',
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 10),
                              ),
                              const SizedBox(width: 10),
                            ],
                            const Icon(Icons.group_add_outlined,
                                size: 11, color: AppTheme.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              '${task.countNeeded} vol${task.countNeeded > 1 ? "s" : ""} needed',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 10),
                            ),
                            const Spacer(),
                            _ConfidenceBar(score: task.confidenceScore),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Micro badge ─────────────────────────────────────────────────
class _MicroBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MicroBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Status chip for non-open tasks ──────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (status) {
      case 'dispatching':
        color = AppTheme.accentAmber;
        label = '↗ Dispatching';
        break;
      case 'completed':
        color = AppTheme.accentGreen;
        label = '✓ Completed';
        break;
      case 'flagged_medium':
        color = AppTheme.accentBlue;
        label = '⚑ Flagged Med';
        break;
      case 'flagged_low':
        color = AppTheme.accentBlue;
        label = '⚑ Flagged Low';
        break;
      default:
        color = AppTheme.textMuted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Dispatch button ──────────────────────────────────────────────
class _DispatchButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DispatchButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.accentRed,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentRed.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'DISPATCH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

// ── AI confidence bar ────────────────────────────────────────────
class _ConfidenceBar extends StatelessWidget {
  final double score;
  const _ConfidenceBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    final color = score >= 0.80
        ? AppTheme.accentGreen
        : score >= 0.60
            ? AppTheme.accentAmber
            : AppTheme.accentRed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AI $pct%',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 36,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
