import 'package:flutter/material.dart';

import '../dashboard_models.dart';
import 'dashboard_alert_tile.dart';
import 'dashboard_kpi_card.dart';
import '../../../l10n/app_text.dart';

class DashboardTomorrowRiskSection extends StatelessWidget {
  final DashboardTomorrowStats tomorrow;
  final Widget Function(String text) emptyPanel;
  final Widget Function({required Widget left, required Widget right}) twoCards;
  final void Function(String classId, bool needsWorkoutAssignment) onClassTap;
  final VoidCallback onUnavailable;
  final bool isCoachView;
  final String Function(String es, String en)? uiText;

  const DashboardTomorrowRiskSection({
    super.key,
    required this.tomorrow,
    required this.emptyPanel,
    required this.twoCards,
    required this.onClassTap,
    required this.onUnavailable,
    this.isCoachView = false,
    this.uiText,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        uiText ??
        (String es, String en) {
          final isSpanish = Localizations.localeOf(
            context,
          ).languageCode.toLowerCase().startsWith('es');
          return isSpanish ? es : en;
        };

    return Column(
      children: [
        if (isCoachView)
          DashboardKpiCard(
            label: text('CLASES MAÑANA', 'CLASSES TOMORROW'),
            value: tomorrow.classesTomorrow.toString(),
            helper: tomorrow.classesTomorrow > 0
                ? text(
                    'Tus próximas clases asignadas.',
                    'Your upcoming assigned classes.',
                  )
                : text(
                    'No tienes clases programadas.',
                    'You have no classes scheduled.',
                  ),
          )
        else
          twoCards(
            left: DashboardKpiCard(
              label: context.appText.classesTomorrow,
              value: tomorrow.classesTomorrow.toString(),
              helper: context.appText.scheduledForTomorrow,
            ),
            right: DashboardKpiCard(
              label: context.appText.lowOccupancy,
              value: tomorrow.lowOccupancyTomorrow.toString(),
              helper: context.appText.needPromotionOrReview,
            ),
          ),
        const SizedBox(height: 12),
        if (tomorrow.riskClasses.isEmpty)
          emptyPanel(
            isCoachView
                ? text(
                    'No classes scheduled for tomorrow.',
                    'No classes scheduled for tomorrow.',
                  )
                : context.appText.tomorrowLooksHealthy,
          )
        else
          Column(
            children: [
              for (var i = 0; i < tomorrow.riskClasses.length; i++) ...[
                GestureDetector(
                  onTap: () {
                    final classId = tomorrow.riskClasses[i].id.trim();
                    if (classId.isEmpty) {
                      onUnavailable();
                      return;
                    }
                    onClassTap(
                      classId,
                      tomorrow.riskClasses[i].needsWorkoutAssignment,
                    );
                  },
                  child: DashboardAlertTile(
                    icon: Icons.event_available_outlined,
                    title: tomorrow.riskClasses[i].title,
                    subtitle: tomorrow.riskClasses[i].subtitle,
                  ),
                ),
                if (i != tomorrow.riskClasses.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}
