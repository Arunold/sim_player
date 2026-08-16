import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui';
import '../../core/constants/theme_constants.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/song_metadata_sheet.dart';
import '../widgets/song_options_menu.dart';
import '../../services/sleep_timer_service.dart';
import 'queue_screen.dart';

/// Full-screen now playing screen
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSongAsync = ref.watch(currentSongProvider);
    final playerStateAsync = ref.watch(playerStateProvider);
    final songsAsync = ref.watch(songsProvider);
    final audioController = ref.read(audioControllerProvider);

    return Scaffold(
      body: currentSongAsync.when(
        data: (currentSong) {
          if (currentSong == null) {
            return const Center(child: Text('No song playing'));
          }

          // Get updated song from songsProvider for reactive isFavorite
          final song =
              songsAsync.whenOrNull(
                data: (songs) =>
                    songs.where((s) => s.id == currentSong.id).firstOrNull,
              ) ??
              currentSong;

          return playerStateAsync.when(
            data: (playerState) =>
                _buildContent(context, ref, song, playerState, audioController),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Song song,
    AppPlayerState playerState,
    AudioController audioController,
  ) {
    final sleepTimer = ref.watch(sleepTimerProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred album art background
        if (song.artworkPath != null)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Image.file(
                File(song.artworkPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        // Overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colors.backgroundPrimary.withValues(alpha: 0.2),
                  context.colors.backgroundSecondary.withValues(alpha: 0.25),
                  context.colors.backgroundTertiary.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Column(
            children: [
              // App bar - minimal with just close button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstants.spacingSm,
                  vertical: ThemeConstants.spacingSm,
                ),
                child: Row(
                  children: [
                    // Only show back button if this screen can be popped
                    if (Navigator.of(context).canPop())
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        iconSize: 32,
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    else
                      const SizedBox(width: 48), // Placeholder for alignment
                    const Spacer(),
                    // Sleep Timer
                    if (sleepTimer.isActive)
                      ActionChip(
                        backgroundColor: context.colors.primary.withValues(alpha: 0.2),
                        side: BorderSide.none,
                        label: Text(
                          '${sleepTimer.remainingTime!.inMinutes}:${(sleepTimer.remainingTime!.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: context.colors.primary),
                        ),
                        onPressed: () => _showSleepTimerDialog(context, ref),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.timer_outlined),
                        onPressed: () => _showSleepTimerDialog(context, ref),
                      ),
                    // More options
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => _showOptionsMenu(context, ref, song),
                    ),
                  ],
                ),
              ),
              // Artwork with swipe gestures for previous/next
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ThemeConstants.spacingXl,
                  ),
                  child: Center(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        // Swipe right = previous song
                        if (velocity > 300) {
                          audioController.skipToPrevious();
                        }
                        // Swipe left = next song
                        else if (velocity < -300) {
                          audioController.skipToNext();
                        }
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              ThemeConstants.radiusLg,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.backgroundPrimary
                                    .withValues(alpha: 0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ThemeConstants.radiusLg,
                            ),
                            child: song.artworkPath != null
                                ? Image.file(
                                    File(song.artworkPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _buildPlaceholder(context),
                                  )
                                : _buildPlaceholder(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Action icons row (between artwork and song info)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstants.spacingXl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Favorite
                    IconButton(
                      icon: Icon(
                        song.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: song.isFavorite ? context.colors.error : null,
                      ),
                      tooltip: song.isFavorite
                          ? 'Remove from favorites'
                          : 'Add to favorites',
                      onPressed: () {
                        ref
                            .read(songsProvider.notifier)
                            .toggleFavorite(song.id);
                      },
                    ),
                    // Queue
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded),
                      tooltip: 'Queue',
                      onPressed: () => _showQueueSheet(context),
                    ),
                    // Song info
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded),
                      tooltip: 'Song details',
                      onPressed: () => SongMetadataSheet.show(context, song),
                    ),
                    // Add to playlist
                    IconButton(
                      icon: const Icon(Icons.playlist_add_rounded),
                      tooltip: 'Add to playlist',
                      onPressed: () =>
                          _showAddToPlaylistSheet(context, ref, song),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ThemeConstants.spacingSm),
              // Song info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstants.spacingLg,
                  vertical: ThemeConstants.spacingSm,
                ),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          song.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${song.album}${song.year != null ? ' • ${song.year}' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstants.spacingLg,
                ),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: playerState.progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final position = Duration(
                            milliseconds:
                                (value * playerState.duration.inMilliseconds)
                                    .toInt(),
                          );
                          audioController.seek(position);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            playerState.positionFormatted,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.colors.textPrimary),
                          ),
                          Text(
                            playerState.durationFormatted,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.colors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Playback controls
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ThemeConstants.spacingMd,
                  vertical: ThemeConstants.spacingMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: playerState.isShuffleEnabled
                            ? context.colors.primary
                            : context.colors.textSecondary,
                      ),
                      onPressed: () => audioController.toggleShuffle(),
                    ),
                    // Previous
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 40,
                      onPressed: () => audioController.skipToPrevious(),
                    ),
                    // Play/Pause
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.primary,
                      ),
                      child: IconButton(
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: context.colors.textPrimary,
                        ),
                        iconSize: 40,
                        onPressed: () => audioController.togglePlayPause(),
                      ),
                    ),
                    // Next
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 40,
                      onPressed: () => audioController.skipToNext(),
                    ),
                    // Repeat
                    IconButton(
                      icon: Icon(
                        _getRepeatIcon(playerState.repeatMode),
                        color: playerState.repeatMode != RepeatMode.off
                            ? context.colors.primary
                            : context.colors.textSecondary,
                      ),
                      onPressed: () => audioController.cycleRepeatMode(),
                    ),
                  ],
                ),
              ),
              // Bottom spacing
              const SizedBox(height: ThemeConstants.spacingMd),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: context.colors.card,
      child: Icon(
        Icons.music_note_rounded,
        size: 100,
        color: context.colors.textSecondary.withAlpha(77),
      ),
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat_rounded;
      case RepeatMode.all:
        return Icons.repeat_rounded;
      case RepeatMode.one:
        return Icons.repeat_one_rounded;
    }
  }

  void _showQueueSheet(BuildContext context) {
    QueueScreen.show(context);
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SongOptionsMenu(song: song),
    );
  }

  void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
    final timerService = ref.read(sleepTimerProvider.notifier);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(ThemeConstants.spacingLg),
                child: Text(
                  'Sleep Timer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.timer_off),
                title: const Text('Off'),
                onTap: () {
                  timerService.cancel();
                  Navigator.pop(context);
                },
              ),
              for (final mins in [15, 30, 45, 60, 90])
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text('$mins minutes'),
                  onTap: () {
                    timerService.start(Duration(minutes: mins));
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }



  void _showAddToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) {
    final playlistsAsync = ref.read(playlistsProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(ThemeConstants.spacingMd),
              child: Text(
                'Add to Playlist',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            playlistsAsync.when(
              data: (playlists) {
                if (playlists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(ThemeConstants.spacingLg),
                    child: Text(
                      'No playlists available. Create one first.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: playlists
                      .map(
                        (playlist) => ListTile(
                          leading: const Icon(Icons.queue_music_rounded),
                          title: Text(playlist.name),
                          subtitle: Text('${playlist.songIds.length} songs'),
                          onTap: () async {
                            await ref
                                .read(playlistsProvider.notifier)
                                .addSongToPlaylist(playlist.id, song.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added to "${playlist.name}"'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(ThemeConstants.spacingLg),
                child: CircularProgressIndicator(),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.all(ThemeConstants.spacingLg),
                child: Text('Error loading playlists'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistSheet(
    BuildContext context,
    WidgetRef ref,
    Song song,
  ) => _showAddToPlaylistDialog(context, ref, song);
}
