import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Application theme configuration
class AppTheme {
  AppTheme._();

  /// Dark theme (default)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.dark.primary,
      scaffoldBackgroundColor: AppColors.dark.backgroundPrimary,
      extensions: const <ThemeExtension<dynamic>>[AppColors.dark],
      colorScheme: ColorScheme.dark(
        primary: AppColors.dark.primary,
        secondary: AppColors.dark.secondary,
        tertiary: AppColors.dark.accent,
        surface: AppColors.dark.surface,
        error: AppColors.dark.error,
        onPrimary: AppColors.dark.textPrimary,
        onSecondary: AppColors.dark.textPrimary,
        onSurface: AppColors.dark.textPrimary,
        onError: AppColors.dark.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.dark.textPrimary,
          fontSize: ThemeConstants.fontHeadline,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.dark.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.dark.surface,
        selectedItemColor: AppColors.dark.primary,
        unselectedItemColor: AppColors.dark.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.dark.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingMedium,
          vertical: ThemeConstants.spacingSmall,
        ),
        iconColor: AppColors.dark.textSecondary,
        textColor: AppColors.dark.textPrimary,
      ),
      iconTheme: IconThemeData(
        color: AppColors.dark.textSecondary,
        size: ThemeConstants.iconMedium,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: ThemeConstants.fontDisplay,
          fontWeight: FontWeight.bold,
          color: AppColors.dark.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: ThemeConstants.fontHeadline,
          fontWeight: FontWeight.bold,
          color: AppColors.dark.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: ThemeConstants.fontTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.dark.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: ThemeConstants.fontSubtitle,
          fontWeight: FontWeight.w500,
          color: AppColors.dark.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: ThemeConstants.fontBody,
          color: AppColors.dark.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: ThemeConstants.fontBody,
          color: AppColors.dark.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: ThemeConstants.fontCaption,
          color: AppColors.dark.textTertiary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.dark.divider,
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.dark.primary,
        inactiveTrackColor: AppColors.dark.divider,
        thumbColor: AppColors.dark.primary,
        overlayColor: AppColors.dark.primary.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark.primary,
          foregroundColor: AppColors.dark.textPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.spacingLarge,
            vertical: ThemeConstants.spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.dark.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.dark.textPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.dark.primary,
        foregroundColor: AppColors.dark.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.dark.card,
        contentTextStyle: TextStyle(color: AppColors.dark.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.dark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ThemeConstants.radiusLarge),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          borderSide: BorderSide(color: AppColors.dark.primary),
        ),
        hintStyle: TextStyle(color: AppColors.dark.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingMedium,
          vertical: ThemeConstants.spacingMedium,
        ),
      ),
    );
  }

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.light.primary,
      scaffoldBackgroundColor: AppColors.light.backgroundPrimary,
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      colorScheme: ColorScheme.light(
        primary: AppColors.light.primary,
        secondary: AppColors.light.secondary,
        tertiary: AppColors.light.accent,
        surface: AppColors.light.surface,
        error: AppColors.light.error,
        onPrimary: AppColors.light.textPrimary,
        onSecondary: AppColors.light.textPrimary,
        onSurface: AppColors.light.textPrimary,
        onError: AppColors.light.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.light.textPrimary,
          fontSize: ThemeConstants.fontHeadline,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.light.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.light.surface,
        selectedItemColor: AppColors.light.primary,
        unselectedItemColor: AppColors.light.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.light.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingMedium,
          vertical: ThemeConstants.spacingSmall,
        ),
        iconColor: AppColors.light.textSecondary,
        textColor: AppColors.light.textPrimary,
      ),
      iconTheme: IconThemeData(
        color: AppColors.light.textSecondary,
        size: ThemeConstants.iconMedium,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: ThemeConstants.fontDisplay,
          fontWeight: FontWeight.bold,
          color: AppColors.light.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: ThemeConstants.fontHeadline,
          fontWeight: FontWeight.bold,
          color: AppColors.light.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: ThemeConstants.fontTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.light.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: ThemeConstants.fontSubtitle,
          fontWeight: FontWeight.w500,
          color: AppColors.light.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: ThemeConstants.fontBody,
          color: AppColors.light.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: ThemeConstants.fontBody,
          color: AppColors.light.textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: ThemeConstants.fontCaption,
          color: AppColors.light.textTertiary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.light.divider,
        thickness: 1,
        space: 1,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.light.primary,
        inactiveTrackColor: AppColors.light.divider,
        thumbColor: AppColors.light.primary,
        overlayColor: AppColors.light.primary.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light.primary,
          foregroundColor: AppColors.light.textPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.spacingLarge,
            vertical: ThemeConstants.spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.light.primary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.light.textPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.light.primary,
        foregroundColor: AppColors.light.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.light.textPrimary,
        contentTextStyle: TextStyle(color: AppColors.light.backgroundPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.light.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusLarge),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.light.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ThemeConstants.radiusLarge),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          borderSide: BorderSide(color: AppColors.light.primary),
        ),
        hintStyle: TextStyle(color: AppColors.light.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingMedium,
          vertical: ThemeConstants.spacingMedium,
        ),
      ),
    );
  }
}
