import 'package:flutter/material.dart';
import '../models/volunteer_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class VolunteerRosterScreen extends StatefulWidget {
  const VolunteerRosterScreen({super.key});

  @override
  State<VolunteerRosterScreen> createState() => _VolunteerRosterScreenState();
}

class _VolunteerRosterScreenState extends State<VolunteerRosterScreen> {
  String _search = '';
  String _filter = 'All'; // All / Available / On duty / Offline

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              Text('Volunteer Roster',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),

        // ── Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search by name or skill...',
              hintStyle:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, size: 16, color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),

        const SizedBox(height: AppTheme.spacingSM),

        // ── Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: Row(
            children: ['All', 'Available', 'On duty', 'Offline']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spacingSM),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _filter == f
                                ? AppTheme.accentOrange
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _filter == f
                                    ? AppTheme.accentOrange
                                    : AppTheme.border),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                color: _filter == f
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: AppTheme.spacingSM),

        // ── Volunteer list
        Expanded(
          child: StreamBuilder<List<VolunteerModel>>(
            stream: FirestoreService().getAllVolunteers(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.accentOrange));
              }

              var volunteers = snap.data!;

              // Apply search filter
              if (_search.isNotEmpty) {
                volunteers = volunteers
                    .where((v) =>
                        v.name.toLowerCase().contains(_search) ||
                        v.skills.any((s) => s.contains(_search)) ||
                        v.areaName.toLowerCase().contains(_search))
                    .toList();
              }

              // Apply status filter
              if (_filter == 'Available') {
                volunteers = volunteers
                    .where((v) =>
                        v.available &&
                        (v.activeTaskId == null || v.activeTaskId!.isEmpty))
                    .toList();
              } else if (_filter == 'On duty') {
                volunteers = volunteers
                    .where((v) =>
                        v.activeTaskId != null && v.activeTaskId!.isNotEmpty)
                    .toList();
              } else if (_filter == 'Offline') {
                volunteers = volunteers
                    .where((v) =>
                        !v.available &&
                        (v.activeTaskId == null || v.activeTaskId!.isEmpty))
                    .toList();
              }

              if (volunteers.isEmpty) {
                return Center(
                    child: Text('No volunteers found',
                        style: Theme.of(context).textTheme.bodyMedium));
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
                itemCount: volunteers.length,
                itemBuilder: (ctx, i) =>
                    _VolunteerTile(volunteer: volunteers[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VolunteerTile extends StatelessWidget {
  final VolunteerModel volunteer;
  const _VolunteerTile({required this.volunteer});

  Color get statusColor {
    if (volunteer.activeTaskId != null && volunteer.activeTaskId!.isNotEmpty)
      return AppTheme.accentAmber;
    if (volunteer.available) return AppTheme.accentGreen;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      padding: const EdgeInsets.all(AppTheme.spacingSM + 2),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.accentOrange.withOpacity(0.15),
            child: Text(volunteer.initials,
                style: const TextStyle(
                    color: AppTheme.accentOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: AppTheme.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(volunteer.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(volunteer.areaName,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: volunteer.skills
                      .take(3)
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(s,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 9)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(height: 4),
              Text(
                '${volunteer.completedTasksCount}',
                style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              const Text('tasks',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
