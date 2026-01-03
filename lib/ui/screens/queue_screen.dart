import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/song_tile.dart';

/// Queue screen showing the current playback queue
/// Full screen glassy design with auto-scroll to current song
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  /// Show queue as a full screen modal
  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: context.colors.backgroundTertiary,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const QueueScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  bool _hasScrolledToCurrentSong = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentSong(int currentIndex) {
    if (_hasScrolledToCurrentSong || currentIndex < 0) return;
    _hasScrolledToCurrentSong = true;

    // Item height is approximately 88 pixels (SongTile with padding)
    const itemHeight = 88.0;
    final targetOffset =
        (currentIndex * itemHeight) - 150; // Show some context above

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, maxScroll),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(playbackQueueProvider);
    final songsAsync = ref.watch(songsProvider);
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final audioController = ref.read(audioControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: const SizedBox.expand(),
            ),
          ),
          // Dark gradient overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.backgroundPrimary.withValues(alpha: 0.1),
                    context.colors.backgroundPrimary.withValues(alpha: 0.2),
                    context.colors.backgroundPrimary.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context, queueAsync, audioController),
                Divider(
                  color: context.colors.divider.withValues(alpha: 0.8),
                  height: 1,
                ),
                // Queue list
                Expanded(
                  child: _buildQueueList(
                    context,
                    queueAsync,
                    songsAsync,
                    currentSong,
                    audioController,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AsyncValue<PlaybackQueue> queueAsync,
    AudioController audioController,
  ) {
    return queueAsync.when(
      data: (queue) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ThemeConstants.spacingXs,
            vertical: ThemeConstants.spacingSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                iconSize: 28,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 15),
              Icon(
                Icons.queue_music_rounded,
                color: context.colors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Queue',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${queue.songIds.length} songs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (queue.isShuffled) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shuffle_rounded,
                        size: 14,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Shuffled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              queue.songIds.isNotEmpty
                  ? TextButton.icon(
                      icon: const Icon(Icons.clear_all_rounded, size: 20),
                      label: const Text('Clear'),
                      onPressed: () => _showClearQueueDialog(context),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQueueList(
    BuildContext context,
    AsyncValue<PlaybackQueue> queueAsync,
    AsyncValue<List<Song>> songsAsync,
    Song? currentSong,
    AudioController audioController,
  ) {
    return queueAsync.when(
      data: (queue) {
        if (queue.isEmpty) {
          return _buildEmptyState(context);
        }

        return songsAsync.when(
          data: (songs) {
            final songMap = {for (var s in songs) s.id: s};
            final queueSongs = queue.songIds
                .map((id) => songMap[id])
                .whereType<Song>()
                .toList();

            // Trigger scroll to current song
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentSong(queue.currentIndex);
            });

            return ReorderableListView.builder(
              key: _listKey,
              scrollController: _scrollController,
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: queueSongs.length,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final elevation = lerpDouble(0, 8, animation.value)!;
                    return Material(
                      elevation: elevation,
                      color: context.colors.card.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(
                        ThemeConstants.radiusMd,
                      ),
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                audioController.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = queueSongs[index];
                final isCurrentSong = song.id == currentSong?.id;

                return _QueueSongItem(
                  key: ValueKey('queue_${song.id}_$index'),
                  song: song,
                  index: index,
                  isCurrentSong: isCurrentSong,
                  onTap: () => audioController.playFromQueue(index),
                  onRemove: () => audioController.removeFromQueue(index),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 80,
            color: context.colors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'Queue is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add songs to start playing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearQueueDialog(BuildContext context) {
    final audioController = ref.read(audioControllerProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Queue'),
        content: const Text(
          'Are you sure you want to clear the playback queue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await audioController.clearQueue();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Queue song item with swipe to delete and drag handle
/// Uses the same visual style as SongTile for consistency
class _QueueSongItem extends ConsumerWidget {
  final Song song;
  final int index;
  final bool isCurrentSong;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueSongItem({
    super.key,
    required this.song,
    required this.index,
    required this.isCurrentSong,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('dismiss_${song.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: context.colors.backgroundTertiary.withAlpha(125),
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: context.colors.error,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        onRemove();
        return false; // Don't auto-dismiss, let the provider handle it
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: ThemeConstants.spacingXs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: isCurrentSong
              ? context.colors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstants.spacingXs,
                  vertical: ThemeConstants.spacingMd,
                ),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: context.colors.textTertiary,
                ),
              ),
            ),
            // Song tile (without its own padding)
            Expanded(
              child: SongTile(
                song: song,
                onTap: onTap,
                trailing: Text(
                  song.durationFormatted,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCurrentSong
                        ? context.colors.primary
                        : context.colors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
