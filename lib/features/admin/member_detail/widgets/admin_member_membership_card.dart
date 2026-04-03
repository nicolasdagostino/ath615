import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/app_card.dart';

class AdminMemberMembershipCard extends StatelessWidget {
  final Map<String, dynamic>? item;

  const AdminMemberMembershipCard({super.key, required this.item});

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');

  String _text(BuildContext context, String es, String en) =>
      _isSpanish(context) ? es : en;

  String _value(dynamic value, String fallback) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return AppCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(context, 'MEMBRESÍA ACTIVA', 'ACTIVE MEMBERSHIP'),
              style: GoogleFonts.barlowCondensed(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF98A2B3),
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE7EBF0)),
              ),
              child: Text(
                _text(context, 'Sin membresía activa', 'No active membership'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF667085),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final planName = _value(item!['plan_name'] ?? item!['name'], 'Plan');
    final planType = _value(item!['plan_type'], '—');
    final billing = _value(item!['billing_period'], '—');
    final bookingWindow = _value(item!['booking_window_days'], '—');
    final classesPerPeriod = _value(item!['classes_per_period'], '—');
    final creditsRemaining = _value(item!['credits_remaining'], '—');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(context, 'MEMBRESÍA ACTIVA', 'ACTIVE MEMBERSHIP'),
            style: GoogleFonts.barlowCondensed(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7D7B0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 20,
                        color: Color(0xFFB59B6A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        planName,
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111318),
                          height: 0.98,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('${_text(context, 'Tipo', 'Type')}: $planType'),
                    _chip('${_text(context, 'Facturación', 'Billing')}: $billing'),
                    _chip('${_text(context, 'Ventana', 'Window')}: $bookingWindow ${_text(context, 'días', 'days')}'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(context, 'Uso', 'Usage'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8A6F3E),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_text(context, 'Clases/período', 'Classes/period')}: $classesPerPeriod',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475467),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_text(context, 'Créditos restantes', 'Credits remaining')}: $creditsRemaining',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475467),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF8A6F3E),
        ),
      ),
    );
  }
}
