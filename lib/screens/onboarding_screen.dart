// ignore_for_file: avoid_print
// Two-step onboarding: pick your sport, then pick your goal.
// I save the profile to Firestore for signed-in users and skip saving for guests
// -- they still get a personalised screen, just nothing persisted.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'screen_screen.dart';

const _kStep1Of2 = 'STEP 1 OF 2';
const _kStep2Of2 = 'STEP 2 OF 2';
const _kSportHeading = "What's your\nmain sport?";
const _kSportSubtitle = "We'll tailor your screen to your movement demands.";
const _kGoalHeading = "What's your\nmain goal?";
const _kCtaNext = 'Next -- my goal';
const _kCtaStart = 'Start screen';

const _kSports = ['Football', 'Running', 'CrossFit', 'Rugby', 'Gym', 'Other'];

const _kGoals = [
  _GoalOption(
    title: 'Stay injury-free',
    subtitle: 'Reduce injury risk before it happens',
  ),
  _GoalOption(
    title: 'Improve my movement',
    subtitle: 'Fix the faults holding back your performance',
  ),
];

const _kSportIcons = <String, IconData>{
  'Football': Icons.sports_soccer,
  'Running': Icons.directions_run,
  'CrossFit': Icons.fitness_center,
  'Rugby': Icons.sports_rugby,
  'Gym': Icons.fitness_center,
  'Other': Icons.more_horiz,
};

// Used from ProfileScreen when a returning user wants to edit their sport/goal.
class OnboardingScreen extends StatefulWidget {
  final String? initialSport;
  final String? initialGoal;

  const OnboardingScreen({super.key, this.initialSport, this.initialGoal});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 1;
  String? _selectedSport;
  String? _selectedGoal;
  bool _isLoading = false;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.initialSport;
    _selectedGoal = widget.initialGoal;
  }

  Future<void> _proceed() async {
    if (_selectedSport == null || _selectedGoal == null) return;
    setState(() => _isLoading = true);

    final user = _authService.currentUser!;
    try {
      final profile = UserProfile(
        uid: user.uid,
        email: user.email,
        sport: _selectedSport!,
        goal: _selectedGoal!,
        createdAt: DateTime.now(),
      );
      await _firestoreService.saveUserProfile(profile);
    } catch (e) {
      print('Failed to save profile: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScreenScreen(
            sport: _selectedSport!,
            goal: _selectedGoal!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: SafeArea(
        child: _step == 1 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    _kStep1Of2,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: PoiseColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _kSportHeading,
                  style: GoogleFonts.syne(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: PoiseColors.offWhite,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _kSportSubtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: PoiseColors.muted,
                  ),
                ),
                const SizedBox(height: 32),
                _SportGrid(
                  sports: _kSports,
                  selected: _selectedSport,
                  onSelect: (s) => setState(() => _selectedSport = s),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ElevatedButton(
            onPressed: _selectedSport != null
                ? () => setState(() => _step = 2)
                : null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: PoiseColors.card,
              disabledForegroundColor: PoiseColors.muted,
            ),
            child: Text(
              _kCtaNext,
              style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: PoiseColors.offWhite),
                      onPressed: () => setState(() => _step = 1),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _kStep2Of2,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: PoiseColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _kGoalHeading,
                  style: GoogleFonts.syne(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: PoiseColors.offWhite,
                  ),
                ),
                const SizedBox(height: 32),
                ..._kGoals.map((goal) {
                  final selected = _selectedGoal == goal.title;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedGoal = goal.title),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PoiseColors.card,
                          borderRadius: BorderRadius.circular(6),
                          border: selected
                              ? Border.all(
                                  color: PoiseColors.accent, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? PoiseColors.accent
                                    : PoiseColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal.subtitle,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: PoiseColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ElevatedButton(
            onPressed: _selectedGoal != null && !_isLoading ? _proceed : null,
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: PoiseColors.card,
              disabledForegroundColor: PoiseColors.muted,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Text(
                    _kCtaStart,
                    style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

}

class _SportGrid extends StatelessWidget {
  final List<String> sports;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SportGrid({
    required this.sports,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sports.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final sport = sports[index];
        final isSelected = selected == sport;
        final icon = _kSportIcons[sport] ?? Icons.sports;

        return GestureDetector(
          onTap: () => onSelect(sport),
          child: Container(
            decoration: BoxDecoration(
              color: PoiseColors.card,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? Border.all(color: PoiseColors.accent, width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected ? PoiseColors.accent : PoiseColors.muted,
                ),
                const SizedBox(height: 8),
                Text(
                  sport,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: isSelected ? PoiseColors.accent : PoiseColors.muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GoalOption {
  final String title;
  final String subtitle;

  const _GoalOption({required this.title, required this.subtitle});
}
