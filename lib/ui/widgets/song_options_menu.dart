import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../providers/providers.dart';

/// Available options for song context menu
enum SongOption {
  playNext,
  addToQueue,
  addToPlaylist,
  toggleFavorite,
  goToArtist,
  goToAlbum,
  gotToComposer,
  songInfo,
  // removeFromPlaylist,
  // share,
  // delete,
}

/// Configuration for a menu option
class SongOptionConfig {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final bool isDanger;

  const SongOptionConfig({
    required this.icon,
    required this.label,
    this.iconColor,
    this.isDanger = false,
  });
}

/// Reusable popup menu for song actions
class SongOptionsMenu extends ConsumerWidget {
  final Song song;
  final Set<SongOption> options;
  final String? playlistId;
  final void Function(SongOption option)? onOptionSelected;
  final Widget? icon;
  final double? iconSize;
  final Color? iconColor;
  final PopupMenuPosition? position;

  const SongOptionsMenu({
    super.key,
    required this.song,
    this.options = defaultOptions,
    this.playlistId,
    this.onOptionSelected,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.position = PopupMenuPosition.under,
  });

  /// Default options for general song lists
  static const Set<SongOption> defaultOptions = {
    SongOption.playNext,
    SongOption.addToQueue,
    SongOption.addToPlaylist,
    SongOption.toggleFavorite,
    SongOption.goToArtist,
    SongOption.goToAlbum,
    SongOption.songInfo,
  };

  /* 
  /// Options for playlist screens
  static const Set<SongOption> playlistOptions = {
    SongOption.playNext,
    SongOption.addToQueue,
    SongOption.toggleFavorite,
    // SongOption.removeFromPlaylist,
    SongOption.goToArtist,
    SongOption.goToAlbum,
    SongOption.songInfo,
  };

  /// Options for queue
  static const Set<SongOption> queueOptions = {
    SongOption.toggleFavorite,
    SongOption.addToPlaylist,
    SongOption.goToArtist,
    SongOption.goToAlbum,
    SongOption.songInfo,
  };

  /// Minimal options (e.g., for now playing)
  static const Set<SongOption> minimalOptions = {
    SongOption.addToPlaylist,
    SongOption.toggleFavorite,
    SongOption.goToArtist,
    SongOption.goToAlbum,
  };
 */

