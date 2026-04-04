import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../dashboard_models.dart';
import 'dashboard_milestones_card.dart';
import 'dashboard_next_class_card.dart';
import 'dashboard_today_highlights_card.dart';
import '../../../l10n/app_text.dart';

class DashboardMorningOverview extends StatelessWidget {
  final DashboardNextClassItem? nextClass;
  final List<DashboardTodayHighlightItem> highlights;
  final List<DashboardMilestoneItem> milestones;
  final VoidCallback? onNextClassTap;
  final bool isCoachView;
  final int pendingAttendanceCount;

  const DashboardMorningOverview({
    super.key,
    required this.nextClass,
    required this.highlights,
    required this.milestones,
    this.onNextClassTap,
    this.isCoachView = false,
    this.pendingAttendanceCount = 0,
  });

  String _text(BuildContext context, String es, String en) {
    final isSpanish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('es');
    return isSpanish ? es : en;
  }

  @override
  Widget build(BuildContext context) {
    final title = isCoachView
        ? _text(context, 'Resumen del coach', 'Coach overview')
        : context.appText.morningOverviewTitle;
    final subtitle = isCoachView
        ? _text(
            context,
            'Tu próxima clase y las asistencias pendientes.',
            'Your next class and pending attendance.',
          )
        : context.appText.morningOverviewSubtitle;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEAECEF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    color: Color(0xFFB59B6A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111318),
                          letterSpacing: -0.2,
                          height: 0.98,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.appText.todayUpper,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF064BB3),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (nextClass != null) ...[
            const SizedBox(height: 12),
            DashboardNextClassCard(
              title: nextClass!.title,
              subtitle: nextClass!.subtitle,
              occupancyLabel: nextClass!.occupancyLabel,
              hasWorkout: nextClass!.hasWorkout,
              secondaryAttentionLabel: isCoachView && pendingAttendanceCount > 0
                  ? _text(
                      context,
                      pendingAttendanceCount == 1
                          ? '1 clase pendiente'
                          : '$pendingAttendanceCount clases pendientes',
                      pendingAttendanceCount == 1
                          ? '1 class pending'
                          : '$pendingAttendanceCount classes pending',
                    )
                  : null,
              onTap: onNextClassTap,
              compact: true,
              embedded: true,
            ),
          ],
          if (!isCoachView) ...[
            const SizedBox(height: 12),
            DashboardTodayHighlightsCard(items: highlights, embedded: true),
            const SizedBox(height: 12),
            DashboardMilestonesCard(items: milestones, embedded: true),
          ],
        ],
      ),
    );
  }
}
