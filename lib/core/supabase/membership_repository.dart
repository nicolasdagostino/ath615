import 'supabase_bootstrap.dart';

class MembershipRepository {
  Future<List<Map<String, dynamic>>> listPlans() async {
    final data = await sb
        .from('membership_plans')
        .select('*')
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
    String memberId,
  ) async {
    final data = await sb
        .from('member_memberships')
        .select('*, membership_plans(name, plan_type, billing_period)')
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
        .eq('id', id);
  }

  Future<void> deletePlan(String id) async {
    await sb.from('membership_plans').delete().eq('id', id);
  }

  Future<void> assignPlanToMember({
    required String memberId,
    required String planId,
    required String status,
    required String startDate,
    String? endDate,
    bool autoRenew = true,
    int? creditsRemaining,
    int classesUsedCurrentPeriod = 0,
  }) async {
    await sb.rpc(
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
  }
}
