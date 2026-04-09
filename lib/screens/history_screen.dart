// ignore_for_file: avoid_print
// Progress screen: score trend chart, category breakdown (mobility/stability/symmetry),
// fault frequency, and tappable session history.
// I merge local SharedPreferences history with Firestore so nothing is lost offline.
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fault.dart';
import '../models/movement_type.dart';
import '../models/screen_result.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

const _kPrefHistory = 'screen_history';

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

// Fault types grouped by category for the dashboard cards.
const _mobilityFaultTypes = {
  FaultType.depth,
  FaultType.forwardLean,
  FaultType.limitedRotation,
  FaultType.armFallForward,
  FaultType.heelRise,
};
const _stabilityFaultTypes = {
  FaultType.kneeCave,
  FaultType.hipDrop,
  FaultType.excessiveSway,
  FaultType.excessiveKneeBend,
};

Color _scoreColor(int score) {
  if (score >= 80) return PoiseColors.accent;
  if (score >= 50) return const Color(0xFFF5A623);
  return PoiseColors.error;
}

String _faultTypeName(FaultType type) {
  switch (type) {
    case FaultType.kneeCave:
      return 'Knee Cave';
    case FaultType.depth:
      return 'Insufficient Depth';
    case FaultType.forwardLean:
      return 'Forward Lean';
    case FaultType.heelRise:
      return 'Heel Rise';
    case FaultType.hipDrop:
      return 'Hip Drop';
    case FaultType.excessiveSway:
      return 'Excessive Sway';
    case FaultType.armFallForward:
      return 'Arms Falling Forward';
    case FaultType.limitedRotation:
      return 'Limited Overhead Reach';
    case FaultType.excessiveKneeBend:
      return 'Excessive Knee Bend';
  }
}

