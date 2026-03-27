import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;

  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAECEF), width: 1),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x080D0D12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.barlowCondensed(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF667085),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111318),
              height: 0.95,
              letterSpacing: -0.25,
            ),
          ),
          if (helper != null && helper!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              helper!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8F96A3),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
