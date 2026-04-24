import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String taskId;
  final String ngoId;
  final String locationText;
  final double? locationLat;
  final double? locationLng;
  final String needType;
  final int urgency;
  final List<String> skillsRequired;
  final int countNeeded;
  final int? estimatedPeopleAffected;
  final double confidenceScore;
  final bool needsReview;
  final String status;
  final List<String> assignedVolunteers;
  final List<String> dispatchedTo;
  final String sourceType;
  final String sourceNgoUser;
  final String rawInputText;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dispatchedAt;
  final DateTime? completedAt;
  final int? timeToDispatchSeconds;
  final bool dispatchTimeout;
  final String notes;
  final String briefDescription;

  // NEW: Tracking physical arrivals
  final Map<String, DateTime> volunteerArrivals;

  TaskModel({
    required this.taskId,
    required this.ngoId,
    required this.locationText,
    this.locationLat,
    this.locationLng,
    required this.needType,
    required this.urgency,
    required this.skillsRequired,
    required this.countNeeded,
    this.estimatedPeopleAffected,
    required this.confidenceScore,
    required this.needsReview,
    required this.status,
    required this.assignedVolunteers,
    required this.dispatchedTo,
    required this.sourceType,
    required this.sourceNgoUser,
    required this.rawInputText,
    this.createdAt,
    this.updatedAt,
    this.dispatchedAt,
    this.completedAt,
    this.timeToDispatchSeconds,
    required this.dispatchTimeout,
    required this.notes,
    required this.briefDescription,
    required this.volunteerArrivals,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    // Safely parse arrivals
    Map<String, DateTime> arrivals = {};
    if (d['volunteer_arrivals'] != null) {
      final map = d['volunteer_arrivals'] as Map<String, dynamic>;
      map.forEach((key, value) {
        if (value is Timestamp) arrivals[key] = value.toDate();
      });
    }

    return TaskModel(
      taskId: doc.id,
      ngoId: d['ngo_id'] ?? '',
      locationText: d['location_text'] ?? 'Unknown location',
      locationLat: (d['location_lat'] as num?)?.toDouble(),
      locationLng: (d['location_lng'] as num?)?.toDouble(),
      needType: d['need_type'] ?? 'other',
      urgency: (d['urgency'] as num?)?.toInt() ?? 3,
      skillsRequired: List<String>.from(d['skills_required'] ?? []),
      countNeeded: (d['count_needed'] as num?)?.toInt() ?? 1,
      estimatedPeopleAffected:
          (d['estimated_people_affected'] as num?)?.toInt(),
      confidenceScore: (d['confidence_score'] as num?)?.toDouble() ?? 0.5,
      needsReview: d['needs_review'] ?? false,
      status: d['status'] ?? 'open',
      assignedVolunteers: List<String>.from(d['assigned_volunteers'] ?? []),
      dispatchedTo: List<String>.from(d['dispatched_to'] ?? []),
      sourceType: d['source_type'] ?? 'text',
      sourceNgoUser: d['source_ngo_user'] ?? '',
      rawInputText: d['raw_input_text'] ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (d['updated_at'] as Timestamp?)?.toDate(),
      dispatchedAt: (d['dispatched_at'] as Timestamp?)?.toDate(),
      completedAt: (d['completed_at'] as Timestamp?)?.toDate(),
      timeToDispatchSeconds: (d['time_to_dispatch_seconds'] as num?)?.toInt(),
      dispatchTimeout: d['dispatch_timeout'] ?? false,
      notes: d['notes'] ?? '',
      briefDescription: d['brief_description'] ?? '',
      volunteerArrivals: arrivals,
    );
  }

  // UPDATED: Now keeps "assigned" tasks visible as active
  bool get isActive => [
        'open',
        'dispatching',
        'assigned',
        'flagged_medium',
        'flagged_low'
      ].contains(status);
  bool get isCritical => urgency >= 4;
  bool get isNew =>
      createdAt != null && DateTime.now().difference(createdAt!).inMinutes < 10;
  bool get canAutoDispatch => confidenceScore >= 0.80 && !needsReview;

  String get needTypeDisplay {
    switch (needType) {
      case 'food_ration':
        return 'Food / Ration';
      case 'medical':
        return 'Medical';
      case 'sanitation':
        return 'Sanitation';
      case 'education':
        return 'Education';
      case 'shelter':
        return 'Shelter';
      case 'disaster':
        return 'Disaster';
      default:
        return 'Other';
    }
  }

  String get sourceIcon {
    switch (sourceType) {
      case 'image':
        return '📷 Photo';
      case 'voice':
        return '🎤 Voice note';
      default:
        return '✏️ Text';
    }
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }

  String get confidenceLabel {
    if (confidenceScore >= 0.80) return '✓ Auto-dispatch enabled';
    if (confidenceScore >= 0.60) return '⚠ Requires coordinator review';
    return '✗ Cannot auto-dispatch — verify manually';
  }
}
