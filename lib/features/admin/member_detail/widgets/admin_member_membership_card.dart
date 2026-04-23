import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';

class AdminMemberMembershipCard extends StatelessWidget {
  final Map<String, dynamic>? item;

  const AdminMemberMembershipCard({super.key, required this.item});

  bool _isSpanish(BuildContext context) => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('es');

  String _text(BuildContext context, String es, String en) =>
      _isSpanish(context) ? es : en;

  String _value(dynamic value, String fallback) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty || text == 'null' ? fallback : text;
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

  String _pretty(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == '—') return '—';
    final clean = value.replaceAll('_', ' ');
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String _formatShortDate(BuildContext context, String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == '—' || value == 'null') return '—';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    return DateFormat('dd-MM-yyyy').format(parsed);
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
              style: _font(
                12,
                weight: FontWeight.w700,
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
                style: _font(
                  14,
                  weight: FontWeight.w600,
                  color: const Color(0xFF667085),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final planName = _value(item!['plan_name'] ?? item!['name'], 'Plan');
    final planType = _pretty(_value(item!['plan_type'], '—'));
    final billing = _pretty(_value(item!['billing_period'], '—'));
    final bookingWindow = _value(item!['booking_window_days'], '—');
    final startDate = _formatShortDate(
      context,
      _value(item!['start_date'], '—'),
    );
    final endDate = _formatShortDate(context, _value(item!['end_date'], '—'));
    final creditsRemaining = _value(item!['credits_remaining'], '—');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(context, 'MEMBRESÍA ACTIVA', 'ACTIVE MEMBERSHIP'),
            style: _font(
              12,
              weight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        planName,
                        style: _font(
                          18,
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
                        _text(context, 'ACTIVA', 'ACTIVE'),
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
                  '$planType · $billing',
                  style: _font(
                    13,
                    weight: FontWeight.w600,
                    color: const Color(0xFF667085),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7EBF0)),
                  ),
                  child: Column(
                    children: [
                      _infoRow(
                        context,
                        _text(context, 'Inicio', 'Start'),
                        startDate,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        _text(context, 'Vence', 'Ends'),
                        endDate,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        _text(
                          context,
                          'Créditos restantes',
                          'Credits remaining',
                        ),
                        creditsRemaining,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        _text(context, 'Ventana de reserva', 'Booking window'),
                        '$bookingWindow ${_text(context, 'días', 'days')}',
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

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: _font(
              13,
              weight: FontWeight.w600,
              color: const Color(0xFF667085),
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: _font(
              13,
              weight: FontWeight.w700,
              color: const Color(0xFF111318),
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
