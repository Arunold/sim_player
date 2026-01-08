import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Settings keys for Hive storage
class SettingsKeys {
  static const String boxName = 'settings';
  static const String themeMode = 'themeMode';
  static const String gaplessPlayback = 'gaplessPlayback';
  static const String playbackSpeed = 'playbackSpeed';
  static const String musicFolders = 'musicFolders';
  static const String autoScanOnStartup = 'autoScanOnStartup';
  static const String skipSilence = 'skipSilence';
  static const String rememberLastPosition = 'rememberLastPosition';
  static const String showAlbumArtOnLockscreen = 'showAlbumArtOnLockscreen';
  static const String crossfadeDuration = 'crossfadeDuration';
  static const String minFileDuration = 'minFileDuration';
  // Audio settings
  static const String fadeOnPausePlay = 'fadeOnPausePlay';
  static const String audioDucking = 'audioDucking';
  static const String replayGain = 'replayGain';
  // Headset/Bluetooth settings
  static const String autoPlayOnConnect = 'autoPlayOnConnect';
  static const String pauseOnDisconnect = 'pauseOnDisconnect';
  // Queue settings
  static const String keepShuffleQueue = 'keepShuffleQueue';
  static const String resumeOnRestart = 'resumeOnRestart';
  // UI settings
  static const String gridColumnCount = 'gridColumnCount';
  static const String showTrackNumbers = 'showTrackNumbers';
  static const String confirmExit = 'confirmExit';
  // Sleep timer
  static const String sleepTimerFinishTrack = 'sleepTimerFinishTrack';
}

/// Default music folders to scan
const List<String> defaultMusicFolders = [
  '/storage/emulated/0/Music',
  '/storage/emulated/0/Download',
  '/storage/emulated/0/Downloads',
];

/// Theme mode notifier for managing app theme
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Box _box;

  ThemeModeNotifier(this._box) : super(_loadInitialTheme(_box));

  static ThemeMode _loadInitialTheme(Box box) {
    final saved = box.get(SettingsKeys.themeMode, defaultValue: 'dark');
    return _stringToThemeMode(saved);
  }

  static ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _box.put(SettingsKeys.themeMode, _themeModeToString(mode));
  }

  void toggleDarkMode() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

/// Settings box provider
final settingsBoxProvider = FutureProvider<Box>((ref) async {
  return await Hive.openBox(SettingsKeys.boxName);
});

/// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => ThemeModeNotifier(box),
    loading: () => ThemeModeNotifier(Hive.box(SettingsKeys.boxName)),
    error: (_, __) => ThemeModeNotifier(Hive.box(SettingsKeys.boxName)),
  );
});

/// Gapless playback provider
final gaplessPlaybackProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.gaplessPlayback, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Playback speed provider
final playbackSpeedProvider = StateProvider<double>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.playbackSpeed, defaultValue: 1.0),
    loading: () => 1.0,
    error: (_, __) => 1.0,
  );
});

/// Music folders notifier for managing scan directories
class MusicFoldersNotifier extends StateNotifier<List<String>> {
  final Box _box;

  MusicFoldersNotifier(this._box) : super(_loadInitialFolders(_box));

  static List<String> _loadInitialFolders(Box box) {
    final saved = box.get(SettingsKeys.musicFolders);
    if (saved == null) {
      return List<String>.from(defaultMusicFolders);
    }
    return List<String>.from(saved as List);
  }

  void addFolder(String path) {
    if (!state.contains(path)) {
      state = [...state, path];
      _box.put(SettingsKeys.musicFolders, state);
    }
  }

  void removeFolder(String path) {
    state = state.where((f) => f != path).toList();
    _box.put(SettingsKeys.musicFolders, state);
  }

  void resetToDefaults() {
    state = List<String>.from(defaultMusicFolders);
    _box.put(SettingsKeys.musicFolders, state);
  }
}

/// Music folders provider
final musicFoldersProvider =
    StateNotifierProvider<MusicFoldersNotifier, List<String>>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => MusicFoldersNotifier(box),
    loading: () => MusicFoldersNotifier(Hive.box(SettingsKeys.boxName)),
    error: (_, __) => MusicFoldersNotifier(Hive.box(SettingsKeys.boxName)),
  );
});

/// Auto-scan on startup provider
final autoScanOnStartupProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.autoScanOnStartup, defaultValue: false),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Skip silence provider
final skipSilenceProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.skipSilence, defaultValue: false),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Remember last playback position provider
final rememberLastPositionProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.rememberLastPosition, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Show album art on lockscreen provider
final showAlbumArtOnLockscreenProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.showAlbumArtOnLockscreen, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Crossfade duration provider (in seconds, 0 = disabled)
final crossfadeDurationProvider = StateProvider<int>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.crossfadeDuration, defaultValue: 0),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Minimum file duration to include (in seconds)
final minFileDurationProvider = StateProvider<int>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.minFileDuration, defaultValue: 30),
    loading: () => 30,
    error: (_, __) => 30,
  );
});

/// Fade on pause/play provider
final fadeOnPausePlayProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.fadeOnPausePlay, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Audio ducking provider (lower volume for notifications)
final audioDuckingProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.audioDucking, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});

/// ReplayGain mode provider (off, track, album)
final replayGainProvider = StateProvider<String>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.replayGain, defaultValue: 'off'),
    loading: () => 'off',
    error: (_, __) => 'off',
  );
});

/// Auto-play on headset/bluetooth connect
final autoPlayOnConnectProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.autoPlayOnConnect, defaultValue: false),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Pause on headset/bluetooth disconnect
final pauseOnDisconnectProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.pauseOnDisconnect, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Keep shuffle queue on restart
final keepShuffleQueueProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.keepShuffleQueue, defaultValue: false),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Resume playback on app restart
final resumeOnRestartProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.resumeOnRestart, defaultValue: false),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Grid column count (2, 3, 4)
final gridColumnCountProvider = StateProvider<int>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.gridColumnCount, defaultValue: 2),
    loading: () => 2,
    error: (_, __) => 2,
  );
});

/// Show track numbers in lists
final showTrackNumbersProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.showTrackNumbers, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Confirm before exiting app
final confirmExitProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.confirmExit, defaultValue: false),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Sleep timer finish current track before stopping
final sleepTimerFinishTrackProvider = StateProvider<bool>((ref) {
  final boxAsync = ref.watch(settingsBoxProvider);
  return boxAsync.when(
    data: (box) => box.get(SettingsKeys.sleepTimerFinishTrack, defaultValue: true),
    loading: () => true,
    error: (_, __) => true,
  );
});
