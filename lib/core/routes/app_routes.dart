import 'package:flutter/material.dart';
import '../../ui/screens/screens.dart';
import '../../ui/shell/main_shell.dart';

/// App route definitions
class AppRoutes {
  static const String home = '/';
  static const String library = '/library';
  static const String playlists = '/playlists';
  static const String nowPlaying = '/now-playing';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String profile = '/profile';
  
  // Prevent instantiation
  AppRoutes._();

  /// Routes that don't need the shell wrapper (full screen)
  static const _fullScreenRoutes = {nowPlaying, search};

  /// Route to screen widget mapping
  static final Map<String, Widget Function()> _routeBuilders = {
    home: () => const HomeScreen(),
    library: () => const LibraryScreen(),
    playlists: () => const PlaylistsScreen(),
    nowPlaying: () => const NowPlayingScreen(),
    settings: () => const SettingsScreen(),
    search: () => const SearchScreen(),
    profile: () => const ProfileScreen(),
  };

  /// Route titles
  static const Map<String, String> _titles = {
    home: 'Home',
    library: 'Library',
    playlists: 'Playlists',
    nowPlaying: 'Now Playing',
    settings: 'Settings',
    search: 'Search',
  };

  /// Generate routes for the app
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? home;
    final builder = _routeBuilders[routeName];
    final screen = builder != null ? builder() : const HomeScreen();
    final effectiveRoute = builder != null ? routeName : home;

    return MaterialPageRoute(
      builder: (_) => _fullScreenRoutes.contains(effectiveRoute)
          ? screen
          : ShellWrapper(route: effectiveRoute, child: screen),
      settings: settings,
    );
  }

  /// Get route title
  static String getTitle(String route) => _titles[route] ?? 'SimPlayer';
}

/// Navigation item for side nav
class NavItem {
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavItem({
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// All navigation items
const List<NavItem> navItems = [
  NavItem(
    route: AppRoutes.home,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  NavItem(
    route: AppRoutes.library,
    icon: Icons.library_music_outlined,
    selectedIcon: Icons.library_music_rounded,
    label: 'Library',
  ),
  NavItem(
    route: AppRoutes.playlists,
    icon: Icons.queue_music_outlined,
    selectedIcon: Icons.queue_music_rounded,
    label: 'Playlists',
  ),
  NavItem(
    route: AppRoutes.search,
    icon: Icons.search_outlined,
    selectedIcon: Icons.search_rounded,
    label: 'Search',
  ),
  NavItem(
    route: AppRoutes.nowPlaying,
    icon: Icons.play_circle_outline_rounded,
    selectedIcon: Icons.play_circle_rounded,
    label: 'Now Playing',
  ),
  NavItem(
    route: AppRoutes.settings,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];
