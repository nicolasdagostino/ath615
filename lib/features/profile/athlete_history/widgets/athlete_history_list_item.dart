import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../athlete_history_models.dart';

class AthleteHistoryListItem extends StatelessWidget {
  final AthleteHistoryEntry item;

  const AthleteHistoryListItem({super.key, required this.item});

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

  ({Color bg, Color fg}) _statusColors(AthleteHistoryStatus status) {
    switch (status) {
      case AthleteHistoryStatus.attended:
        return (bg: const Color(0xFFDDF5E5), fg: const Color(0xFF16A34A));
      case AthleteHistoryStatus.noShow:
        return (bg: const Color(0xFFFEE4E2), fg: const Color(0xFFB42318));
      case AthleteHistoryStatus.cancelled:
        return (bg: const Color(0xFFF2F4F7), fg: const Color(0xFF667085));
      case AthleteHistoryStatus.booked:
        return (bg: const Color(0xFFE6EDF7), fg: const Color(0xFF245BEB));
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('EEE, d MMM').format(item.classStartsAt);
    final time = DateFormat('HH:mm').format(item.classStartsAt);
    final colors = _statusColors(item.status);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title.toUpperCase(),
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF0E0E11),
                    letterSpacing: -0.2,
                    height: 0.98,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.statusLabel,
                  style: _font(
                    13,
                    weight: FontWeight.w700,
                    color: colors.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF98A2B3)),
              const SizedBox(width: 8),
              Text(
                '$day · $time',
                style: _font(
                  14,
                  weight: FontWeight.w600,
                  color: const Color(0xFF344054),
                ),
              ),
            ],
          ),
          if (item.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: Color(0xFF98A2B3)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.location,
                    style: _font(
                      14,
                      weight: FontWeight.w500,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _font(
                14,
                weight: FontWeight.w500,
                color: const Color(0xFF667085),
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
