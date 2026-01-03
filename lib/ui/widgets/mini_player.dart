import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/glass_style.dart';
import '../../providers/providers.dart';

/// Mini player widget shown at the bottom of screens
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSongAsync = ref.watch(currentSongProvider);
    final playerStateAsync = ref.watch(playerStateProvider);
    final songsAsync = ref.watch(songsProvider);
    final audioController = ref.read(audioControllerProvider);

    return currentSongAsync.when(
      data: (currentSong) {
        if (currentSong == null) return const SizedBox.shrink();

        // Get updated song from songsProvider for reactive isFavorite
        final song =
            songsAsync.whenOrNull(
              data: (songs) =>
                  songs.where((s) => s.id == currentSong.id).firstOrNull,
            ) ??
            currentSong;

        return playerStateAsync.when(
          data: (playerState) {
            return GestureDetector(
              onTap: onTap,
              child: GlassContainer.miniPlayer(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    children: [
                      // Progress bar
                      LinearProgressIndicator(
                        value: playerState.progress,
                        backgroundColor: ThemeConstants.darkCard.withValues(
                          alpha: 0.5,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.colors.primary,
                        ),
                        minHeight: 3,
                      ),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              // Artwork
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: ThemeConstants.darkCard,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: song.artworkPath != null
                                      ? Image.file(
                                          File(song.artworkPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildPlaceholder(context),
                                        )
                                      : _buildPlaceholder(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Song info and controls
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Song info
                                    Text(
                                      song.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      song.artist,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.colors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${song.album}${song.year != null ? ' • ${song.year}' : ''}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.colors.textSecondary
                                            .withValues(alpha: 0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Controls
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            song.isFavorite
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: song.isFavorite
                                                ? ThemeConstants.errorColor
                                                : null,
                                          ),
                                          iconSize: 24,
                                          onPressed: () => ref
                                              .read(songsProvider.notifier)
                                              .toggleFavorite(song.id),
                                          padding: EdgeInsets.zero,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_previous_rounded,
                                          ),
                                          iconSize: 30,
                                          onPressed: () =>
                                              audioController.skipToPrevious(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            playerState.isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                          ),
                                          iconSize: 35,
                                          onPressed: () =>
                                              audioController.togglePlayPause(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.skip_next_rounded,
                                          ),
                                          iconSize: 30,
                                          onPressed: () =>
                                              audioController.skipToNext(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        Text(song.durationFormatted),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: context.colors.card,
      child: Icon(
        Icons.music_note_rounded,
        color: context.colors.textSecondary.withValues(alpha: 0.5),
        size: 20,
      ),
    );
  }
}
