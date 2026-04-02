import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../pending_attendance_models.dart';
import 'pending_attendance_class_card.dart';

class PendingAttendanceDaySection extends StatelessWidget {
  final PendingAttendanceDayGroup group;
  final ValueChanged<PendingAttendanceClassItem> onTapClass;

  const PendingAttendanceDaySection({
    super.key,
    required this.group,
    required this.onTapClass,
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

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEEE, MMM d').format(group.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayLabel.toUpperCase(),
          style: _font(
            12,
            weight: FontWeight.w700,
            color: const Color(0xFF98A2B3),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        ...group.classes.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PendingAttendanceClassCard(
              item: item,
              onTap: () => onTapClass(item),
            ),
          ),
        ),
      ],
    );
  }
}
