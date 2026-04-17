// ignore_for_file: avoid_print
// Shows the score, movement observations, and fitness suggestions after a screen completes.
// I save the result to SharedPreferences on every screen (guest-safe) and to
// Firestore only if the user is signed in.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movement_observation.dart';
import '../models/movement_type.dart';
import '../models/screen_result.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fault_card.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'screen_screen.dart';

const _kPrefLastResult = 'last_screen_result';
const _kPrefHistory = 'screen_history';

const _kScreenComplete = 'ANALYSIS COMPLETE';
const _kYourResults = 'Your results.';
const _kMovementScore = 'Movement score';
const _kObservationsLabel = 'MOVEMENT OBSERVATIONS';
const _kNoObservationsTitle = 'No observations.';
const _kNoObservationsBody = 'Great work!';
const _kScreenAgain = 'Audit again';
const _kViewProgress = 'View my progress';
const _kBackToHome = 'Back to home';

const _kDisclaimer = '''
IMPORTANT: This app provides general fitness feedback for educational purposes only.
• NOT a medical device
• NOT medical advice
• Consult a healthcare provider if you have pain or injury concerns
''';

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// Score colour: green above 80, amber above 50, red below.
Color _scoreColor(int score) {
  if (score >= 80) return PoiseColors.accent;
  if (score >= 50) return const Color(0xFFF5A623);
  return PoiseColors.error;
}

String _formattedDate(DateTime date) {
  return '${date.day} ${_kMonths[date.month - 1]} ${date.year}';
}

class ResultsScreen extends StatefulWidget {
  final ScreenResult result;

  // readOnly is true when viewing from history -- no save, no CTAs.
  final bool readOnly;

  const ResultsScreen({
    super.key,
    required this.result,
    this.readOnly = false,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (!widget.readOnly) _saveResult();
  }

  Future<void> _saveResult() async {
    // SharedPreferences save runs for all users including guests.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kPrefLastResult, jsonEncode(widget.result.toJson()));

      // Append to the history list, deduplicating by timestamp.
      final existing = prefs.getStringList(_kPrefHistory) ?? [];
      final ts = widget.result.completedAt.toIso8601String();
      final alreadyExists = existing.any((s) {
        try {
          final m = jsonDecode(s) as Map<String, dynamic>;
          return m['completedAt'] == ts;
        } catch (_) {
          return false;
        }
      });
      if (!alreadyExists) {
        existing.add(jsonEncode(widget.result.toJson()));
        await prefs.setStringList(_kPrefHistory, existing);
      }
    } catch (e) {
      print('Failed to save to SharedPreferences: $e');
    }

    // Firestore save only for signed-in users.
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await _firestoreService.saveScreenResult(user.uid, widget.result);
      } catch (e) {
        print('Failed to save to Firestore: $e');
      }
    }
  }

  // Groups observations by type and surfaces left/right asymmetry when an observation
  // only appears on one side. Bilateral observations (same type, both sides) are
  // shown individually without an asymmetry note since both sides are affected.
  List<Widget> _buildObservationCards(List<MovementObservation> observations) {
    final byType = <MovementObservationType, List<MovementObservation>>{};
    for (final observation in observations) {
      byType.putIfAbsent(observation.type, () => []).add(observation);
    }

    final widgets = <Widget>[];
    for (final group in byType.values) {
      final sides = group.map((o) => o.side).toSet();
      // One-sided observation on a unilateral movement = asymmetry worth noting.
      final isAsymmetric = sides.length == 1 && sides.first != null;

      for (final observation in group) {
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: isAsymmetric ? 4 : 8),
          child: MovementObservationCard(observation: observation),
        ));
      }

      if (isAsymmetric) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFF5A623).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Observed on one side only. This is common and may indicate natural asymmetries in your movement.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFFF5A623),
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.result.score;
    final scoreColor = _scoreColor(score);

    return Scaffold(
      backgroundColor: PoiseColors.background,
      // Back button only in read-only (history) mode.
      appBar: widget.readOnly
          ? AppBar(
              backgroundColor: PoiseColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: PoiseColors.offWhite),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Text(
                _kScreenComplete,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PoiseColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _kYourResults,
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: PoiseColors.offWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.result.sport} · ${widget.result.movementType.displayName} · ${_formattedDate(widget.result.completedAt)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: PoiseColors.muted,
                ),
              ),

              const SizedBox(height: 28),

              // Score circle
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: scoreColor, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: GoogleFonts.syne(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _kMovementScore,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: PoiseColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Movement observations section
              Text(
                _kObservationsLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PoiseColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (widget.result.observations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PoiseColors.card,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _kNoObservationsTitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: PoiseColors.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _kNoObservationsBody,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: PoiseColors.muted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._buildObservationCards(widget.result.observations),

              const SizedBox(height: 24),

              // Disclaimer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PoiseColors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: PoiseColors.muted.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _kDisclaimer,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: PoiseColors.muted,
                    height: 1.5,
                  ),
                ),
              ),

              // CTAs -- hidden in read-only mode.
              if (!widget.readOnly) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => ScreenScreen(
                          sport: widget.result.sport,
                          goal: widget.result.goal,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    _kScreenAgain,
                    style: GoogleFonts.syne(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen()),
                      );
                    },
                    child: Text(
                      _kViewProgress,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: PoiseColors.offWhite,
                        decoration: TextDecoration.underline,
                        decorationColor: PoiseColors.offWhite,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      _kBackToHome,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: PoiseColors.muted,
                        decoration: TextDecoration.underline,
                        decorationColor: PoiseColors.muted,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
