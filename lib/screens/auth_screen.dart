// The first screen a new user sees. I want it to feel clean and confident --
// big wordmark, minimal form, no clutter.
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

const _kTagline = 'Your personal movement screen.';
const _kEmailHint = 'Email';
const _kPasswordHint = 'Password';
const _kSignUpTab = 'Sign up';
const _kSignInTab = 'Sign in';
const _kCreateAccount = 'Create account';
const _kSignInCta = 'Sign in';
const _kAppleSignIn = 'Continue with Apple';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // I start on the sign-up tab because new users are the happy path.
  bool _isSignUp = true;

  String _friendlyAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Check your internet connection and try again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _authService.signInWithApple();
      if (!mounted) return;
      final isNew = result.isNewUser;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isNew ? const OnboardingScreen() : const HomeScreen(),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isSignUp) {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // New users go to onboarding to set their profile before the home screen.
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      } else {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        // Returning users skip onboarding and go straight to the dashboard.
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 96,
                    height: 96,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _kTagline,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: PoiseColors.offWhite,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Sign up / Sign in toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ToggleButton(
                        label: _kSignUpTab,
                        selected: _isSignUp,
                        onTap: () => setState(() => _isSignUp = true),
                      ),
                      const SizedBox(width: 24),
                      _ToggleButton(
                        label: _kSignInTab,
                        selected: !_isSignUp,
                        onTap: () => setState(() => _isSignUp = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: GoogleFonts.dmSans(
                        color: PoiseColors.offWhite, fontSize: 14),
                    decoration: const InputDecoration(hintText: _kEmailHint),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.dmSans(
                        color: PoiseColors.offWhite, fontSize: 14),
                    decoration:
                        const InputDecoration(hintText: _kPasswordHint),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.dmSans(
                          color: PoiseColors.error, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(_isSignUp ? _kCreateAccount : _kSignInCta),
                  ),

                  // I only show Apple Sign In on iOS -- the button looks wrong on Android.
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithApple,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          _kAppleSignIn,
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const Spacer(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A simple text toggle -- selected state is shown with an underline in accent colour.
class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: selected ? PoiseColors.offWhite : PoiseColors.muted,
          decoration:
              selected ? TextDecoration.underline : TextDecoration.none,
          decorationColor: PoiseColors.accent,
          decorationThickness: 2,
        ),
      ),
    );
  }
}
