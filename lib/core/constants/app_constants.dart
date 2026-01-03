/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'SimPlayer';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String songsBox = 'songs_box';
  static const String playlistsBox = 'playlists_box';
  static const String settingsBox = 'settings_box';
  static const String queueBox = 'queue_box';

  // Hive Type IDs
  static const int songTypeId = 0;
  static const int playlistTypeId = 1;
  static const int playerStateTypeId = 2;

  // Audio Settings
  static const double defaultVolume = 1.0;
  static const double defaultSpeed = 1.0;
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;
  static const double speedStep = 0.1;

  // Supported Audio Formats
  static const List<String> supportedAudioFormats = [
    'mp3',
    'wav',
    'flac',
    'aac',
    'm4a',
    'ogg',
    'wma',
    'opus',
  ];

  // File Scanner
  static const int scanBatchSize = 20;
  static const Duration scanDebounce = Duration(milliseconds: 300);

  // UI Constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const double miniPlayerHeight = 72.0;
  static const double bottomNavHeight = 80.0;

  // Artwork
  static const double artworkThumbnailSize = 56.0;
  static const double artworkMediumSize = 200.0;
  static const double artworkLargeSize = 300.0;

  // Search
  static const int searchDebounceMs = 300;
  static const int minSearchLength = 2;
  static const int maxRecentSearches = 10;

  // Pagination
  static const int defaultPageSize = 50;
  static const int maxQueueSize = 1000;
}
