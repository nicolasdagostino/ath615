import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../dashboard_models.dart';
import '../../../l10n/app_text.dart';

class DashboardTodayHighlightsCard extends StatelessWidget {
  final List<DashboardTodayHighlightItem> items;
  final bool embedded;

  const DashboardTodayHighlightsCard({
    super.key,
    required this.items,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = embedded ? const Color(0xFFF8FAFD) : Colors.white;
    final borderColor = embedded
        ? const Color(0xFFE3EAF5)
        : const Color(0xFFEAECEF);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: embedded
            ? null
            : const [
                BoxShadow(
                  blurRadius: 10,
                  offset: Offset(0, 4),
                  color: Color(0x080D0D12),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  size: 20,
                  color: Color(0xFF064BB3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.appText.todayHighlightsTitle,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111318),
                        height: 0.98,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.appText.todayHighlightsSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8F96A3),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              context.appText.nothingUrgentToday,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            )
          else
            ...List.generate(items.length, (i) {
              final item = items[i];
              final accentBg = item.type == 'birthday'
                  ? const Color(0xFFF7F3EA)
                  : const Color(0xFFEFF4FB);
              final accentColor = item.type == 'birthday'
                  ? const Color(0xFFB59B6A)
                  : const Color(0xFF064BB3);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == items.length - 1 ? 0 : 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE8ECF1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accentBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _icon(item.type),
                          size: 20,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111318),
                                letterSpacing: -0.15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF667085),
                                height: 1.4,
                              ),
                            ),
                          ],
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
