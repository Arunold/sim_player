import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Glassmorphism style configuration and utilities
class GlassStyle {
  GlassStyle._();

  // Default glass colors
  static const Color defaultTint = Color(0xFF1A1A2E);
  static const Color defaultBorder = Color(0xFF2E2E2E);

  /// Creates a glass-style BoxDecoration
  ///
  /// [tintColor] - Background tint color (defaults to dark surface)
  /// [opacity] - Background opacity (0.0 - 1.0, defaults to 0.7)
  /// [borderRadius] - Corner radius (defaults to radiusMd)
  /// [borderColor] - Border color (defaults to subtle white)
  /// [borderWidth] - Border width (defaults to 0.5)
  /// [borderOpacity] - Border opacity (0.0 - 1.0, defaults to 0.1)
  /// [shadows] - Custom box shadows (defaults to soft shadow)
  static BoxDecoration decoration({
    Color? tintColor,
    double opacity = 0.7,
    double borderRadius = ThemeConstants.radiusMd,
    Color? borderColor,
    double borderWidth = 0.5,
    double borderOpacity = 0.1,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: (tintColor ?? defaultTint).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (borderColor ?? Colors.white).withValues(alpha: borderOpacity),
        width: borderWidth,
      ),
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  /// Creates a glass decoration with gradient
  ///
  /// [colors] - List of colors for the gradient
  /// [opacity] - Overall opacity of the gradient
  /// [borderRadius] - Corner radius
  /// [borderColor] - Border color
  /// [borderWidth] - Border width
  /// [borderOpacity] - Border opacity
  /// [begin] - Gradient begin alignment
  /// [end] - Gradient end alignment
  static BoxDecoration gradientDecoration({
    List<Color>? colors,
    double opacity = 0.7,
    double borderRadius = ThemeConstants.radiusMd,
    Color? borderColor,
    double borderWidth = 0.5,
    double borderOpacity = 0.1,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          defaultTint.withValues(alpha: opacity),
          defaultTint.withValues(alpha: opacity * 0.8),
        ],
        begin: begin,
        end: end,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (borderColor ?? Colors.white).withValues(alpha: borderOpacity),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Preset: Mini player style
  static BoxDecoration miniPlayer() => decoration(
    tintColor: ThemeConstants.darkSurface,
    opacity: 0.015,
    borderRadius: 0,
    borderOpacity: 0.15,
    shadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.01),
        blurRadius: 15,
        offset: const Offset(0, -5),
      ),
    ],
  );

  /// Preset: Side navigation style
  static BoxDecoration sideNav() => decoration(
    tintColor: ThemeConstants.darkSurface,
    opacity: 0.50,
    borderRadius: 0,
    borderOpacity: 0.15,
    // shadows: [
    //   BoxShadow(
    //     color: Colors.black.withValues(alpha: 0.01),
    //     blurRadius: 15,
    //     offset: const Offset(0, -5),
    //   ),
    // ],
  );

  /// Preset: Now playing screen style
  static BoxDecoration nowPlaying() => decoration(
    tintColor: ThemeConstants.playerGradientStart,
    opacity: 0.50,
    borderRadius: ThemeConstants.radiusLg,
    borderOpacity: 0.40,
  );

  /// Preset: Card style
  static BoxDecoration card({double borderRadius = ThemeConstants.radiusMd}) =>
      decoration(
        tintColor: ThemeConstants.darkCard,
        opacity: 0.6,
        borderRadius: borderRadius,
        borderOpacity: 0.08,
      );

  /// Preset: Bottom sheet style
  static BoxDecoration bottomSheet() => decoration(
    tintColor: ThemeConstants.darkSurface,
    opacity: 0.95,
    borderRadius: ThemeConstants.radiusXl,
    borderOpacity: 0.1,
  );
}

/// A widget that applies glassmorphism effect to its child
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration? decoration;
  final double? blurAmount;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const GlassContainer({
    super.key,
    required this.child,
    this.decoration,
    this.blurAmount,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Mini player preset
  factory GlassContainer.miniPlayer({
    required Widget child,
    double blurAmount = 10,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      decoration: GlassStyle.miniPlayer(),
      blurAmount: blurAmount,
      padding: padding,
      child: child,
    );
  }

  /// Side nav preset
  factory GlassContainer.sideNav({
    required Widget child,
    double blurAmount = 10,
    double? width,
    BoxDecoration? decoration,
  }) {
    return GlassContainer(
      decoration: decoration ?? GlassStyle.sideNav(),
      blurAmount: blurAmount,
      width: width,
      child: child,
    );
  }

  /// Now playing preset
  factory GlassContainer.nowPlaying({
    required Widget child,
    double blurAmount = 20,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassContainer(
      decoration: GlassStyle.nowPlaying(),
      blurAmount: blurAmount,
      padding: padding,
      margin: margin,
      child: child,
    );
  }

  /// Card preset
  factory GlassContainer.card({
    required Widget child,
    double blurAmount = 8,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = ThemeConstants.radiusMd,
  }) {
    return GlassContainer(
      decoration: GlassStyle.card(borderRadius: borderRadius),
      blurAmount: blurAmount,
      padding: padding,
      margin: margin,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = decoration ?? GlassStyle.decoration();
    final effectiveBlur = blurAmount ?? 10;
    final borderRadius =
        effectiveDecoration.borderRadius as BorderRadius? ?? BorderRadius.zero;

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: Container(
            decoration: effectiveDecoration,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
