import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              Text("Reports & Analytics",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TaskModel>>(
            stream: service.getAllTasksThisWeek(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.accentOrange));
              }

              final all = snap.data!;
              final today = DateTime.now();
              final startOfDay = DateTime(today.year, today.month, today.day);
              final todayTasks = all
                  .where((t) =>
                      t.createdAt != null && t.createdAt!.isAfter(startOfDay))
                  .toList();
              final completedToday =
                  todayTasks.where((t) => t.status == 'completed').length;
              final autoDispatched = todayTasks
                  .where((t) =>
                      t.dispatchedAt != null &&
                      t.timeToDispatchSeconds != null &&
                      t.timeToDispatchSeconds! < 60)
                  .length;

              // Category counts for chart
              final categoryCounts = <String, int>{
                'medical': 0,
                'food_ration': 0,
                'sanitation': 0,
                'education': 0,
                'shelter': 0,
                'disaster': 0,
                'other': 0,
              };
              for (final t in todayTasks) {
                categoryCounts[t.needType] =
                    (categoryCounts[t.needType] ?? 0) + 1;
              }

              final avgDispatch = all
                  .where((t) =>
                      t.timeToDispatchSeconds != null &&
                      t.timeToDispatchSeconds! > 0)
                  .fold<int>(0, (s, t) => s + (t.timeToDispatchSeconds ?? 0));
              final dispatchCount = all
                  .where((t) =>
                      t.timeToDispatchSeconds != null &&
                      t.timeToDispatchSeconds! > 0)
                  .length;
              final avgSecs =
                  dispatchCount > 0 ? avgDispatch ~/ dispatchCount : 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Metrics",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: AppTheme.spacingSM),
                    Row(
                      children: [
                        _MetricTile('Total received', '${todayTasks.length}'),
                        const SizedBox(width: AppTheme.spacingSM),
                        _MetricTile('Auto-dispatched', '$autoDispatched'),
                        const SizedBox(width: AppTheme.spacingSM),
                        _MetricTile('Completed', '$completedToday'),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSM),
                    Row(
                      children: [
                        _MetricTile('Avg report→dispatch', '${avgSecs}s'),
                        const SizedBox(width: AppTheme.spacingSM),
                        _MetricTile('This week total', '${all.length}'),
                        const SizedBox(width: AppTheme.spacingSM),
                        _MetricTile('Completed this week',
                            '${all.where((t) => t.status == "completed").length}'),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLG),
                    Text("Tasks by Category Today",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.textMuted, letterSpacing: 0.5)),
                    const SizedBox(height: AppTheme.spacingMD),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (categoryCounts.values
                                      .fold(0, (a, b) => a > b ? a : b) +
                                  1)
                              .toDouble(),
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  const labels = [
                                    'Med',
                                    'Food',
                                    'San',
                                    'Edu',
                                    'Shl',
                                    'Dis',
                                    'Oth'
                                  ];
                                  if (val.toInt() >= labels.length)
                                    return const SizedBox.shrink();
                                  return Text(labels[val.toInt()],
                                      style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 10));
                                },
                                reservedSize: 24,
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            'medical',
                            'food_ration',
                            'sanitation',
                            'education',
                            'shelter',
                            'disaster',
                            'other'
                          ].asMap().entries.map((e) {
                            final count =
                                (categoryCounts[e.value] ?? 0).toDouble();
                            return BarChartGroupData(
                              x: e.key,
                              barRods: [
                                BarChartRodData(
                                  toY: count == 0 ? 0.1 : count,
                                  color: AppTheme.needTypeColor(e.value),
                                  width: 22,
                                  borderRadius: BorderRadius.circular(3),
                                )
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSM + 2),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Outfit')),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
