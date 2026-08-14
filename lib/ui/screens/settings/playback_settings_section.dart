import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../providers/providers.dart';
import 'settings_widgets.dart';

/// Playback settings section: speed, gapless, crossfade, skip silence, fade, remember position
class PlaybackSettingsSection extends ConsumerWidget {
  const PlaybackSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gaplessPlayback = ref.watch(gaplessPlaybackProvider);
    final playbackSpeed = ref.watch(playbackSpeedProvider);
    final skipSilence = ref.watch(skipSilenceProvider);
    final rememberLastPosition = ref.watch(rememberLastPositionProvider);
    final crossfadeDuration = ref.watch(crossfadeDurationProvider);
    final fadeOnPausePlay = ref.watch(fadeOnPausePlayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Playback'),
        SettingsTile(
          icon: Icons.speed_rounded,
          title: 'Playback Speed',
          subtitle: '${playbackSpeed.toStringAsFixed(1)}x',
          onTap: () => _showPlaybackSpeedDialog(context, ref),
        ),
        SettingsTile(
          icon: Icons.skip_next_rounded,
          title: 'Gapless Playback',
          subtitle: 'Seamless transitions between tracks',
          trailing: Switch(
            value: gaplessPlayback,
            onChanged: (value) =>
                ref.read(gaplessPlaybackProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.blur_linear_rounded,
          title: 'Crossfade',
          subtitle: crossfadeDuration == 0
              ? 'Disabled'
              : '${crossfadeDuration}s between tracks',
          onTap: () => _showCrossfadeDialog(context, ref),
        ),
        SettingsTile(
          icon: Icons.volume_off_rounded,
          title: 'Skip Silence',
          subtitle: 'Skip silent parts in tracks',
          trailing: Switch(
            value: skipSilence,
            onChanged: (value) {
              ref.read(skipSilenceProvider.notifier).set(value);
              ref.read(audioControllerProvider).setSkipSilence(value);
            },
            activeThumbColor: context.colors.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.play_circle_outline_rounded,
          title: 'Fade on Play/Pause',
          subtitle: 'Smooth fade when playing or pausing',
          trailing: Switch(
            value: fadeOnPausePlay,
            onChanged: (value) {
              ref.read(fadeOnPausePlayProvider.notifier).set(value);
              ref.read(audioControllerProvider).setFadeOnPausePlay(value);
            },
            activeThumbColor: context.colors.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.history_rounded,
          title: 'Remember Position',
          subtitle: 'Resume playback from last position',
          trailing: Switch(
            value: rememberLastPosition,
            onChanged: (value) =>
                ref.read(rememberLastPositionProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
      ],
    );
  }

  void _showPlaybackSpeedDialog(BuildContext context, WidgetRef ref) {
    final currentSpeed = ref.read(playbackSpeedProvider);
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Playback Speed'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: speeds.map((speed) {
              final isSelected = (speed - currentSpeed).abs() < 0.01;
              return ListTile(
                title: Text(
                  '${speed.toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? context.colors.primary : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: context.colors.primary)
                    : null,
                onTap: () {
                  ref.read(playbackSpeedProvider.notifier).set(speed);
                  ref.read(audioControllerProvider).setSpeed(speed);
                  Navigator.pop(dialogContext);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCrossfadeDialog(BuildContext context, WidgetRef ref) {
    final currentDuration = ref.read(crossfadeDurationProvider);
    final durations = [0, 2, 3, 5, 7, 10, 12, 15];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crossfade Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: durations.map((duration) {
            return RadioListTile<int>(
              title: Text(duration == 0 ? 'Disabled' : '$duration seconds'),
              value: duration,
              // ignore: deprecated_member_use
              groupValue: currentDuration,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  ref.read(crossfadeDurationProvider.notifier).set(value);
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
