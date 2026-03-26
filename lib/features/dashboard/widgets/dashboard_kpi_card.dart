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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECEF), width: 1),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x0A0D0D12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8F96A3),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111318),
              height: 1.0,
            ),
          ),
          if (helper != null && helper!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              helper!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8F96A3),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
