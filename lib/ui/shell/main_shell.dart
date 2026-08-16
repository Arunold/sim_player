import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sim_player/core/constants/app_constants.dart';
import '../../core/constants/theme_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/providers.dart';
import '../../services/file_scanner_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/side_nav.dart';

/// Shell wrapper that adds drawer, app bar, scanning indicator, and mini player
/// to any screen based on the current route.
class ShellWrapper extends ConsumerStatefulWidget {
  final String route;
  final Widget child;

  const ShellWrapper({super.key, required this.route, required this.child});

  @override
  ConsumerState<ShellWrapper> createState() => _ShellWrapperState();
}

class _ShellWrapperState extends ConsumerState<ShellWrapper> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> _onWillPop() async {
    final confirmExit = ref.read(confirmExitProvider);
    if (!confirmExit) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final fileScanner = ref.watch(fileScannerServiceProvider);
    final showProfile = widget.route != AppRoutes.profile;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop) {
          await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: SideNav(currentRoute: widget.route),
        body: Stack(
          children: [
            // Main content column - extends behind mini player for blur effect
            Column(
              children: [
                // App Bar
                AppBarWidget(
                  scaffoldKey: _scaffoldKey,
                  title: AppRoutes.getTitle(widget.route),
                  showProfile: showProfile,
                ),

                // Scanning indicator
                ScanningIndicator(fileScanner: fileScanner),

                // Screen content - full height, scrollable content handles its own bottom padding
                Expanded(child: widget.child),

                // Bottom padding for mini player
                const SizedBox(height: AppConstants.miniPlayerHeight + 10),
              ],
            ),
            // Mini player overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                onTap: () => Navigator.pushNamed(context, AppRoutes.nowPlaying),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable App Bar Widget
class AppBarWidget extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final bool showProfile;

  const AppBarWidget({
    super.key,
    required this.scaffoldKey,
    required this.title,
    this.showProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(color: context.colors.divider, width: 0.5),
        ),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            // Menu button
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
              tooltip: 'Open menu',
            ),
            // Title
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            // Profile button
            if (showProfile)
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                tooltip: 'Profile',
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

/// Scanning indicator widget
class ScanningIndicator extends ConsumerWidget {
  final FileScannerService fileScanner;

  const ScanningIndicator({super.key, required this.fileScanner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<bool>(
      stream: fileScanner.isScanningStream,
      initialData: fileScanner.isScanning,
      builder: (context, snapshot) {
        final isScanning = snapshot.data ?? false;
        if (!isScanning) return const SizedBox.shrink();

        return StreamBuilder<ScanProgress>(
          stream: fileScanner.progressStream,
          builder: (context, progressSnapshot) {
            final progress = progressSnapshot.data;
            final songsAdded = progress?.songsAdded ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.15),
                border: Border(
                  bottom: BorderSide(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Scanning... $songsAdded songs added',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.music_note_rounded,
                    size: 16,
                    color: context.colors.primary.withValues(alpha: 0.7),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
