// ignore_for_file: avoid_print
// Shows all past screens with stats at the top.
// I merge local SharedPreferences history with Firestore history for signed-in
// users so nothing is lost if they were offline during a session.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/screen_result.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

const _kPrefHistory = 'screen_history';
const _kTitle = 'Your progress.';
const _kPastScreens = 'PAST SCREENS';
const _kTotalScreens = 'Screens';
const _kAvgScore = 'Avg score';
const _kTopFault = 'Top fault';
const _kNoHistory = 'No screens yet.';
const _kNoHistoryBody = 'Complete your first screen to track progress.';
const _kSquatScreen = 'Squat Screen';

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

Color _scoreColor(int score) {
  if (score >= 80) return PoiseColors.accent;
  if (score >= 50) return const Color(0xFFF5A623);
  return PoiseColors.error;
}

String _formattedDate(DateTime date) {
  return '${date.day} ${_kMonths[date.month - 1]} ${date.year}';
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  List<ScreenResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final user = _authService.currentUser;
      final localResults = await _loadLocalHistory();
      List<ScreenResult> firestoreResults = [];

      if (user != null) {
        try {
          firestoreResults =
              await _firestoreService.getScreenHistory(user.uid);
        } catch (e) {
          print('Failed to load Firestore history: $e');
        }
      }

      // Merge local and Firestore results, deduplicate by timestamp,
      // and sort newest first.
      final merged = <String, ScreenResult>{};
      for (final r in [...localResults, ...firestoreResults]) {
        merged[r.completedAt.toIso8601String()] = r;
      }
      _history = merged.values.toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } catch (e) {
      print('Failed to load history: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<ScreenResult>> _loadLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kPrefHistory) ?? [];
    final results = raw
        .map((s) {
          try {
            return ScreenResult.fromJson(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ScreenResult>()
        .toList();
    results.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return results;
  }

  int get _avgScore {
    if (_history.isEmpty) return 0;
    return _history.fold<int>(0, (s, r) => s + r.score) ~/ _history.length;
  }

  // Find the most frequently detected fault name across all sessions.
  String get _topFault {
    if (_history.isEmpty) return 'None';
    final counts = <String, int>{};
    for (final result in _history) {
      for (final fault in result.faults) {
        counts[fault.name] = (counts[fault.name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'None';
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 60 + MediaQuery.of(context).padding.top, 16, 0),
            child: Text(
              _kTitle,
              style: GoogleFonts.syne(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: PoiseColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (!_isLoading) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${_history.length}',
                      valueColor: PoiseColors.accent,
                      label: _kTotalScreens,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      value: '$_avgScore',
                      valueColor: _history.isNotEmpty
                          ? _scoreColor(_avgScore)
                          : PoiseColors.accent,
                      label: _kAvgScore,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TopFaultTile(
                      value: _topFault,
                      label: _kTopFault,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _kPastScreens,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PoiseColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: PoiseColors.accent),
                  )
                : _history.isEmpty
                    ? Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: PoiseColors.card,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _kNoHistory,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: PoiseColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _kNoHistoryBody,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: PoiseColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final result = _history[index];
                          return _HistoryTile(
                            result: result,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ResultsScreen(
                                    result: result,
                                    readOnly: true,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final Color valueColor;
  final String label;

  const _StatTile({
    required this.value,
    required this.valueColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PoiseColors.card,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.syne(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 11, color: PoiseColors.muted),
          ),
        ],
      ),
    );
  }
}

class _TopFaultTile extends StatelessWidget {
  final String value;
  final String label;

  const _TopFaultTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PoiseColors.card,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: PoiseColors.offWhite,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 11, color: PoiseColors.muted),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ScreenResult result;
  final VoidCallback onTap;

  const _HistoryTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final faultCount = result.faults.length;
    final scoreColor = _scoreColor(result.score);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PoiseColors.card,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kSquatScreen,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: PoiseColors.offWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formattedDate(result.completedAt),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$faultCount ${faultCount == 1 ? 'fault' : 'faults'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
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
