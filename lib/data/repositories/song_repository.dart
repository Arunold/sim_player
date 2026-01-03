import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';
import '../../core/constants/app_constants.dart';

/// Repository for managing song data persistence
class SongRepository {
  late Box<Song> _songsBox;

  Future<void> init() async {
    _songsBox = await Hive.openBox<Song>(AppConstants.songsBox);
  }

  /// Get all songs
  List<Song> getAllSongs() {
    return _songsBox.values.toList();
  }

  /// Get song by ID
  Song? getSongById(String id) {
    return _songsBox.get(id);
  }

  /// Get songs by IDs
  List<Song> getSongsByIds(List<String> ids) {
    return ids
        .map((id) => _songsBox.get(id))
        .where((song) => song != null)
        .cast<Song>()
        .toList();
  }

  /// Add or update a song
  Future<void> saveSong(Song song) async {
    await _songsBox.put(song.id, song);
  }

  /// Add multiple songs
  Future<void> saveSongs(List<Song> songs) async {
    final Map<String, Song> songMap = {for (var song in songs) song.id: song};
    await _songsBox.putAll(songMap);
  }

  /// Delete a song
  Future<void> deleteSong(String id) async {
    await _songsBox.delete(id);
  }

  /// Delete multiple songs
  Future<void> deleteSongs(List<String> ids) async {
    await _songsBox.deleteAll(ids);
  }

  /// Clear all songs
  Future<void> clearAll() async {
    await _songsBox.clear();
  }

  /// Get songs count
  int get songsCount => _songsBox.length;

  /// Search songs by title, artist, or album
  List<Song> searchSongs(String query) {
    final lowerQuery = query.toLowerCase();
    return _songsBox.values.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery) ||
          song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get all unique artists
  List<String> getAllArtists() {
    final artists = _songsBox.values.map((s) => s.artist).toSet().toList();
    artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return artists;
  }

  /// Get all unique albums
  List<String> getAllAlbums() {
    final albums = _songsBox.values.map((s) => s.album).toSet().toList();
    albums.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return albums;
  }

  /// Get songs by artist
  List<Song> getSongsByArtist(String artist) {
    return _songsBox.values.where((s) => s.artist == artist).toList();
  }

  /// Get songs by album
  List<Song> getSongsByAlbum(String album) {
    return _songsBox.values.where((s) => s.album == album).toList();
  }

  /// Get favorite songs
  List<Song> getFavoriteSongs() {
    return _songsBox.values.where((s) => s.isFavorite).toList();
  }

  /// Get recently added songs
  List<Song> getRecentlyAdded({int limit = 20}) {
    final songs = _songsBox.values.toList()
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return songs.take(limit).toList();
  }

  /// Get recently played songs
  List<Song> getRecentlyPlayed({int limit = 20}) {
    final songs = _songsBox.values
        .where((s) => s.lastPlayed != null)
        .toList()
      ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
    return songs.take(limit).toList();
  }

  /// Get most played songs
  List<Song> getMostPlayed({int limit = 20}) {
    final songs = _songsBox.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return songs.where((s) => s.playCount > 0).take(limit).toList();
  }

  /// Toggle favorite status
  Future<Song> toggleFavorite(String songId) async {
    final song = _songsBox.get(songId);
    if (song != null) {
      final updatedSong = song.copyWith(isFavorite: !song.isFavorite);
      await _songsBox.put(songId, updatedSong);
      return updatedSong;
    }
    throw Exception('Song not found');
  }

  /// Update play count and last played
  Future<void> recordPlay(String songId) async {
    final song = _songsBox.get(songId);
    if (song != null) {
      final updatedSong = song.copyWith(
        playCount: song.playCount + 1,
        lastPlayed: DateTime.now(),
      );
      await _songsBox.put(songId, updatedSong);
    }
  }

  /// Check if song exists by file path
  bool songExistsByPath(String filePath) {
    return _songsBox.values.any((s) => s.filePath == filePath);
  }

  /// Get song by file path
  Song? getSongByPath(String filePath) {
    try {
      return _songsBox.values.firstWhere((s) => s.filePath == filePath);
    } catch (_) {
      return null;
    }
  }
}
