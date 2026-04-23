import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../admin_member_detail_models.dart';

class AdminMemberRecentHistorySection extends StatelessWidget {
  final List<AdminMemberHistoryItem> items;

  const AdminMemberRecentHistorySection({super.key, required this.items});

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

  ({Color bg, Color fg, String label}) _statusStyle(
    BuildContext context,
    String status,
  ) {
    switch (status) {
      case 'attended':
        return (
          bg: const Color(0xFFDDF5E5),
          fg: const Color(0xFF16A34A),
          label: _text(context, 'Asistió', 'Attended'),
        );
      case 'cancelled':
        return (
          bg: const Color(0xFFF2F4F7),
          fg: const Color(0xFF667085),
          label: _text(context, 'Cancelada', 'Cancelled'),
        );
      case 'no_show':
        return (
          bg: const Color(0xFFFEE4E2),
          fg: const Color(0xFFB42318),
          label: _text(context, 'No asistió', 'No-show'),
        );
      default:
        return (
          bg: const Color(0xFFE6EDF7),
          fg: const Color(0xFF245BEB),
          label: _text(context, 'Reservada', 'Booked'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(context, 'HISTORIAL RECIENTE', 'RECENT HISTORY'),
            style: _font(
              12,
              weight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              _text(
                context,
                'Todavía no hay historial reciente de clases.',
                'No recent class history yet.',
              ),
              style: _font(
                14,
                weight: FontWeight.w500,
                color: const Color(0xFF667085),
              ),
            )
          else
            ...items.take(10).map((item) {
              final status = _statusStyle(context, item.status);
              final when = item.startsAt == null
                  ? '—'
                  : DateFormat('MMM d · HH:mm').format(item.startsAt!);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7EBF0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayTitle,
                              style: _font(
                                16,
                                weight: FontWeight.w800,
                                color: const Color(0xFF0E0E11),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              when,
                              style: _font(
                                13,
                                weight: FontWeight.w500,
                                color: const Color(0xFF667085),
                              ),
                            ),
                            if (item.coachName.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${_text(context, 'Coach', 'Coach')}: ${item.coachName}',
                                style: _font(
                                  13,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: status.bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status.label,
                          style: _font(
                            13,
                            weight: FontWeight.w700,
                            color: status.fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
