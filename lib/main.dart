import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/models/playlist.dart';
import 'data/models/song.dart';
import 'providers/providers.dart';
import 'ui/screens/screens.dart';
import 'ui/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style (initial - will be updated in app)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(DurationAdapter());

  // Open settings box early for theme
  await Hive.openBox(SettingsKeys.boxName);

  runApp(const ProviderScope(child: SimPlayerApp()));
}

class SimPlayerApp extends ConsumerStatefulWidget {
  const SimPlayerApp({super.key});

  @override
  ConsumerState<SimPlayerApp> createState() => _SimPlayerAppState();
}

class _SimPlayerAppState extends ConsumerState<SimPlayerApp> {
  bool _initialized = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize repositories
    await ref.read(songRepositoryProvider).init();
    await ref.read(playlistRepositoryProvider).init();

    // Initialize audio service
    await ref.read(audioServiceProvider).init();
    
    // Apply saved audio settings
    _applyAudioSettings();

    setState(() {
      _initialized = true;
    });

    // Auto-scan on startup if enabled
    _checkAutoScan();
  }
  
  void _applyAudioSettings() {
    final audioService = ref.read(audioServiceProvider);
    
    // Apply skip silence setting
    final skipSilence = ref.read(skipSilenceProvider);
    audioService.setSkipSilence(skipSilence);
    
    // Apply playback speed setting
    final playbackSpeed = ref.read(playbackSpeedProvider);
    audioService.setSpeed(playbackSpeed);
    
    // Apply fade on pause/play setting
    final fadeOnPausePlay = ref.read(fadeOnPausePlayProvider);
    audioService.setFadeOnPausePlay(fadeOnPausePlay);
    
    // Resume playback if enabled
    final resumeOnRestart = ref.read(resumeOnRestartProvider);
    if (resumeOnRestart) {
      // Check if there's a queue to resume
      final queue = audioService.queue;
      if (queue.songIds.isNotEmpty && queue.currentSongId != null) {
        // Resume playback (not starting from beginning)
        audioService.play();
      }
    }
  }

  Future<void> _checkAutoScan() async {
    final autoScan = ref.read(autoScanOnStartupProvider);
    if (autoScan) {
      final fileScanner = ref.read(fileScannerServiceProvider);
      final musicFolders = ref.read(musicFoldersProvider);
      final minDuration = ref.read(minFileDurationProvider);
      
      await fileScanner.scanDevice(
        folders: musicFolders,
        minDurationSeconds: minDuration,
      );
      
      // Refresh songs after scan
      ref.read(songsProvider.notifier).refresh();
    }
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Update system UI based on theme
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    if (_showSplash || !_initialized) {
      return MaterialApp(
        title: 'SimPlayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: SplashScreen(onComplete: _onSplashComplete),
      );
    }

    return MaterialApp(
      title: 'SimPlayer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const ShellWrapper(route: AppRoutes.home, child: HomeScreen()),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
