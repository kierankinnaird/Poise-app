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
import '../models/movement_type.dart';
import '../models/prehab_plan.dart';
import '../models/screen_result.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';
import 'screen_screen.dart';
import 'profile_screen.dart';

const _kPrefLastResult = 'last_screen_result';
const _kPrefHistory = 'screen_history';
const _kHowItWorks = 'HOW IT WORKS';
const _kStartLabel = 'Start a screen';
const _kStartSub = 'Takes about 2 minutes';
const _kScreensDone = 'Screens done';
const _kAvgScore = 'Avg score';
const _kPlanLabel = 'YOUR PREHAB PLAN';
const _kNoPlan = 'Complete a screen to get your plan.';
const _kLastScreen = 'LAST SCREEN';

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
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  // Navigates to ScreenScreen if the user has a saved profile,
  // otherwise goes through onboarding to collect sport/goal first.
  Future<void> _startScreen() async {
    final user = _authService.currentUser;
    if (user != null) {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (!mounted) return;
      if (profile != null && profile.sport.isNotEmpty) {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => ScreenScreen(
                    sport: profile.sport, goal: profile.goal)))
            .then((_) {
          if (mounted) setState(() => _selectedIndex = 0);
        });
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const OnboardingScreen()))
        .then((_) {
      if (mounted) setState(() => _selectedIndex = 0);
    });
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      _startScreen();
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

    const labels = ['Home', 'Screen', 'Progress', 'Profile'];

    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
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
            final color = active ? PoiseColors.accent : PoiseColors.muted;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[i], size: 22, color: color),
                    const SizedBox(height: 3),
                    Text(
                      labels[i],
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: color,
                      ),
                    ),
                  ],
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
  final _firestoreService = FirestoreService();
  UserProfile? _profile;
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
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _firestoreService.getUserProfile(user.uid);
        if (mounted) setState(() => _profile = profile);
      }

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

  String _firstName() {
    // Prefer profile name, fall back to email prefix, then "You".
    if (_profile?.name != null && _profile!.name!.isNotEmpty) {
      return _profile!.name!;
    }
    final email = _authService.currentUser?.email ?? '';
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return 'You';
    return '${prefix[0].toUpperCase()}${prefix.substring(1)}';
  }

  String _initial() {
    final name = _firstName();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  int get _screenCount => _history.length;

  int get _avgScore {
    if (_history.isEmpty) return 0;
    return _history.fold<int>(0, (s, r) => s + r.score) ~/ _history.length;
  }

  void _goToScreen() {
    final profile = _profile;
    if (profile != null && profile.sport.isNotEmpty) {
      Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (_) =>
                  ScreenScreen(sport: profile.sport, goal: profile.goal)))
          .then((_) {
        if (mounted) _loadData();
      });
      return;
    }
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

              // How it works for first-timers, last screen card for returning users.
              if (result == null)
                const _HowItWorksCard()
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

// Shown to first-time users in place of the last screen card.
// Three numbered steps explaining what to expect.
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PoiseColors.card,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _kHowItWorks,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: PoiseColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _HowItWorksStep(
            number: '1',
            title: 'Point your front camera at yourself',
            body: 'Stand a few metres back so your whole body is in frame.',
          ),
          const SizedBox(height: 12),
          _HowItWorksStep(
            number: '2',
            title: 'Perform 5 simple movements',
            body: 'Squat, lunge, hip hinge, single leg balance, and shoulder reach. On-screen prompts guide you through each one.',
          ),
          const SizedBox(height: 12),
          _HowItWorksStep(
            number: '3',
            title: 'Get your score and exercise plan',
            body: 'We detect movement faults and prescribe corrective exercises tailored to what we find.',
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String body;

  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: PoiseColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PoiseColors.offWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: PoiseColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
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
                result.movementType.displayName,
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
