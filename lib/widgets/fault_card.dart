// Displays a single movement observation with an intensity chip.
// Intensity colour goes muted -> amber -> red for visual hierarchy.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movement_observation.dart';
import '../theme/app_theme.dart';

class MovementObservationCard extends StatelessWidget {
  final MovementObservation observation;

  const MovementObservationCard({super.key, required this.observation});

  Color _chipColor() {
    switch (observation.intensity) {
      case ObservationIntensity.minimal:
        return PoiseColors.muted;
      case ObservationIntensity.moderate:
        return const Color(0xFFF5A623);
      case ObservationIntensity.significant:
        return PoiseColors.error;
    }
  }

  String _chipLabel() {
    switch (observation.intensity) {
      case ObservationIntensity.minimal:
        return 'MINIMAL';
      case ObservationIntensity.moderate:
        return 'MODERATE';
      case ObservationIntensity.significant:
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
                  observation.name,
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
            observation.description,
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
