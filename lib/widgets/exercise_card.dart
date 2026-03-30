// A single prehab exercise card. Sets and duration are shown in accent colour
// so they stand out from the description text below.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prehab_plan.dart';
import '../theme/app_theme.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    // Show "sets · duration" when both exist, otherwise just whichever is set.
    final setsLabel = exercise.duration != null
        ? '${exercise.sets} · ${exercise.duration}'
        : exercise.sets;

    return Container(
      decoration: BoxDecoration(
        color: PoiseColors.card,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: PoiseColors.offWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            setsLabel,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: PoiseColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exercise.description,
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
