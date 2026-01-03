import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sim_player/core/constants/app_constants.dart';
import 'package:sim_player/core/theme/glass_style.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/providers.dart';
import 'mini_player.dart';

/// Side navigation drawer widget with route-based navigation
class SideNav extends ConsumerWidget {
  final String currentRoute;

  /// Width as percentage of screen width (0.0 to 1.0). Default is 0.75 (75%)
  final double widthPercent;

  const SideNav({
    super.key,
    required this.currentRoute,
    this.widthPercent = 0.85,
  });

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer first

    if (route == currentRoute) {
      return; // Already on this route
    }

    if (route == AppRoutes.home) {
      // Go back to home - pop all routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } else if (currentRoute == AppRoutes.home) {
      // From home, push new route
      Navigator.pushNamed(context, route);
    } else {
      // Replace current route
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth * widthPercent.clamp(0.2, 0.95);

    return GlassContainer.sideNav(
      child: Drawer(
        width: drawerWidth,
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              // Drawer header
              _buildHeader(context, ref),
              Divider(height: 1, color: context.colors.divider),
              // Navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Main navigation (first 3 items)
                    ...navItems
                        .take(3)
                        .map(
                          (item) => _NavItemTile(
                            item: item,
                            isSelected: currentRoute == item.route,
                            onTap: () => _navigateTo(context, item.route),
                          ),
                        ),
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Divider(height: 1, color: context.colors.divider),
                    ),
                    // Secondary navigation (remaining items)
                    ...navItems
                        .skip(3)
                        .map(
                          (item) => _NavItemTile(
                            item: item,
                            isSelected: currentRoute == item.route,
                            onTap: () => _navigateTo(context, item.route),
                          ),
                        ),
                  ],
                ),
              ),
              // Mini player in drawer - reuse the main MiniPlayer in compact mode
              MiniPlayer(
                compact: true,
                useGlassContainer: false,
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushNamed(context, AppRoutes.nowPlaying);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary,
                  context.colors.secondary,
                  context.colors.accent,
                  context.colors.error,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: context.colors.textPrimary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  AppConstants.appTagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle button
          IconButton(
            onPressed: () {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: context.colors.textSecondary,
              ),
            ),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          ),
        ],
      ),
    );
  }
}

/// Individual navigation item tile
class _NavItemTile extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 10,
          ),
          leading: Icon(
            isSelected ? item.selectedIcon : item.icon,
            color: isSelected
                ? context.colors.primary
                : context.colors.textPrimary,
          ),
          title: Text(
            item.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedTileColor: context.colors.primary.withValues(alpha: 0.20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
