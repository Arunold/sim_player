import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../providers/providers.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScanning = ref.watch(isScanningProvider);
    final gaplessPlayback = ref.watch(gaplessPlaybackProvider);
    final playbackSpeed = ref.watch(playbackSpeedProvider);
    final autoScanOnStartup = ref.watch(autoScanOnStartupProvider);
    final skipSilence = ref.watch(skipSilenceProvider);
    final rememberLastPosition = ref.watch(rememberLastPositionProvider);
    final showAlbumArtOnLockscreen = ref.watch(showAlbumArtOnLockscreenProvider);
    final crossfadeDuration = ref.watch(crossfadeDurationProvider);
    final minFileDuration = ref.watch(minFileDurationProvider);
    // New settings
    final fadeOnPausePlay = ref.watch(fadeOnPausePlayProvider);
    final audioDucking = ref.watch(audioDuckingProvider);
    final replayGain = ref.watch(replayGainProvider);
    final autoPlayOnConnect = ref.watch(autoPlayOnConnectProvider);
    final pauseOnDisconnect = ref.watch(pauseOnDisconnectProvider);
    final keepShuffleQueue = ref.watch(keepShuffleQueueProvider);
    final resumeOnRestart = ref.watch(resumeOnRestartProvider);
    final gridColumnCount = ref.watch(gridColumnCountProvider);
    final showTrackNumbers = ref.watch(showTrackNumbersProvider);
    final confirmExit = ref.watch(confirmExitProvider);
    final sleepTimerFinishTrack = ref.watch(sleepTimerFinishTrackProvider);

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
            icon: isScanning.when(
              data: (scanning) => scanning ? Icons.stop_rounded : Icons.refresh_rounded,
              loading: () => Icons.refresh_rounded,
              error: (_, __) => Icons.refresh_rounded,
            ),
            title: isScanning.when(
              data: (scanning) => scanning ? 'Cancel Scan' : 'Rescan Library',
              loading: () => 'Rescan Library',
              error: (_, __) => 'Rescan Library',
            ),
            subtitle: isScanning.when(
              data: (scanning) =>
                  scanning ? 'Tap to cancel scanning' : 'Scan for new music files',
              loading: () => 'Scan for new music files',
              error: (_, __) => 'Scan for new music files',
            ),
            onTap: isScanning.when(
              data: (scanning) => scanning
                  ? () => _cancelScan(context, ref)
                  : () => _rescanLibrary(context, ref),
              loading: () => () => _rescanLibrary(context, ref),
              error: (_, __) => () => _rescanLibrary(context, ref),
            ),
            trailing: isScanning.when(
              data: (scanning) => scanning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
              loading: () => const Icon(Icons.chevron_right_rounded),
              error: (_, __) => const Icon(Icons.chevron_right_rounded),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.autorenew_rounded,
            title: 'Auto-scan on Startup',
            subtitle: 'Scan for new music when app opens',
            trailing: Switch(
              value: autoScanOnStartup,
              onChanged: (value) => _setAutoScanOnStartup(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.timer_outlined,
            title: 'Minimum Track Duration',
            subtitle: minFileDuration == 0 
                ? 'Include all files' 
                : 'Skip files under ${minFileDuration}s',
            onTap: () => _showMinDurationDialog(context, ref),
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
            subtitle: '${playbackSpeed.toStringAsFixed(1)}x',
            onTap: () => _showPlaybackSpeedDialog(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.skip_next_rounded,
            title: 'Gapless Playback',
            subtitle: 'Seamless transitions between tracks',
            trailing: Switch(
              value: gaplessPlayback,
              onChanged: (value) => _setGaplessPlayback(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.blur_linear_rounded,
            title: 'Crossfade',
            subtitle: crossfadeDuration == 0 
                ? 'Disabled' 
                : '${crossfadeDuration}s between tracks',
            onTap: () => _showCrossfadeDialog(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.volume_off_rounded,
            title: 'Skip Silence',
            subtitle: 'Skip silent parts in tracks',
            trailing: Switch(
              value: skipSilence,
              onChanged: (value) => _setSkipSilence(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.play_circle_outline_rounded,
            title: 'Fade on Play/Pause',
            subtitle: 'Smooth fade when playing or pausing',
            trailing: Switch(
              value: fadeOnPausePlay,
              onChanged: (value) => _setFadeOnPausePlay(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.history_rounded,
            title: 'Remember Position',
            subtitle: 'Resume playback from last position',
            trailing: Switch(
              value: rememberLastPosition,
              onChanged: (value) => _setRememberLastPosition(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Audio'),
          _buildSettingsTile(
            context,
            icon: Icons.equalizer_rounded,
            title: 'ReplayGain',
            subtitle: _replayGainLabel(replayGain),
            onTap: () => _showReplayGainDialog(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.volume_down_rounded,
            title: 'Audio Ducking',
            subtitle: 'Lower volume for notifications',
            trailing: Switch(
              value: audioDucking,
              onChanged: (value) => _setAudioDucking(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Headset & Bluetooth'),
          _buildSettingsTile(
            context,
            icon: Icons.headphones_rounded,
            title: 'Auto-play on Connect',
            subtitle: 'Resume playback when headset connects',
            trailing: Switch(
              value: autoPlayOnConnect,
              onChanged: (value) => _setAutoPlayOnConnect(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.headset_off_rounded,
            title: 'Pause on Disconnect',
            subtitle: 'Pause when headset disconnects',
            trailing: Switch(
              value: pauseOnDisconnect,
              onChanged: (value) => _setPauseOnDisconnect(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Queue'),
          _buildSettingsTile(
            context,
            icon: Icons.shuffle_rounded,
            title: 'Keep Shuffle Queue',
            subtitle: 'Preserve shuffle order on restart',
            trailing: Switch(
              value: keepShuffleQueue,
              onChanged: (value) => _setKeepShuffleQueue(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.restore_rounded,
            title: 'Resume on Restart',
            subtitle: 'Auto-play last track on app start',
            trailing: Switch(
              value: resumeOnRestart,
              onChanged: (value) => _setResumeOnRestart(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Sleep Timer'),
          _buildSettingsTile(
            context,
            icon: Icons.music_note_rounded,
            title: 'Finish Current Track',
            subtitle: 'Complete song before sleep timer stops',
            trailing: Switch(
              value: sleepTimerFinishTrack,
              onChanged: (value) => _setSleepTimerFinishTrack(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingsTile(
            context,
            icon: Icons.album_rounded,
            title: 'Album Art on Lockscreen',
            subtitle: 'Show album art in media notification',
            trailing: Switch(
              value: showAlbumArtOnLockscreen,
              onChanged: (value) => _setShowAlbumArtOnLockscreen(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeSelector(context, ref),
          _buildSettingsTile(
            context,
            icon: Icons.grid_view_rounded,
            title: 'Grid Columns',
            subtitle: '$gridColumnCount columns',
            onTap: () => _showGridColumnsDialog(context, ref),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.format_list_numbered_rounded,
            title: 'Show Track Numbers',
            subtitle: 'Display track numbers in lists',
            trailing: Switch(
              value: showTrackNumbers,
              onChanged: (value) => _setShowTrackNumbers(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.exit_to_app_rounded,
            title: 'Confirm Exit',
            subtitle: 'Show confirmation when leaving app',
            trailing: Switch(
              value: confirmExit,
              onChanged: (value) => _setConfirmExit(ref, value),
              activeThumbColor: context.colors.primary,
            ),
          ),
          const Divider(height: 32),
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'About ${AppConstants.appName}',
            subtitle: 'Version ${AppConstants.appVersion}',
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MusicFoldersSheet(),
    );
  }

  void _cancelScan(BuildContext context, WidgetRef ref) {
    final fileScanner = ref.read(fileScannerServiceProvider);
    fileScanner.cancelScan();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cancelling scan...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _rescanLibrary(BuildContext context, WidgetRef ref) async {
    debugPrint('_rescanLibrary called');
    final messenger = ScaffoldMessenger.of(context);
    final fileScanner = ref.read(fileScannerServiceProvider);
    final musicFolders = ref.read(musicFoldersProvider);
    final minDuration = ref.read(minFileDurationProvider);

    debugPrint('Music folders: $musicFolders');

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Starting library scan...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      debugPrint('Calling scanDevice...');
      final result = await fileScanner.scanDevice(
        folders: musicFolders,
        minDurationSeconds: minDuration,
      );
      debugPrint('Scan result: ${result.newSongs} new, ${result.updatedSongs} updated, ${result.totalFound} found, ${result.skippedFiles} skipped');

      // Refresh the songs provider
      ref.read(songsProvider.notifier).refresh();

      if (context.mounted) {
        final skippedText = result.skippedFiles > 0 
            ? ', ${result.skippedFiles} skipped' 
            : '';
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              result.cancelled
                  ? 'Scan cancelled'
                  : 'Scan complete: ${result.newSongs} new, ${result.updatedSongs} updated$skippedText',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Scan error: $e');
      debugPrint('Stack: $stack');
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Scan failed: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
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
                  _setPlaybackSpeed(ref, speed);
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

  void _setPlaybackSpeed(WidgetRef ref, double speed) async {
    // Update provider state
    ref.read(playbackSpeedProvider.notifier).state = speed;

    // Persist to Hive
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.playbackSpeed, speed);
    });

    // Apply to audio controller
    final audioController = ref.read(audioControllerProvider);
    await audioController.setSpeed(speed);
  }

  void _setGaplessPlayback(WidgetRef ref, bool enabled) async {
    // Update provider state
    ref.read(gaplessPlaybackProvider.notifier).state = enabled;

    // Persist to Hive
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.gaplessPlayback, enabled);
    });
  }

  void _setAutoScanOnStartup(WidgetRef ref, bool enabled) {
    ref.read(autoScanOnStartupProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.autoScanOnStartup, enabled);
    });
  }

  void _setSkipSilence(WidgetRef ref, bool enabled) {
    ref.read(skipSilenceProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.skipSilence, enabled);
    });
    // Apply to audio player immediately
    final audioController = ref.read(audioControllerProvider);
    audioController.setSkipSilence(enabled);
  }

  void _setRememberLastPosition(WidgetRef ref, bool enabled) {
    ref.read(rememberLastPositionProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.rememberLastPosition, enabled);
    });
  }

  void _setShowAlbumArtOnLockscreen(WidgetRef ref, bool enabled) {
    ref.read(showAlbumArtOnLockscreenProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.showAlbumArtOnLockscreen, enabled);
    });
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
              groupValue: currentDuration,
              onChanged: (value) {
                if (value != null) {
                  _setCrossfadeDuration(ref, value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _setCrossfadeDuration(WidgetRef ref, int duration) {
    ref.read(crossfadeDurationProvider.notifier).state = duration;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.crossfadeDuration, duration);
    });
  }

  void _showMinDurationDialog(BuildContext context, WidgetRef ref) {
    final currentDuration = ref.read(minFileDurationProvider);
    final durations = [0, 10, 20, 30, 45, 60, 90, 120];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minimum Track Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: durations.map((duration) {
            return RadioListTile<int>(
              title: Text(duration == 0 
                  ? 'Include all files' 
                  : duration < 60 
                      ? 'Skip under ${duration}s'
                      : 'Skip under ${duration ~/ 60}m ${duration % 60 == 0 ? '' : '${duration % 60}s'}'),
              value: duration,
              groupValue: currentDuration,
              onChanged: (value) {
                if (value != null) {
                  _setMinFileDuration(ref, value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _setMinFileDuration(WidgetRef ref, int duration) {
    ref.read(minFileDurationProvider.notifier).state = duration;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.minFileDuration, duration);
    });
  }

  void _setFadeOnPausePlay(WidgetRef ref, bool enabled) {
    ref.read(fadeOnPausePlayProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.fadeOnPausePlay, enabled);
    });
    // Apply to audio player immediately
    final audioController = ref.read(audioControllerProvider);
    audioController.setFadeOnPausePlay(enabled);
  }

  void _setAudioDucking(WidgetRef ref, bool enabled) {
    ref.read(audioDuckingProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.audioDucking, enabled);
    });
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

  void _showReplayGainDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(replayGainProvider);
    final modes = ['off', 'track', 'album'];
    final labels = {'off': 'Disabled', 'track': 'Track mode', 'album': 'Album mode'};

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
              groupValue: currentMode,
              onChanged: (value) {
                if (value != null) {
                  _setReplayGain(ref, value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
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

  void _setReplayGain(WidgetRef ref, String mode) {
    ref.read(replayGainProvider.notifier).state = mode;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.replayGain, mode);
    });
  }

  void _setAutoPlayOnConnect(WidgetRef ref, bool enabled) {
    ref.read(autoPlayOnConnectProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.autoPlayOnConnect, enabled);
    });
  }

  void _setPauseOnDisconnect(WidgetRef ref, bool enabled) {
    ref.read(pauseOnDisconnectProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.pauseOnDisconnect, enabled);
    });
  }

  void _setKeepShuffleQueue(WidgetRef ref, bool enabled) {
    ref.read(keepShuffleQueueProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.keepShuffleQueue, enabled);
    });
  }

  void _setResumeOnRestart(WidgetRef ref, bool enabled) {
    ref.read(resumeOnRestartProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.resumeOnRestart, enabled);
    });
  }

  void _setSleepTimerFinishTrack(WidgetRef ref, bool enabled) {
    ref.read(sleepTimerFinishTrackProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.sleepTimerFinishTrack, enabled);
    });
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
              groupValue: currentCount,
              onChanged: (value) {
                if (value != null) {
                  _setGridColumnCount(ref, value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _setGridColumnCount(WidgetRef ref, int count) {
    ref.read(gridColumnCountProvider.notifier).state = count;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.gridColumnCount, count);
    });
  }

  void _setShowTrackNumbers(WidgetRef ref, bool enabled) {
    ref.read(showTrackNumbersProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.showTrackNumbers, enabled);
    });
  }

  void _setConfirmExit(WidgetRef ref, bool enabled) {
    ref.read(confirmExitProvider.notifier).state = enabled;
    final boxAsync = ref.read(settingsBoxProvider);
    boxAsync.whenData((box) {
      box.put(SettingsKeys.confirmExit, enabled);
    });
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

/// Bottom sheet for managing music folders
class _MusicFoldersSheet extends ConsumerWidget {
  const _MusicFoldersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(musicFoldersProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Music Folders',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${folders.length} folders selected',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    // Add folder button
                    FilledButton.icon(
                      onPressed: () => _addFolder(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Folders list
              Expanded(
                child: folders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_rounded,
                              size: 48,
                              color: context.colors.textSecondary
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No folders selected',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  ref.read(musicFoldersProvider.notifier).resetToDefaults(),
                              child: const Text('Reset to defaults'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return _buildFolderTile(context, ref, folder);
                        },
                      ),
              ),
              // Reset button
              if (folders.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: () => _showResetConfirmation(context, ref),
                      child: Text(
                        'Reset to default folders',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFolderTile(
      BuildContext context, WidgetRef ref, String folderPath) {
    // Get just the folder name for display
    final folderName = folderPath.split('/').last;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.folder_rounded,
          color: context.colors.primary,
          size: 24,
        ),
      ),
      title: Text(
        folderName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        folderPath,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.remove_circle_outline_rounded,
          color: context.colors.error,
        ),
        onPressed: () => _removeFolder(context, ref, folderPath),
      ),
    );
  }

  Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Music Folder',
      );

      if (result != null) {
        ref.read(musicFoldersProvider.notifier).addFolder(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added: ${result.split('/').last}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add folder: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  void _removeFolder(BuildContext context, WidgetRef ref, String folderPath) {
    ref.read(musicFoldersProvider.notifier).removeFolder(folderPath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed: ${folderPath.split('/').last}'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(musicFoldersProvider.notifier).addFolder(folderPath);
          },
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Folders'),
        content: const Text(
          'Reset music folders to defaults? This will remove any custom folders you\'ve added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(musicFoldersProvider.notifier).resetToDefaults();
              Navigator.pop(dialogContext);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
