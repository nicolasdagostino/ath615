import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/membership_payments_repository.dart';
import '../../../core/supabase/membership_repository.dart';
import '../../../core/supabase/profile_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late Future<Map<String, dynamic>> _future;
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
      // Self-serve card purchases are disabled for MVP cash payments.
      plans = const [];
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

  Future<void> _buyPlan({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> plan,
  }) async {
    _showToast(
      _txt(
        'Los pagos con tarjeta están desactivados por ahora. Paga en el gimnasio para activar tu membresía.',
        'Card payments are disabled for now. Pay at the gym to activate your membership.',
      ),
    );
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
                            'Habla con el coach o recepción para activar tu membresía.',
                            'Talk to your coach or front desk to activate your membership.',
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
              ],
            ),
          );
        },
      ),
    );
  }
}
