import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../pending_attendance_models.dart';

class PendingAttendanceClassCard extends StatelessWidget {
  final PendingAttendanceClassItem item;
  final VoidCallback onTap;

  const PendingAttendanceClassCard({
    super.key,
    required this.item,
    required this.onTap,
  });

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

  Widget _chip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF98A2B3)),
          const SizedBox(width: 8),
          Text(
            label,
            style: _font(
              12,
              weight: FontWeight.w700,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = DateFormat('EEEE, MMM d · HH:mm').format(item.startsAt);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_2_rounded,
                    size: 22,
                    color: Color(0xFFB59B6A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayTitle.toUpperCase(),
                        style: _font(
                          20,
                          weight: FontWeight.w800,
                          color: const Color(0xFF0E0E11),
                          letterSpacing: -0.3,
                          height: 0.98,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: _font(
                          14,
                          weight: FontWeight.w500,
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.bookedCount} pending',
                    style: _font(
                      13,
                      weight: FontWeight.w700,
                      color: const Color(0xFFB54708),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip(
                  icon: Icons.timer_outlined,
                  label: '${item.durationMinutes} min',
                ),
                _chip(
                  icon: Icons.person_outline_rounded,
                  label: item.coachName.isEmpty ? 'Coach: TBD' : 'Coach: ${item.coachName}',
                ),
                _chip(
                  icon: Icons.event_available_outlined,
                  label: 'Booked: ${item.bookedCount}',
                ),
                _chip(
                  icon: Icons.check_circle_outline,
                  label: 'Attended: ${item.attendedCount}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
