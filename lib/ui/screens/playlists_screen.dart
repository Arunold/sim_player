import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../data/models/playlist.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

/// Playlists screen showing all playlists
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return CustomScrollView(
      slivers: [
        // Add button as a header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ThemeConstants.spacingMd,
              vertical: ThemeConstants.spacingSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showCreatePlaylistDialog(context, ref),
                  tooltip: 'Create Playlist',
                ),
              ],
            ),
          ),
        ),
        playlistsAsync.when(
          data: (playlists) {
            if (playlists.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        size: 80,
                        color: context.colors.textSecondary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playlists yet',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: context.colors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first playlist',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showCreatePlaylistDialog(context, ref),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create Playlist'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final playlist = playlists[index];
                return PlaylistTile(
                  playlist: playlist,
                  onTap: () => _showPlaylistDetail(context, ref, playlist),
                  onLongPress: () => _showPlaylistOptions(
                    context,
                    ref,
                    playlist.id,
                    playlist.name,
                  ),
                );
              }, childCount: playlists.length),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              SliverFillRemaining(child: Center(child: Text('Error: $e'))),
        ),
        // Bottom spacing
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(playlistsProvider.notifier)
                    .createPlaylist(name: controller.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String playlistName,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(context).pop();
                _showRenameDialog(context, ref, playlistId, playlistName);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: context.colors.error),
              title: Text(
                'Delete',
                style: TextStyle(color: context.colors.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ref
                    .read(playlistsProvider.notifier)
                    .deletePlaylist(playlistId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await ref
                    .read(playlistsProvider.notifier)
                    .renamePlaylist(playlistId, controller.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistDetail(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) {
    final songsAsync = ref.read(songsProvider);
    final audioController = ref.read(audioControllerProvider);

    // Get songs in the playlist
    final playlistSongs = songsAsync.when(
      data: (allSongs) =>
          allSongs.where((s) => playlist.songIds.contains(s.id)).toList(),
      loading: () => <dynamic>[],
      error: (_, __) => <dynamic>[],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(ThemeConstants.spacingMd),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.colors.primary, context.colors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: context.colors.textPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${playlistSongs.length} song${playlistSongs.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (playlistSongs.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.play_circle_filled_rounded),
                      iconSize: 48,
                      color: context.colors.primary,
                      onPressed: () {
                        Navigator.pop(context);
                        audioController.playSongs(playlistSongs.cast());
                      },
                    ),
                ],
              ),
            ),
            const Divider(),
            if (playlistSongs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 48,
                        color: context.colors.textSecondary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No songs in this playlist',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddSongsToPlaylist(context, ref, playlist.id);
                        },
                        child: const Text('Add songs'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: playlistSongs.length,
                  itemBuilder: (context, index) {
                    final song = playlistSongs[index];
                    return SongTile(
                      song: song,
                      onTap: () {
                        Navigator.pop(context);
                        audioController.playSongs(
                          playlistSongs.cast(),
                          startIndex: index,
                        );
                      },
                      onLongPress: () {
                        _showRemoveSongDialog(
                          context,
                          ref,
                          playlist.id,
                          song.id,
                        );
                      },
                    );
                  },
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(ThemeConstants.spacingMd),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddSongsToPlaylist(context, ref, playlist.id);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Songs'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSongsToPlaylist(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
  ) {
    final songsAsync = ref.read(songsProvider);
    final allSongs = songsAsync.when(
      data: (songs) => songs,
      loading: () => <dynamic>[],
      error: (_, __) => <dynamic>[],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(ThemeConstants.spacingMd),
              child: Text(
                'Add Songs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(),
            if (allSongs.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No songs available. Scan your library first.'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: allSongs.length,
                  itemBuilder: (context, index) {
                    final song = allSongs[index];
                    return SongTile(
                      song: song,
                      onTap: () async {
                        await ref
                            .read(playlistsProvider.notifier)
                            .addSongToPlaylist(playlistId, song.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added "${song.title}" to playlist',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showRemoveSongDialog(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
    String songId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: const Text('Remove this song from the playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(playlistsProvider.notifier)
                  .removeSongFromPlaylist(playlistId, songId);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // Close the playlist detail as well
              }
            },
            child: Text(
              'Remove',
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
  }
}
