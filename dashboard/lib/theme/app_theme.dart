import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Urgency Colors ─────────────────────────────────────────────
  static const Color urgency5 = Color(0xFFDC2626); // Critical red
  static const Color urgency4 = Color(0xFFEA580C); // High orange
  static const Color urgency3 = Color(0xFF2563EB); // Medium blue
  static const Color urgency2 = Color(0xFF16A34A); // Low green
  static const Color urgency1 = Color(0xFF9CA3AF); // Monitoring gray

  // ── Background & Surface ───────────────────────────────────────
  static const Color background = Color(0xFFF3F4F6); // Light gray page bg
  static const Color surface = Color(0xFFFFFFFF); // White card surface
  static const Color surfaceElevated = Color(0xFFF9FAFB);
  static const Color border = Color(0xFFE5E7EB);

  // ── Text Colors ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ── Accent Colors ──────────────────────────────────────────────
  static const Color accentOrange = Color(0xFFFF7D26); // Blinkit orange
  static const Color accentGreen = Color(0xFF1A9B6C);
  static const Color accentRed = Color(0xFFE23744); // Zomato red — primary CTA
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color primaryRed = Color(0xFFE23744);

  // ── Status Colors ──────────────────────────────────────────────
  static const Color liveGreen = Color(0xFF10B981);
  static const Color offlineRed = Color(0xFFDC2626);
  static const Color warningAmber = Color(0xFFF59E0B);

  // ── Need Type Colors ───────────────────────────────────────────
  static const Color needMedical = Color(0xFFDC2626);
  static const Color needFood = Color(0xFFFF7D26);
  static const Color needSanitation = Color(0xFF2563EB);
  static const Color needEducation = Color(0xFF7C3AED);
  static const Color needShelter = Color(0xFF0891B2);
  static const Color needDisaster = Color(0xFF9F1239);
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

  // ── Card Shadows ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadowElevated => [
        BoxShadow(
          color: const Color(0xFFE23744).withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

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

  // ── Helper: get emoji icon by need type ───────────────────────
  static String needTypeIcon(String needType) {
    switch (needType) {
      case 'medical':
        return '🏥';
      case 'food_ration':
        return '🍱';
      case 'sanitation':
        return '🚿';
      case 'education':
        return '📚';
      case 'shelter':
        return '🏠';
      case 'disaster':
        return '🆘';
      default:
        return '📋';
    }
  }

  // ── Main Light ThemeData ───────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        background: background,
        surface: surface,
        primary: accentRed,
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
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(radiusMD)),
          side: const BorderSide(color: border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radiusSM)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMD,
            vertical: spacingSM,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: const BorderSide(color: accentRed, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMD,
          vertical: spacingSM,
        ),
      ),
      dividerColor: border,
      dialogBackgroundColor: surface,
      useMaterial3: false,
    );
  }

  // ── darkTheme alias — keeps main.dart untouched ───────────────
  static ThemeData get darkTheme => lightTheme;
}
