import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/theme_constants.dart';
import '../../data/models/library_category.dart';
import '../../data/models/song.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';
import 'browse_screen.dart';
import 'songs_list_screen.dart';

/// Provider to track if library is in grid or list view mode
final libraryViewModeProvider = StateProvider<bool>((ref) => true);

/// Library screen with category-based navigation
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final playlistsAsync = ref.watch(playlistsProvider);
    final artists = ref.watch(artistsProvider);
    final albums = ref.watch(albumsProvider);
    final genres = ref.watch(genresProvider);
    final years = ref.watch(yearsProvider);
    final favorites = ref.watch(favoriteSongsProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final isGridView = ref.watch(libraryViewModeProvider);

    final totalSongs = songsAsync.when(
      data: (songs) => songs.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final playlistCount = playlistsAsync.when(
      data: (playlists) => playlists.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    // Build counts map for subtitles
    final counts = {
      LibraryCategory.allSongs: totalSongs,
      LibraryCategory.playlists: playlistCount,
      LibraryCategory.artists: artists.length,
      LibraryCategory.albums: albums.length,
      LibraryCategory.genres: genres.length,
      LibraryCategory.years: years.length,
      LibraryCategory.favorites: favorites.length,
      LibraryCategory.recentlyAdded: recentlyAdded.length,
      LibraryCategory.recentlyPlayed: recentlyPlayed.length,
    };

    // Main categories (first 7)
    final mainCategories = LibraryCategory.values
        .where(
          (c) =>
              c != LibraryCategory.favorites &&
              c != LibraryCategory.recentlyAdded &&
              c != LibraryCategory.recentlyPlayed,
        )
        .toList();

    // Activity categories (last 2)
    final activityCategories = [
      LibraryCategory.favorites,
      LibraryCategory.recentlyAdded,
      LibraryCategory.recentlyPlayed,
    ];

    return CustomScrollView(
      slivers: [
        // Header with toggle button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(ThemeConstants.spacingLg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Library',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalSongs songs in your collection',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Grid/List toggle button
                IconButton(
                  onPressed: () {
                    ref.read(libraryViewModeProvider.notifier).state =
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

        // Main Categories - Grid or List view based on toggle
        if (isGridView)
          _buildGridView(context, ref, mainCategories, counts)
        else
          _buildListView(context, ref, mainCategories, counts),

        // Activity section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ThemeConstants.spacingLg,
              ThemeConstants.spacingLg,
              ThemeConstants.spacingLg,
              ThemeConstants.spacingSm,
            ),
            child: Text(
              'ACTIVITY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),

        // Activity categories - Grid or List view based on toggle
        if (isGridView)
          _buildGridView(context, ref, activityCategories, counts)
        else
          _buildListView(context, ref, activityCategories, counts),
      ],
    );
  }

  Widget _buildGridView(
    BuildContext context,
    WidgetRef ref,
    List<LibraryCategory> categories,
    Map<LibraryCategory, int> counts,
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
        delegate: SliverChildListDelegate(
          categories.map((category) {
            final config = CategoryConfig.get(category);
            final count = counts[category] ?? 0;

            return GradientCard(
              icon: config.icon,
              customIcon: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
                  child: Icon(config.icon, color: config.color, size: 28),
                ),
              ),
              title: config.title,
              subtitle: _getSubtitle(category, count),
              color: config.color,
              onTap: () => _navigateToCategory(context, ref, category, counts),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<LibraryCategory> categories,
    Map<LibraryCategory, int> counts,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: ThemeConstants.spacingLg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final category = categories[index];
          final config = CategoryConfig.get(category);
          final count = counts[category] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: ThemeConstants.spacingSm),
            child: LibraryListTile(
              icon: config.icon,
              title: config.title,
              subtitle: _getSubtitle(category, count),
              color: config.color,
              onTap: () => _navigateToCategory(context, ref, category, counts),
            ),
          );
        }, childCount: categories.length),
      ),
    );
  }

  String _getSubtitle(LibraryCategory category, int count) {
    switch (category) {
      case LibraryCategory.allSongs:
        return '$count songs';
      case LibraryCategory.playlists:
        return '$count playlists';
      case LibraryCategory.artists:
        return '$count artists';
      case LibraryCategory.albums:
        return '$count albums';
      case LibraryCategory.genres:
        return '$count genres';
      case LibraryCategory.years:
        return '$count years';
      case LibraryCategory.favorites:
      case LibraryCategory.recentlyAdded:
      case LibraryCategory.recentlyPlayed:
        return '$count songs';
    }
  }

  void _navigateToCategory(
    BuildContext context,
    WidgetRef ref,
    LibraryCategory category,
    Map<LibraryCategory, int> counts,
  ) {
    final config = CategoryConfig.get(category);

    switch (category) {
      // Navigate to BrowseScreen for browsing categories
      case LibraryCategory.artists:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BrowseScreen(type: BrowseType.artists),
          ),
        );
        break;

      case LibraryCategory.albums:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BrowseScreen(type: BrowseType.albums),
          ),
        );
        break;

      case LibraryCategory.genres:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BrowseScreen(type: BrowseType.genres),
          ),
        );
        break;

      case LibraryCategory.years:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BrowseScreen(type: BrowseType.years),
          ),
        );
        break;

      case LibraryCategory.playlists:
        // Navigate to existing playlists screen
        Navigator.pushNamed(context, '/playlists');
        break;

      // Navigate directly to songs list for song-based categories
      case LibraryCategory.allSongs:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongsListScreen(
              title: config.title,
              subtitle: '${counts[LibraryCategory.allSongs] ?? 0} songs',
              icon: config.icon,
              color: config.color,
              songs: ref
                  .watch(songsProvider)
                  .when(
                    data: (songs) => songs,
                    loading: () => <Song>[],
                    error: (_, __) => <Song>[],
                  ),
            ),
          ),
        );
        break;

      case LibraryCategory.favorites:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongsListScreen(
              title: config.title,
              subtitle: '${counts[LibraryCategory.favorites] ?? 0} songs',
              icon: config.icon,
              color: config.color,
              songs: ref.watch(favoriteSongsProvider),
            ),
          ),
        );
        break;

      case LibraryCategory.recentlyAdded:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongsListScreen(
              title: config.title,
              subtitle: '${counts[LibraryCategory.recentlyAdded] ?? 0} songs',
              icon: config.icon,
              color: config.color,
              songs: ref.watch(recentlyAddedProvider),
            ),
          ),
        );
        break;

      case LibraryCategory.recentlyPlayed:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongsListScreen(
              title: config.title,
              subtitle: '${counts[LibraryCategory.recentlyPlayed] ?? 0} songs',
              icon: config.icon,
              color: config.color,
              songs: ref.watch(recentlyPlayedProvider),
            ),
          ),
        );
        break;
    }
  }
}
