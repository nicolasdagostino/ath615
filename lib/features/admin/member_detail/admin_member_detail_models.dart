import 'package:flutter/foundation.dart';

@immutable
class AdminMemberHistoryItem {
  final String bookingId;
  final String classId;
  final String title;
  final String programName;
  final String coachName;
  final String location;
  final String status;
  final DateTime? startsAt;
  final DateTime? createdAt;

  const AdminMemberHistoryItem({
    required this.bookingId,
    required this.classId,
    required this.title,
    required this.programName,
    required this.coachName,
    required this.location,
    required this.status,
    required this.startsAt,
    required this.createdAt,
  });

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (programName.trim().isNotEmpty) return programName.trim();
    return 'Class';
  }
}

@immutable
class AdminMemberActivitySummary {
  final DateTime? lastActivityAt;
  final int attendedCount;
  final int bookedCount;
  final int cancelledCount;
  final int noShowCount;

  const AdminMemberActivitySummary({
    required this.lastActivityAt,
    required this.attendedCount,
    required this.bookedCount,
    required this.cancelledCount,
    required this.noShowCount,
  });
}

@immutable
class AdminMemberDetailData {
  final Map<String, dynamic> profile;
  final Map<String, dynamic>? activeMembership;
  final AdminMemberActivitySummary activity;
  final List<AdminMemberHistoryItem> recentHistory;

  const AdminMemberDetailData({
    required this.profile,
    required this.activeMembership,
    required this.activity,
    required this.recentHistory,
  });
}
