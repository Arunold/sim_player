import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/repositories/song_repository.dart';
import 'service_providers.dart';

/// Songs list provider
final songsProvider =
    NotifierProvider<SongsNotifier, AsyncValue<List<Song>>>(SongsNotifier.new);

class SongsNotifier extends Notifier<AsyncValue<List<Song>>> {
  late final SongRepository _repository;

  @override
  AsyncValue<List<Song>> build() {
    _repository = ref.watch(songRepositoryProvider);
    Future<void>.microtask(() => loadSongs());
    return const AsyncValue.loading();
  }

  Future<void> loadSongs() async {
    state = const AsyncValue.loading();
    try {
      final songs = _repository.getAllSongs();
      state = AsyncValue.data(songs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() {
    Future<void>.microtask(() => loadSongs());
  }

  Future<void> toggleFavorite(String songId) async {
    await _repository.toggleFavorite(songId);
    refresh();
  }
}

/// Search query provider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) {
    state = value;
  }
}

/// Filtered songs provider (for search)
final filteredSongsProvider = Provider<List<Song>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  final query = ref.watch(searchQueryProvider);

  return songsAsync.when(
    data: (songs) {
      if (query.isEmpty) return songs;
      final lowerQuery = query.toLowerCase();
      return songs.where((song) {
        return song.title.toLowerCase().contains(lowerQuery) ||
            song.artist.toLowerCase().contains(lowerQuery) ||
            song.album.toLowerCase().contains(lowerQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Artists provider
final artistsProvider = Provider<List<String>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) {
      final artists = songs.map((s) => s.artist).toSet().toList();
      artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return artists;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Albums provider
final albumsProvider = Provider<List<String>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) {
      final albums = songs.map((s) => s.album).toSet().toList();
      albums.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return albums;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Songs by artist provider
final songsByArtistProvider = Provider.family<List<Song>, String>((ref, artist) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) => songs.where((s) => s.artist == artist).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Songs by album provider
final songsByAlbumProvider = Provider.family<List<Song>, String>((ref, album) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) => songs.where((s) => s.album == album).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Favorite songs provider
final favoriteSongsProvider = Provider<List<Song>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) => songs.where((s) => s.isFavorite).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Recently added songs provider (50 songs)
final recentlyAddedProvider = Provider<List<Song>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) {
      final sorted = List<Song>.from(songs)
        ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      return sorted.take(50).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Recently played songs provider (50 songs)
final recentlyPlayedProvider = Provider<List<Song>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) {
      final played = songs.where((s) => s.lastPlayed != null).toList()
        ..sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
      return played.take(50).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Years provider (sorted descending)
final yearsProvider = Provider<List<int>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) {
      final years = songs
          .where((s) => s.year != null && s.year! > 0)
          .map((s) => s.year!)
          .toSet()
          .toList();
      years.sort((a, b) => b.compareTo(a)); // Descending
      return years;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Songs by year provider
final songsByYearProvider = Provider.family<List<Song>, int>((ref, year) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) => songs.where((s) => s.year == year).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Genres provider
final genresProvider = Provider<List<String>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) {
      final genres = songs
          .where((s) => s.genre != null && s.genre!.isNotEmpty)
          .map((s) => s.genre!)
          .toSet()
          .toList();
      genres.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return genres;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Songs by genre provider
final songsByGenreProvider = Provider.family<List<Song>, String>((ref, genre) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) => songs.where((s) => s.genre == genre).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Most played songs provider
final mostPlayedProvider = Provider<List<Song>>((ref) {
  final songsAsync = ref.watch(songsProvider);
  return songsAsync.when(
    data: (songs) {
      final sorted = songs.where((s) => s.playCount > 0).toList()
        ..sort((a, b) => b.playCount.compareTo(a.playCount));
      return sorted.take(20).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});
