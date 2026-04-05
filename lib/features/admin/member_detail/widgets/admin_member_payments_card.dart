import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../admin_member_detail_models.dart';

class AdminMemberPaymentsCard extends StatelessWidget {
  final List<AdminMemberPaymentItem> payments;

  const AdminMemberPaymentsCard({super.key, required this.payments});

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');

  String _text(BuildContext context, String es, String en) =>
      _isSpanish(context) ? es : en;

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

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('MMM d, yyyy · HH:mm').format(value);
  }

  String _pretty(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '—';
    final clean = value.replaceAll('_', ' ');
    return clean[0].toUpperCase() + clean.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(context, 'PAGOS', 'PAYMENTS'),
            style: _font(
              12,
              weight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (payments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7EBF0)),
              ),
              child: Text(
                _text(context, 'Sin pagos registrados', 'No payments recorded'),
                style: _font(
                  14,
                  weight: FontWeight.w600,
                  color: const Color(0xFF667085),
                ),
              ),
            )
          else
            ...payments.map((payment) {
              final paidAt = payment.paidAt ?? payment.createdAt;
              final amount = payment.amountText.isEmpty ? '—' : payment.amountText;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7EBF0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            payment.planName,
                            style: _font(
                              16,
                              weight: FontWeight.w800,
                              color: const Color(0xFF111318),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        Text(
                          '$amount ${payment.currency}',
                          style: _font(
                            16,
                            weight: FontWeight.w800,
                            color: const Color(0xFFB59B6A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        _pretty(payment.paymentMethod),
                        _pretty(payment.paymentStatus),
                        _formatDate(paidAt),
                      ].join(' · '),
                      style: _font(
                        13,
                        weight: FontWeight.w600,
                        color: const Color(0xFF667085),
                        height: 1.25,
                      ),
                    ),
                    if (payment.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        payment.notes.trim(),
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
  }
}
