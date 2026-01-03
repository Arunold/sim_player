import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sim_player/core/theme/glass_style.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/providers.dart';

/// Side navigation drawer widget with route-based navigation
class SideNav extends ConsumerWidget {
  final String currentRoute;

  const SideNav({super.key, required this.currentRoute});

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
    final currentSongAsync = ref.watch(currentSongProvider);
    return GlassContainer.sideNav(
      child: Drawer(
        backgroundColor: context.colors.surface.withAlpha(1),
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
              // Mini player in drawer
              currentSongAsync.when(
                data: (song) {
                  if (song == null) return const SizedBox.shrink();
                  return _SideNavMiniPlayer(song: song);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
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
                colors: [context.colors.primary, context.colors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SimPlayer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  'Your music, your way',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            isSelected ? item.selectedIcon : item.icon,
            color: isSelected
                ? context.colors.primary
                : context.colors.textSecondary,
          ),
          title: Text(
            item.label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedTileColor: context.colors.primary.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

/// Mini player shown at bottom of side nav
class _SideNavMiniPlayer extends ConsumerWidget {
  final dynamic song;

  const _SideNavMiniPlayer({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, AppRoutes.nowPlaying);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeConstants.darkCard,
          border: Border(
            top: BorderSide(color: ThemeConstants.darkDivider, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Album art
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
                color: ThemeConstants.darkSurface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
                child: song.artworkPath != null
                    ? Image.file(
                        File(song.artworkPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),
            ),
            const SizedBox(width: 12),
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${song.album}${song.year != null ? ' • ${song.year}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play/Pause button
            Consumer(
              builder: (context, ref, _) {
                final playerState = ref.watch(playerStateProvider);
                return playerState.when(
                  data: (state) {
                    final isPlaying = state.isPlaying;
                    return IconButton(
                      onPressed: () {
                        final controller = ref.read(audioControllerProvider);
                        if (isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      },
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: context.colors.primary,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: context.colors.card,
      child: Icon(
        Icons.music_note_rounded,
        color: context.colors.textSecondary.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }
}
