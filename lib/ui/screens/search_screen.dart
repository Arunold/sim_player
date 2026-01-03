import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

/// Search screen for searching songs, artists, albums
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus on the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final filteredSongs = ref.watch(filteredSongsProvider);
    final audioController = ref.read(audioControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(ThemeConstants.spacingMd),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Search songs, artists, albums...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: context.colors.textSecondary,
                        ),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            const Divider(height: 1),
            // Results
            Expanded(
              child: query.isEmpty
                  ? _buildRecentSearches(context)
                  : filteredSongs.isEmpty
                  ? _buildNoResults(context)
                  : ListView.builder(
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        return SongTile(
                          song: song,
                          onTap: () => audioController.playSongs(
                            filteredSongs,
                            startIndex: index,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    // TODO: Implement recent searches with persistence
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for music',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find songs, artists, and albums',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
