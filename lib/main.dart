import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/models/song.dart';
import 'data/models/playlist.dart';
import 'providers/providers.dart';
import 'ui/screens/screens.dart';
import 'ui/shell/main_shell.dart';
import 'ui/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
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

    setState(() {
      _initialized = true;
    });
  }

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

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
