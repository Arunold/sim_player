import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Glassmorphism style configuration and utilities
class GlassStyle {
  GlassStyle._();

  /// Get default tint color from theme
  static Color defaultTint(BuildContext context) =>
      context.colors.backgroundTertiary;

  /// Get default border color from theme
  static Color defaultBorder(BuildContext context) => context.colors.divider;

  /// Creates a glass-style BoxDecoration
  ///
  /// [context] - BuildContext to access theme colors
  /// [tintColor] - Background tint color (defaults to theme background)
  /// [opacity] - Background opacity (0.0 - 1.0, defaults to 0.7)
  /// [borderRadius] - Corner radius (defaults to radiusMd)
  /// [borderColor] - Border color (defaults to theme divider)
  /// [borderWidth] - Border width (defaults to 0.5)
  /// [borderOpacity] - Border opacity (0.0 - 1.0, defaults to 0.1)
  /// [shadows] - Custom box shadows (defaults to soft shadow)
  static BoxDecoration decoration(
    BuildContext context, {
    Color? tintColor,
    double opacity = 0.7,
    double borderRadius = ThemeConstants.radiusMd,
    Color? borderColor,
    double borderWidth = 0.5,
    double borderOpacity = 0.1,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: (tintColor ?? defaultTint(context)).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (borderColor ?? defaultBorder(context)).withValues(
          alpha: borderOpacity,
        ),
        width: borderWidth,
      ),
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: context.colors.backgroundPrimary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  /// Creates a glass decoration with gradient
  ///
  /// [context] - BuildContext to access theme colors
  /// [colors] - List of colors for the gradient
  /// [opacity] - Overall opacity of the gradient
  /// [borderRadius] - Corner radius
  /// [borderColor] - Border color
  /// [borderWidth] - Border width
  /// [borderOpacity] - Border opacity
  /// [begin] - Gradient begin alignment
  /// [end] - Gradient end alignment
  static BoxDecoration gradientDecoration(
    BuildContext context, {
    List<Color>? colors,
    double opacity = 0.7,
    double borderRadius = ThemeConstants.radiusMd,
    Color? borderColor,
    double borderWidth = 0.5,
    double borderOpacity = 0.1,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    final tint = defaultTint(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors:
            colors ??
            [
              tint.withValues(alpha: opacity),
              tint.withValues(alpha: opacity * 0.8),
            ],
        begin: begin,
        end: end,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (borderColor ?? defaultBorder(context)).withValues(
          alpha: borderOpacity,
        ),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: context.colors.backgroundPrimary.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Preset: Mini player style
  static BoxDecoration miniPlayer(BuildContext context) => decoration(
    context,
    tintColor: context.colors.surface,
    opacity: 0.015,
    borderRadius: 0,
    borderOpacity: 0.15,
    shadows: [
      BoxShadow(
        color: context.colors.backgroundPrimary.withValues(alpha: 0.01),
        blurRadius: 15,
        offset: const Offset(0, -5),
      ),
    ],
  );

  /// Preset: Side navigation style
  static BoxDecoration sideNav(BuildContext context) => decoration(
    context,
    tintColor: context.colors.surface,
    opacity: 0.50,
    borderRadius: 0,
    borderOpacity: 0.15,
  );

  /// Preset: Now playing screen style
  static BoxDecoration nowPlaying(BuildContext context) => decoration(
    context,
    tintColor: context.colors.backgroundPrimary,
    opacity: 0.50,
    borderRadius: ThemeConstants.radiusLg,
    borderOpacity: 0.40,
  );

  /// Preset: Card style
  static BoxDecoration card(
    BuildContext context, {
    double borderRadius = ThemeConstants.radiusMd,
  }) => decoration(
    context,
    tintColor: context.colors.card,
    opacity: 0.6,
    borderRadius: borderRadius,
    borderOpacity: 0.08,
  );

  /// Preset: Bottom sheet style
  static BoxDecoration bottomSheet(BuildContext context) => decoration(
    context,
    tintColor: context.colors.surface,
    opacity: 0.95,
    borderRadius: ThemeConstants.radiusXl,
    borderOpacity: 0.1,
  );
}

/// A widget that applies glassmorphism effect to its child
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BoxDecoration Function(BuildContext)? decorationBuilder;
  final double? blurAmount;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const GlassContainer({
    super.key,
    required this.child,
    this.decorationBuilder,
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
      decorationBuilder: (context) => GlassStyle.miniPlayer(context),
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
    BoxDecoration Function(BuildContext)? decorationBuilder,
  }) {
    return GlassContainer(
      decorationBuilder:
          decorationBuilder ?? ((context) => GlassStyle.sideNav(context)),
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
      decorationBuilder: (context) => GlassStyle.nowPlaying(context),
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
      decorationBuilder: (context) =>
          GlassStyle.card(context, borderRadius: borderRadius),
      blurAmount: blurAmount,
      padding: padding,
      margin: margin,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration =
        decorationBuilder?.call(context) ?? GlassStyle.decoration(context);
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
