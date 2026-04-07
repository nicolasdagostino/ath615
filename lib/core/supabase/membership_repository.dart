import 'supabase_bootstrap.dart';

class MembershipRepository {
  Future<List<Map<String, dynamic>>> listPlans(String gymId) async {
    final data = await sb
        .from('membership_plans')
        .select('*')
        .eq('gym_id', gymId)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> myActiveMembership() async {
    final user = sb.auth.currentUser;
    if (user == null) return null;

    final data = await sb
        .from('v_active_member_memberships')
        .select('*')
        .eq('member_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listMemberMemberships(
    String memberId, {
    String? gymId,
  }) async {
    dynamic query = sb
        .from('member_memberships')
        .select(
          '*, membership_plans!inner(name, plan_type, billing_period, gym_id)',
        )
        .eq('member_id', memberId);

    if (gymId != null && gymId.trim().isNotEmpty) {
      query = query.eq('membership_plans.gym_id', gymId.trim());
    }

    final data = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> listActiveMemberMemberships(
    String memberId, {
    String? gymId,
  }) async {
    final data = await sb
        .from('v_active_member_memberships')
        .select('*')
        .eq('member_id', memberId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createPlan({
    required String gymId,
    required String name,
    required String planType,
    required String billingPeriod,
    num? price,
    int? classesPerPeriod,
    int? creditsTotal,
    required int bookingWindowDays,
    String? description,
  }) async {
    await sb.from('membership_plans').insert({
      'gym_id': gymId,
      'name': name,
      'plan_type': planType,
      'billing_period': billingPeriod,
      'price': price,
      'currency': 'EUR',
      'classes_per_period': classesPerPeriod,
      'credits_total': creditsTotal,
      'booking_window_days': bookingWindowDays,
      'description': description,
      'is_active': true,
    });
  }

  Future<void> updatePlan({
    required String gymId,
    required String id,
    required String name,
    required String planType,
    required String billingPeriod,
    num? price,
    int? classesPerPeriod,
    int? creditsTotal,
    required int bookingWindowDays,
    String? description,
  }) async {
    await sb
        .from('membership_plans')
        .update({
          'name': name,
          'plan_type': planType,
          'billing_period': billingPeriod,
          'price': price,
          'classes_per_period': classesPerPeriod,
          'credits_total': creditsTotal,
          'booking_window_days': bookingWindowDays,
          'description': description,
        })
        .eq('id', id)
        .eq('gym_id', gymId);
  }

  Future<void> deletePlan({
    required String gymId,
    required String id,
  }) async {
    await sb.from('membership_plans').delete().eq('id', id).eq('gym_id', gymId);
  }

  Future<void> updateMemberMembership({
    required String membershipId,
    String? status,
    String? endDate,
    bool? autoRenew,
    int? creditsRemaining,
    int? classesUsedCurrentPeriod,
  }) async {
    final payload = <String, dynamic>{};

    if (status != null) payload['status'] = status;
    if (endDate != null) {
      payload['end_date'] = endDate.trim().isEmpty ? null : endDate.trim();
    }
    if (autoRenew != null) payload['auto_renew'] = autoRenew;
    if (creditsRemaining != null) payload['credits_remaining'] = creditsRemaining;
    if (classesUsedCurrentPeriod != null) {
      payload['classes_used_current_period'] = classesUsedCurrentPeriod;
    }

    await sb.from('member_memberships').update(payload).eq('id', membershipId);
  }

  Future<Map<String, dynamic>> assignPlanToMember({
    required String memberId,
    required String planId,
    required String status,
    required String startDate,
    String? endDate,
    bool autoRenew = false,
    int? creditsRemaining,
    int classesUsedCurrentPeriod = 0,
  }) async {
    final res = await sb.rpc(
      'assign_membership_plan',
      params: {
        'p_member_id': memberId,
        'p_plan_id': planId,
        'p_status': status,
        'p_start_date': startDate,
        'p_end_date': endDate,
        'p_auto_renew': autoRenew,
        'p_credits_remaining': creditsRemaining,
        'p_classes_used_current_period': classesUsedCurrentPeriod,
      },
    );

    return Map<String, dynamic>.from(res as Map);
  }
}
