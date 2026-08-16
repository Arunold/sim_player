import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/repositories.dart';
import '../services/services.dart';

/// Song Repository Provider
final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository();
});

/// Playlist Repository Provider
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepository();
});

/// Audio Player Handler Provider
///
/// This must be overridden at ProviderScope level with the handler
/// returned by [AudioService.init] in main(). The handler provides
/// background playback and media notification controls.
final audioPlayerHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  throw UnimplementedError(
    'audioPlayerHandlerProvider must be overridden with the handler '
    'returned by AudioService.init() in main().',
  );
});

/// File Scanner Service Provider
final fileScannerServiceProvider = Provider<FileScannerService>((ref) {
  final songRepository = ref.watch(songRepositoryProvider);
  final fileScanner = FileScannerService(songRepository);
  ref.onDispose(() => fileScanner.dispose());
  return fileScanner;
});

/// Scanning State Provider - tracks if scanning is in progress
final isScanningProvider = StreamProvider<bool>((ref) {
  final fileScanner = ref.watch(fileScannerServiceProvider);
  return fileScanner.isScanningStream;
});

/// Permission Service Provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});
