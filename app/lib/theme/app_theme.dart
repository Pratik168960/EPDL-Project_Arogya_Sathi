import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Healthcare Blues
  static const Color bluePrimary = Color(0xFF1A6FC4);
  static const Color blueDark = Color(0xFF0D4F8C);
  static const Color blueMid = Color(0xFF4A9EE0);
  static const Color blueLight = Color(0xFFEBF4FF);

  // Calming Greens
  static const Color greenPrimary = Color(0xFF2EAE82);
  static const Color greenDark = Color(0xFF1A7A5C);
  static const Color greenLight = Color(0xFFE6F7F2);

  // Alert Red
  static const Color redAlert = Color(0xFFE53E3E);
  static const Color redLight = Color(0xFFFFF0F0);

  // Orange / Warning
  static const Color orange = Color(0xFFF6820D);
  static const Color orangeLight = Color(0xFFFEF3E2);

  // Purple / Accent
  static const Color purple = Color(0xFF7C5CBF);
  static const Color purpleLight = Color(0xFFF0EBFF);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F7FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2235);
  static const Color textSecondary = Color(0xFF6B7A99);
  static const Color textMuted = Color(0xFFA3AECB);
  static const Color border = Color(0xFFE8EDF5);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bluePrimary,
        primary: AppColors.bluePrimary,
        secondary: AppColors.greenPrimary,
        error: AppColors.redAlert,
        background: AppColors.background,
        surface: AppColors.card,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.nunito(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.blueDark,
        foregroundColor: AppColors.white,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: AppColors.bluePrimary.withOpacity(0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bluePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blueLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.bluePrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.nunito(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.nunito(color: AppColors.textMuted, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.bluePrimary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w700),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 16,
      ),
    );
  }
}

// Box shadow presets
List<BoxShadow> cardShadow = [
  BoxShadow(
    color: AppColors.bluePrimary.withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 4),
  ),
];

List<BoxShadow> elevatedShadow = [
  BoxShadow(
    color: AppColors.bluePrimary.withOpacity(0.18),
    blurRadius: 32,
    offset: const Offset(0, 8),
  ),
];

// Border radius constants
const double kRadiusSm = 10.0;
const double kRadius = 16.0;
const double kRadiusXl = 24.0;
