import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_text.dart';

import '../../../core/supabase/membership_repository.dart';
import '../../../core/supabase/notification_repository.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../class_attendance_screen.dart';
import 'admin_member_detail_models.dart';
import 'admin_member_detail_repository.dart';
import 'widgets/admin_member_activity_card.dart';
import 'widgets/admin_member_detail_header.dart';
import 'widgets/admin_member_detail_sheet_ui.dart';
import 'widgets/admin_member_membership_card.dart';
import 'widgets/admin_member_payments_card.dart';
import 'widgets/admin_member_recent_history_section.dart';
import '../../../core/supabase/membership_payments_repository.dart';
import '../../../core/supabase/stripe_payments_repository.dart';

class AdminMemberDetailScreen extends StatefulWidget {
  final String gymId;
  final String memberId;

  const AdminMemberDetailScreen({
    super.key,
    required this.gymId,
    required this.memberId,
  });

  @override
  State<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen> {
  bool get _isSpanish =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');

  String _txt(String es, String en) => _isSpanish ? es : en;

  final _repo = AdminMemberDetailRepository();
  final _membershipRepo = MembershipRepository();
  final _notificationRepo = NotificationRepository();
  final _paymentsRepo = MembershipPaymentsRepository();
  final _stripePaymentsRepo = StripePaymentsRepository();
  final _offboardReasonCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  AdminMemberDetailData? _data;

  
  @override
  void dispose() {
    _offboardReasonCtrl.dispose();
    super.dispose();
  }

@override
  void initState() {
    super.initState();
    _load();
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

  void _toast(
    String message, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: const Color(0xFF111318),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toastInSheet(
    BuildContext ctx,
    String message, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    final messenger = ScaffoldMessenger.of(ctx);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        backgroundColor: const Color(0xFF111318),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizedPlanType(Map<String, dynamic> plan) {
    return (plan['plan_type'] ?? '').toString().trim().toLowerCase();
  }

  bool _hasConflictingActiveMembership({
    required String selectedPlanType,
    required List<Map<String, dynamic>> activeMemberships,
  }) {
    if (selectedPlanType != 'unlimited' && selectedPlanType != 'weekly_limit') {
      return false;
    }

    for (final membership in activeMemberships) {
      final type = (membership['plan_type'] ?? '').toString().trim().toLowerCase();
      if (type == 'unlimited' || type == 'weekly_limit') {
        return true;
      }
    }
    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _repo.loadMemberDetail(
        gymId: widget.gymId,
        memberId: widget.memberId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showAssignPlanSheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    if (memberId.isEmpty) {
      _toast(context.appText.memberNotFound);
      return;
    }

    final gymId = (data.profile['gym_id'] ?? '').toString().trim();
    if (gymId.isEmpty) {
      _toast(context.appText.gymNotFound);
      return;
    }

    final t = context.appText;

    List<Map<String, dynamic>> plans;
    try {
      plans = await _membershipRepo.listPlans(gymId);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
      return;
    }

    if (plans.isEmpty) {
      _toast(t.noPlansAvailableYet);
      return;
    }

    var selectedPlanId = (data.activeMembership?['plan_id'] ?? '')
        .toString()
        .trim();
    if (selectedPlanId.isEmpty) {
      selectedPlanId = (plans.first['id'] ?? '').toString().trim();
    }

    final todayIso = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;
        String selectedPaymentMethod = 'cash';

        String prettyType(String raw) {
          final value = raw.trim();
          if (value.isEmpty) return _txt('Plan', 'Plan');
          final clean = value.replaceAll('_', ' ');
          return clean[0].toUpperCase() + clean.substring(1);
        }

        String prettyBilling(String raw) {
          final value = raw.trim();
          if (value.isEmpty) return '—';
          final clean = value.replaceAll('_', ' ');
          return clean[0].toUpperCase() + clean.substring(1);
        }

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: _txt('Vender plan', 'Sell plan'),
              subtitle: _txt('Selecciona un plan y registra el pago para activar la membresía.', 'Select a plan and register payment to activate the membership.'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...plans.map((plan) {
                    final planId = (plan['id'] ?? '').toString().trim();
                    final selected = planId == selectedPlanId;
                    final name = (plan['name'] ?? 'Plan').toString().trim();
                    final planType = prettyType(
                      (plan['plan_type'] ?? '').toString(),
                    );
                    final billing = prettyBilling(
                      (plan['billing_period'] ?? '').toString(),
                    );
                    final price = (plan['price'] ?? '').toString().trim();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: saving
                            ? null
                            : () {
                                setLocalState(() {
                                  selectedPlanId = planId;
                                  amountCtrl.text =
                                      (plan['price'] ?? '').toString().trim();
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFB59B6A)
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 1.4 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x080D1210),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: memberDetailSheetFont(
                                        17,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        planType,
                                        billing,
                                        if (price.isNotEmpty) '$price €',
                                      ].join(' · '),
                                      style: memberDetailSheetFont(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF667085),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? const Color(0xFFB59B6A)
                                    : const Color(0xFF98A2B3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    _txt('Método de pago', 'Payment method'),
                    style: memberDetailSheetFont(
                      13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: saving
                              ? null
                              : () {
                                  setLocalState(() {
                                    selectedPaymentMethod = 'cash';
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 'cash'
                                  ? const Color(0xFFF7F3EA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedPaymentMethod == 'cash'
                                    ? const Color(0xFFB59B6A)
                                    : const Color(0xFFE2E8F0),
                                width: selectedPaymentMethod == 'cash' ? 1.3 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 16,
                                  color: selectedPaymentMethod == 'cash'
                                      ? const Color(0xFF8A6F3E)
                                      : const Color(0xFF667085),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _txt('Cash', 'Cash'),
                                  style: memberDetailSheetFont(
                                    13,
                                    weight: FontWeight.w700,
                                    color: selectedPaymentMethod == 'cash'
                                        ? const Color(0xFF8A6F3E)
                                        : const Color(0xFF475467),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: saving
                              ? null
                              : () {
                                  setLocalState(() {
                                    selectedPaymentMethod = 'card';
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 'card'
                                  ? const Color(0xFFF7F3EA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedPaymentMethod == 'card'
                                    ? const Color(0xFFB59B6A)
                                    : const Color(0xFFE2E8F0),
                                width: selectedPaymentMethod == 'card' ? 1.3 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card_rounded,
                                  size: 16,
                                  color: selectedPaymentMethod == 'card'
                                      ? const Color(0xFF8A6F3E)
                                      : const Color(0xFF667085),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _txt('Card', 'Card'),
                                  style: memberDetailSheetFont(
                                    13,
                                    weight: FontWeight.w700,
                                    color: selectedPaymentMethod == 'card'
                                        ? const Color(0xFF8A6F3E)
                                        : const Color(0xFF475467),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedPaymentMethod == 'card') ...[
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'Stripe próximamente.',
                        'Stripe coming soon.',
                      ),
                      style: memberDetailSheetFont(
                        12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  AdminMemberDetailSheetTextField(
                    controller: amountCtrl,
                    label: _txt('Importe', 'Amount'),
                    hint: '49',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  AdminMemberDetailSheetTextField(
                    controller: notesCtrl,
                    label: _txt('Notas', 'Notes'),
                    hint: _txt('Pago en efectivo', 'Cash payment'),
                    minLines: 2,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: _txt('Vender plan', 'Sell plan'),
                    busyText: context.appText.saving,
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      if (selectedPlanId.trim().isEmpty) {
                        _toast(_txt('Selecciona un plan', 'Select a plan'));
                        return;
                      }

                      final amount = num.tryParse(
                        amountCtrl.text.trim().replaceAll(',', '.'),
                      );
                      if (amount == null || amount < 0) {
                        _toastInSheet(
                          sheetContext,
                          _txt('Introduce un importe válido', 'Enter a valid amount'),
                        );
                        return;
                      }

                      if (selectedPaymentMethod == 'card') {
                        FocusManager.instance.primaryFocus?.unfocus();

                        setLocalState(() {
                          saving = true;
                        });

                        try {
                          final cardPayload =
                              await _stripePaymentsRepo
                                  .createMembershipPaymentIntent(
                                    memberId: memberId,
                                    planId: selectedPlanId.trim(),
                                    amount: amount,
                                    currency: 'EUR',
                                    notes: notesCtrl.text,
                                  );

                          final clientSecret =
                              (cardPayload['clientSecret'] ?? '')
                                  .toString()
                                  .trim();
                          final paymentId =
                              (cardPayload['paymentId'] ?? '')
                                  .toString()
                                  .trim();

                          await _stripePaymentsRepo.presentMembershipPaymentSheet(
                            clientSecret: clientSecret,
                            merchantDisplayName: 'Athlete Lab',
                          );

                          if (!sheetContext.mounted) return;

                          Navigator.of(sheetContext).pop();
                          await _load();

                          _toast(
                            _txt(
                              paymentId.isEmpty
                                  ? 'Pago con tarjeta enviado. Confirmando…'
                                  : 'Pago con tarjeta enviado. Confirmando… · $paymentId',
                              paymentId.isEmpty
                                  ? 'Card payment submitted. Confirming…'
                                  : 'Card payment submitted. Confirming… · $paymentId',
                            ),
                          );
                        } on StripeException catch (e) {
                          final errorMessage =
                              e.error.localizedMessage?.trim().isNotEmpty == true
                                  ? e.error.localizedMessage!.trim()
                                  : _txt(
                                      'Pago con tarjeta cancelado',
                                      'Card payment cancelled',
                                    );
                          _toast(errorMessage);
                        } catch (e) {
                          _toast(e.toString().replaceFirst('Exception: ', ''));
                        } finally {
                          if (sheetContext.mounted) {
                            setLocalState(() {
                              saving = false;
                            });
                          }
                        }
                        return;
                      }

                      FocusManager.instance.primaryFocus?.unfocus();

                      setLocalState(() {
                        saving = true;
                      });

                      try {
                        final selectedPlan = plans.firstWhere(
                          (plan) =>
                              (plan['id'] ?? '').toString().trim() ==
                              selectedPlanId.trim(),
                          orElse: () => <String, dynamic>{},
                        );

                        final selectedPlanType = _normalizedPlanType(selectedPlan);

                        final activeMemberships =
                            await _membershipRepo.listActiveMemberMemberships(
                              memberId,
                              gymId: gymId,
                            );

                        if (_hasConflictingActiveMembership(
                          selectedPlanType: selectedPlanType,
                          activeMemberships: activeMemberships,
                        )) {
                          final activeUnlimited = activeMemberships.firstWhere(
                            (m) =>
                                (m['plan_type'] ?? '')
                                    .toString()
                                    .trim()
                                    .toLowerCase() ==
                                'unlimited',
                            orElse: () => <String, dynamic>{},
                          );

                          final planName =
                              (activeUnlimited['plan_name'] ??
                                      activeUnlimited['name'] ??
                                      'Unlimited')
                                  .toString()
                                  .trim();

                          _toastInSheet(
                            sheetContext,
                            _txt(
                              'Ya tiene activo: $planName',
                              'Already active: $planName',
                            ),
                          );
                          return;
                        }

                        final alreadyPaidToday =
                            await _paymentsRepo.hasPaidPlanToday(
                              memberId: memberId,
                              planId: selectedPlanId.trim(),
                            );

                        if (alreadyPaidToday) {
                          _toastInSheet(
                            sheetContext,
                            _txt(
                              'Ya hay un pago registrado hoy para este plan',
                              'A payment for this plan is already registered today',
                            ),
                          );
                          return;
                        }

                        final paymentId = await _paymentsRepo.createPayment(
                          memberId: memberId,
                          planId: selectedPlanId.trim(),
                          amount: amount,
                          currency: 'EUR',
                          paymentMethod: 'cash',
                          notes: notesCtrl.text,
                        );

                        final membership = await _membershipRepo.assignPlanToMember(
                          memberId: memberId,
                          planId: selectedPlanId.trim(),
                          status: 'active',
                          startDate: todayIso,
                          autoRenew: false,
                        );

                        final membershipId =
                            (membership['id'] ?? '').toString().trim();
                        if (membershipId.isNotEmpty) {
                          await _paymentsRepo.attachMembershipToPayment(
                            paymentId: paymentId,
                            membershipId: membershipId,
                          );
                        }

                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        await _load();
                        _toast(
                          _txt(
                            'Plan vendido y membresía activada',
                            'Plan sold and membership activated',
                          ),
                        );
                      } catch (e) {
                        _toastInSheet(
                          sheetContext,
                          e.toString().replaceFirst('Exception: ', ''),
                        );
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() {
                            saving = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Future<void> _showRegisterPaymentSheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    if (memberId.isEmpty) {
      _toast(context.appText.memberNotFound);
      return;
    }

    final gymId = (data.profile['gym_id'] ?? '').toString().trim();
    if (gymId.isEmpty) {
      _toast(context.appText.gymNotFound);
      return;
    }

    List<Map<String, dynamic>> plans = const [];
    try {
      plans = await _membershipRepo.listPlans(gymId);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
      return;
    }

    if (plans.isEmpty) {
      _toast(_txt('No hay planes activos disponibles', 'No active plans available'));
      return;
    }

    String selectedPlanId = '';
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String formatPlanSubtitle(Map<String, dynamic> plan) {
      final type = ((plan['plan_type'] ?? '').toString().trim()).replaceAll('_', ' ');
      final billing = ((plan['billing_period'] ?? '').toString().trim()).replaceAll('_', ' ');
      final price = (plan['price'] ?? '').toString().trim();

      final pieces = <String>[];
      if (type.isNotEmpty) {
        pieces.add(type[0].toUpperCase() + type.substring(1));
      }
      if (billing.isNotEmpty) {
        pieces.add(billing[0].toUpperCase() + billing.substring(1));
      }
      if (price.isNotEmpty && price != 'null') {
        pieces.add('$price €');
      }
      return pieces.join(' · ');
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;
        String selectedPaymentMethod = 'cash';

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: _txt('Anotar pago', 'Log payment'),
              subtitle: _txt(
                'Este registro solo anota un cobro manual. No activa una membresía.',
                'This only records a manual payment. It does not activate a membership.',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...plans.map((plan) {
                    final planId = (plan['id'] ?? '').toString().trim();
                    final selected = planId == selectedPlanId;
                    final name = (plan['name'] ?? 'Plan').toString().trim();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: saving
                            ? null
                            : () {
                                setLocalState(() {
                                  selectedPlanId = planId;
                                  amountCtrl.text = (plan['price'] ?? '').toString().trim();
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFB59B6A)
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 1.4 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x080D1210),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: memberDetailSheetFont(
                                        17,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatPlanSubtitle(plan),
                                      style: memberDetailSheetFont(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF667085),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? const Color(0xFFB59B6A)
                                    : const Color(0xFF98A2B3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE7D7B0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF8A6F3E),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _txt(
                              'Esto solo registra el pago en el historial. Para activar una membresía usa “Vender plan”.',
                              'This only records the payment in history. To activate a membership use “Sell plan”.',
                            ),
                            style: memberDetailSheetFont(
                              12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF8A6F3E),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _txt('Método de pago', 'Payment method'),
                    style: memberDetailSheetFont(
                      13,
                      weight: FontWeight.w700,
                      color: const Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: saving
                              ? null
                              : () {
                                  setLocalState(() {
                                    selectedPaymentMethod = 'cash';
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 'cash'
                                  ? const Color(0xFFF7F3EA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedPaymentMethod == 'cash'
                                    ? const Color(0xFFB59B6A)
                                    : const Color(0xFFE2E8F0),
                                width: selectedPaymentMethod == 'cash' ? 1.3 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  size: 16,
                                  color: selectedPaymentMethod == 'cash'
                                      ? const Color(0xFF8A6F3E)
                                      : const Color(0xFF667085),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _txt('Cash', 'Cash'),
                                  style: memberDetailSheetFont(
                                    13,
                                    weight: FontWeight.w700,
                                    color: selectedPaymentMethod == 'cash'
                                        ? const Color(0xFF8A6F3E)
                                        : const Color(0xFF475467),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: saving
                              ? null
                              : () {
                                  setLocalState(() {
                                    selectedPaymentMethod = 'card';
                                  });
                                },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: selectedPaymentMethod == 'card'
                                  ? const Color(0xFFF7F3EA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedPaymentMethod == 'card'
                                    ? const Color(0xFFB59B6A)
                                    : const Color(0xFFE2E8F0),
                                width: selectedPaymentMethod == 'card' ? 1.3 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card_rounded,
                                  size: 16,
                                  color: selectedPaymentMethod == 'card'
                                      ? const Color(0xFF8A6F3E)
                                      : const Color(0xFF667085),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _txt('Card', 'Card'),
                                  style: memberDetailSheetFont(
                                    13,
                                    weight: FontWeight.w700,
                                    color: selectedPaymentMethod == 'card'
                                        ? const Color(0xFF8A6F3E)
                                        : const Color(0xFF475467),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedPaymentMethod == 'card') ...[
                    const SizedBox(height: 8),
                    Text(
                      _txt(
                        'Stripe próximamente.',
                        'Stripe coming soon.',
                      ),
                      style: memberDetailSheetFont(
                        12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  AdminMemberDetailSheetTextField(
                    controller: amountCtrl,
                    label: _txt('Importe', 'Amount'),
                    hint: '49',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  AdminMemberDetailSheetTextField(
                    controller: notesCtrl,
                    label: _txt('Notas', 'Notes'),
                    hint: _txt('Pago en efectivo en recepción', 'Cash payment at front desk'),
                    minLines: 2,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 8),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: _txt('Anotar pago', 'Log payment'),
                    busyText: context.appText.saving,
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      if (selectedPlanId.trim().isEmpty) {
                        _toast(_txt('Selecciona un plan', 'Select a plan'));
                        return;
                      }

                      final amount = num.tryParse(
                        amountCtrl.text.trim().replaceAll(',', '.'),
                      );
                      if (amount == null || amount <= 0) {
                        _toast(_txt('Introduce un importe válido', 'Enter a valid amount'));
                        return;
                      }

                      if (selectedPaymentMethod == 'card') {
                        _toast(
                          _txt(
                            'Stripe próximamente',
                            'Stripe coming soon',
                          ),
                        );
                        return;
                      }

                      FocusManager.instance.primaryFocus?.unfocus();

                      setLocalState(() {
                        saving = true;
                      });

                      try {
                        final selectedPlan = plans.firstWhere(
                          (plan) =>
                              (plan['id'] ?? '').toString().trim() ==
                              selectedPlanId.trim(),
                          orElse: () => <String, dynamic>{},
                        );

                        final selectedPlanType = _normalizedPlanType(selectedPlan);

                        final activeMemberships =
                            await _membershipRepo.listActiveMemberMemberships(
                              memberId,
                              gymId: gymId,
                            );

                        if (_hasConflictingActiveMembership(
                          selectedPlanType: selectedPlanType,
                          activeMemberships: activeMemberships,
                        )) {
                          final activeBlockingMembership = activeMemberships.firstWhere(
                            (m) {
                              final type = (m['plan_type'] ?? '')
                                  .toString()
                                  .trim()
                                  .toLowerCase();
                              return type == 'unlimited' || type == 'weekly_limit';
                            },
                            orElse: () => <String, dynamic>{},
                          );

                          final planName =
                              (activeBlockingMembership['plan_name'] ??
                                      activeBlockingMembership['name'] ??
                                      'Active membership')
                                  .toString()
                                  .trim();

                          _toast(
                            _txt(
                              'Ya tiene activo: $planName',
                              'Already active: $planName',
                            ),
                          );
                          return;
                        }

                        await _paymentsRepo.createPayment(
                          memberId: memberId,
                          planId: selectedPlanId.trim(),
                          amount: amount,
                          currency: 'EUR',
                          paymentMethod: selectedPaymentMethod,
                          notes: notesCtrl.text,
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        _toast(
                          _txt(
                            'Pago registrado correctamente',
                            'Payment registered successfully',
                          ),
                        );
                      } catch (e) {
                        _toast(e.toString().replaceFirst('Exception: ', ''));
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() {
                            saving = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  AdminMemberHistoryItem? _preferredAttendanceHistoryItem() {
    final data = _data;
    if (data == null || data.recentHistory.isEmpty) return null;

    final now = DateTime.now();

    for (final item in data.recentHistory) {
      final startsAt = item.startsAt;
      if (startsAt == null) continue;
      if (!startsAt.isBefore(now)) continue;
      if (item.status == 'booked') return item;
    }

    for (final item in data.recentHistory) {
      final startsAt = item.startsAt;
      if (startsAt == null) continue;
      if (!startsAt.isBefore(now)) continue;
      return item;
    }

    return null;
  }

  Future<Map<String, dynamic>?> _loadClassItemForAttendance(
    String classId,
  ) async {
    final trimmed = classId.trim();
    if (trimmed.isEmpty) return null;

    final fromView = await sb
        .from('v_classes_with_spots')
        .select('*')
        .eq('id', trimmed)
        .maybeSingle();

    if (fromView != null) {
      return Map<String, dynamic>.from(fromView);
    }

    final fromClasses = await sb
        .from('classes')
        .select(
          'id, title, starts_at, duration_minutes, location, status, program_id, coach_id',
        )
        .eq('id', trimmed)
        .maybeSingle();

    if (fromClasses == null) return null;
    return Map<String, dynamic>.from(fromClasses);
  }

  Future<void> _openAttendanceAction() async {
    final item = _preferredAttendanceHistoryItem();
    if (item == null) {
      _toast(
        _txt(
          'Todavía no hay asistencia para registrar',
          'No past classes available yet',
        ),
        icon: Icons.event_busy_outlined,
      );
      return;
    }

    try {
      final classItem = await _loadClassItemForAttendance(item.classId);
      if (classItem == null) {
        _toast(_txt('No se pudo cargar la asistencia de la clase', 'Could not load class attendance'));
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ClassAttendanceScreen(classItem: classItem, gymId: widget.gymId),
        ),
      );
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showNotifySheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    final gymId = (data.profile['gym_id'] ?? '').toString().trim();
    final memberName = (data.profile['full_name'] ?? 'Member')
        .toString()
        .trim();

    if (memberId.isEmpty || gymId.isEmpty) {
      _toast(_txt('La notificación del miembro no está disponible', 'Member notification is not available'));
      return;
    }

    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: _txt('Notificar miembro', 'Notify member'),
              subtitle: memberName.isEmpty
                  ? _txt('Enviar una notificación push directa solo a este miembro.', 'Send a direct push notification only to this member.')
                  : _txt('Enviar una notificación push directa solo a $memberName.', 'Send a direct push notification only to $memberName.'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminMemberDetailSheetTextField(
                    controller: titleCtrl,
                    label: _txt('Título', 'Title'),
                    hint: _txt('Actualización de clase', 'Class update'),
                    textInputAction: TextInputAction.next,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: messageCtrl,
                    label: _txt('Mensaje', 'Message'),
                    hint: _txt('Escribe un mensaje corto', 'Write a short message'),
                    minLines: 4,
                    maxLines: 5,
                    textInputAction: TextInputAction.done,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  const SizedBox(height: 18),
                  AdminMemberDetailSheetActions(
                    busy: sending,
                    primaryText: _txt('Enviar notificación', 'Send notification'),
                    busyText: _txt('Enviando...', 'Sending...'),
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      final title = titleCtrl.text.trim();
                      final message = messageCtrl.text.trim();

                      if (title.isEmpty || message.isEmpty) {
                        _toast(_txt('El título y el mensaje son obligatorios', 'Title and message are required'));
                        return;
                      }

                      FocusManager.instance.primaryFocus?.unfocus();

                      setLocalState(() {
                        sending = true;
                      });

                      try {
                        final notificationId = await _notificationRepo
                            .createNotification(
                              gymId: gymId,
                              type: 'announcement',
                              title: title,
                              message: message,
                              recipientsScope: 'all_users',
                              status: 'draft',
                              metadata: {
                                'pushType': 'member_direct_message',
                                'targetMemberId': memberId,
                              },
                            );

                        await _notificationRepo.publishNotification(
                          notificationId,
                        );

                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        _toast(_txt('Notificación enviada', 'Notification sent'));
                      } catch (e) {
                        _toast(e.toString().replaceFirst('Exception: ', ''));
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() {
                            sending = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditActiveMembershipSheet() async {
    final data = _data;
    final membership = data?.activeMembership;
    if (data == null || membership == null) {
      _toast(_txt('No hay una membresía activa para editar', 'No active membership to edit'));
      return;
    }

    final membershipId = (membership['id'] ?? '').toString().trim();

    final endDateCtrl = TextEditingController(
      text: (membership['end_date'] ?? '').toString(),
    );
    final creditsCtrl = TextEditingController(
      text: (membership['credits_remaining'] ?? '').toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;
        bool autoRenew = membership['auto_renew'] == true;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: _txt('Membresía', 'Membership'),
              subtitle: _txt('Ajusta la configuración de la membresía.', 'Adjust membership settings.'),
              child: Column(
                children: [
                  AdminMemberDetailSheetTextField(
                    controller: endDateCtrl,
                    label: _txt('Fecha de finalización', 'End date'),
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: creditsCtrl,
                    label: _txt('Créditos restantes', 'Credits remaining'),
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetSwitchCard(
                    title: _txt('Renovación automática', 'Auto-renew'),
                    subtitle: _txt('Renovar automáticamente', 'Renew automatically'),
                    value: autoRenew,
                    onChanged: saving
                        ? null
                        : (v) => setLocalState(() => autoRenew = v),
                  ),
                  const SizedBox(height: 18),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: context.appText.save,
                    busyText: context.appText.saving,
                    onCancel: () => Navigator.pop(sheetContext),
                    onPrimary: () async {
                      setLocalState(() => saving = true);

                      try {
                        await _membershipRepo.updateMemberMembership(
                          membershipId: membershipId,
                          endDate: endDateCtrl.text,
                          autoRenew: autoRenew,
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        await _load();
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() => saving = false);
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditMemberSheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    if (memberId.isEmpty) {
      _toast(context.appText.memberNotFound);
      return;
    }

    final fullNameCtrl = TextEditingController(
      text: (data.profile['full_name'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (data.profile['email'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (data.profile['phone'] ?? '').toString(),
    );
    final notesCtrl = TextEditingController(
      text: (data.profile['notes'] ?? '').toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;
        bool isActive = data.profile['is_active'] == true;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: _txt('Editar miembro', 'Edit member'),
              subtitle: _txt('Actualiza los datos del perfil del miembro.', 'Update member profile details.'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminMemberDetailSheetTextField(
                    controller: fullNameCtrl,
                    label: _txt('Nombre completo', 'Full name'),
                    hint: _txt('Nombre Apellido', 'John Doe'),
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: emailCtrl,
                    label: _txt('Email', 'Email'),
                    hint: 'john@email.com',
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: phoneCtrl,
                    label: _txt('Teléfono', 'Phone'),
                    hint: '+34 600 000 000',
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: notesCtrl,
                    label: _txt('Notas', 'Notes'),
                    hint: _txt('Notas opcionales', 'Optional notes'),
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetSwitchCard(
                    title: _txt('Miembro activo', 'Active member'),
                    subtitle: _txt('Permitir acceso a la app después de configurar la contraseña', 'Allow access to the app after password setup'),
                    value: isActive,
                    onChanged: saving
                        ? null
                        : (value) {
                            setLocalState(() {
                              isActive = value;
                            });
                          },
                  ),
                  const SizedBox(height: 18),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: _txt('Guardar cambios', 'Save changes'),
                    busyText: context.appText.saving,
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      if (fullNameCtrl.text.trim().isEmpty) {
                        _toast(_txt('El nombre completo es obligatorio', 'Full name is required'));
                        return;
                      }

                      setLocalState(() => saving = true);

                      final t = context.appText;

                      try {
                        final memberGymId = (data.profile['gym_id'] ?? '')
                            .toString()
                            .trim();
                        if (memberGymId.isEmpty) {
                          throw Exception(
                            memberGymId.isEmpty ? t.gymNotFound : t.gymNotFound,
                          );
                        }

                        await _repo.updateMemberProfile(
                          gymId: memberGymId,
                          memberId: memberId,
                          fullName: fullNameCtrl.text,
                          email: emailCtrl.text,
                          phone: phoneCtrl.text,
                          notes: notesCtrl.text,
                          isActive: isActive,
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        await _load();
                        _toast(t.memberUpdated);
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() => saving = false);
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Future<void> _showOffboardMemberSheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    if (memberId.isEmpty) {
      _toast(context.appText.memberNotFound);
      return;
    }

    _offboardReasonCtrl.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: context.appText.offboardMemberTitle,
              subtitle: context.appText.offboardMemberSubtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminMemberDetailSheetTextField(
                    controller: _offboardReasonCtrl,
                    label: _txt('Motivo', 'Reason'),
                    hint: _txt(
                      'Opcional: impago, baja, solicitud del cliente...',
                      'Optional: unpaid, churn, client request...',
                    ),
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 18),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: context.appText.offboardMemberTitle,
                    busyText: context.appText.saving,
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      final successMessage = context.appText.memberOffboarded;
                      setLocalState(() => saving = true);
                      try {
                        await _repo.offboardMember(
                          memberId: memberId,
                          reason: _offboardReasonCtrl.text.trim().isEmpty
                              ? null
                              : _offboardReasonCtrl.text.trim(),
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        await _load();
                        if (!mounted) return;
                        _toast(successMessage);
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() => saving = false);
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickActions() {
    Widget action({
      required String title,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFF1F4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080D1210),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFB59B6A)),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: _font(
                  13,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _txt('ACCIONES RÁPIDAS', 'QUICK ACTIONS'),
          style: _font(
            12,
            weight: FontWeight.w700,
            color: const Color(0xFF98A2B3),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.18,
          children: [
            action(
              title: _txt('Vender plan', 'Sell plan'),
              icon: Icons.credit_card_outlined,
              onTap: _showAssignPlanSheet,
            ),
            action(
              title: _txt('Anotar pago', 'Log payment'),
              icon: Icons.receipt_long_outlined,
              onTap: _showRegisterPaymentSheet,
            ),
            action(
              title: _txt('Asistencia', 'Attendance'),
              icon: Icons.check_circle_outline,
              onTap: _openAttendanceAction,
            ),
            action(
              title: _txt('Notificar', 'Notify'),
              icon: Icons.notifications_outlined,
              onTap: _showNotifySheet,
            ),
            action(
              title: context.appText.edit,
              icon: Icons.edit_outlined,
              onTap: _showEditMemberSheet,
            ),
            action(
              title: _txt('Membresía', 'Membership'),
              icon: Icons.workspace_premium_outlined,
              onTap: _showEditActiveMembershipSheet,
            ),
            action(
              title: _txt('Baja lógica', 'Offboard'),
              icon: Icons.person_off_outlined,
              onTap: _showOffboardMemberSheet,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        _txt('DETALLE DEL MIEMBRO', 'MEMBER DETAIL'),
                        style: _font(
                          18,
                          weight: FontWeight.w800,
                          color: const Color(0xFF0E0E11),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Color(0xFFB59B6A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB59B6A),
                        ),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 36),
                      child: Center(
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: _font(
                            15,
                            weight: FontWeight.w600,
                            color: const Color(0xFFB42318),
                          ),
                        ),
                      ),
                    )
                  else if (data != null) ...[
                    _quickActions(),
                    const SizedBox(height: 18),
                    AdminMemberDetailHeader(profile: data.profile),
                    const SizedBox(height: 14),
                    AdminMemberMembershipCard(item: data.activeMembership),
                    const SizedBox(height: 14),
                    AdminMemberActivityCard(activity: data.activity),
                    const SizedBox(height: 14),
                    AdminMemberPaymentsCard(payments: data.payments),
                    const SizedBox(height: 14),
                    AdminMemberRecentHistorySection(items: data.recentHistory),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
