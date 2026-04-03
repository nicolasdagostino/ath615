import 'package:flutter/material.dart';

import '../dashboard_models.dart';
import 'dashboard_alert_tile.dart';
import '../../../l10n/app_text.dart';

class DashboardAlertsSection extends StatelessWidget {
  final List<DashboardAlertItem> alerts;
  final IconData Function(String type) iconForType;
  final Widget Function(String text) emptyPanel;

  const DashboardAlertsSection({
    super.key,
    required this.alerts,
    required this.iconForType,
    required this.emptyPanel,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return emptyPanel(context.appText.noUrgentAlerts);
    }

    return Column(
      children: [
        for (var i = 0; i < alerts.length; i++) ...[
          DashboardAlertTile(
            icon: iconForType(alerts[i].type),
            title: alerts[i].title,
            subtitle: alerts[i].subtitle,
          ),
          if (i != alerts.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
