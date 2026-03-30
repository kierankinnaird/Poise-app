// Stub -- full results screen is built in Stage 6.
import 'package:flutter/material.dart';
import '../models/screen_result.dart';
import '../theme/app_theme.dart';

class ResultsScreen extends StatelessWidget {
  final ScreenResult result;

  const ResultsScreen({super.key, required this.result});

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
