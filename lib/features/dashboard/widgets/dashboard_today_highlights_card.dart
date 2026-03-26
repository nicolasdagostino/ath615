import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../dashboard_models.dart';

class DashboardTodayHighlightsCard extends StatelessWidget {
  final List<DashboardTodayHighlightItem> items;

  const DashboardTodayHighlightsCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today highlights',
            style: GoogleFonts.barlowCondensed(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111318),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Useful things to check first thing in the morning.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8F96A3),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'Nothing urgent for today.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            )
          else
            ...List.generate(items.length, (i) {
              final item = items[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == items.length - 1 ? 0 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _icon(item.type),
                        size: 20,
                        color: const Color(0xFF064BB3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111318),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.subtitle,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B7280),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'birthday':
        return Icons.cake_outlined;
      case 'workout':
        return Icons.fitness_center_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
