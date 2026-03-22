import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.headerDark,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: 327,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.28,
                          color: Color(0xFF818898),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 16), trailing!],
          ],
        ),
      ),
    );
  }
}
