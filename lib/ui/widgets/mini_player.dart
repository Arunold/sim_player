import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sim_player/core/constants/app_constants.dart';
import 'dart:io';
import '../../core/constants/theme_constants.dart';
import '../../core/theme/glass_style.dart';
import '../../providers/providers.dart';

/// Mini player widget shown at the bottom of screens
///
/// [compact] - If true, shows a smaller version suitable for side nav
/// [useGlassContainer] - If true, wraps content in GlassContainer (default: true)
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool compact;
  final bool useGlassContainer;

  const MiniPlayer({
    super.key,
    this.onTap,
    this.compact = false,
    this.useGlassContainer = true,
  });

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
            final content = _buildContent(
              context,
              ref,
              song,
              playerState,
              audioController,
            );

            return GestureDetector(
              onTap: onTap,
              child: useGlassContainer
                  ? GlassContainer.miniPlayer(child: content)
                  : Container(
                      decoration: BoxDecoration(
                        color: context.colors.card,
                        border: Border(
                          top: BorderSide(
                            color: context.colors.divider,
                            width: 1,
                          ),
                        ),
                      ),
                      child: content,
                    ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    dynamic song,
    dynamic playerState,
    dynamic audioController,
  ) {
    // Sizes based on compact mode
    final height = compact ? 110.0 : AppConstants.miniPlayerHeight;
    final artworkSize = compact ? 70.0 : 90.0;
    final progressHeight = compact ? 2.0 : 3.0;
    final titleSize = compact ? 14.0 : 15.0;
    final subtitleSize = compact ? 12.0 : 14.0;
    final iconSize = compact ? 24.0 : 30.0;
    final playIconSize = compact ? 28.0 : 35.0;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: playerState.progress,
            backgroundColor: context.colors.primary.withValues(alpha: 0.35),
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            minHeight: progressHeight,
          ),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 10),
              child: Row(
                children: [
                  // Artwork
                  Container(
                    width: artworkSize,
                    height: artworkSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ThemeConstants.radiusSm,
                      ),
                      color: context.colors.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ThemeConstants.radiusSm,
                      ),
                      child: song.artworkPath != null
                          ? Image.file(
                              File(song.artworkPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildPlaceholder(context, compact),
                            )
                          : _buildPlaceholder(context, compact),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Song info and controls
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Song info
                        Text(
                          song.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: titleSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: context.colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${song.album}${song.year != null ? ' • ${song.year}' : ''}',
                          style: TextStyle(
                            fontSize: compact ? 11 : 13,
                            color: context.colors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                song.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: song.isFavorite
                                    ? context.colors.error
                                    : null,
                              ),
                              iconSize: compact ? 20 : 24,
                              onPressed: () => ref
                                  .read(songsProvider.notifier)
                                  .toggleFavorite(song.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded),
                              iconSize: iconSize,
                              onPressed: () => audioController.skipToPrevious(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Container(
                              decoration: compact
                                  ? BoxDecoration(
                                      color: context.colors.primary,
                                      shape: BoxShape.circle,
                                    )
                                  : null,
                              child: IconButton(
                                icon: Icon(
                                  playerState.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: compact
                                      ? context.colors.backgroundPrimary
                                      : null,
                                ),
                                iconSize: playIconSize,
                                onPressed: () =>
                                    audioController.togglePlayPause(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded),
                              iconSize: iconSize,
                              onPressed: () => audioController.skipToNext(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Text(
                              song.durationFormatted,
                              style: TextStyle(
                                fontSize: compact ? 11 : 13,
                                color: context.colors.textSecondary,
                              ),
                            ),
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
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isCompact) {
    return Container(
      color: context.colors.card,
      child: Icon(
        Icons.music_note_rounded,
        color: context.colors.textSecondary.withValues(alpha: 0.5),
        size: isCompact ? 28 : 20,
      ),
    );
  }
}
