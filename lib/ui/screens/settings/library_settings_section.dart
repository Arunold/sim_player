import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme_constants.dart';
import '../../../providers/providers.dart';
import 'settings_widgets.dart';

/// Library settings section: folders, scanning, clearing
class LibrarySettingsSection extends ConsumerWidget {
  const LibrarySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScanning = ref.watch(isScanningProvider);
    final autoScanOnStartup = ref.watch(autoScanOnStartupProvider);
    final minFileDuration = ref.watch(minFileDurationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: 'Library'),
        SettingsTile(
          icon: Icons.folder_rounded,
          title: 'Music Folders',
          subtitle: 'Manage folders to scan for music',
          onTap: () => _showMusicFoldersDialog(context),
        ),
        SettingsTile(
          icon: isScanning.when(
            data: (scanning) => scanning ? Icons.stop_rounded : Icons.refresh_rounded,
            loading: () => Icons.refresh_rounded,
            error: (_, _) => Icons.refresh_rounded,
          ),
          title: isScanning.when(
            data: (scanning) => scanning ? 'Cancel Scan' : 'Rescan Library',
            loading: () => 'Rescan Library',
            error: (_, _) => 'Rescan Library',
          ),
          subtitle: isScanning.when(
            data: (scanning) =>
                scanning ? 'Tap to cancel scanning' : 'Scan for new music files',
            loading: () => 'Scan for new music files',
            error: (_, _) => 'Scan for new music files',
          ),
          onTap: isScanning.when(
            data: (scanning) => scanning
                ? () => _cancelScan(context, ref)
                : () => _rescanLibrary(context, ref),
            loading: () => () => _rescanLibrary(context, ref),
            error: (_, _) => () => _rescanLibrary(context, ref),
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
            error: (_, _) => const Icon(Icons.chevron_right_rounded),
          ),
        ),
        SettingsTile(
          icon: Icons.autorenew_rounded,
          title: 'Auto-scan on Startup',
          subtitle: 'Scan for new music when app opens',
          trailing: Switch(
            value: autoScanOnStartup,
            onChanged: (value) =>
                ref.read(autoScanOnStartupProvider.notifier).set(value),
            activeThumbColor: context.colors.primary,
          ),
        ),
        SettingsTile(
          icon: Icons.timer_outlined,
          title: 'Minimum Track Duration',
          subtitle: minFileDuration == 0
              ? 'Include all files'
              : 'Skip files under ${minFileDuration}s',
          onTap: () => _showMinDurationDialog(context, ref),
        ),
        SettingsTile(
          icon: Icons.delete_outline_rounded,
          title: 'Clear Library',
          subtitle: 'Remove all songs from library',
          onTap: () => _showClearLibraryDialog(context, ref),
          isDestructive: true,
        ),
      ],
    );
  }

  void _showMusicFoldersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MusicFoldersSheet(),
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
      debugPrint(
          'Scan result: ${result.newSongs} new, ${result.updatedSongs} updated, ${result.totalFound} found, ${result.skippedFiles} skipped');

      // Refresh the songs provider
      ref.read(songsProvider.notifier).refresh();

      if (context.mounted) {
        final skippedText =
            result.skippedFiles > 0 ? ', ${result.skippedFiles} skipped' : '';
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
              // ignore: deprecated_member_use
              groupValue: currentDuration,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  ref.read(minFileDurationProvider.notifier).set(value);
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

/// Bottom sheet for managing music folders
class MusicFoldersSheet extends ConsumerWidget {
  const MusicFoldersSheet({super.key});

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
                              onPressed: () => ref
                                  .read(musicFoldersProvider.notifier)
                                  .resetToDefaults(),
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
      final result = await FilePicker.getDirectoryPath(
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
