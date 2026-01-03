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

/// Audio Service Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final songRepository = ref.watch(songRepositoryProvider);
  return AudioService(songRepository);
});

/// File Scanner Service Provider
final fileScannerServiceProvider = Provider<FileScannerService>((ref) {
  final songRepository = ref.watch(songRepositoryProvider);
  return FileScannerService(songRepository);
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
