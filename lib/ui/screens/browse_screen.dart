import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/library_category.dart';
import '../../data/models/song.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';
import 'songs_list_screen.dart';

/// Types of browsable content
enum BrowseType { artists, albums, genres, years }

/// Data item for browsing - represents an artist, album, genre, or year
class BrowseItem {
  final String id;
  final String title;
  final String subtitle;
  final String? artworkPath;
  final List<Song> songs;

  const BrowseItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.artworkPath,
    required this.songs,
  });
}

/// Provider to track if browse screen is in grid or list view mode
final browseViewModeProvider = StateProvider<bool>((ref) => true);

/// A unified screen for browsing artists, albums, genres, or years
/// Displays items in a grid/list and navigates to SongsListScreen on tap
class BrowseScreen extends ConsumerWidget {
  final BrowseType type;

  const BrowseScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _getConfig();
    final items = _getItems(ref);
    final isGridView = ref.watch(browseViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? _buildEmptyState(context, config)
          : CustomScrollView(
              slivers: [
                // Header with title, count and toggle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(ThemeConstants.spacingLg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                config.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${items.length} ${type.name}(s)',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Grid/List toggle button
                        IconButton(
                          onPressed: () {
                            ref.read(browseViewModeProvider.notifier).state =
                                !isGridView;
                          },
                          icon: Icon(
                            isGridView
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            color: context.colors.primary,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: context.colors.primary.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Grid or List view
                if (isGridView)
                  _buildGridSliver(context, items, config)
                else
                  _buildListSliver(context, items, config),
              ],
            ),
    );
  }

  CategoryConfig _getConfig() {
    switch (type) {
      case BrowseType.artists:
        return CategoryConfig.get(LibraryCategory.artists);
      case BrowseType.albums:
        return CategoryConfig.get(LibraryCategory.albums);
      case BrowseType.genres:
        return CategoryConfig.get(LibraryCategory.genres);
      case BrowseType.years:
        return CategoryConfig.get(LibraryCategory.years);
    }
  }

  List<BrowseItem> _getItems(WidgetRef ref) {
    switch (type) {
      case BrowseType.artists:
        final artists = ref.watch(artistsProvider);
        return artists.map((artist) {
          final songs = ref.watch(songsByArtistProvider(artist));
          return BrowseItem(
            id: artist,
            title: artist,
            subtitle: '${songs.length} song${songs.length != 1 ? 's' : ''}',
            artworkPath: songs.isNotEmpty ? songs.first.artworkPath : null,
            songs: songs,
          );
        }).toList();

      case BrowseType.albums:
        final albums = ref.watch(albumsProvider);
        return albums.map((album) {
          final songs = ref.watch(songsByAlbumProvider(album));
          final artist = songs.isNotEmpty ? songs.first.artist : '';
          return BrowseItem(
            id: album,
            title: album,
            subtitle: '$artist • ${songs.length} songs',
            artworkPath: songs.isNotEmpty ? songs.first.artworkPath : null,
            songs: songs,
          );
        }).toList();

      case BrowseType.genres:
        final genres = ref.watch(genresProvider);
        return genres.map((genre) {
          final songs = ref.watch(songsByGenreProvider(genre));
          return BrowseItem(
            id: genre,
            title: genre,
            subtitle: '${songs.length} song${songs.length != 1 ? 's' : ''}',
            artworkPath: songs.isNotEmpty ? songs.first.artworkPath : null,
            songs: songs,
          );
        }).toList();

      case BrowseType.years:
        final years = ref.watch(yearsProvider);
        return years.map((year) {
          final songs = ref.watch(songsByYearProvider(year));
          return BrowseItem(
            id: year.toString(),
            title: year.toString(),
            subtitle: '${songs.length} song${songs.length != 1 ? 's' : ''}',
            artworkPath: songs.isNotEmpty ? songs.first.artworkPath : null,
            songs: songs,
          );
        }).toList();
    }
  }

  Widget _buildGridSliver(
    BuildContext context,
    List<BrowseItem> items,
    CategoryConfig config,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: ThemeConstants.spacingLg),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: ThemeConstants.spacingMd,
          crossAxisSpacing: ThemeConstants.spacingMd,
          childAspectRatio: 1.3,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return GradientCard(
            icon: config.icon,
            title: item.title,
            subtitle: item.subtitle,
            color: config.color,
            customIcon: _buildCustomIcon(context, item, config),
            onTap: () => _navigateToSongs(context, item, config),
          );
        }, childCount: items.length),
      ),
    );
  }

  Widget _buildListSliver(
    BuildContext context,
    List<BrowseItem> items,
    CategoryConfig config,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: ThemeConstants.spacingLg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: ThemeConstants.spacingSm),
            child: LibraryListTile(
              icon: config.icon,
              title: item.title,
              subtitle: item.subtitle,
              color: config.color,
              customIcon: _buildListCustomIcon(context, item, config),
              onTap: () => _navigateToSongs(context, item, config),
            ),
          );
        }, childCount: items.length),
      ),
    );
  }

  Widget? _buildCustomIcon(
    BuildContext context,
    BrowseItem item,
    CategoryConfig config,
  ) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        child: item.artworkPath != null
            ? Image.file(
                File(item.artworkPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(config.icon, color: config.color, size: 28),
              )
            : Icon(config.icon, color: config.color, size: 28),
      ),
    );
  }

  Widget? _buildListCustomIcon(
    BuildContext context,
    BrowseItem item,
    CategoryConfig config,
  ) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
        child: item.artworkPath != null
            ? Image.file(
                File(item.artworkPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(config.icon, color: config.color, size: 22),
              )
            : Icon(config.icon, color: config.color, size: 22),
      ),
    );
  }

  void _navigateToSongs(
    BuildContext context,
    BrowseItem item,
    CategoryConfig config,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongsListScreen(
          title: item.title,
          subtitle: item.subtitle,
          icon: config.icon,
          color: config.color,
          songs: item.songs,
          artworkPath: item.artworkPath,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, CategoryConfig config) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            config.icon,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${config.title.toLowerCase()} found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
