import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardMemberActivityTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isAtRisk;
  final VoidCallback? onTap;

  const DashboardMemberActivityTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isAtRisk,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isAtRisk ? const Color(0xFFFEE4E2) : const Color(0xFFDDF5E5);
    final iconColor = isAtRisk
        ? const Color(0xFFE11D48)
        : const Color(0xFF16A34A);
    final iconData = isAtRisk
        ? Icons.person_search_outlined
        : Icons.check_circle_outline_rounded;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEAECEF), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111318),
                        letterSpacing: -0.15,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF667085),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: onTap == null
                    ? const Color(0x00000000)
                    : const Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
