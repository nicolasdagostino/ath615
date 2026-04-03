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

  const DashboardTomorrowRiskSection({
    super.key,
    required this.tomorrow,
    required this.emptyPanel,
    required this.twoCards,
    required this.onClassTap,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
          emptyPanel(context.appText.tomorrowLooksHealthy)
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
                    icon: Icons.event_busy_outlined,
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