String _formattedDate(DateTime date) =>
    '${date.day} ${_kMonths[date.month - 1]} ${date.year}';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  List<ScreenResult> _history = []; // newest first
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
          firestoreResults = await _firestoreService.getScreenHistory(user.uid);
        } catch (e) {
          print('Failed to load Firestore history: $e');
        }
      }
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
            return ScreenResult.fromJson(jsonDecode(s) as Map<String, dynamic>);
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

  String get _topFault {
    if (_history.isEmpty) return 'None';
    final counts = <String, int>{};
    for (final result in _history) {
      for (final fault in result.faults) {
        counts[fault.name] = (counts[fault.name] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return 'None';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // Average per-session mobility score. Each unique mobility fault costs 20 points.
  int get _mobilityScore {
    if (_history.isEmpty) return 0;
    final total = _history.fold<int>(0, (sum, result) {
      final unique = result.faults
          .where((f) => _mobilityFaultTypes.contains(f.type))
          .map((f) => f.type)
          .toSet()
          .length;
      return sum + (100 - unique * 20).clamp(0, 100);
    });
    return total ~/ _history.length;
  }

  // Average per-session stability score. Each unique stability fault costs 25 points.
  int get _stabilityScore {
    if (_history.isEmpty) return 0;
    final total = _history.fold<int>(0, (sum, result) {
      final unique = result.faults
          .where((f) => _stabilityFaultTypes.contains(f.type))
          .map((f) => f.type)
          .toSet()
          .length;
      return sum + (100 - unique * 25).clamp(0, 100);
    });
    return total ~/ _history.length;
  }

  // Symmetry score: 100 minus the % of sessions that showed left/right asymmetry
  // (same fault type detected on one side but not the other in the same session).
  int get _symmetryScore {
    if (_history.isEmpty) return 0;
    final asymmetricCount = _history.where((result) {
      final left = result.faults
          .where((f) => f.side == 'left')
          .map((f) => f.type)
          .toSet();
      final right = result.faults
          .where((f) => f.side == 'right')
          .map((f) => f.type)
          .toSet();
      return left.any((t) => !right.contains(t)) ||
          right.any((t) => !left.contains(t));
    }).length;
    return (100 - asymmetricCount / _history.length * 100).round();
  }

  // Top 5 fault types by number of sessions in which they appeared.
  List<MapEntry<FaultType, int>> get _topFaultEntries {
    final counts = <FaultType, int>{};
    for (final result in _history) {
      for (final type in result.faults.map((f) => f.type).toSet()) {
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: PoiseColors.background,
        body: Center(child: CircularProgressIndicator(color: PoiseColors.accent)),
      );
    }

    final chronological = _history.reversed.toList();
    final faultEntries = _topFaultEntries;

    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 60 + top, 16, 32),
        children: [
          Text(
            'Your progress.',
            style: GoogleFonts.syne(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: PoiseColors.accent,
            ),
          ),
          const SizedBox(height: 16),

          // Summary stat tiles
          Row(children: [
            Expanded(
              child: _StatTile(
                value: '${_history.length}',
                valueColor: PoiseColors.accent,
                label: 'Screens',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                value: '$_avgScore',
                valueColor: _history.isNotEmpty
                    ? _scoreColor(_avgScore)
                    : PoiseColors.accent,
                label: 'Avg score',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TopFaultTile(value: _topFault, label: 'Top fault'),
            ),
          ]),

          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ScoreTrendCard(chronological: chronological),
            const SizedBox(height: 12),

            // Mobility / stability / symmetry category scores
            Row(children: [
              Expanded(child: _CategoryTile(label: 'MOBILITY', score: _mobilityScore)),
              const SizedBox(width: 8),
              Expanded(child: _CategoryTile(label: 'STABILITY', score: _stabilityScore)),
              const SizedBox(width: 8),
              Expanded(child: _CategoryTile(label: 'SYMMETRY', score: _symmetryScore)),
            ]),

            if (faultEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FaultFrequencyCard(
                faults: faultEntries,
                totalSessions: _history.length,
              ),
            ],
          ],

          const SizedBox(height: 16),
          Text(
            'PAST SCREENS',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: PoiseColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          if (_history.isEmpty)
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
                    'No screens yet.',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: PoiseColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete your first screen to track progress.',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: PoiseColors.muted),
                  ),
                ],
              ),
            )
          else
            ..._history.map(
              (result) => _HistoryTile(
                result: result,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ResultsScreen(result: result, readOnly: true),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Score trend line chart using fl_chart. Shows all sessions chronologically.
class _ScoreTrendCard extends StatelessWidget {
  final List<ScreenResult> chronological;

  const _ScoreTrendCard({required this.chronological});

  @override
  Widget build(BuildContext context) {
    final spots = chronological
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble()))
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
      decoration: BoxDecoration(
        color: PoiseColors.card,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCORE OVER TIME',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: PoiseColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: chronological.length > 2,
                    curveSmoothness: 0.3,
                    color: PoiseColors.accent,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: chronological.length <= 8,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: PoiseColors.accent,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: PoiseColors.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == 50 || value == 100) {
                          return Text(
                            '${value.toInt()}',
                            style: GoogleFonts.dmSans(
                                fontSize: 9, color: PoiseColors.muted),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        final n = chronological.length;
                        if (i < 0 || i >= n) return const SizedBox.shrink();
                        // Show labels at first, middle, and last session only.
                        final show =
                            i == 0 || i == n - 1 || (n > 3 && i == n ~/ 2);
                        if (!show) return const SizedBox.shrink();
                        final date = chronological[i].completedAt;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.day} ${_kMonths[date.month - 1]}',
                            style: GoogleFonts.dmSans(
                                fontSize: 9, color: PoiseColors.muted),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: PoiseColors.muted.withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Single category tile: label, numeric score, and a coloured progress bar.
class _CategoryTile extends StatelessWidget {
  final String label;
  final int score;

  const _CategoryTile({required this.label, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
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
            label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: PoiseColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score',
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: PoiseColors.muted.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// Horizontal bars showing how often each fault appeared across all sessions.
// Bar width = fraction of sessions in which that fault appeared.
// Color reflects frequency: rare = green, common = red.
class _FaultFrequencyCard extends StatelessWidget {
  final List<MapEntry<FaultType, int>> faults;
  final int totalSessions;

  const _FaultFrequencyCard(
      {required this.faults, required this.totalSessions});

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
            'COMMON FAULTS',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: PoiseColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ...faults.map((entry) {
            final fraction = entry.value / totalSessions;
            // Invert fraction so high-frequency faults get a low "score" (red).
            final barColor = _scoreColor(100 - (fraction * 100).round());
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _faultTypeName(entry.key),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: PoiseColors.offWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}/$totalSessions',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: PoiseColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: fraction,
                      backgroundColor: PoiseColors.muted.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            );
          }),
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
            style:
                GoogleFonts.dmSans(fontSize: 11, color: PoiseColors.muted),
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
            style:
                GoogleFonts.dmSans(fontSize: 11, color: PoiseColors.muted),
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
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
                    result.movementType.displayName,
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
