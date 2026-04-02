import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/app_card.dart';

class AdminMemberMembershipCard extends StatelessWidget {
  final Map<String, dynamic>? membership;

  const AdminMemberMembershipCard({super.key, required this.membership});

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

  String _value(dynamic input, String fallback) {
    final value = (input ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final item = membership;
    if (item == null) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ACTIVE MEMBERSHIP',
              style: _font(
                12,
                weight: FontWeight.w700,
                color: const Color(0xFF98A2B3),
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No active membership',
              style: _font(
                18,
                weight: FontWeight.w800,
                color: const Color(0xFF0E0E11),
              ),
            ),
          ],
        ),
      );
    }

    final planName = _value(item['plan_name'] ?? item['name'], 'Plan');
    final planType = _value(item['plan_type'], '—');
    final billing = _value(item['billing_period'], '—');
    final bookingWindow = _value(item['booking_window_days'], '—');
    final classesPerPeriod = _value(item['classes_per_period'], '—');
    final creditsRemaining = _value(item['credits_remaining'], '—');

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE MEMBERSHIP',
            style: _font(
              12,
              weight: FontWeight.w700,
              color: const Color(0xFF98A2B3),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            planName.toUpperCase(),
            style: _font(
              20,
              weight: FontWeight.w800,
              color: const Color(0xFF0E0E11),
              height: 0.98,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Type: $planType · Billing: $billing',
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Booking window: $bookingWindow days · Classes/period: $classesPerPeriod',
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Credits remaining: $creditsRemaining',
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}
