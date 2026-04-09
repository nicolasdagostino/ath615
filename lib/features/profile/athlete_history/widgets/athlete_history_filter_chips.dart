import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_text.dart';
import '../athlete_history_models.dart';

class AthleteHistoryFilterChips extends StatelessWidget {
  final AthleteHistoryFilter selected;
  final AthleteHistoryCounts counts;
  final ValueChanged<AthleteHistoryFilter> onChanged;

  const AthleteHistoryFilterChips({
    super.key,
    required this.selected,
    required this.counts,
    required this.onChanged,
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
    final t = context.appText;
    final items = <(AthleteHistoryFilter, String, int)>[
      (AthleteHistoryFilter.all, 'All', counts.total),
      (AthleteHistoryFilter.attended, t.attended, counts.attended),
      (AthleteHistoryFilter.missed, t.missed, counts.missed),
      (AthleteHistoryFilter.cancelled, t.cancelled, counts.cancelled),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((entry) {
        final filter = entry.$1;
        final label = entry.$2;
        final count = entry.$3;
        final active = filter == selected;

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged(filter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF111318) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? const Color(0xFF111318) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              '$label ($count)',
              style: _font(
                14,
                weight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF344054),
                letterSpacing: 0.0,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
