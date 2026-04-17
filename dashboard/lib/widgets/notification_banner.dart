import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class NotificationBanner extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onDismiss;
  final VoidCallback onDispatch;
  final VoidCallback onView;

  const NotificationBanner({
    super.key,
    required this.task,
    required this.onDismiss,
    required this.onDispatch,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.accentRed,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'CRITICAL: ${task.needTypeDisplay} in ${task.locationText}!',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
              onPressed: onView,
              child: const Text('VIEW', style: TextStyle(color: Colors.white))),
          IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: Colors.white)),
        ],
      ),
    );
  }
}
