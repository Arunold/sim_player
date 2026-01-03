import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/playlist.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing playlist data persistence
class PlaylistRepository {
  late Box<Playlist> _playlistsBox;
  final _uuid = const Uuid();

  Future<void> init() async {
    _playlistsBox = await Hive.openBox<Playlist>(AppConstants.playlistsBox);
  }

  /// Get all playlists
  List<Playlist> getAllPlaylists() {
    return _playlistsBox.values.toList();
  }

  /// Get playlist by ID
  Playlist? getPlaylistById(String id) {
    return _playlistsBox.get(id);
  }

  /// Create a new playlist
  Future<Playlist> createPlaylist({
    required String name,
    String? description,
    List<String>? songIds,
  }) async {
    final now = DateTime.now();
    final playlist = Playlist(
      id: _uuid.v4(),
      name: name,
      description: description,
      songIds: songIds ?? [],
      createdAt: now,
      updatedAt: now,
    );
    await _playlistsBox.put(playlist.id, playlist);
    return playlist;
  }

  /// Update playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    final updatedPlaylist = playlist.copyWith(updatedAt: DateTime.now());
    await _playlistsBox.put(playlist.id, updatedPlaylist);
  }

  /// Delete playlist
  Future<void> deletePlaylist(String id) async {
    await _playlistsBox.delete(id);
  }

  /// Rename playlist
  Future<Playlist> renamePlaylist(String id, String newName) async {
    final playlist = _playlistsBox.get(id);
    if (playlist != null) {
      final updatedPlaylist = playlist.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      await _playlistsBox.put(id, updatedPlaylist);
      return updatedPlaylist;
    }
    throw Exception('Playlist not found');
  }

  /// Add song to playlist
  Future<Playlist> addSongToPlaylist(String playlistId, String songId) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      if (!playlist.songIds.contains(songId)) {
        final updatedPlaylist = playlist.copyWith(
          songIds: [...playlist.songIds, songId],
          updatedAt: DateTime.now(),
        );
        await _playlistsBox.put(playlistId, updatedPlaylist);
        return updatedPlaylist;
      }
      return playlist;
    }
    throw Exception('Playlist not found');
  }

  /// Add multiple songs to playlist
  Future<Playlist> addSongsToPlaylist(
      String playlistId, List<String> songIds) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      final newSongIds = songIds.where((id) => !playlist.songIds.contains(id));
      final updatedPlaylist = playlist.copyWith(
        songIds: [...playlist.songIds, ...newSongIds],
        updatedAt: DateTime.now(),
      );
      await _playlistsBox.put(playlistId, updatedPlaylist);
      return updatedPlaylist;
    }
    throw Exception('Playlist not found');
  }

  /// Remove song from playlist
  Future<Playlist> removeSongFromPlaylist(
      String playlistId, String songId) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      final updatedPlaylist = playlist.copyWith(
        songIds: playlist.songIds.where((id) => id != songId).toList(),
        updatedAt: DateTime.now(),
      );
      await _playlistsBox.put(playlistId, updatedPlaylist);
      return updatedPlaylist;
    }
    throw Exception('Playlist not found');
  }

  /// Reorder songs in playlist
  Future<Playlist> reorderSongs(
      String playlistId, int oldIndex, int newIndex) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      final songIds = List<String>.from(playlist.songIds);
      final songId = songIds.removeAt(oldIndex);
      songIds.insert(newIndex, songId);
      final updatedPlaylist = playlist.copyWith(
        songIds: songIds,
        updatedAt: DateTime.now(),
      );
      await _playlistsBox.put(playlistId, updatedPlaylist);
      return updatedPlaylist;
    }
    throw Exception('Playlist not found');
  }

  /// Clear all songs from playlist
  Future<Playlist> clearPlaylist(String playlistId) async {
    final playlist = _playlistsBox.get(playlistId);
    if (playlist != null) {
      final updatedPlaylist = playlist.copyWith(
        songIds: [],
        updatedAt: DateTime.now(),
      );
      await _playlistsBox.put(playlistId, updatedPlaylist);
      return updatedPlaylist;
    }
    throw Exception('Playlist not found');
  }

  /// Get playlists count
  int get playlistsCount => _playlistsBox.length;

  /// Check if playlist name exists
  bool playlistNameExists(String name, {String? excludeId}) {
    return _playlistsBox.values.any(
      (p) => p.name.toLowerCase() == name.toLowerCase() && p.id != excludeId,
    );
  }

  /// Get playlists containing a specific song
  List<Playlist> getPlaylistsContainingSong(String songId) {
    return _playlistsBox.values.where((p) => p.songIds.contains(songId)).toList();
  }
}
