import '../../../core/supabase/membership_repository.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import 'admin_member_detail_models.dart';

class AdminMemberDetailRepository {
  final _membershipRepository = MembershipRepository();

  AdminMemberDetailRepository();

  Future<void> updateMemberProfile({
    required String gymId,
    required String memberId,
    required String fullName,
    required String email,
    required String phone,
    required String notes,
    required bool isActive,
  }) async {
    await sb
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'notes': notes.trim(),
          'is_active': isActive,
        })
        .eq('id', memberId)
        .eq('gym_id', gymId);
  }

  Future<AdminMemberDetailData> loadMemberDetail({
    required String gymId,
    required String memberId,
  }) async {
    final resolvedGymId = gymId.trim();
    final id = memberId.trim();
    if (resolvedGymId.isEmpty) throw Exception('Gym not found');
    if (id.isEmpty) throw Exception('Member not found');

    final profile = await sb
        .from('profiles')
        .select(
          'id, gym_id, full_name, email, phone, is_active, member_since, notes',
        )
        .eq('id', id)
        .eq('gym_id', resolvedGymId)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Member not found');
    }

    final activeMembership = await sb
        .from('v_active_member_memberships')
        .select('*')
        .eq('member_id', id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final membershipHistory = await _membershipRepository.listMemberMemberships(
      id,
      gymId: resolvedGymId,
    );

    final paymentRowsRaw = await sb
        .from('membership_payments')
        .select('''
          id,
          payment_method,
          payment_status,
          amount,
          currency,
          paid_at,
          created_at,
          notes,
          membership_plans:membership_plans(name)
        ''')
        .eq('member_id', id)
        .order('created_at', ascending: false)
        .limit(20);

    final rows = await sb
        .from('class_bookings')
        .select('''
          id,
          class_id,
          status,
          created_at,
          classes!inner(
            id,
            title,
            starts_at,
            location,
            gym_id
          )
        ''')
        .eq('member_id', id)
        .eq('classes.gym_id', resolvedGymId)
        .order('created_at', ascending: false)
        .limit(40);

    final bookingRows = List<Map<String, dynamic>>.from(rows);
    final classIds = bookingRows
        .map((row) => (row['class_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final classMetaById = <String, Map<String, dynamic>>{};
    if (classIds.isNotEmpty) {
      final classMetaRows = await sb
          .from('v_classes_with_spots')
          .select('id, program_name, coach_name')
          .eq('gym_id', resolvedGymId)
          .inFilter('id', classIds);

      for (final raw in List<Map<String, dynamic>>.from(classMetaRows)) {
        final classId = (raw['id'] ?? '').toString().trim();
        if (classId.isEmpty) continue;
        classMetaById[classId] = raw;
      }
    }

    final paymentRows = List<Map<String, dynamic>>.from(paymentRowsRaw);
    final payments = <AdminMemberPaymentItem>[];

    var attendedCount = 0;
    var bookedCount = 0;
    var cancelledCount = 0;
    var noShowCount = 0;
    DateTime? lastActivityAt;

    final history = <AdminMemberHistoryItem>[];

    for (final row in paymentRows) {
      final planData = row['membership_plans'];
      final planMap = planData is Map
          ? Map<String, dynamic>.from(planData)
          : const <String, dynamic>{};

      payments.add(
        AdminMemberPaymentItem(
          id: (row['id'] ?? '').toString().trim(),
          planName: (planMap['name'] ?? 'Plan').toString().trim(),
          paymentMethod: (row['payment_method'] ?? '').toString().trim(),
          paymentStatus: (row['payment_status'] ?? '').toString().trim(),
          amountText: (row['amount'] ?? '').toString().trim(),
          currency: (row['currency'] ?? '').toString().trim(),
          paidAt: _parseDateTime(row['paid_at']),
          createdAt: _parseDateTime(row['created_at']),
          notes: (row['notes'] ?? '').toString().trim(),
        ),
      );
    }

    for (final row in bookingRows) {
      final status = (row['status'] ?? '').toString().toLowerCase().trim();
      switch (status) {
        case 'attended':
          attendedCount++;
          break;
        case 'booked':
          bookedCount++;
          break;
        case 'cancelled':
          cancelledCount++;
          break;
        case 'no_show':
          noShowCount++;
          break;
      }

      final classId = (row['class_id'] ?? '').toString().trim();
      final classData = row['classes'];
      final classMap = classData is Map
          ? Map<String, dynamic>.from(classData)
          : const <String, dynamic>{};
      final extra = classMetaById[classId] ?? const <String, dynamic>{};

      final startsAt = _parseDateTime(classMap['starts_at']);
      final createdAt = _parseDateTime(row['created_at']);
      final activityAt = startsAt ?? createdAt;
      if (activityAt != null &&
          (lastActivityAt == null || activityAt.isAfter(lastActivityAt))) {
        lastActivityAt = activityAt;
      }

      history.add(
        AdminMemberHistoryItem(
          bookingId: (row['id'] ?? '').toString().trim(),
          classId: classId,
          title: (classMap['title'] ?? '').toString().trim(),
          programName: (extra['program_name'] ?? '').toString().trim(),
          coachName: (extra['coach_name'] ?? '').toString().trim(),
          location: (classMap['location'] ?? '').toString().trim(),
          status: status,
          startsAt: startsAt,
          createdAt: createdAt,
        ),
      );
    }

    return AdminMemberDetailData(
      profile: Map<String, dynamic>.from(profile),
      activeMembership: activeMembership == null
          ? null
          : Map<String, dynamic>.from(activeMembership),
      membershipHistory: membershipHistory
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      activity: AdminMemberActivitySummary(
        lastActivityAt: lastActivityAt,
        attendedCount: attendedCount,
        bookedCount: bookedCount,
        cancelledCount: cancelledCount,
        noShowCount: noShowCount,
      ),
      recentHistory: history,
      payments: payments,
    );
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }
}
