import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return StreamBuilder<Map<String, dynamic>>(
      stream: service.getDashboardStats(),
      builder: (context, statsSnap) {
        final stats = statsSnap.data ??
            {
              'activeTasks': 0,
              'criticalTasks': 0,
              'completedToday': 0,
              'avgDispatchSeconds': 0,
            };

        return StreamBuilder<int>(
          stream: service.getAvailableVolunteerCount(),
          builder: (context, volSnap) {
            final volunteerCount = volSnap.data ?? 0;

            final avgSecs = stats['avgDispatchSeconds'] as int? ?? 0;
            final avgMin = avgSecs ~/ 60;
            final avgSec = avgSecs % 60;
            final avgLabel = avgSecs > 0
                ? 'Avg dispatch: ${avgMin}m ${avgSec}s'
                : 'No data yet';

            return Row(
              children: [
                _StatCard(
                  value: '${stats['activeTasks']}',
                  label: 'Active tasks',
                  subtext: '',
                  valueColor: AppTheme.textPrimary,
                  borderColor: AppTheme.border,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                _StatCard(
                  value: '${stats['criticalTasks']}',
                  label: 'Critical (urgency 4–5)',
                  subtext: 'Needs immediate dispatch',
                  valueColor: AppTheme.accentRed,
                  borderColor: AppTheme.accentRed,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                _StatCard(
                  value: '$volunteerCount',
                  label: 'Volunteers active',
                  subtext: 'Currently available',
                  valueColor: AppTheme.accentGreen,
                  borderColor: AppTheme.accentGreen,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                _StatCard(
                  value: '${stats['completedToday']}',
                  label: 'Completed today',
                  subtext: avgLabel,
                  valueColor: AppTheme.accentGreen.withOpacity(0.8),
                  borderColor: AppTheme.border,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String subtext;
  final Color valueColor;
  final Color borderColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.subtext,
    required this.valueColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (subtext.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtext,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
