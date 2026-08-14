import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings/appearance_settings_section.dart';
import 'settings/audio_settings_sections.dart';
import 'settings/library_settings_section.dart';
import 'settings/playback_settings_section.dart';

/// Settings screen for app configuration
///
/// Composed of focused section widgets for maintainability.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Library: folders, scan, clear
          LibrarySettingsSection(),
          Divider(height: 32),

          // Playback: speed, gapless, crossfade, silence, fade, position
          PlaybackSettingsSection(),
          Divider(height: 32),

          // Audio: ReplayGain, ducking
          AudioSettingsSection(),
          Divider(height: 32),

          // Headset & Bluetooth
          HeadsetSettingsSection(),
          Divider(height: 32),

          // Queue: shuffle, resume
          QueueSettingsSection(),
          Divider(height: 32),

          // Sleep Timer
          SleepTimerSettingsSection(),
          Divider(height: 32),

          // Notifications
          NotificationSettingsSection(),
          Divider(height: 32),

          // Appearance: theme, grid, track numbers, exit
          AppearanceSettingsSection(),
          Divider(height: 32),

          // About
          AboutSettingsSection(),
        ],
      ),
    );
  }
}
