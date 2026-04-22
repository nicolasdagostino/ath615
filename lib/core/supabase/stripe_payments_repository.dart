import 'package:flutter_stripe/flutter_stripe.dart';

import 'supabase_bootstrap.dart';
import 'auth_repository.dart';

class StripePaymentsRepository {
  Future<Map<String, dynamic>> createMembershipPaymentIntent({
    required String memberId,
    required String planId,
    required num amount,
    required String currency,
    String? notes,
  }) async {
    final res = await sb.functions.invoke(
      'create-membership-payment-intent',
      body: {
        'memberId': memberId,
        'planId': planId,
        'amount': amount,
        'currency': currency,
        'notes': notes,
      },
    );

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not create card payment intent');
    }

    return Map<String, dynamic>.from(payload as Map);
  }

  Future<Map<String, dynamic>> createMyMembershipPaymentIntent({
    required String planId,
    required num amount,
    required String currency,
    String? notes,
  }) async {
    final session = await AuthRepository().requireFreshSession();

    final res = await sb.functions.invoke(
      'create-my-membership-payment-intent',
      body: {
        'planId': planId,
        'amount': amount,
        'currency': currency,
        'notes': notes,
      },
      headers: {
        'X-Client-Authorization': 'Bearer ${session.accessToken}',
      },
    );

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not create self-serve card payment intent');
    }

    return Map<String, dynamic>.from(payload as Map);
  }

  Future<void> presentMembershipPaymentSheet({
    required String clientSecret,
    String merchantDisplayName = 'Athlete Lab',
  }) async {
    final trimmedSecret = clientSecret.trim();
    if (trimmedSecret.isEmpty) {
      throw Exception('Missing payment sheet client secret');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: merchantDisplayName,
        paymentIntentClientSecret: trimmedSecret,
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }
}
