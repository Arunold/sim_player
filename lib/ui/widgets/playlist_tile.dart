import 'package:flutter/material.dart';
import '../../data/models/playlist.dart';
import '../../core/constants/theme_constants.dart';

/// A tile widget displaying playlist information
class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const PlaylistTile({
    super.key,
    required this.playlist,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMd,
        vertical: ThemeConstants.spacingXs,
      ),
      leading: _buildArtwork(context),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${playlist.songCount} song${playlist.songCount != 1 ? 's' : ''}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textSecondary,
          ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildArtwork(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        gradient: LinearGradient(
          colors: [context.colors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.queue_music_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
