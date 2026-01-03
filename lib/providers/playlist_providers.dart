import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/playlist.dart';
import '../data/repositories/playlist_repository.dart';
import 'service_providers.dart';

/// Playlists provider
final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, AsyncValue<List<Playlist>>>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return PlaylistsNotifier(repository);
});

class PlaylistsNotifier extends StateNotifier<AsyncValue<List<Playlist>>> {
  final PlaylistRepository _repository;

  PlaylistsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPlaylists();
  }

  Future<void> loadPlaylists() async {
    state = const AsyncValue.loading();
    try {
      final playlists = _repository.getAllPlaylists();
      state = AsyncValue.data(playlists);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    final playlists = _repository.getAllPlaylists();
    state = AsyncValue.data(playlists);
  }

  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    List<String>? songIds,
  }) async {
    final playlist = await _repository.createPlaylist(
      name: name,
      description: description,
      songIds: songIds,
    );
    refresh();
    return playlist;
  }

  Future<void> deletePlaylist(String id) async {
    await _repository.deletePlaylist(id);
    refresh();
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _repository.renamePlaylist(id, newName);
    refresh();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _repository.addSongToPlaylist(playlistId, songId);
    refresh();
  }

  Future<void> addSongsToPlaylist(String playlistId, List<String> songIds) async {
    await _repository.addSongsToPlaylist(playlistId, songIds);
    refresh();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    await _repository.removeSongFromPlaylist(playlistId, songId);
    refresh();
  }

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    await _repository.reorderSongs(playlistId, oldIndex, newIndex);
    refresh();
  }
}

/// Single playlist provider
final playlistProvider =
    Provider.family<Playlist?, String>((ref, playlistId) {
  final playlistsAsync = ref.watch(playlistsProvider);
  return playlistsAsync.when(
    data: (playlists) {
      try {
        return playlists.firstWhere((p) => p.id == playlistId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
