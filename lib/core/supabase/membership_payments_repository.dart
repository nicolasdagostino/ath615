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
    String paymentStatus = 'paid',
    DateTime? paidAt,
    String? notes,
    String? stripeCustomerId,
    String? stripePaymentIntentId,
    String? failureReason,
    Map<String, dynamic>? metadata,
  }) async {
    final user = sb.auth.currentUser;

    final normalizedStatus = paymentStatus.trim().isEmpty
        ? 'paid'
        : paymentStatus.trim();

    final resolvedPaidAt = normalizedStatus == 'paid'
        ? (paidAt ?? DateTime.now()).toIso8601String()
        : null;

    final payload = <String, dynamic>{
      'member_id': memberId,
      'plan_id': planId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod.trim(),
      'payment_status': normalizedStatus,
      'paid_at': resolvedPaidAt,
      'created_by': user?.id,
      'notes': notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      'stripe_customer_id': stripeCustomerId?.trim().isEmpty ?? true
          ? null
          : stripeCustomerId!.trim(),
      'stripe_payment_intent_id': stripePaymentIntentId?.trim().isEmpty ?? true
          ? null
          : stripePaymentIntentId!.trim(),
      'failure_reason': failureReason?.trim().isEmpty ?? true
          ? null
          : failureReason!.trim(),
      'metadata': metadata ?? <String, dynamic>{},
    };

    final res = await sb
        .from('membership_payments')
        .insert(payload)
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

  Future<List<Map<String, dynamic>>> listMyPayments({
    required String memberId,
  }) async {
    if (memberId.trim().isEmpty) return const [];

    final rows = await sb
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
          membership_plans (
            name
          )
        ''')
        .eq('member_id', memberId.trim())
        .order('paid_at', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }
}
