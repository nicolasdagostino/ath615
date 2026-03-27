import 'package:flutter/material.dart';

import '../dashboard_models.dart';
import 'dashboard_action_tile.dart';

class DashboardRecommendedActionsSection extends StatelessWidget {
  final List<DashboardRecommendedAction> actions;
  final IconData Function(String type) iconForActionType;
  final Future<void> Function(DashboardRecommendedAction action) onActionTap;

  const DashboardRecommendedActionsSection({
    super.key,
    required this.actions,
    required this.iconForActionType,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          DashboardActionTile(
            icon: iconForActionType(actions[i].type),
            title: actions[i].title,
            subtitle: actions[i].subtitle,
            onTap: () => onActionTap(actions[i]),
          ),
          if (i != actions.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
