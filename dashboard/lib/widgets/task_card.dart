import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(String) onDispatch;

  const TaskCard({
    super.key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onDispatch,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentOrange.withOpacity(0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentOrange : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Uses your custom isCritical getter
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: task.isCritical ? Colors.red : Colors.amber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Uses your needTypeDisplay getter
                  Text(task.needTypeDisplay,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  // Uses your locationText field
                  Text(task.locationText,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed:
                  task.status == 'open' ? () => onDispatch(task.taskId) : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange),
              child: const Text('DISPATCH'),
            ),
          ],
        ),
      ),
    );
  }
}
