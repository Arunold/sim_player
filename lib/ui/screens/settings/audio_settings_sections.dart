import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../providers/providers.dart';
import 'settings_widgets.dart';

/// Audio settings section: ReplayGain, audio ducking
class AudioSettingsSection extends ConsumerWidget {
  const AudioSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioDucking = ref.watch(audioDuckingProvider);
    final replayGain = ref.watch(replayGainProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Audio'),
        SettingsTile(
          icon: Icons.equalizer_rounded,
          title: 'ReplayGain',
          subtitle: _replayGainLabel(replayGain),
          onTap: () => _showReplayGainDialog(context, ref),
        ),
        SettingsTile(
          icon: Icons.volume_down_rounded,
          title: 'Audio Ducking',
          subtitle: 'Lower volume for notifications',
          trailing: Switch(
            value: audioDucking,
            onChanged: (value) =>
                ref.read(audioDuckingProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
      ],
    );
  }

  String _replayGainLabel(String mode) {
    switch (mode) {
      case 'track':
        return 'Track mode';
      case 'album':
        return 'Album mode';
      default:
        return 'Disabled';
    }
  }

  String _replayGainDescription(String mode) {
    switch (mode) {
      case 'track':
        return 'Normalize each track individually';
      case 'album':
        return 'Preserve album dynamics';
      default:
        return 'No volume normalization';
    }
  }

  void _showReplayGainDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(replayGainProvider);
    final modes = ['off', 'track', 'album'];
    final labels = {
      'off': 'Disabled',
      'track': 'Track mode',
      'album': 'Album mode'
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ReplayGain'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((mode) {
            return RadioListTile<String>(
              title: Text(labels[mode]!),
              subtitle: Text(_replayGainDescription(mode)),
              value: mode,
              // ignore: deprecated_member_use
              groupValue: currentMode,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  ref.read(replayGainProvider.notifier).set(value);
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

/// Headset & Bluetooth settings section
class HeadsetSettingsSection extends ConsumerWidget {
  const HeadsetSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoPlayOnConnect = ref.watch(autoPlayOnConnectProvider);
    final pauseOnDisconnect = ref.watch(pauseOnDisconnectProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Headset & Bluetooth'),
        SettingsTile(
          icon: Icons.headphones_rounded,
          title: 'Auto-play on Connect',
          subtitle: 'Resume playback when headset connects',
          trailing: Switch(
            value: autoPlayOnConnect,
            onChanged: (value) =>
                ref.read(autoPlayOnConnectProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.headset_off_rounded,
          title: 'Pause on Disconnect',
          subtitle: 'Pause when headset disconnects',
          trailing: Switch(
            value: pauseOnDisconnect,
            onChanged: (value) =>
                ref.read(pauseOnDisconnectProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
      ],
    );
  }
}

/// Queue settings section
class QueueSettingsSection extends ConsumerWidget {
  const QueueSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keepShuffleQueue = ref.watch(keepShuffleQueueProvider);
    final resumeOnRestart = ref.watch(resumeOnRestartProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Queue'),
        SettingsTile(
          icon: Icons.shuffle_rounded,
          title: 'Keep Shuffle Queue',
          subtitle: 'Preserve shuffle order on restart',
          trailing: Switch(
            value: keepShuffleQueue,
            onChanged: (value) =>
                ref.read(keepShuffleQueueProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.restore_rounded,
          title: 'Resume on Restart',
          subtitle: 'Auto-play last track on app start',
          trailing: Switch(
            value: resumeOnRestart,
            onChanged: (value) =>
                ref.read(resumeOnRestartProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
      ],
    );
  }
}

/// Sleep timer settings section
class SleepTimerSettingsSection extends ConsumerWidget {
  const SleepTimerSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepTimerFinishTrack = ref.watch(sleepTimerFinishTrackProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Sleep Timer'),
        SettingsTile(
          icon: Icons.music_note_rounded,
          title: 'Finish Current Track',
          subtitle: 'Complete song before sleep timer stops',
          trailing: Switch(
            value: sleepTimerFinishTrack,
            onChanged: (value) =>
                ref.read(sleepTimerFinishTrackProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
      ],
    );
  }
}

/// Notification settings section
class NotificationSettingsSection extends ConsumerWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAlbumArtOnLockscreen =
        ref.watch(showAlbumArtOnLockscreenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Notifications'),
        SettingsTile(
          icon: Icons.album_rounded,
          title: 'Album Art on Lockscreen',
          subtitle: 'Show album art in media notification',
          trailing: Switch(
            value: showAlbumArtOnLockscreen,
            onChanged: (value) =>
                ref.read(showAlbumArtOnLockscreenProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
      ],
    );
  }
}
