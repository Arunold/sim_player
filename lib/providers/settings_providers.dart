import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Settings keys for Hive storage
class SettingsKeys {
  static const String boxName = 'settings';
  static const String themeMode = 'themeMode';
  static const String gaplessPlayback = 'gaplessPlayback';
  static const String playbackSpeed = 'playbackSpeed';
}

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
