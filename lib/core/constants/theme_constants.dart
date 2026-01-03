import 'package:flutter/material.dart';

/// Theme-related constants
class ThemeConstants {
  ThemeConstants._();

  /// Dark Theme Colors (Premium, sophisticated dark mode) ///
  // Surface colors - subtle warm undertone for depth
  static const Color darkSurface = Color(0xFF18181B); // Zinc 900
  static const Color darkCard = Color(0xFF27272A); // Zinc 800
  static const Color darkDivider = Color(0xFF3F3F46); // Zinc 700

  // Brand Colors - refined, not too saturated
  static const Color darkPrimary = Color(0xFF818CF8); // Indigo 400 - softer
  static const Color darkSecondary = Color(0xFFA78BFA); // Violet 400
  static const Color darkAccent = Color(0xFF22D3EE); // Cyan 400
  static const Color darkError = Color(0xFFEF4444); // Red 500

  // Background Colors - layered depth
  static const Color darkBackgroundPrimary = Color(0xFF09090B); // Zinc 950
  static const Color darkBackgroundSecondary = Color(0xFF18181B); // Zinc 900
  static const Color darkBackgroundTertiary = Color(0xFF27272A); // Zinc 800

  // Text Colors - proper contrast hierarchy
  static const Color darkTextPrimary = Color(0xFFFAFAFA); // Zinc 50
  static const Color darkTextSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color darkTextTertiary = Color(0xFF71717A); // Zinc 500

  /// Light Theme Colors (Clean, elegant light mode) ///
  // Surface colors
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure white
  static const Color lightCard = Color(0xFFF4F4F5); // Zinc 100
  static const Color lightDivider = Color(0xFFE4E4E7); // Zinc 200

  // Brand Colors - slightly deeper for light backgrounds
  static const Color lightPrimary = Color(0xFF6366F1); // Indigo 500
  static const Color lightSecondary = Color(0xFF8B5CF6); // Violet 500
  static const Color lightAccent = Color(0xFF06B6D4); // Cyan 500
  static const Color lightError = Color(0xFFEF4444); // Red 500

  // Background Colors - subtle hierarchy
  static const Color lightBackgroundPrimary = Color(0xFFFAFAFA); // Zinc 50
  static const Color lightBackgroundSecondary = Color(0xFFF4F4F5); // Zinc 100
  static const Color lightBackgroundTertiary = Color(0xFFE4E4E7); // Zinc 200

  // Text Colors - softer than pure black
  static const Color lightTextPrimary = Color(0xFF18181B); // Zinc 900
  static const Color lightTextSecondary = Color(0xFF52525B); // Zinc 600
  static const Color lightTextTertiary = Color(0xFF71717A); // Zinc 500

  // Status Colors - balanced saturation
  static const Color successColor = Color(0xFF22C55E); // Green 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color infoColor = Color(0xFF3B82F6); // Blue 500

  // Player Colors - atmospheric gradient
  static const Color playerGradientStart = Color(0xFF0F0F12);
  static const Color playerGradientEnd = Color(0xFF1A1A2E);

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound = 100.0;
  // Aliases for abbreviated names
  static const double radiusSm = radiusSmall;
  static const double radiusMd = radiusMedium;
  static const double radiusLg = radiusLarge;
  static const double radiusXl = radiusXLarge;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  // Aliases for abbreviated names
  static const double spacingXs = spacingXSmall;
  static const double spacingSm = spacingSmall;
  static const double spacingMd = spacingMedium;
  static const double spacingLg = spacingLarge;
  static const double spacingXl = spacingXLarge;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;

  // Font Sizes
  static const double fontCaption = 12.0;
  static const double fontBody = 14.0;
  static const double fontSubtitle = 16.0;
  static const double fontTitle = 18.0;
  static const double fontHeadline = 24.0;
  static const double fontDisplay = 32.0;

  // Elevation
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
}

/// Custom app colors that adapt to theme
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color surface;
  final Color card;
  final Color divider;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color backgroundTertiary;

  const AppColors({
    required this.surface,
    required this.card,
    required this.divider,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
  });

  /// Dark theme colors
  static const dark = AppColors(
    surface: ThemeConstants.darkSurface,
    card: ThemeConstants.darkCard,
    divider: ThemeConstants.darkDivider,
    primary: ThemeConstants.darkPrimary,
    secondary: ThemeConstants.darkSecondary,
    accent: ThemeConstants.darkAccent,
    error: ThemeConstants.darkError,
    textPrimary: ThemeConstants.darkTextPrimary,
    textSecondary: ThemeConstants.darkTextSecondary,
    textTertiary: ThemeConstants.darkTextTertiary,
    backgroundPrimary: ThemeConstants.darkBackgroundPrimary,
    backgroundSecondary: ThemeConstants.darkBackgroundSecondary,
    backgroundTertiary: ThemeConstants.darkBackgroundTertiary,
  );

  /// Light theme colors
  static const light = AppColors(
    surface: ThemeConstants.lightSurface,
    card: ThemeConstants.lightCard,
    divider: ThemeConstants.lightDivider,
    primary: ThemeConstants.lightPrimary,
    secondary: ThemeConstants.lightSecondary,
    accent: ThemeConstants.lightAccent,
    error: ThemeConstants.lightError,
    textPrimary: ThemeConstants.lightTextPrimary,
    textSecondary: ThemeConstants.lightTextSecondary,
    textTertiary: ThemeConstants.lightTextTertiary,
    backgroundPrimary: ThemeConstants.lightBackgroundPrimary,
    backgroundSecondary: ThemeConstants.lightBackgroundSecondary,
    backgroundTertiary: ThemeConstants.lightBackgroundTertiary,
  );

  @override
  AppColors copyWith({
    Color? surface,
    Color? card,
    Color? divider,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? error,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    Color? backgroundTertiary,
  }) {
    return AppColors(
      surface: surface ?? this.surface,
      card: card ?? this.card,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundTertiary: backgroundTertiary ?? this.backgroundTertiary,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      error: Color.lerp(error, other.error, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      backgroundPrimary: Color.lerp(
        backgroundPrimary,
        other.backgroundPrimary,
        t,
      )!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      backgroundTertiary: Color.lerp(
        backgroundTertiary,
        other.backgroundTertiary,
        t,
      )!,
    );
  }
}

/// Extension on BuildContext for easy access to theme colors
extension ThemeContextExtension on BuildContext {
  /// Get adaptive app colors - automatically uses correct theme
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;

  /// Quick access to common theme properties
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
