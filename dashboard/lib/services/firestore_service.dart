import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/volunteer_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Tasks ──────────────────────────────────────────────────────

  // Stream all active tasks, sorted by urgency desc then createdAt desc
  Stream<List<TaskModel>> getActiveTasks() {
    return _db
        .collection('tasks')
        .where('status', whereIn: ['open', 'dispatching', 'flagged_medium', 'flagged_low'])
        .orderBy('urgency', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  // Stream completed tasks for today
  Stream<List<TaskModel>> getCompletedTasksToday() {
    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
    return _db
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .where('completed_at', isGreaterThan: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  // Stream all tasks (for reporting)
  Stream<List<TaskModel>> getAllTasksThisWeek() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _db
        .collection('tasks')
        .where('created_at', isGreaterThan: Timestamp.fromDate(weekAgo))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addCoordinatorNote(String taskId, String note) async {
    await _db.collection('tasks').doc(taskId).update({
      'notes': note,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markVerified(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'needs_review': false,
      'status': 'open',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Volunteers ─────────────────────────────────────────────────

  Stream<List<VolunteerModel>> getAllVolunteers() {
    return _db
        .collection('volunteers')
        .orderBy('completed_tasks_count', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => VolunteerModel.fromFirestore(d)).toList());
  }

  Stream<int> getAvailableVolunteerCount() {
    return _db
        .collection('volunteers')
        .where('available', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Stats ──────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> getDashboardStats() {
    // Combine multiple streams — simplified approach using snapshots
    return _db.collection('tasks').snapshots().map((snap) {
      final all = snap.docs.map((d) => TaskModel.fromFirestore(d)).toList();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final active = all.where((t) => ['open', 'dispatching', 'flagged_medium', 'flagged_low'].contains(t.status)).length;
      final critical = all.where((t) => t.urgency >= 4 && t.isActive).length;
      final completedToday = all.where((t) =>
        t.status == 'completed' &&
        t.completedAt != null &&
        t.completedAt!.isAfter(startOfDay)
      ).toList();

      final avgDispatch = completedToday.isNotEmpty
        ? completedToday
            .where((t) => t.timeToDispatchSeconds != null)
            .fold<int>(0, (sum, t) => sum + (t.timeToDispatchSeconds ?? 0)) /
          completedToday.where((t) => t.timeToDispatchSeconds != null).length
        : 0.0;

      return {
        'activeTasks': active,
        'criticalTasks': critical,
        'completedToday': completedToday.length,
        'avgDispatchSeconds': avgDispatch.isNaN ? 0 : avgDispatch.round(),
      };
    });
  }

  // ── Audit Log ──────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getAuditLogForTask(String taskId) {
    return _db
        .collection('audit_log')
        .where('task_id', isEqualTo: taskId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}