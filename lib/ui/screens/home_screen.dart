import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/providers.dart';
import '../../services/file_scanner_service.dart';
import '../widgets/widgets.dart';

/// Home screen with recently played, favorites, etc.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final audioController = ref.read(audioControllerProvider);

    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(ThemeConstants.spacingMd),
            child: CustomSearchBar(
              readOnly: true,
              onTap: () => _navigateToSearch(context),
            ),
          ),
        ),
        // Stats
        SliverToBoxAdapter(
          child: songsAsync.when(
            data: (songs) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ThemeConstants.spacingMd,
              ),
              child: Row(
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.music_note_rounded,
                    label: 'Songs',
                    value: songs.length.toString(),
                    color: context.colors.primary,
                    onTap: () => _navigateToLibrary(context),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    icon: Icons.person_rounded,
                    label: 'Artists',
                    value: ref.watch(artistsProvider).length.toString(),
                    color: context.colors.accent,
                    onTap: () => _navigateToLibrary(context),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    icon: Icons.album_rounded,
                    label: 'Albums',
                    value: ref.watch(albumsProvider).length.toString(),
                    color: Colors.pinkAccent,
                    onTap: () => _navigateToLibrary(context),
                  ),
                ],
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(ThemeConstants.spacingMd),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(ThemeConstants.spacingMd),
              child: Text('Error: $e'),
            ),
          ),
        ),
        // Recently Added Section
        if (recentlyAdded.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, ref, 'Recently Added'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = recentlyAdded[index];
              return SongTile(
                song: song,
                onTap: () =>
                    audioController.playSongs(recentlyAdded, startIndex: index),
              );
            }, childCount: recentlyAdded.take(5).length),
          ),
        ],
        // Recently Played Section
        if (recentlyPlayed.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, ref, 'Recently Played'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final song = recentlyPlayed[index];
              return SongTile(
                song: song,
                onTap: () => audioController.playSongs(
                  recentlyPlayed,
                  startIndex: index,
                ),
              );
            }, childCount: recentlyPlayed.take(5).length),
          ),
        ],
        // Empty state
        if (songsAsync.value?.isEmpty ?? true)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_music_rounded,
                    size: 80,
                    color: context.colors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No songs yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan your music library to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _scanMusic(context, ref);
                    },
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Scan Music'),
                  ),
                ],
              ),
            ),
          ),
        // Bottom spacing for mini player
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: ThemeConstants.darkCard,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(ThemeConstants.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ThemeConstants.spacingMd,
        ThemeConstants.spacingLg,
        ThemeConstants.spacingMd,
        ThemeConstants.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          TextButton(
            onPressed: () => _navigateToLibrary(context),
            child: const Text('See all'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanMusic(BuildContext context, WidgetRef ref) async {
    final permissionService = ref.read(permissionServiceProvider);
    final fileScanner = ref.read(fileScannerServiceProvider);

    // Request storage permission first
    final hasPermission = await permissionService.requestStoragePermission();

    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Storage permission is required to scan music files',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => permissionService.openSettings(),
            ),
          ),
        );
      }
      return;
    }

    // Start scanning FIRST (before showing dialog)
    final scanFuture = fileScanner.scanDevice();

    // Show scanning dialog - don't await, let scan continue
    bool runInBackground = false;
    if (context.mounted) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _ScanningDialog(),
      );
      runInBackground = result == true;
    }

    if (runInBackground) {
      // User chose to run in background - show snackbar and let it continue
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scanning in background...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Listen to progress stream to refresh library while running in background
      final progressSubscription = fileScanner.progressStream.listen((
        progress,
      ) {
        ref.read(songsProvider.notifier).refresh();
      });

      // Continue scan in background, refresh when done and cancel subscription
      scanFuture.then((result) {
        progressSubscription.cancel();
        ref.read(songsProvider.notifier).refresh();
        // Show completion snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.newSongs} songs added in ${_formatDuration(result.duration)}',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
      return;
    }

    try {
      // Wait for the scan to complete
      final result = await scanFuture;

      // Refresh the songs list
      ref.read(songsProvider.notifier).refresh();

      // Show result
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.newSongs} songs added in ${_formatDuration(result.duration)}',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes >= 1) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '$minutes min ${seconds}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.search);
  }

  void _navigateToLibrary(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.library);
  }
}

class _ScanningDialog extends ConsumerStatefulWidget {
  const _ScanningDialog();

  @override
  ConsumerState<_ScanningDialog> createState() => _ScanningDialogState();
}

class _ScanningDialogState extends ConsumerState<_ScanningDialog> {
  late final Stream<ScanResult> _completeStream;

  @override
  void initState() {
    super.initState();
    final fileScanner = ref.read(fileScannerServiceProvider);
    _completeStream = fileScanner.completeStream;
    // Listen for scan completion to auto-close dialog
    _completeStream.listen((result) {
      if (mounted) {
        Navigator.of(context).pop(false); // false = not running in background
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileScanner = ref.watch(fileScannerServiceProvider);

    return AlertDialog(
      content: StreamBuilder<ScanProgress>(
        stream: fileScanner.progressStream,
        builder: (context, snapshot) {
          final progress = snapshot.data;
          final phase = progress?.phase ?? ScanPhase.counting;
          final songsAdded = progress?.songsAdded ?? 0;

          // Refresh library when we get a progress update (already throttled by scanner)
          if (songsAdded > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(songsProvider.notifier).refresh();
              }
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (phase == ScanPhase.counting) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Finding music files...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ] else ...[
                // Show songs added count
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Processing...',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Text(
                  '$songsAdded',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Songs added',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Run in Background'),
              ),
            ],
          );
        },
      ),
    );
  }
}
