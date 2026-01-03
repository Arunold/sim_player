import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../data/models/song.dart';
import '../../core/constants/theme_constants.dart';
import '../../providers/providers.dart';
import 'song_options_menu.dart';

/// A tile widget displaying song information
class SongTile extends ConsumerWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const SongTile({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if this song is currently playing
    final playerState = ref.watch(playerStateProvider);
    final isPlaying = playerState.valueOrNull?.isPlaying ?? false;
    final currentSong = ref.watch(currentSongProvider).valueOrNull;
    final isSelected = currentSong?.id == song.id;

    return ListTile(
      horizontalTitleGap: 10,
      selected: isSelected,
      selectedColor: context.colors.primary,
      selectedTileColor: context.colors.accent.withValues(alpha: 0.15),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingSm,
        vertical: ThemeConstants.spacingXs,
      ),
      leading: _buildArtwork(context, isSelected, isPlaying),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            '${song.album}${song.year != null ? ' • ${song.year}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: isSelected
                  ? context.colors.primary
                  : context.colors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: trailing ?? _buildTrailing(context, isSelected),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildArtwork(BuildContext context, bool isSelected, bool isPlaying) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
            color: ThemeConstants.darkCard,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
            child: _getAlbumArt(context, song.artworkPath),
          ),
        ),
        // Playing overlay with animation
        if (isSelected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
                color: Colors.black.withValues(alpha: 0.5),
              ),
              child: Center(
                child: PlayingIndicator(
                  color: context.colors.primary,
                  barCount: 5,
                  size: 40,
                  paused: !isPlaying,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _getAlbumArt(BuildContext context, String? artworkPath) {
    return artworkPath != null
        ? Image.file(
            File(artworkPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(context),
          )
        : _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: ThemeConstants.darkCard,
      child: Icon(
        Icons.music_note_rounded,
        color: context.colors.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          song.durationFormatted,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected
                ? context.colors.primary
                : context.colors.textSecondary,
          ),
        ),
        SongOptionsMenu(song: song),
      ],
    );
  }
}

/// Animated playing indicator with bouncing bars
class PlayingIndicator extends StatefulWidget {
  final Color color;
  final int barCount;
  final double size;
  final bool paused;

  const PlayingIndicator({
    super.key,
    this.color = Colors.white,
    this.barCount = 3,
    this.size = 16,
    this.paused = false,
  });

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (!widget.paused) {
      _startAnimations();
    }
  }

  void _initControllers() {
    _controllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void didUpdateWidget(PlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paused != widget.paused) {
      if (widget.paused) {
        for (final controller in _controllers) {
          controller.stop();
        }
      } else {
        for (final controller in _controllers) {
          controller.repeat(reverse: true);
        }
      }
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = widget.size / (widget.barCount * 2);
    final spacing = barWidth / 2;

    return SizedBox(
      width: widget.size,
      height: widget.size * 0.75,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: spacing / 2),
                width: barWidth,
                height: widget.size * 0.75 * _animations[index].value,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
