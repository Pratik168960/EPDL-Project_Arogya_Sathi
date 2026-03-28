import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════
//  AROGYASATHI — PROFESSIONAL DESIGN SYSTEM
//  Aesthetic: Clinical Clarity · Trustworthy · Calm
// ═══════════════════════════════════════════════

class AppColors {
  // ── Core Brand ──────────────────────────────
  static const Color navy       = Color(0xFF0C1E35);   // Authority, headers
  static const Color navyMid    = Color(0xFF132D4A);   // Subtle navy variant
  static const Color bluePrimary= Color(0xFF1565C0);   // Links, secondary actions
  static const Color blueLight  = Color(0xFFE8F1FD);   // Blue tinted backgrounds

  // ── Primary Action — Teal ────────────────────
  static const Color teal       = Color(0xFF00897B);   // Primary CTA
  static const Color tealDark   = Color(0xFF00695C);   // Pressed state
  static const Color tealLight  = Color(0xFF4DB6AC);   // Icons on dark bg, subtle text
  static const Color tealPale   = Color(0xFFE0F2F1);   // Teal tinted card bg

  // ── Semantic — Success ───────────────────────
  static const Color success    = Color(0xFF2E7D32);   // Taken, confirmed
  static const Color successBg  = Color(0xFFEDF7EE);   // Success card background

  // ── Semantic — Warning ───────────────────────
  static const Color warning    = Color(0xFFB45309);   // Upcoming, caution
  static const Color warningBg  = Color(0xFFFEF3C7);   // Warning card background

  // ── Semantic — Danger ───────────────────────
  static const Color danger     = Color(0xFFC62828);   // Missed, SOS, emergency
  static const Color dangerBg   = Color(0xFFFFF0F0);   // Danger card background

  // ── Neutral Surface ──────────────────────────
  static const Color background = Color(0xFFF2F6FA);   // App scaffold
  static const Color surface    = Color(0xFFF8FAFB);   // Subtle inner sections
  static const Color white      = Color(0xFFFFFFFF);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color border     = Color(0xFFE4ECF3);
  static const Color divider    = Color(0xFFF1F5F9);

  // ── Typography ───────────────────────────────
  static const Color textPrimary   = Color(0xFF0C1E35);
  static const Color textSecondary = Color(0xFF4A6080);
  static const Color textMuted     = Color(0xFF8FA3BA);

  // ── Alias (backward-compat with common_widgets) ──
  static const Color greenPrimary  = success;

  // ── Shadows ──────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x080C1E35), blurRadius: 8,  offset: Offset(0, 2)),
    BoxShadow(color: Color(0x050C1E35), blurRadius: 24, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> floatShadow = [
    BoxShadow(color: Color(0x1800897B), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> navShadow = [
    BoxShadow(color: Color(0x100C1E35), blurRadius: 16, offset: Offset(0, -4)),
  ];
}

// ── Top-level radius constants ────────────────────
const double kRadiusXs = 6.0;
const double kRadiusSm = 8.0;
const double kRadius   = 12.0;
const double kRadiusLg = 16.0;
const double kRadiusXl = 20.0;

// ── Top-level shadow alias (used bare in widgets) ─
List<BoxShadow> get cardShadow => AppColors.cardShadow;

// ═══════════════════════════════════════════════
//  THEME DATA
// ═══════════════════════════════════════════════
class AppTheme {
  static ThemeData get lightTheme {
    final base = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.bluePrimary,
        error: AppColors.danger,
        background: AppColors.background,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: base.copyWith(
        displayLarge:  GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700,  color: AppColors.textPrimary, letterSpacing: -0.5),
        headlineMedium:GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700,  color: AppColors.textPrimary, letterSpacing: -0.3),
        titleLarge:    GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w600,  color: AppColors.textPrimary),
        titleMedium:   GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,  color: AppColors.textPrimary),
        bodyLarge:     GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500,  color: AppColors.textPrimary),
        bodyMedium:    GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w400,  color: AppColors.textSecondary),
        labelLarge:    GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,  color: AppColors.textPrimary),
        labelSmall:    GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,  color: AppColors.textMuted, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: Colors.white, letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.teal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
          textStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? Colors.white : Colors.white),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected) ? AppColors.teal : AppColors.border),
        trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusSm),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        hintStyle:  GoogleFonts.outfit(color: AppColors.textMuted,      fontWeight: FontWeight.w400),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
