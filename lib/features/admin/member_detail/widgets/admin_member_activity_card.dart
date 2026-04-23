import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../admin_member_detail_models.dart';

class AdminMemberActivityCard extends StatelessWidget {
  final AdminMemberActivitySummary activity;

  const AdminMemberActivityCard({super.key, required this.activity});

  bool _isSpanish(BuildContext context) => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('es');

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

  String _lastActivityLabel(BuildContext context) {
    final value = activity.lastActivityAt;
    if (value == null) {
      return _text(context, 'Sin actividad reciente', 'No recent activity');
    }
    return DateFormat('MMM d, yyyy · HH:mm').format(value);
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7EBF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: _font(
                24,
                weight: FontWeight.w800,
                color: const Color(0xFF0E0E11),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: _font(
                13,
                weight: FontWeight.w600,
                color: const Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(context, 'ACTIVIDAD', 'ACTIVITY'),
            style: _font(
              12,
              weight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_text(context, 'Última actividad', 'Last activity')}: ${_lastActivityLabel(context)}',
            style: _font(
              15,
              weight: FontWeight.w600,
              color: const Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stat(
                '${activity.attendedCount}',
                _text(context, 'Asistidas', 'Attended'),
              ),
              const SizedBox(width: 10),
              _stat(
                '${activity.bookedCount}',
                _text(context, 'Reservadas', 'Booked'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(
                '${activity.cancelledCount}',
                _text(context, 'Canceladas', 'Cancelled'),
              ),
              const SizedBox(width: 10),
              _stat(
                '${activity.noShowCount}',
                _text(context, 'No asistió', 'No-show'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
