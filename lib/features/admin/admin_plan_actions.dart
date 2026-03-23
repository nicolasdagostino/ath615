part of 'admin_screen.dart';

extension _AdminScreenPlanActions on _AdminScreenState {
void _showPlanActions(Map<String, dynamic> plan) {
    final title = (plan['name'] ?? 'Plan').toString().trim();
    final subtitle = (plan['description'] ?? '').toString().trim();

    Widget actionTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback? onTap,
      Color iconBg = const Color(0xFFF3F4F6),
      Color iconColor = const Color(0xFF111318),
      Color titleColor = const Color(0xFF111318),
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _font(
                        16,
                        weight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _font(
                          12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F9),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DBE1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            Icons.badge_rounded,
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
                                title.isEmpty ? 'Plan' : title,
                                style: _font(
                                  18,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFF111318),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF8F96A3),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Plan actions',
                    style: _font(
                      14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF8F96A3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  actionTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit plan',
                    subtitle: 'Update billing, credits and booking rules',
                    iconBg: const Color(0xFFF7F3EA),
                    iconColor: const Color(0xFFB59B6A),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlanModal(plan: plan);
                    },
                  ),
                  const SizedBox(height: 10),
                  actionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete plan',
                    subtitle: 'Remove this membership plan',
                    iconBg: const Color(0xFFFEE4E2),
                    iconColor: const Color(0xFFE11D48),
                    titleColor: const Color(0xFFE11D48),
                    onTap: _adminActionBusy
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await _runAdminAction(
                              () => _deletePlan(plan['id'].toString()),
                              successMessage: 'Plan deleted',
                            );
                          },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                      text: 'Cancel',
                      compact: true,
                      radius: 16,
                      textStyle: _font(
                        16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF344054),
                        letterSpacing: -0.15,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
