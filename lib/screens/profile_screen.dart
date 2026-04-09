// ignore_for_file: avoid_print
// Profile screen: avatar, name, sport edit shortcut, notification toggle, account actions.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
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
const _kCompleteProfile = 'COMPLETE YOUR PROFILE';
const _kAddName = 'Add your name';
const _kAddNameSub = "We'll use it to personalise your experience.";

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _notificationService = NotificationService();

  UserProfile? _profile;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;
    try {
      final profile = await _firestoreService.getUserProfile(user.uid);
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      print('Failed to load profile: $e');
    }
  }

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

  // Opens a dialog to enter/edit the display name and saves it.
  Future<void> _editName() async {
    final controller = TextEditingController(text: _profile?.name ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PoiseColors.card,
        title: Text(
          'Your name',
          style: GoogleFonts.syne(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: PoiseColors.offWhite,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.dmSans(color: PoiseColors.offWhite, fontSize: 14),
          decoration: const InputDecoration(hintText: 'First name'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: PoiseColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('Save',
                style: GoogleFonts.dmSans(color: PoiseColors.accent)),
          ),
        ],
      ),
    );

    if (saved == null || saved.isEmpty || _profile == null) return;
    final updated = _profile!.copyWith(name: saved);
    setState(() => _profile = updated);
    try {
      await _firestoreService.saveUserProfile(updated);
    } catch (e) {
      print('Failed to save name: $e');
    }
  }

  String _displayName() {
    if (_profile?.name != null && _profile!.name!.isNotEmpty) {
      return _profile!.name!;
    }
    // Fall back to email prefix for email/password users.
    final email = _authService.currentUser?.email ?? '';
    if (email.isEmpty) return '';
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return '';
    return '${prefix[0].toUpperCase()}${prefix.substring(1)}';
  }

  String _initial() {
    final name = _displayName();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get _needsNameCompletion {
    // Apple Sign In users have no email -- prompt them to add a name
    // if they haven't already.
    final hasEmail = _authService.currentUser?.email != null;
    final hasName = _profile?.name?.isNotEmpty == true;
    return !hasEmail && !hasName;
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email;
    final displayName = _displayName();
    final initial = _initial();
    final sport = _profile?.sport ?? '';

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

              // Complete profile prompt -- shown for Apple Sign In users with no name.
              if (_needsNameCompletion) ...[
                Text(
                  _kCompleteProfile,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: PoiseColors.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _editName,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PoiseColors.card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: PoiseColors.accent, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: PoiseColors.accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _kAddName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: PoiseColors.accent,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _kAddNameSub,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: PoiseColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: PoiseColors.accent, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                    GestureDetector(
                      onTap: _editName,
                      child: Container(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _editName,
                            child: Text(
                              displayName.isNotEmpty ? displayName : 'Tap to add name',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: displayName.isNotEmpty
                                    ? PoiseColors.offWhite
                                    : PoiseColors.muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (email != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: PoiseColors.muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                      sport.isNotEmpty ? sport : 'Not set',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: sport.isNotEmpty
                            ? PoiseColors.offWhite
                            : PoiseColors.muted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) => const OnboardingScreen()))
                          .then((_) => _loadProfile()),
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
