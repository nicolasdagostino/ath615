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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAECEF), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isAtRisk
                      ? const Color(0xFFEAF1FB)
                      : const Color(0xFFF3F5F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAtRisk
                      ? Icons.person_search_outlined
                      : Icons.person_outline,
                  size: 20,
                  color: isAtRisk
                      ? const Color(0xFF064BB3)
                      : const Color(0xFF8F96A3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111318),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8F96A3),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: onTap == null
                    ? const Color(0x00000000)
                    : const Color(0xFF8F96A3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
