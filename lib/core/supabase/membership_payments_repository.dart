import 'supabase_bootstrap.dart';

class MembershipPaymentsRepository {
  Future<bool> hasPaidPlanToday({
    required String memberId,
    required String planId,
  }) async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final rows = await sb
        .from('membership_payments')
        .select('id')
        .eq('member_id', memberId)
        .eq('plan_id', planId)
        .eq('payment_status', 'paid')
        .gte('created_at', dayStart.toIso8601String())
        .lt('created_at', dayEnd.toIso8601String())
        .limit(1);

    return rows.isNotEmpty;
  }

  Future<String> createPayment({
    required String memberId,
    required String planId,
    required num amount,
    required String currency,
    required String paymentMethod,
    String? notes,
  }) async {
    final user = sb.auth.currentUser;

    final res = await sb
        .from('membership_payments')
        .insert({
          'member_id': memberId,
          'plan_id': planId,
          'amount': amount,
          'currency': currency,
          'payment_method': paymentMethod,
          'payment_status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
          'created_by': user?.id,
          'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
        })
        .select('id')
        .single();

    return (res['id'] ?? '').toString();
  }

  Future<void> attachMembershipToPayment({
    required String paymentId,
    required String membershipId,
  }) async {
    await sb
        .from('membership_payments')
        .update({
          'membership_id': membershipId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', paymentId);
  }
}
