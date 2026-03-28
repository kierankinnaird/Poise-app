// Stub -- full auth UI is built in Stage 2.
// I just need something here so main.dart compiles and I can do the first commit.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: PoiseColors.background,
      body: Center(
        child: CircularProgressIndicator(color: PoiseColors.accent),
      ),
    );
  }
}
