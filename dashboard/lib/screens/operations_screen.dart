import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/volunteer_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/header_bar.dart';
import '../widgets/task_card.dart';
import '../widgets/task_detail_panel.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  final FirestoreService _service = FirestoreService();
  TaskModel? _selectedTask;
  List<VolunteerModel> _volunteers = [];

  @override
  void initState() {
    super.initState();
    _service.getAllVolunteers().listen((vols) {
      if (mounted) setState(() => _volunteers = vols);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const HeaderBar(),
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG, vertical: AppTheme.spacingSM),
              child: Row(
                children: [
                  const Icon(Icons.radar, color: AppTheme.accentBlue),
                  const SizedBox(width: AppTheme.spacingSM),
                  Text(
                    'Operations & History Vault',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text('Back to Triage'),
                  ),
                ],
              ),
            ),
            Container(
              color: AppTheme.surface,
              child: const TabBar(
                labelColor: AppTheme.accentBlue,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.accentBlue,
                tabs: [
                  Tab(text: '⏳ IN PROGRESS (Accepted)'),
                  Tab(text: '✓ COMPLETED & ARCHIVED'),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Fetching all tasks sorted by newest
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final allTasks = snapshot.data!.docs
                      .map((doc) => TaskModel.fromFirestore(doc))
                      .toList();

                  final inProgressTasks = allTasks
                      .where((t) =>
                          t.status == 'assigned' || t.status == 'dispatching')
                      .toList();
                  final completedTasks = allTasks
                      .where((t) =>
                          t.status == 'completed' || t.status == 'cancelled')
                      .toList();

                  return Row(
                    children: [
                      Expanded(
                        flex: _selectedTask != null ? 6 : 10,
                        child: TabBarView(
                          children: [
                            _buildTaskList(inProgressTasks),
                            _buildTaskList(completedTasks),
                          ],
                        ),
                      ),
                      if (_selectedTask != null) ...[
                        Container(width: 1, color: AppTheme.border),
                        SizedBox(
                          width: 380,
                          child: TaskDetailPanel(
                            task: _selectedTask!,
                            allVolunteers: _volunteers,
                            onDispatch: (id) {}, // Disabled in vault
                            onClose: () => setState(() => _selectedTask = null),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(
          child: Text('No tasks found.',
              style: TextStyle(color: AppTheme.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) => TaskCard(
        task: tasks[i],
        isSelected: _selectedTask?.taskId == tasks[i].taskId,
        allVolunteers: _volunteers,
        onDispatch: (id) {}, // Disabled in vault
        onTap: () => setState(() {
          _selectedTask =
              _selectedTask?.taskId == tasks[i].taskId ? null : tasks[i];
        }),
      ),
    );
  }
}
