import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/theme_constants.dart';
import '../../providers/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Stats'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: songsAsync.when(
        data: (songs) {
          final totalSongs = songs.length;
          final totalDuration = songs.fold<Duration>(
            Duration.zero,
            (prev, song) => prev + (song.duration * song.playCount),
          );
          
          final favorites = songs.where((s) => s.isFavorite).length;

          return ListView(
            padding: const EdgeInsets.all(ThemeConstants.spacingLg),
            children: [
              _buildHeaderCard(context, totalSongs, totalDuration),
              const SizedBox(height: ThemeConstants.spacingLg),
              _buildStatTile(
                context,
                icon: Icons.favorite_rounded,
                title: 'Favorite Songs',
                value: favorites.toString(),
                color: context.colors.error,
              ),
              playlistsAsync.when(
                data: (playlists) => _buildStatTile(
                  context,
                  icon: Icons.queue_music_rounded,
                  title: 'Playlists',
                  value: playlists.length.toString(),
                  color: context.colors.primary,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => const Text('Error loading playlists'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, int totalSongs, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    return Container(
      padding: const EdgeInsets.all(ThemeConstants.spacingXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary,
            context.colors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: context.colors.backgroundPrimary,
                child: Icon(Icons.person_rounded, size: 32, color: context.colors.primary),
              ),
              const SizedBox(width: ThemeConstants.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Library',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalSongs Tracks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ThemeConstants.spacingXl),
          Text(
            'Total Listening Time',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$hours hrs $minutes mins',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: ThemeConstants.spacingMd),
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ThemeConstants.spacingSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: ThemeConstants.spacingMd),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
