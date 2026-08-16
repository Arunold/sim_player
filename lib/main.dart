import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/models/playlist.dart';
import 'data/models/song.dart';
import 'data/repositories/song_repository.dart';
import 'providers/providers.dart';
import 'services/audio_service.dart' as app;
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

  // Initialize song repository early so the handler can access songs
  final songRepository = SongRepository();
  await songRepository.init();

  // Initialize audio_service with our handler for background playback
  // and media notification controls (lockscreen, notification shade).
  final audioHandler = await AudioService.init(
    builder: () => app.AudioPlayerHandler(songRepository),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          '${AppConstants.appPackageName}.channel.audio',
      androidNotificationChannelName: AppConstants.appName,
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  // Run handler's own init (queue restore, audio session, listeners)
  await audioHandler.init();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the already-initialized instances so they are shared
        songRepositoryProvider.overrideWithValue(songRepository),
        audioPlayerHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const SimPlayerApp(),
    ),
  );
}

class SimPlayerApp extends ConsumerStatefulWidget {
  const SimPlayerApp({super.key});

  @override
  ConsumerState<SimPlayerApp> createState() => _SimPlayerAppState();
}

class _SimPlayerAppState extends ConsumerState<SimPlayerApp> {
  bool _initialized = false;
  bool _showSplash = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize playlist repository
      await ref.read(playlistRepositoryProvider).init();

      // Apply saved audio settings (safe now that Hive boxes are open)
      _applyAudioSettings();

      setState(() {
        _initialized = true;
      });

      // Auto-scan on startup if enabled
      _checkAutoScan();
    } catch (e) {
      setState(() {
        _initError = e.toString();
        _initialized = true; // Stop showing splash
      });
    }
  }
  
  void _applyAudioSettings() {
    final handler = ref.read(audioPlayerHandlerProvider);
    
    // Apply skip silence setting
    final skipSilence = ref.read(skipSilenceProvider);
    handler.setSkipSilence(skipSilence);
    
    // Apply playback speed setting
    final playbackSpeed = ref.read(playbackSpeedProvider);
    handler.setSpeed(playbackSpeed);
    
    // Apply fade on pause/play setting
    final fadeOnPausePlay = ref.read(fadeOnPausePlayProvider);
    handler.setFadeOnPausePlay(fadeOnPausePlay);
    
    // Resume playback if enabled
    final resumeOnRestart = ref.read(resumeOnRestartProvider);
    if (resumeOnRestart) {
      // Check if there's a queue to resume
      final queue = handler.currentQueue;
      if (queue.songIds.isNotEmpty && queue.currentSongId != null) {
        // Resume playback (not starting from beginning)
        handler.play();
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

    if (_initError != null) {
      return MaterialApp(
        title: 'SimPlayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initError = null;
                        _initialized = false;
                        _showSplash = true;
                      });
                      _initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
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
