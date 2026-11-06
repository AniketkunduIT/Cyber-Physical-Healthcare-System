import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized theme, color and style tokens for the whole app.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF3F6F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primaryStart = Color(0xFF6D5DF6);
  static const Color primaryEnd = Color(0xFF9B4DFF);
  static const Color textPrimary = Color(0xFF14161F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFD7DCE3);

  static const Color emergencyStart = Color(0xFFEF4444);
  static const Color emergencyEnd = Color(0xFFB91C1C);
  static const Color profileStart = Color(0xFF22C55E);
  static const Color profileEnd = Color(0xFF15803D);
  static const Color hospitalStart = Color(0xFF3B82F6);
  static const Color hospitalEnd = Color(0xFF1D4ED8);

  static const Color success = Color(0xFF15803D);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  // Brand purple tones
  static const Color brandPurple = Color(0xFF6B4EE6);
  static const Color brandPurpleDark = Color(0xFF5B30DE);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color lightPurple = Color(0xFFEDE9FE);
  static const Color avatarBg = Color(0xFFE7E1FB);
  static const Color navyButton = Color(0xFF14224D);

  // Upload action button tones
  static const Color photoBg = Color(0xFFD1F2ED);
  static const Color photoText = Color(0xFF0F766E);
  static const Color galleryBg = Color(0xFFD6E3F8);
  static const Color galleryText = Color(0xFF1D4ED8);

  // Voice note tones
  static const Color voiceBg = Color(0xFF4C2E96);
  static const Color voiceDuration = Color(0xFFD4C5F9);

  static const List<Color> primaryGradient = [primaryStart, primaryEnd];
  static const List<Color> emergencyGradient = [emergencyStart, emergencyEnd];
  static const List<Color> profileGradient = [profileStart, profileEnd];
  static const List<Color> hospitalGradient = [hospitalStart, hospitalEnd];
  static const List<Color> brandPurpleGradient = [brandPurple, brandPurpleDark];
}

class AppRadii {
  AppRadii._();
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryStart,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.primaryStart, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Color(0xFF9AA1AC)),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryStart,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.4,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
