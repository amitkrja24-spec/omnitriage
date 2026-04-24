import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/volunteer_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class TaskDetailPanel extends StatefulWidget {
  final TaskModel task;
  final List<VolunteerModel> allVolunteers;
  final Function(String) onDispatch;
  final VoidCallback onClose;

  const TaskDetailPanel({
    super.key,
    required this.task,
    required this.allVolunteers,
    required this.onDispatch,
    required this.onClose,
  });

  @override
  State<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends State<TaskDetailPanel> {
  late TextEditingController _noteController;
  bool _savingNote = false;
  bool _showRawInput = false;
  final FirestoreService _service = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.task.notes);
  }

  @override
  void didUpdateWidget(TaskDetailPanel old) {
    super.didUpdateWidget(old);
    if (old.task.taskId != widget.task.taskId) {
      _noteController.text = widget.task.notes;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() => _savingNote = true);
    await _service.addCoordinatorNote(widget.task.taskId, _noteController.text);
    if (mounted) setState(() => _savingNote = false);
  }

  Future<void> _markVerified() async {
    await _service.markVerified(widget.task.taskId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task verified and moved to Open'),
          backgroundColor: Color.fromARGB(255, 182, 236, 216),
        ),
      );
    }
  }

  Future<void> _markComplete() async {
    await _service.updateTaskStatus(widget.task.taskId, 'completed');
    if (mounted) widget.onClose();
  }

  List<VolunteerModel> get _involvedVolunteers {
    return widget.task.assignedVolunteers
        .map((id) =>
            widget.allVolunteers.where((v) => v.volunteerId == id).toList())
        .where((list) => list.isNotEmpty)
        .map((list) => list.first)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final urgencyColor = AppTheme.urgencyColor(task.urgency);
    final needColor = AppTheme.needTypeColor(task.needType);

    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingSM + 2,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    task.needTypeDisplay,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                ),
                // Short task ID
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '#${task.taskId.length > 8 ? task.taskId.substring(0, 8) : task.taskId}',
                    style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ──────────────────────────────────────
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              children: [
                // ── Status + urgency row ──────────────────────────
                Row(
                  children: [
                    _DetailChip(
                      icon: Icons.local_fire_department,
                      label: 'Urgency ${task.urgency}/5',
                      color: urgencyColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    _DetailChip(
                      icon: Icons.info_outline,
                      label: task.status.replaceAll('_', ' ').toUpperCase(),
                      color: task.status == 'open'
                          ? AppTheme.accentRed
                          : task.status == 'dispatching'
                              ? AppTheme.accentAmber
                              : task.status == 'completed'
                                  ? AppTheme.accentGreen
                                  : AppTheme.accentBlue,
                    ),
                    if (task.canAutoDispatch) ...[
                      const SizedBox(width: AppTheme.spacingSM),
                      _DetailChip(
                        icon: Icons.bolt,
                        label: 'Auto ✓',
                        color: AppTheme.accentGreen,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppTheme.spacingMD),

                // ── Location ───────────────────────────────────────
                _SectionCard(
                  title: 'LOCATION',
                  icon: Icons.location_on,
                  iconColor: AppTheme.accentRed,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.locationText,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (task.locationLat != null &&
                          task.locationLng != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${task.locationLat!.toStringAsFixed(4)}, Lng: ${task.locationLng!.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSM),

                // ── Brief description ─────────────────────────────
                if (task.briefDescription.isNotEmpty)
                  _SectionCard(
                    title: 'BRIEF',
                    icon: Icons.description_outlined,
                    iconColor: AppTheme.accentBlue,
                    child: Text(
                      task.briefDescription,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),

                if (task.briefDescription.isNotEmpty)
                  const SizedBox(height: AppTheme.spacingSM),

                // ── Source info ───────────────────────────────────
                _SectionCard(
                  title: 'REPORTED BY',
                  icon: Icons.send_outlined,
                  iconColor: AppTheme.accentOrange,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(task.sourceIcon,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: AppTheme.spacingSM),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.sourceNgoUser.isNotEmpty
                                    ? task.sourceNgoUser
                                    : 'Unknown',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'via ${task.sourceType}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (task.createdAt != null)
                            Text(
                              _formatDateTime(task.createdAt!),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      // Raw input collapsible
                      if (task.rawInputText.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingSM),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showRawInput = !_showRawInput),
                          child: Row(
                            children: [
                              Icon(
                                _showRawInput
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _showRawInput
                                    ? 'Hide original message'
                                    : 'Show original message',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showRawInput) ...[
                          const SizedBox(height: AppTheme.spacingSM),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spacingSM),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSM),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              task.rawInputText,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSM),

                // ── Stats row: people, volunteers, confidence ─────
                _SectionCard(
                  title: 'DETAILS',
                  icon: Icons.analytics_outlined,
                  iconColor: AppTheme.accentBlue,
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Volunteers needed',
                        value: '${task.countNeeded}',
                        valueColor: AppTheme.textPrimary,
                      ),
                      if (task.estimatedPeopleAffected != null)
                        _DetailRow(
                          label: 'People affected',
                          value: '~${task.estimatedPeopleAffected}',
                          valueColor: AppTheme.textPrimary,
                        ),
                      _DetailRow(
                        label: 'Skills required',
                        value: task.skillsRequired.isEmpty
                            ? 'None specified'
                            : task.skillsRequired.join(', '),
                        valueColor: AppTheme.textSecondary,
                      ),
                      _DetailRow(
                        label: 'AI confidence',
                        value: '${(task.confidenceScore * 100).round()}%',
                        valueColor: task.confidenceScore >= 0.80
                            ? AppTheme.accentGreen
                            : task.confidenceScore >= 0.60
                                ? AppTheme.accentAmber
                                : AppTheme.accentRed,
                      ),
                      if (task.timeToDispatchSeconds != null)
                        _DetailRow(
                          label: 'Dispatch time',
                          value: _formatSeconds(task.timeToDispatchSeconds!),
                          valueColor: AppTheme.accentGreen,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSM),

                // ── Assigned volunteers ───────────────────────────
                // ── Assigned / Pinged volunteers ───────────────────────────
                _SectionCard(
                  title: widget.task.assignedVolunteers.isNotEmpty
                      ? 'ASSIGNED VOLUNTEERS (${_involvedVolunteers.length})'
                      : 'PINGED / DISPATCHED TO (${_involvedVolunteers.length})',
                  icon: Icons.people_outline,
                  iconColor: AppTheme.accentGreen,
                  child: _involvedVolunteers.isEmpty
                      ? const Text(
                          'No volunteers assigned or pinged',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        )
                      : Column(
                          children: _involvedVolunteers
                              .map((v) =>
                                  _VolunteerMiniCard(volunteer: v, task: task))
                              .toList(),
                        ),
                ),

                const SizedBox(height: AppTheme.spacingSM),

                // ── Coordinator notes ─────────────────────────────
                _SectionCard(
                  title: 'COORDINATOR NOTES',
                  icon: Icons.edit_note,
                  iconColor: AppTheme.accentBlue,
                  child: Column(
                    children: [
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add notes for this task...',
                          hintStyle: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                            borderSide:
                                const BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSM),
                            borderSide: const BorderSide(
                                color: AppTheme.accentBlue, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(10),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSM),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: _savingNote ? null : _saveNote,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentBlue,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: _savingNote
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save note',
                                    style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacingSM),

                // ── Audit log ─────────────────────────────────────
                _AuditLogSection(taskId: task.taskId, service: _service),

                const SizedBox(height: AppTheme.spacingLG),
              ],
            ),
          ),

          // ── Action buttons ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                if (task.status == 'open') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onDispatch(task.taskId),
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text('CONFIRM MANUAL DISPATCH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentRed,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (task.needsReview) ...[
                    const SizedBox(height: AppTheme.spacingSM),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _markVerified,
                        icon: const Icon(Icons.verified_outlined, size: 14),
                        label: const Text('Mark as Verified'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentGreen,
                          side: const BorderSide(color: AppTheme.accentGreen),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
                if (task.status == 'dispatching') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _markComplete,
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text('MARK COMPLETE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatSeconds(int secs) {
    if (secs < 60) return '${secs}s';
    return '${secs ~/ 60}m ${secs % 60}s';
  }
}

// ── Section card container ───────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: iconColor),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          child,
        ],
      ),
    );
  }
}

// ── Key-value detail row ─────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small chip for status/urgency ────────────────────────────────
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Volunteer mini card ──────────────────────────────────────────
// ── Volunteer mini card with PROGRESS TRACKING ───────────────────
class _VolunteerMiniCard extends StatelessWidget {
  final VolunteerModel volunteer;
  final TaskModel task;
  const _VolunteerMiniCard({required this.volunteer, required this.task});

  Color get _statusColor {
    if (task.volunteerArrivals.containsKey(volunteer.telegramId))
      return AppTheme.accentGreen;
    if (task.assignedVolunteers.contains(volunteer.telegramId))
      return AppTheme.accentAmber;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final hasArrived = task.volunteerArrivals.containsKey(volunteer.telegramId);
    final arrivedAt =
        hasArrived ? task.volunteerArrivals[volunteer.telegramId] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingSM),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: _statusColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.accentRed.withOpacity(0.10),
            child: Text(
              volunteer.initials,
              style: const TextStyle(
                color: AppTheme.accentRed,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  volunteer.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ID: ${volunteer.telegramId}',
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasArrived) ...[
                const Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 10, color: AppTheme.accentGreen),
                    SizedBox(width: 2),
                    Text('ARRIVED ON SITE',
                        style: TextStyle(
                            color: AppTheme.accentGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                if (arrivedAt != null)
                  Text(
                      '${arrivedAt.hour.toString().padLeft(2, '0')}:${arrivedAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: AppTheme.accentGreen, fontSize: 9)),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.directions_run,
                        size: 10, color: AppTheme.accentAmber),
                    SizedBox(width: 2),
                    Text('EN ROUTE (Accepted)',
                        style: TextStyle(
                            color: AppTheme.accentAmber,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

// ── Audit log timeline ───────────────────────────────────────────
class _AuditLogSection extends StatelessWidget {
  final String taskId;
  final FirestoreService service;
  const _AuditLogSection({required this.taskId, required this.service});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'ACTIVITY LOG',
      icon: Icons.history,
      iconColor: AppTheme.textMuted,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.getAuditLogForTask(taskId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Text('Loading...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11));
          }
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const Text('No activity yet',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11));
          }
          return Column(
            children: entries.map((e) => _AuditEntry(entry: e)).toList(),
          );
        },
      ),
    );
  }
}

class _AuditEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _AuditEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final action = entry['action'] ?? '';
    final actor = entry['actor'] ?? '';
    final ts = entry['timestamp'];
    String timeStr = '';
    if (ts != null) {
      try {
        final dt = (ts as dynamic).toDate() as DateTime;
        timeStr =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accentBlue,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1,
                height: 14,
                color: AppTheme.border,
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.toString(),
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
                ),
                Row(
                  children: [
                    Text(actor.toString(),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10)),
                    if (timeStr.isNotEmpty) ...[
                      const Text(' · ',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                      Text(timeStr,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
