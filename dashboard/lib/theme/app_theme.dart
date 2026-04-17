import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Urgency Colors ─────────────────────────────────────────────
  static const Color urgency5 = Color(0xFFE24B4A); // Critical red
  static const Color urgency4 = Color(0xFFEF9F27); // High orange
  static const Color urgency3 = Color(0xFF378ADD); // Medium blue
  static const Color urgency2 = Color(0xFF1D9E75); // Low green
  static const Color urgency1 = Color(0xFF9B9894); // Monitoring gray

  // ── Background & Surface ───────────────────────────────────────
  static const Color background = Color(0xFF111827); // Deep navy/charcoal
  static const Color surface = Color(0xFF1F2937); // Card background
  static const Color surfaceElevated = Color(0xFF374151);
  static const Color border = Color(0xFF374151);

  // ── Text Colors ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // ── Accent Colors ──────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFEF9F27);
  static const Color accentGreen = Color(0xFF1D9E75);
  static const Color accentRed = Color(0xFFE24B4A);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF378ADD);

  // ── Status Colors ──────────────────────────────────────────────
  static const Color liveGreen = Color(0xFF10B981);
  static const Color offlineRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);

  // ── Need Type Colors ───────────────────────────────────────────
  static const Color needMedical = Color(0xFFE24B4A);
  static const Color needFood = Color(0xFFEF9F27);
  static const Color needSanitation = Color(0xFF378ADD);
  static const Color needEducation = Color(0xFF8B5CF6);
  static const Color needShelter = Color(0xFF6366F1);
  static const Color needDisaster = Color(0xFF7F1D1D);
  static const Color needOther = Color(0xFF6B7280);

  // ── Spacing ────────────────────────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;

  // ── Border Radius ──────────────────────────────────────────────
  static const double radiusSM = 6.0;
  static const double radiusMD = 10.0;
  static const double radiusLG = 16.0;

  // ── Animation Durations ────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  // ── Helper: get color by urgency level ────────────────────────
  static Color urgencyColor(int urgency) {
    switch (urgency) {
      case 5:
        return urgency5;
      case 4:
        return urgency4;
      case 3:
        return urgency3;
      case 2:
        return urgency2;
      default:
        return urgency1;
    }
  }

  // ── Helper: get color by need type ────────────────────────────
  static Color needTypeColor(String needType) {
    switch (needType) {
      case 'medical':
        return needMedical;
      case 'food_ration':
        return needFood;
      case 'sanitation':
        return needSanitation;
      case 'education':
        return needEducation;
      case 'shelter':
        return needShelter;
      case 'disaster':
        return needDisaster;
      default:
        return needOther;
    }
  }

  // ── Main ThemeData ─────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        primary: accentOrange,
        secondary: accentGreen,
        error: accentRed,
      ),
      textTheme: GoogleFonts.soraTextTheme(
        const TextTheme(
          displayLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          headlineMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          headlineSmall:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          titleSmall:
              TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textMuted, fontSize: 11),
          labelLarge:
              TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          labelSmall: TextStyle(color: textMuted, fontSize: 10),
        ),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMD)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusSM)),
          ),
          padding:
              EdgeInsets.symmetric(horizontal: spacingMD, vertical: spacingSM),
        ),
      ),
      dividerColor: border,
      useMaterial3: false,
    );
  }
}
