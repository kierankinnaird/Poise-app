// Reusable history tile -- used anywhere a ScreenResult needs to be
// shown in a list outside of the HistoryScreen itself.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movement_type.dart';
import '../models/screen_result.dart';
import '../theme/app_theme.dart';

class ScreenHistoryTile extends StatelessWidget {
  final ScreenResult result;
  final VoidCallback? onTap;

  const ScreenHistoryTile({
    super.key,
    required this.result,
    this.onTap,
  });

  Color _scoreColor() {
    if (result.score >= 80) return PoiseColors.accent;
    if (result.score >= 50) return const Color(0xFFF5A623);
    return PoiseColors.error;
  }

  String _formattedDate() {
    final d = result.completedAt;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = d.day.toString().padLeft(2, '0');
    return '$day ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: PoiseColors.card,
          borderRadius: BorderRadius.circular(6),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formattedDate(),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: PoiseColors.offWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${result.sport} · ${result.movementType.displayName}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: PoiseColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.score}',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor(),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${result.faults.length} fault${result.faults.length == 1 ? '' : 's'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: PoiseColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
