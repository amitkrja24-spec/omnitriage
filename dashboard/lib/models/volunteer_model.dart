import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerModel {
  final String volunteerId;
  final String name;
  final String telegramId;
  final String phone;
  final List<String> skills;
  final double? locationLat;
  final double? locationLng;
  final String areaName;
  final bool available;
  final String? activeTaskId;
  final int completedTasksCount;
  final DateTime? joinedAt;
  final DateTime? lastActive;

  VolunteerModel({
    required this.volunteerId,
    required this.name,
    required this.telegramId,
    required this.phone,
    required this.skills,
    this.locationLat,
    this.locationLng,
    required this.areaName,
    required this.available,
    this.activeTaskId,
    required this.completedTasksCount,
    this.joinedAt,
    this.lastActive,
  });

  factory VolunteerModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return VolunteerModel(
      volunteerId: doc.id,
      name: d['name'] ?? 'Unknown',
      telegramId: d['telegram_id'] ?? '',
      phone: d['phone'] ?? '',
      skills: List<String>.from(d['skills'] ?? []),
      locationLat: (d['location_lat'] as num?)?.toDouble(),
      locationLng: (d['location_lng'] as num?)?.toDouble(),
      areaName: d['area_name'] ?? '',
      available: d['available'] ?? false,
      activeTaskId: d['active_task_id'] as String?,
      completedTasksCount: (d['completed_tasks_count'] as num?)?.toInt() ?? 0,
      joinedAt: (d['joined_at'] as Timestamp?)?.toDate(),
      lastActive: (d['last_active'] as Timestamp?)?.toDate(),
    );
  }

  String get statusLabel {
    if (activeTaskId != null && activeTaskId!.isNotEmpty) return 'On duty';
    if (available) return 'Available';
    return 'Offline';
  }

  String get maskedPhone {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, 4)}XXXXXX';
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
