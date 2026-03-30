// ignore_for_file: avoid_print
// The app shell. I use a custom bottom nav rather than BottomNavigationBar
// so I have full control over sizing and hit areas.
// The Screen tab pushes OnboardingScreen rather than swapping the body --
// I want the camera flow to feel like a separate journey, not a tab.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analysis/prehab_generator.dart';
import '../models/prehab_plan.dart';
import '../models/screen_result.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';

const _kPrefLastResult = 'last_screen_result';
const _kPrefHistory = 'screen_history';
const _kNoScreensYet = 'No screens yet';
const _kNoScreensBody = 'Complete your first screen to get started.';
const _kStartLabel = 'Start a screen';
const _kStartSub = 'Takes about 2 minutes';
const _kScreensDone = 'Screens done';
const _kAvgScore = 'Avg score';
const _kPlanLabel = 'YOUR PREHAB PLAN';
const _kNoPlan = 'Complete a screen to get your plan.';
const _kLastScreen = 'LAST SCREEN';
const _kSquatScreen = 'Squat Screen';

Color _scoreColor(int score) {
  if (score >= 80) return PoiseColors.accent;
  if (score >= 50) return const Color(0xFFF5A623);
  return PoiseColors.error;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    // The Screen tab (index 1) is not a real tab -- it pushes a new route.
    if (index == 1) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const OnboardingScreen()))
          .then((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const _HomeHubScreen();
      case 2:
        return const HistoryScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const _HomeHubScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: _buildBody(),
      bottomNavigationBar: _PoiseBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _PoiseBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _PoiseBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home,
      Icons.videocam,
      Icons.history,
      Icons.person,
    ];

    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: PoiseColors.card,
        border: Border(top: BorderSide(color: Color(0xFF2A2A28), width: 1)),
      ),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(icons.length, (i) {
            final active = selectedIndex == i;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Icon(
                    icons[i],
                    size: 24,
                    color:
                        active ? PoiseColors.accent : PoiseColors.muted,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// The home tab content -- last screen card, start CTA, stats, top prehab exercise.
class _HomeHubScreen extends StatefulWidget {
  const _HomeHubScreen();

  @override
  State<_HomeHubScreen> createState() => _HomeHubScreenState();
}

class _HomeHubScreenState extends State<_HomeHubScreen> {
  final _authService = AuthService();
  ScreenResult? _lastResult;
  List<ScreenResult> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final lastJson = prefs.getString(_kPrefLastResult);
      if (lastJson != null) {
        try {
          _lastResult = ScreenResult.fromJson(
              jsonDecode(lastJson) as Map<String, dynamic>);
        } catch (e) {
          print('Failed to parse last result: $e');
        }
      }

      final historyRaw = prefs.getStringList(_kPrefHistory) ?? [];
      _history = historyRaw
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
    } catch (e) {
      print('Failed to load home data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Derive a first name from the email prefix, fall back to "You".
  String _firstName() {
    final user = _authService.currentUser;
    if (user == null) return 'You';
    final email = user.email ?? '';
    final name = email.split('@').first;
    if (name.isEmpty) return 'You';
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _initial() {
    final name = _firstName();
    return name.isNotEmpty ? name[0].toUpperCase() : 'Y';
  }

  int get _screenCount => _history.length;

  int get _avgScore {
    if (_history.isEmpty) return 0;
    return _history.fold<int>(0, (s, r) => s + r.score) ~/ _history.length;
  }

  void _goToScreen() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const OnboardingScreen()))
        .then((_) {
      if (mounted) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: PoiseColors.background,
        body: Center(
            child: CircularProgressIndicator(color: PoiseColors.accent)),
      );
    }

    final result = _lastResult;
    final plan =
        result != null ? PrehabGenerator.generate(result.faults) : null;

    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Top bar: name greeting + avatar initial
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: PoiseColors.offWhite,
                      ),
                      children: [
                        TextSpan(text: _firstName()),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: PoiseColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initial(),
                        style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Last screen card
              if (result == null)
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
                        _kLastScreen,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: PoiseColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _kNoScreensYet,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: PoiseColors.offWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _kNoScreensBody,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: PoiseColors.muted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _LastScreenCard(result: result),

              const SizedBox(height: 12),

              // Start a screen CTA
              GestureDetector(
                onTap: _goToScreen,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: PoiseColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _kStartLabel,
                            style: GoogleFonts.syne(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            _kStartSub,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.play_arrow,
                          color: Colors.black, size: 28),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Stats row: screens done + avg score
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '$_screenCount',
                      valueColor: PoiseColors.accent,
                      label: _kScreensDone,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      value: '$_avgScore',
                      valueColor: _screenCount > 0
                          ? _scoreColor(_avgScore)
                          : PoiseColors.accent,
                      label: _kAvgScore,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                _kPlanLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PoiseColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (plan == null || plan.exercises.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PoiseColors.card,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _kNoPlan,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: PoiseColors.muted,
                    ),
                  ),
                )
              else
                // I show only the first exercise on the home screen --
                // the full plan is on the results screen.
                _PrehabExerciseTile(exercise: plan.exercises.first),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastScreenCard extends StatelessWidget {
  final ScreenResult result;

  const _LastScreenCard({required this.result});

  @override
  Widget build(BuildContext context) {
    // Show up to two fault names, joined with " / ".
    final faultSummary = result.faults.length >= 2
        ? '${result.faults[0].name} / ${result.faults[1].name}'
        : result.faults.isNotEmpty
            ? result.faults[0].name
            : '';

    return Container(
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
            _kLastScreen,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: PoiseColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _kSquatScreen,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: PoiseColors.offWhite,
                ),
              ),
              const Spacer(),
              Text(
                '${result.score}',
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _scoreColor(result.score),
                ),
              ),
            ],
          ),
          if (faultSummary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              faultSummary,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: PoiseColors.muted,
              ),
            ),
          ],
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
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: PoiseColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrehabExerciseTile extends StatelessWidget {
  final Exercise exercise;

  const _PrehabExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final setsLabel = exercise.duration != null
        ? '${exercise.sets} · ${exercise.duration}'
        : exercise.sets;

    return Container(
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
            exercise.name,
            style: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PoiseColors.offWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            setsLabel,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: PoiseColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
