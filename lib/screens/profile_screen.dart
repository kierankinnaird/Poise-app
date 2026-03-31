// ignore_for_file: avoid_print
// Profile screen: avatar, sport edit shortcut, notification toggle, account actions.
// The notification toggle is wired up fully in Stage 8 -- the stub service is a no-op for now.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'onboarding_screen.dart';

const _kTitle = 'Profile.';
const _kMySport = 'MY SPORT';
const _kRescreenReminders = 'RESCREEN REMINDERS';
const _kAccount = 'ACCOUNT';
const _kWeeklyReminder = 'Weekly reminder';
const _kEvery7Days = 'Every 7 days';
const _kPrivacyPolicy = 'Privacy policy';
const _kSignOut = 'Sign out';
const _kChange = 'Change';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _notificationService = NotificationService();
  bool _notificationsEnabled = false;

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    if (value) {
      await _notificationService.scheduleRescreenReminder();
    } else {
      await _notificationService.cancelAll();
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  String _displayName(String? email) {
    if (email == null || email.isEmpty) return '';
    final name = email.split('@').first;
    if (name.isEmpty) return '';
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _initial(String? email) {
    final name = _displayName(email);
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final email = user?.email;
    final displayName = _displayName(email);
    final initial = _initial(email);

    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                _kTitle,
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: PoiseColors.offWhite,
                ),
              ),
              const SizedBox(height: 20),

              // Avatar card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PoiseColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: PoiseColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.syne(
                            fontSize: 18,
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
                            displayName,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: PoiseColors.offWhite,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email ?? '',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: PoiseColors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // MY SPORT
              Text(
                _kMySport,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PoiseColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: PoiseColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sport',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: PoiseColors.offWhite,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OnboardingScreen()),
                      ),
                      child: Text(
                        _kChange,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: PoiseColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // RESCREEN REMINDERS
              Text(
                _kRescreenReminders,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PoiseColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: PoiseColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _kWeeklyReminder,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: PoiseColors.offWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _kEvery7Days,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: PoiseColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeThumbColor: PoiseColors.accent,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ACCOUNT
              Text(
                _kAccount,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PoiseColors.muted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: PoiseColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _AccountRow(
                  label: _kPrivacyPolicy,
                  labelColor: PoiseColors.offWhite,
                  trailing: const Icon(Icons.chevron_right,
                      color: PoiseColors.muted, size: 20),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: PoiseColors.card,
                      title: Text(
                        'Privacy Policy',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: PoiseColors.offWhite,
                        ),
                      ),
                      content: Text(
                        'Your data is stored securely and never shared with third parties.',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: PoiseColors.muted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Close',
                            style:
                                GoogleFonts.dmSans(color: PoiseColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: PoiseColors.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _AccountRow(
                  label: _kSignOut,
                  labelColor: PoiseColors.error,
                  onTap: _signOut,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _AccountRow({
    required this.label,
    required this.labelColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 14, color: labelColor),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
