import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/app_card.dart';
import '../athlete_history_models.dart';

class AthleteHistoryEmptyState extends StatelessWidget {
  final AthleteHistoryFilter filter;

  const AthleteHistoryEmptyState({super.key, required this.filter});

  String get _title {
    switch (filter) {
      case AthleteHistoryFilter.all:
        return 'No class history yet';
      case AthleteHistoryFilter.attended:
        return 'No attended classes yet';
      case AthleteHistoryFilter.missed:
        return 'No missed classes';
      case AthleteHistoryFilter.cancelled:
        return 'No cancelled classes';
    }
  }

  String get _subtitle {
    switch (filter) {
      case AthleteHistoryFilter.all:
        return 'Your past bookings and attendance will appear here.';
      case AthleteHistoryFilter.attended:
        return 'Completed classes will appear here.';
      case AthleteHistoryFilter.missed:
        return 'No-shows or past booked classes will appear here.';
      case AthleteHistoryFilter.cancelled:
        return 'Cancelled bookings will appear here.';
    }
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

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Column(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 30,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(height: 12),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: _font(
              20,
              weight: FontWeight.w800,
              color: const Color(0xFF0E0E11),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
