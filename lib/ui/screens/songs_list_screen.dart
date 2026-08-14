import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../data/models/song.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

/// A screen that displays a list of songs with play functionality
/// Used for showing songs from artists, albums, genres, years, etc.
class SongsListScreen extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Song> songs;
  final String? artworkPath;

  const SongsListScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.songs,
    this.artworkPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioController = ref.read(audioControllerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with artwork/icon
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color.withValues(alpha: 0.3),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.4),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Artwork or icon
                      if (artworkPath != null)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              ThemeConstants.radiusMd,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ThemeConstants.radiusMd,
                            ),
                            child: Image.file(
                              File(artworkPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildIconContainer(),
                            ),
                          ),
                        )
                      else
                        _buildIconContainer(),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (songs.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded),
                  onPressed: () {
                    final shuffled = List<Song>.from(songs)..shuffle();
                    audioController.playSongs(shuffled);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_filled_rounded),
                  iconSize: 40,
                  color: context.colors.primary,
                  onPressed: () => audioController.playSongs(songs),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),

          // Songs list
          if (songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_off_rounded,
                      size: 64,
                      color: context.colors.textSecondary.withValues(
                        alpha: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No songs found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final song = songs[index];
                return SongTile(
                  song: song,
                  onTap: () =>
                      audioController.playSongs(songs, startIndex: index),
                );
              }, childCount: songs.length),
            ),
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      ),
      child: Icon(icon, color: color, size: 40),
    );
  }
}
