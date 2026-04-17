import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/volunteer_model.dart';
import '../theme/app_theme.dart';

class TaskDetailPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TASK DETAILS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 20),
          Text('Location: ${task.locationText}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          // Uses your confidenceLabel getter for better UX
          Text(task.confidenceLabel,
              style: TextStyle(
                  color: task.canAutoDispatch ? Colors.green : Colors.amber,
                  fontSize: 12)),
          const SizedBox(height: 20),
          // Uses your briefDescription field
          const Text('BRIEF:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.textSecondary)),
          Text(task.briefDescription,
              style: const TextStyle(color: AppTheme.textPrimary)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onDispatch(task.taskId),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.all(16)),
              child: const Text('CONFIRM MANUAL DISPATCH'),
            ),
          ),
        ],
      ),
    );
  }
}
