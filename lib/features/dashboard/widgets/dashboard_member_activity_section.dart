import 'package:flutter/material.dart';

import '../dashboard_models.dart';
import 'dashboard_member_activity_tile.dart';

class DashboardMemberActivitySection extends StatelessWidget {
  final List<DashboardMemberActivityItem> items;
  final Widget Function(String text) emptyPanel;
  final ValueChanged<String> onMemberTap;
  final VoidCallback onUnavailable;

  const DashboardMemberActivitySection({
    super.key,
    required this.items,
    required this.emptyPanel,
    required this.onMemberTap,
    required this.onUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyPanel('No active member data yet.');
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          DashboardMemberActivityTile(
            name: items[i].name,
            subtitle: items[i].subtitle,
            isAtRisk: items[i].isAtRisk,
            onTap: () {
              final memberId = items[i].id.trim();
              if (memberId.isEmpty) {
                onUnavailable();
                return;
              }
              onMemberTap(memberId);
            },
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
