// Stub -- full home dashboard is built in Stage 7.
// Placeholder so main.dart compiles from the first commit.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