  SongOptionConfig _getConfig(
    BuildContext context,
    SongOption option,
    bool isFavorite,
  ) {
    switch (option) {
      case SongOption.playNext:
        return const SongOptionConfig(
          icon: Icons.playlist_play_rounded,
          label: 'Play next',
        );
      case SongOption.addToQueue:
        return const SongOptionConfig(
          icon: Icons.queue_music_rounded,
          label: 'Add to queue',
        );
      case SongOption.addToPlaylist:
        return const SongOptionConfig(
          icon: Icons.playlist_add_rounded,
          label: 'Add to playlist',
        );
      case SongOption.toggleFavorite:
        return SongOptionConfig(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          iconColor: isFavorite ? context.colors.error : null,
        );
      case SongOption.goToArtist:
        return const SongOptionConfig(
          icon: Icons.person_rounded,
          label: 'Go to artist',
        );
      case SongOption.goToAlbum:
        return const SongOptionConfig(
          icon: Icons.album_rounded,
          label: 'Go to album',
        );
      case SongOption.gotToComposer:
        return const SongOptionConfig(
          icon: Icons.piano_rounded,
          label: 'Go to composer',
        );
      case SongOption.songInfo:
        return const SongOptionConfig(
          icon: Icons.info_outline_rounded,
          label: 'Song info',
        );
      // case SongOption.removeFromPlaylist:
      //   return const SongOptionConfig(
      //     icon: Icons.remove_circle_outline_rounded,
      //     label: 'Remove from playlist',
      //     iconColor: context.colors.error,
      //   );
      // case SongOption.share:
      //   return const SongOptionConfig(
      //     icon: Icons.share_rounded,
      //     label: 'Share',
      //   );
      // case SongOption.delete:
      //   return const SongOptionConfig(
      //     icon: Icons.delete_outline_rounded,
      //     label: 'Delete',
      //     iconColor: context.colors.error,
      //     isDanger: true,
      //   );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch songsProvider to get reactive isFavorite status
    final songsAsync = ref.watch(songsProvider);
    final currentSong =
        songsAsync.whenOrNull(
          data: (songs) => songs.where((s) => s.id == song.id).firstOrNull,
        ) ??
        song;

    return PopupMenuButton<SongOption>(
      icon: icon ?? Icon(Icons.more_vert_rounded, size: iconSize ?? 20),
      tooltip: 'More options',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      ),
      color: iconColor ?? context.colors.card,
      elevation: 8,
      position: position,
      itemBuilder: (context) => options.map((option) {
        final config = _getConfig(context, option, currentSong.isFavorite);
        return PopupMenuItem<SongOption>(
          value: option,
          child: Row(
            children: [
              Icon(
                config.icon,
                size: 20,
                color: config.iconColor ?? context.colors.textPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                config.label,
                style: TextStyle(
                  color: config.isDanger
                      ? context.colors.error
                      : context.colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onSelected: (option) => _handleOption(context, ref, option),
    );
  }

  void _handleOption(BuildContext context, WidgetRef ref, SongOption option) {
    // Call custom handler if provided
    if (onOptionSelected != null) {
      onOptionSelected!(option);
    }

    final audioController = ref.read(audioControllerProvider);

    switch (option) {
      case SongOption.playNext:
        audioController.addToQueueNext(song);
        _showSnackBar(context, 'Added to play next');
        break;
      case SongOption.addToQueue:
        audioController.addToQueue(song);
        _showSnackBar(context, 'Added to queue');
        break;
      case SongOption.addToPlaylist:
        _showAddToPlaylistDialog(context, ref);
        break;
      case SongOption.toggleFavorite:
        ref.read(songsProvider.notifier).toggleFavorite(song.id);
        break;
      case SongOption.goToArtist:
        // TODO: Navigate to artist screen
        _showSnackBar(context, 'Go to ${song.artist}');
        break;
      case SongOption.goToAlbum:
        // TODO: Navigate to album screen
        _showSnackBar(context, 'Go to ${song.album}');
        break;
      case SongOption.gotToComposer:
        // TODO: Navigate to album screen
        _showSnackBar(context, 'Go to ${song.album}');
        break;
      case SongOption.songInfo:
        _showSongInfoDialog(context);
        break;
      // case SongOption.removeFromPlaylist:
      //   if (playlistId != null) {
      //     ref.read(playlistsProvider.notifier).removeSongFromPlaylist(
      //       playlistId!,
      //       song.id,
      //     );
      //     _showSnackBar(context, 'Removed from playlist');
      //   }
      //   break;
      // case SongOption.share:
      //   // TODO: Implement share
      //   break;
      // case SongOption.delete:
      //   _showDeleteConfirmation(context, ref);
      //   break;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref) {
    final playlists = ref.read(playlistsProvider).when(
      data: (value) => value,
      loading: () => <Playlist>[],
      error: (_, _) => <Playlist>[],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.card,
        title: const Text('Add to playlist'),
        content: playlists.isEmpty
            ? const Text('No playlists yet. Create one first!')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: const Icon(Icons.playlist_play_rounded),
                      title: Text(playlist.name),
                      subtitle: Text('${playlist.songCount} songs'),
                      onTap: () {
                        ref
                            .read(playlistsProvider.notifier)
                            .addSongToPlaylist(playlist.id, song.id);
                        Navigator.pop(context);
                        _showSnackBar(context, 'Added to ${playlist.name}');
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.card,
        title: const Text('Delete song?'),
        content: Text('Are you sure you want to delete "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSongInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.card,
        title: const Text('Song info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(context, 'Title', song.title),
            _infoRow(context, 'Artist', song.artist),
            _infoRow(context, 'Album', song.album),
            if (song.year != null)
              _infoRow(context, 'Year', song.year.toString()),
            _infoRow(context, 'Duration', song.durationFormatted),
            _infoRow(context, 'Path', song.filePath),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
