import 'package:flutter/material.dart';

/// Library category types for organizing music collection
enum LibraryCategory {
  allSongs,
  playlists,
  artists,
  albums,
  genres,
  years,
  favorites,

  // Activity-based categories
  recentlyAdded,
  recentlyPlayed,
}

/// Category configuration data containing display properties
class CategoryConfig {
  final String title;
  final IconData icon;
  final Color color;

  const CategoryConfig({
    required this.title,
    required this.icon,
    required this.color,
  });

  /// Static configurations for all categories
  static final Map<LibraryCategory, CategoryConfig> configs = {
    LibraryCategory.allSongs: CategoryConfig(
      title: 'All Songs',
      icon: Icons.music_note_rounded,
      color: Colors.blue,
    ),
    LibraryCategory.playlists: CategoryConfig(
      title: 'Playlists',
      icon: Icons.playlist_play_rounded,
      color: Colors.purple,
    ),
    LibraryCategory.artists: CategoryConfig(
      title: 'Artists',
      icon: Icons.person_rounded,
      color: Colors.orange,
    ),
    LibraryCategory.albums: CategoryConfig(
      title: 'Albums',
      icon: Icons.album_rounded,
      color: Colors.teal,
    ),
    LibraryCategory.genres: CategoryConfig(
      title: 'Genres',
      icon: Icons.category_rounded,
      color: Colors.pink,
    ),
    LibraryCategory.years: CategoryConfig(
      title: 'Years',
      icon: Icons.calendar_today_rounded,
      color: Colors.indigo,
    ),

    // Activity-based categories configurations
    LibraryCategory.favorites: CategoryConfig(
      title: 'Favorites',
      icon: Icons.favorite_rounded,
      color: Colors.red,
    ),
    LibraryCategory.recentlyAdded: CategoryConfig(
      title: 'Recently Added',
      icon: Icons.access_time_rounded,
      color: Colors.green,
    ),
    LibraryCategory.recentlyPlayed: CategoryConfig(
      title: 'Recently Played',
      icon: Icons.history_rounded,
      color: Colors.amber,
    ),
  };

  /// Get configuration for a specific category
  static CategoryConfig get(LibraryCategory category) => configs[category]!;
}
