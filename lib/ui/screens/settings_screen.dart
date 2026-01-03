import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/providers.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Library'),
          _buildSettingsTile(
            context,
            icon: Icons.folder_rounded,
            title: 'Music Folders',
            subtitle: 'Manage folders to scan for music',
            onTap: () => _showMusicFoldersDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.refresh_rounded,
            title: 'Rescan Library',
            subtitle: 'Scan for new music files',
            onTap: () => _rescanLibrary(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_outline_rounded,
            title: 'Clear Library',
            subtitle: 'Remove all songs from library',
            onTap: () => _showClearLibraryDialog(context, ref),
            isDestructive: true,
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Playback'),
          _buildSettingsTile(
            context,
            icon: Icons.speed_rounded,
            title: 'Playback Speed',
            subtitle: 'Adjust audio playback speed',
            onTap: () => _showPlaybackSpeedDialog(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.skip_next_rounded,
            title: 'Gapless Playback',
            subtitle: 'Seamless transitions between tracks',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeSelector(context, ref),
          const Divider(height: 32),
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About SimPlayer',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? context.colors.error : null;

    return ListTile(
      leading: Icon(icon, color: color ?? context.colors.textSecondary),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing:
          trailing ??
          (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
      onTap: onTap,
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded, color: context.colors.textSecondary),
              const SizedBox(width: 16),
              Text('Theme', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
            ),
            child: Row(
              children: [
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.light_mode_rounded,
                  label: 'Light',
                  mode: ThemeMode.light,
                  isSelected: themeMode == ThemeMode.light,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark',
                  mode: ThemeMode.dark,
                  isSelected: themeMode == ThemeMode.dark,
                ),
                _buildThemeOption(
                  context,
                  ref,
                  icon: Icons.settings_suggest_rounded,
                  label: 'System',
                  mode: ThemeMode.system,
                  isSelected: themeMode == ThemeMode.system,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? context.colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? context.colors.textPrimary
                    : context.colors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMusicFoldersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Music Folders'),
        content: const Text('Music folder management coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _rescanLibrary(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    // Navigate to home and trigger scan
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Go to Home screen to scan library'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearLibraryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Library'),
        content: const Text(
          'Are you sure you want to clear your entire music library? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final audioController = ref.read(audioControllerProvider);
              await audioController.clearQueue();
              await ref.read(songRepositoryProvider).clearAll();
              ref.read(songsProvider.notifier).refresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Library cleared')),
                );
              }
            },
            child: Text('Clear', style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
  }

  void _showPlaybackSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Speed'),
        content: const Text('Playback speed adjustment coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SimPlayer',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.music_note_rounded,
          color: context.colors.textPrimary,
          size: 32,
        ),
      ),
      children: [const Text('A beautiful music player built with Flutter.')],
    );
  }
}
