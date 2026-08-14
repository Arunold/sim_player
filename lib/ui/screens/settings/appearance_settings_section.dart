import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../providers/providers.dart';
import 'settings_widgets.dart';

/// Appearance settings section: theme, grid columns, track numbers, confirm exit
class AppearanceSettingsSection extends ConsumerWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gridColumnCount = ref.watch(gridColumnCountProvider);
    final showTrackNumbers = ref.watch(showTrackNumbersProvider);
    final confirmExit = ref.watch(confirmExitProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Appearance'),
        _buildThemeSelector(context, ref),
        SettingsTile(
          icon: Icons.grid_view_rounded,
          title: 'Grid Columns',
          subtitle: '$gridColumnCount columns',
          onTap: () => _showGridColumnsDialog(context, ref),
        ),
        SettingsTile(
          icon: Icons.format_list_numbered_rounded,
          title: 'Show Track Numbers',
          subtitle: 'Display track numbers in lists',
          trailing: Switch(
            value: showTrackNumbers,
            onChanged: (value) =>
                ref.read(showTrackNumbersProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.exit_to_app_rounded,
          title: 'Confirm Exit',
          subtitle: 'Show confirmation when leaving app',
          trailing: Switch(
            value: confirmExit,
            onChanged: (value) =>
                ref.read(confirmExitProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
      ],
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

  void _showGridColumnsDialog(BuildContext context, WidgetRef ref) {
    final currentCount = ref.read(gridColumnCountProvider);
    final counts = [2, 3, 4];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grid Columns'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: counts.map((count) {
            return RadioListTile<int>(
              title: Text('$count columns'),
              value: count,
              // ignore: deprecated_member_use
              groupValue: currentCount,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  ref.read(gridColumnCountProvider.notifier).set(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// About section
class AboutSettingsSection extends StatelessWidget {
  const AboutSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'About'),
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'About ${AppConstants.appName}',
          subtitle: 'Version ${AppConstants.appVersion}',
          onTap: () => _showAboutDialog(context),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
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
      children: [
        Text(AppConstants.appDescription),
        const SizedBox(height: 8),
        Text(
          AppConstants.appCopyright,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
        ),
      ],
    );
  }
}
