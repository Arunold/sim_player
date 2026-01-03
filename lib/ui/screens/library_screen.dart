import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

/// Library screen showing all songs, with scan functionality
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(songsProvider);
    final artists = ref.watch(artistsProvider);
    final albums = ref.watch(albumsProvider);
    final audioController = ref.read(audioControllerProvider);

    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Songs'),
            Tab(text: 'Artists'),
            Tab(text: 'Albums'),
            Tab(text: 'Favorites'),
          ],
          indicatorColor: context.colors.primary,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textSecondary,
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // All Songs tab
              songsAsync.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.music_note_rounded,
                      message: 'No songs found',
                      action: 'Scan a folder to add music',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return SongTile(
                        song: song,
                        onTap: () =>
                            audioController.playSongs(songs, startIndex: index),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              // Artists tab
              _buildArtistsList(artists),
              // Albums tab
              _buildAlbumsList(albums),
              // Favorites tab
              _buildFavoritesList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(action, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildArtistsList(List<String> artists) {
    if (artists.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_rounded,
        message: 'No artists found',
        action: 'Scan a folder to add music',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final songCount = ref.watch(songsByArtistProvider(artist)).length;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.card,
            child: Text(
              artist[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colors.primary,
              ),
            ),
          ),
          title: Text(artist),
          subtitle: Text('$songCount song${songCount != 1 ? 's' : ''}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showArtistSongs(context, artist),
        );
      },
    );
  }

  Widget _buildAlbumsList(List<String> albums) {
    if (albums.isEmpty) {
      return _buildEmptyState(
        icon: Icons.album_rounded,
        message: 'No albums found',
        action: 'Scan a folder to add music',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final songs = ref.watch(songsByAlbumProvider(album));
        final artist = songs.isNotEmpty ? songs.first.artist : '';

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.album_rounded, color: context.colors.primary),
          ),
          title: Text(album, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '$artist • ${songs.length} song${songs.length != 1 ? 's' : ''}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showAlbumSongs(context, album),
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    final favorites = ref.watch(favoriteSongsProvider);
    final audioController = ref.read(audioControllerProvider);

    if (favorites.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_rounded,
        message: 'No favorites yet',
        action: 'Tap the heart icon on songs to add them',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        return SongTile(
          song: song,
          onTap: () => audioController.playSongs(favorites, startIndex: index),
        );
      },
    );
  }

  void _showArtistSongs(BuildContext context, String artist) {
    final songs = ref.read(songsByArtistProvider(artist));
    final audioController = ref.read(audioControllerProvider);

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
                  CircleAvatar(
                    backgroundColor: context.colors.primary,
                    radius: 24,
                    child: Text(
                      artist[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artist,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${songs.length} song${songs.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled_rounded),
                    iconSize: 48,
                    color: context.colors.primary,
                    onPressed: () {
                      Navigator.pop(context);
                      audioController.playSongs(songs);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongTile(
                    song: song,
                    onTap: () {
                      Navigator.pop(context);
                      audioController.playSongs(songs, startIndex: index);
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

  void _showAlbumSongs(BuildContext context, String album) {
    final songs = ref.read(songsByAlbumProvider(album));
    final audioController = ref.read(audioControllerProvider);
    final artist = songs.isNotEmpty ? songs.first.artist : '';

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
                      color: context.colors.card,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.album_rounded,
                      color: context.colors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$artist • ${songs.length} song${songs.length != 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.play_circle_filled_rounded),
                    iconSize: 48,
                    color: context.colors.primary,
                    onPressed: () {
                      Navigator.pop(context);
                      audioController.playSongs(songs);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongTile(
                    song: song,
                    onTap: () {
                      Navigator.pop(context);
                      audioController.playSongs(songs, startIndex: index);
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
}
