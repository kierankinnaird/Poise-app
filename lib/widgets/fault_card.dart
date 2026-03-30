// Displays a single detected fault with a severity chip.
// Severity colour goes muted -> amber -> red to match the level of concern.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/fault.dart';
import '../theme/app_theme.dart';

class FaultCard extends StatelessWidget {
  final Fault fault;

  const FaultCard({super.key, required this.fault});

  Color _chipColor() {
    switch (fault.severity) {
      case FaultSeverity.mild:
        return PoiseColors.muted;
      case FaultSeverity.moderate:
        return const Color(0xFFF5A623);
      case FaultSeverity.significant:
        return PoiseColors.error;
    }
  }

  String _chipLabel() {
    switch (fault.severity) {
      case FaultSeverity.mild:
        return 'MILD';
      case FaultSeverity.moderate:
        return 'MODERATE';
      case FaultSeverity.significant:
        return 'SIGNIFICANT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PoiseColors.card,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fault.name,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PoiseColors.offWhite,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _chipColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: _chipColor().withValues(alpha: 0.4)),
                ),
                child: Text(
                  _chipLabel(),
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _chipColor(),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fault.description,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: PoiseColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
