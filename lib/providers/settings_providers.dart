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

/// Default music folders to scan (empty defaults to platform specific dirs)
const List<String> defaultMusicFolders = [];

class SettingsValueNotifier<T> extends Notifier<T> {
  SettingsValueNotifier(this._key, this._defaultValue);

  final String _key;
  final T _defaultValue;
  late final Box _box;

  @override
  T build() {
    final boxAsync = ref.watch(settingsBoxProvider);
    return boxAsync.when(
      data: (box) {
        _box = box;
        return _box.get(_key, defaultValue: _defaultValue) as T;
      },
      loading: () {
        _box = Hive.box(SettingsKeys.boxName);
        return _box.get(_key, defaultValue: _defaultValue) as T;
      },
      error: (_, _) {
        _box = Hive.box(SettingsKeys.boxName);
        return _box.get(_key, defaultValue: _defaultValue) as T;
      },
    );
  }

  void set(T value) {
    state = value;
    _box.put(_key, value);
  }
}

/// Theme mode notifier for managing app theme
class ThemeModeNotifier extends Notifier<ThemeMode> {
  late final Box _box;

  @override
  ThemeMode build() {
    final boxAsync = ref.watch(settingsBoxProvider);
    return boxAsync.when(
      data: (box) {
        _box = box;
        return _loadInitialTheme(box);
      },
      loading: () {
        _box = Hive.box(SettingsKeys.boxName);
        return _loadInitialTheme(_box);
      },
      error: (_, _) {
        _box = Hive.box(SettingsKeys.boxName);
        return _loadInitialTheme(_box);
      },
    );
  }

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
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Gapless playback provider
final gaplessPlaybackProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.gaplessPlayback, true),
);

/// Playback speed provider
final playbackSpeedProvider = NotifierProvider<SettingsValueNotifier<double>, double>(
  () => SettingsValueNotifier<double>(SettingsKeys.playbackSpeed, 1.0),
);

/// Music folders notifier for managing scan directories
class MusicFoldersNotifier extends Notifier<List<String>> {
  late final Box _box;

  @override
  List<String> build() {
    final boxAsync = ref.watch(settingsBoxProvider);
    return boxAsync.when(
      data: (box) {
        _box = box;
        return _loadInitialFolders(box);
      },
      loading: () {
        _box = Hive.box(SettingsKeys.boxName);
        return _loadInitialFolders(_box);
      },
      error: (_, _) {
        _box = Hive.box(SettingsKeys.boxName);
        return _loadInitialFolders(_box);
      },
    );
  }

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
    NotifierProvider<MusicFoldersNotifier, List<String>>(MusicFoldersNotifier.new);

/// Auto-scan on startup provider
final autoScanOnStartupProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.autoScanOnStartup, false),
);

/// Skip silence provider
final skipSilenceProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.skipSilence, false),
);

/// Remember last playback position provider
final rememberLastPositionProvider =
    NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.rememberLastPosition, true),
);

/// Show album art on lockscreen provider
final showAlbumArtOnLockscreenProvider =
    NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.showAlbumArtOnLockscreen, true),
);

/// Crossfade duration provider (in seconds, 0 = disabled)
final crossfadeDurationProvider =
    NotifierProvider<SettingsValueNotifier<int>, int>(
  () => SettingsValueNotifier<int>(SettingsKeys.crossfadeDuration, 0),
);

/// Minimum file duration to include (in seconds)
final minFileDurationProvider = NotifierProvider<SettingsValueNotifier<int>, int>(
  () => SettingsValueNotifier<int>(SettingsKeys.minFileDuration, 30),
);

/// Fade on pause/play provider
final fadeOnPausePlayProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.fadeOnPausePlay, true),
);

/// Audio ducking provider (lower volume for notifications)
final audioDuckingProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.audioDucking, true),
);

/// ReplayGain mode provider (off, track, album)
final replayGainProvider = NotifierProvider<SettingsValueNotifier<String>, String>(
  () => SettingsValueNotifier<String>(SettingsKeys.replayGain, 'off'),
);

/// Auto-play on headset/bluetooth connect
final autoPlayOnConnectProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.autoPlayOnConnect, false),
);

/// Pause on headset/bluetooth disconnect
final pauseOnDisconnectProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.pauseOnDisconnect, true),
);

/// Keep shuffle queue on restart
final keepShuffleQueueProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.keepShuffleQueue, false),
);

/// Resume playback on app restart
final resumeOnRestartProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.resumeOnRestart, false),
);

/// Grid column count (2, 3, 4)
final gridColumnCountProvider = NotifierProvider<SettingsValueNotifier<int>, int>(
  () => SettingsValueNotifier<int>(SettingsKeys.gridColumnCount, 2),
);

/// Show track numbers in lists
final showTrackNumbersProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.showTrackNumbers, true),
);

/// Confirm before exiting app
final confirmExitProvider = NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.confirmExit, false),
);

/// Sleep timer finish current track before stopping
final sleepTimerFinishTrackProvider =
    NotifierProvider<SettingsValueNotifier<bool>, bool>(
  () => SettingsValueNotifier<bool>(SettingsKeys.sleepTimerFinishTrack, true),
);
