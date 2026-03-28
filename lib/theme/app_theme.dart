// I want the whole app to feel dark, minimal, and a bit athletic.
// Near-black background, a lime-green accent, and off-white text.
// I'm using Syne for headings (bold, geometric) and DM Sans for body.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Single source of truth for every colour in the app.
// I import this anywhere I need a colour rather than hardcoding hex values.
class PoiseColors {
  static const background = Color(0xFF080808);
  static const card = Color(0xFF181816);
  static const accent = Color(0xFFC8F562); // lime green
  static const offWhite = Color(0xFFF5F2ED);
  static const muted = Color(0xFF5A5A52);
  static const error = Color(0xFFFF5050);
}

class PoiseTheme {
  // I only use dark mode. The method is called light() only because
  // MaterialApp.theme expects a light-slot ThemeData -- the colours are all dark.
  static ThemeData light() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
    );

    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: PoiseColors.background,
      colorScheme: const ColorScheme.dark(
        primary: PoiseColors.accent,
        secondary: PoiseColors.accent,
        surface: PoiseColors.card,
        error: PoiseColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: PoiseColors.offWhite,
        onError: Colors.white,
      ),
      // DM Sans as the base body font with Syne for display/title sizes
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.syne(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: PoiseColors.offWhite,
        ),
        displayMedium: GoogleFonts.syne(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: PoiseColors.offWhite,
        ),
        titleLarge: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: PoiseColors.offWhite,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: PoiseColors.offWhite,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: PoiseColors.muted,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: PoiseColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PoiseColors.accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
          textStyle: GoogleFonts.syne(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PoiseColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: PoiseColors.muted),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: PoiseColors.muted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: PoiseColors.accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.dmSans(color: PoiseColors.muted, fontSize: 14),
        hintStyle: GoogleFonts.dmSans(color: PoiseColors.muted, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PoiseColors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: PoiseColors.offWhite,
        ),
        iconTheme: const IconThemeData(color: PoiseColors.offWhite),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: Colors.transparent,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PoiseColors.card,
        selectedItemColor: PoiseColors.accent,
        unselectedItemColor: PoiseColors.muted,
      ),
    );
  }
}
