import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const DashboardSectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.barlowCondensed(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111318),
            height: 1.0,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8F96A3),
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}
