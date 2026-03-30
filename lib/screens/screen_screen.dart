// Stub -- camera and pose detection are built in Stage 5.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScreenScreen extends StatelessWidget {
  final String sport;
  final String goal;

  const ScreenScreen({super.key, required this.sport, required this.goal});

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
