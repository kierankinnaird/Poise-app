// Stub -- full history screen is built in Stage 8.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
