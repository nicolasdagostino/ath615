import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/membership_payments_repository.dart';
import '../../../core/supabase/membership_repository.dart';
import '../../../core/supabase/profile_repository.dart';
import '../../../core/supabase/stripe_payments_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late Future<Map<String, dynamic>> _future;
  final _stripePaymentsRepo = StripePaymentsRepository();
  final _membershipPaymentsRepo = MembershipPaymentsRepository();

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final profile = await ProfileRepository().getMyProfile();

    Map<String, dynamic>? activeMembership;
    List<Map<String, dynamic>> plans = const [];
    List<Map<String, dynamic>> payments = const [];

    final gymId = (profile?['gym_id'] ?? '').toString().trim();
    final memberId = (profile?['id'] ?? '').toString().trim();
    if (gymId.isNotEmpty) {
      final membershipRepo = MembershipRepository();
      activeMembership = await membershipRepo.myActiveMembership();
      plans = await membershipRepo.listPublicPlansForAthlete(gymId);
    }

    payments = await _membershipPaymentsRepo.listMyPayments(memberId: memberId);

    return {
      'profile': profile,
      'activeMembership': activeMembership,
      'plans': plans,
      'payments': payments,
    };
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  TextStyle _font(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = const Color(0xFF111318),
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  String _txt(String es, String en) {
    return Localizations.localeOf(
          context,
        ).languageCode.toLowerCase().startsWith('es')
        ? es
        : en;
  }

  String _pretty(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '—';
    final clean = trimmed.replaceAll('_', ' ');
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String _planMeta(Map<String, dynamic> plan) {
    final type = _pretty((plan['plan_type'] ?? '').toString());
    final billing = _pretty((plan['billing_period'] ?? '').toString());
    final price = (plan['price'] ?? '').toString().trim();

    final parts = <String>[];
    if (type != '—') parts.add(type);
    if (billing != '—') parts.add(billing);
    if (price.isNotEmpty && price != 'null') {
      parts.add('$price €');
    }

    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String _formatPaymentDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('MMM d, yyyy · HH:mm').format(parsed.toLocal());
  }

  Color _statusBackground(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return const Color(0xFFE8F5E9);
      case 'pending':
        return const Color(0xFFFFF3E0);
      case 'failed':
        return const Color(0xFFFEECEC);
      default:
        return const Color(0xFFF2F4F7);
    }
  }

  Color _statusForeground(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return const Color(0xFF18794E);
      case 'pending':
        return const Color(0xFFB54708);
      case 'failed':
        return const Color(0xFFB42318);
      case 'cancelled':
        return const Color(0xFF475467);
      default:
        return const Color(0xFF475467);
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'paid':
        return _txt('Pagado', 'Paid');
      case 'pending':
        return _txt('Procesando', 'Processing');
      case 'failed':
        return _txt('Fallido', 'Failed');
      case 'cancelled':
        return _txt('Cancelado', 'Cancelled');
      case 'refunded':
        return _txt('Reembolsado', 'Refunded');
      default:
        return _pretty(status);
    }
  }

  int _paymentStatusPriority(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 0;
      case 'paid':
        return 1;
      case 'failed':
        return 2;
      case 'cancelled':
        return 3;
      case 'refunded':
        return 4;
      default:
        return 5;
    }
  }

  void _showToast(String message, {bool isError = false, IconData? icon}) {
    if (!mounted) return;
    AppToast.show(context, message, isError: isError, icon: icon);
  }

  Future<bool> _confirmPlanPurchaseIfNeeded({
    required Map<String, dynamic>? activeMembership,
    required Map<String, dynamic> plan,
  }) async {
    final currentPlanType = (activeMembership?['plan_type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final nextPlanType = (plan['plan_type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final creditsRemaining = (activeMembership?['credits_remaining'] ?? '')
        .toString()
        .trim();
    final currentPlanName =
        ((activeMembership?['plan_name'] ??
                    activeMembership?['name'] ??
                    'Plan activo')
                .toString())
            .trim();
    final parsedCredits = int.tryParse(creditsRemaining);

    final shouldWarn =
        currentPlanType == 'class_pack' &&
        nextPlanType == 'class_pack' &&
        parsedCredits != null &&
        parsedCredits > 0;

    if (!shouldWarn) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            _txt('Atención', 'Heads up'),
            style: _font(
              20,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
            ),
          ),
          content: Text(
            _txt(
              'Ya tienes "$currentPlanName" activo y todavía te quedan $parsedCredits créditos. Si compras otro pack ahora, se añadirá como una nueva membresía/pago. ¿Quieres continuar?',
              'You already have "$currentPlanName" active and still have $parsedCredits credits left. If you buy another pack now, it will be added as a new membership/payment. Do you want to continue?',
            ),
            style: _font(
              14,
              weight: FontWeight.w600,
              color: const Color(0xFF475467),
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                _txt('Cancelar', 'Cancel'),
                style: _font(
                  14,
                  weight: FontWeight.w700,
                  color: const Color(0xFF667085),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111318),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _txt('Continuar compra', 'Continue purchase'),
                style: _font(14, weight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _buyPlan({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> plan,
  }) async {
    final memberId = (profile['id'] ?? '').toString().trim();
    final planId = (plan['id'] ?? '').toString().trim();
    final amount = num.tryParse(
      (plan['price'] ?? '').toString().replaceAll(',', '.'),
    );

    final couldNotStartPurchase = _txt(
      'No se pudo iniciar la compra',
      'Could not start purchase',
    );
    final invalidPriceMessage = _txt(
      'Este plan no tiene un precio válido',
      'This plan does not have a valid price',
    );
    final activatedMessage = _txt(
      'Procesando pago...',
      'Processing payment...',
    );
    final cancelledMessage = _txt(
      'Pago con tarjeta cancelado',
      'Card payment cancelled',
    );

    if (memberId.isEmpty || planId.isEmpty) {
      _showToast(couldNotStartPurchase);
      return;
    }

    if (amount == null || amount <= 0) {
      _showToast(invalidPriceMessage);
      return;
    }

    try {
      final payload = await _stripePaymentsRepo.createMyMembershipPaymentIntent(
        planId: planId,
        amount: amount,
        currency: 'EUR',
        notes: 'Athlete self-serve purchase',
      );

      final clientSecret = (payload['clientSecret'] ?? '').toString().trim();

      await _stripePaymentsRepo.presentMembershipPaymentSheet(
        clientSecret: clientSecret,
        merchantDisplayName: 'Athlete Lab',
      );

      if (!mounted) return;
      _showToast(activatedMessage);

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      await _refresh();

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      await _refresh();
    } on StripeException catch (e) {
      final errorMessage = e.error.localizedMessage?.trim().isNotEmpty == true
          ? e.error.localizedMessage!.trim()
          : cancelledMessage;
      _showToast(errorMessage);
    } catch (e) {
      final msg = e.toString();

      if (msg.contains('already registered today')) {
        _showToast(
          _txt(
            'Ya has comprado este mismo plan hoy. Si necesitas otro, contacta con el gimnasio.',
            'You already purchased this plan today. If you need another one, please contact the gym.',
          ),
        );
        return;
      }

      _showToast(msg.replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: const Color(0xFF111318),
        title: Text(
          _txt('Membresía', 'Membership'),
          style: _font(
            22,
            weight: FontWeight.w800,
            color: const Color(0xFF111318),
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? <String, dynamic>{};
          final profile =
              (data['profile'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final activeMembership =
              data['activeMembership'] as Map<String, dynamic>?;
          final plans =
              (data['plans'] as List?)?.cast<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[];
          final payments =
              (data['payments'] as List?)?.cast<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[];
          final sortedPayments = [...payments]
            ..sort((a, b) {
              final aStatus = (a['payment_status'] ?? '').toString();
              final bStatus = (b['payment_status'] ?? '').toString();
              final byStatus = _paymentStatusPriority(
                aStatus,
              ).compareTo(_paymentStatusPriority(bStatus));
              if (byStatus != 0) return byStatus;

              final aDate = DateTime.tryParse(
                ((a['paid_at'] ?? a['created_at']) ?? '').toString(),
              );
              final bDate = DateTime.tryParse(
                ((b['paid_at'] ?? b['created_at']) ?? '').toString(),
              );

              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;
              return bDate.compareTo(aDate);
            });

          final activePlanName =
              ((activeMembership?['plan_name'] ??
                          activeMembership?['name'] ??
                          '')
                      .toString())
                  .trim();
          final activePlanType = _pretty(
            (activeMembership?['plan_type'] ?? '').toString(),
          );
          final activeBilling = _pretty(
            (activeMembership?['billing_period'] ?? '').toString(),
          );
          final activePlanId = (activeMembership?['plan_id'] ?? '')
              .toString()
              .trim();
          final creditsRemaining =
              (activeMembership?['credits_remaining'] ?? '').toString().trim();
          final endDate = (activeMembership?['end_date'] ?? '')
              .toString()
              .trim();

          bool isCurrentPlan(Map<String, dynamic> plan) {
            final planId = (plan['id'] ?? '').toString().trim();
            if (activePlanId.isNotEmpty &&
                planId.isNotEmpty &&
                planId == activePlanId) {
              return true;
            }

            final planName = (plan['name'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
            final normalizedActivePlanName = activePlanName.toLowerCase();
            if (planName.isNotEmpty &&
                normalizedActivePlanName.isNotEmpty &&
                planName == normalizedActivePlanName) {
              return true;
            }

            return false;
          }

          final availablePlans = activeMembership == null
              ? plans
              : plans.where((plan) => !isCurrentPlan(plan)).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeMembership == null) ...[
                        Text(
                          _txt('Sin membresía activa', 'No active membership'),
                          style: _font(
                            18,
                            weight: FontWeight.w800,
                            color: const Color(0xFF111318),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _txt(
                            'Compra un plan para empezar a reservar.',
                            'Buy a plan to start booking.',
                          ),
                          style: _font(
                            13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                activePlanName.isEmpty
                                    ? 'Plan'
                                    : activePlanName,
                                style: _font(
                                  20,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFF111318),
                                  letterSpacing: -0.1,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: _font(
                                  11,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFF18794E),
                                  letterSpacing: 0.6,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [activePlanType, activeBilling]
                              .where((e) => e.trim().isNotEmpty && e != '—')
                              .join(' · '),
                          style: _font(
                            13,
                            weight: FontWeight.w600,
                            color: const Color(0xFF667085),
                          ),
                        ),
                        if (creditsRemaining.isNotEmpty &&
                            creditsRemaining != 'null') ...[
                          const SizedBox(height: 10),
                          Text(
                            _txt(
                              'Créditos restantes: $creditsRemaining',
                              'Credits remaining: $creditsRemaining',
                            ),
                            style: _font(
                              14,
                              weight: FontWeight.w700,
                              color: const Color(0xFF111318),
                            ),
                          ),
                        ],
                        if (endDate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _txt('Vence: $endDate', 'Expires: $endDate'),
                            style: _font(
                              13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _txt('Historial de pagos', 'Payment history'),
                  style: _font(
                    16,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 8),
                if (sortedPayments.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _txt('Sin pagos registrados', 'No payments recorded'),
                      style: _font(
                        14,
                        weight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  )
                else
                  ...sortedPayments.take(10).map((payment) {
                    final rawPlan = payment['membership_plans'];
                    String planName = 'Plan';
                    if (rawPlan is Map<String, dynamic>) {
                      planName = (rawPlan['name'] ?? 'Plan').toString().trim();
                    } else if (rawPlan is Map) {
                      planName = (rawPlan['name'] ?? 'Plan').toString().trim();
                    }

                    final amount = (payment['amount'] ?? '').toString().trim();
                    final currency = (payment['currency'] ?? '')
                        .toString()
                        .trim();
                    final status = (payment['payment_status'] ?? '')
                        .toString()
                        .trim();
                    final method = (payment['payment_method'] ?? '')
                        .toString()
                        .trim();
                    final paidAt = (payment['paid_at'] ?? '').toString();
                    final createdAt = (payment['created_at'] ?? '').toString();
                    final notes = (payment['notes'] ?? '').toString().trim();
                    final dateText = _formatPaymentDate(
                      paidAt.trim().isNotEmpty ? paidAt : createdAt,
                    );

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7EBF0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  planName.isEmpty ? 'Plan' : planName,
                                  style: _font(
                                    16,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF111318),
                                    letterSpacing: -0.1,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                amount.isEmpty
                                    ? '—'
                                    : (() {
                                        final value = double.tryParse(amount);
                                        final formatted =
                                            (value != null && value % 1 == 0)
                                            ? value.toInt().toString()
                                            : amount;
                                        final symbol =
                                            currency.toUpperCase() == 'EUR'
                                            ? '€'
                                            : currency;
                                        return '$formatted $symbol';
                                      })(),
                                style: _font(
                                  16,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFFB59B6A),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBackground(status),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _paymentStatusLabel(status).toUpperCase(),
                                  style: _font(
                                    11,
                                    weight: FontWeight.w800,
                                    color: _statusForeground(status),
                                    letterSpacing: 0.6,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _pretty(method),
                                style: _font(
                                  13,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF475467),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateText,
                            style: _font(
                              13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF667085),
                              height: 1.25,
                            ),
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              notes,
                              style: _font(
                                13,
                                weight: FontWeight.w500,
                                color: const Color(0xFF475467),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                if (availablePlans.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    _txt('Planes disponibles', 'Available plans'),
                    style: _font(
                      16,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111318),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...availablePlans.take(6).map((plan) {
                    final planName = (plan['name'] ?? 'Plan').toString().trim();

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE7EBF0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: _font(
                              16,
                              weight: FontWeight.w800,
                              color: const Color(0xFF111318),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _planMeta(plan),
                            style: _font(
                              13,
                              weight: FontWeight.w600,
                              color: const Color(0xFF667085),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final confirmed =
                                    await _confirmPlanPurchaseIfNeeded(
                                      activeMembership: activeMembership,
                                      plan: plan,
                                    );
                                if (!confirmed) return;

                                await _buyPlan(profile: profile, plan: plan);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF111318),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                _txt('Comprar plan', 'Buy plan'),
                                style: _font(
                                  14,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
