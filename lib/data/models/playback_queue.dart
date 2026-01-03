import 'package:equatable/equatable.dart';

/// Represents the current playback queue
class PlaybackQueue extends Equatable {
  final List<String> songIds;
  final int currentIndex;
  final String? originalPlaylistId;
  final bool isShuffled;
  final List<String>? originalOrder;

  const PlaybackQueue({
    required this.songIds,
    this.currentIndex = 0,
    this.originalPlaylistId,
    this.isShuffled = false,
    this.originalOrder,
  });

  PlaybackQueue copyWith({
    List<String>? songIds,
    int? currentIndex,
    String? originalPlaylistId,
    bool? isShuffled,
    List<String>? originalOrder,
  }) {
    return PlaybackQueue(
      songIds: songIds ?? this.songIds,
      currentIndex: currentIndex ?? this.currentIndex,
      originalPlaylistId: originalPlaylistId ?? this.originalPlaylistId,
      isShuffled: isShuffled ?? this.isShuffled,
      originalOrder: originalOrder ?? this.originalOrder,
    );
  }

  String? get currentSongId {
    if (songIds.isEmpty || currentIndex < 0 || currentIndex >= songIds.length) {
      return null;
    }
    return songIds[currentIndex];
  }

  bool get hasNext => currentIndex < songIds.length - 1;

  bool get hasPrevious => currentIndex > 0;

  int get length => songIds.length;

  bool get isEmpty => songIds.isEmpty;

  PlaybackQueue moveToNext() {
    if (!hasNext) return this;
    return copyWith(currentIndex: currentIndex + 1);
  }

  PlaybackQueue moveToPrevious() {
    if (!hasPrevious) return this;
    return copyWith(currentIndex: currentIndex - 1);
  }

  PlaybackQueue moveTo(int index) {
    if (index < 0 || index >= songIds.length) return this;
    return copyWith(currentIndex: index);
  }

  PlaybackQueue addSong(String songId) {
    return copyWith(songIds: [...songIds, songId]);
  }

  PlaybackQueue addSongNext(String songId) {
    final newList = List<String>.from(songIds);
    newList.insert(currentIndex + 1, songId);
    return copyWith(songIds: newList);
  }

  PlaybackQueue removeSong(int index) {
    if (index < 0 || index >= songIds.length) return this;
    final newList = List<String>.from(songIds)..removeAt(index);
    int newIndex = currentIndex;
    if (index < currentIndex) {
      newIndex--;
    } else if (index == currentIndex && currentIndex >= newList.length) {
      newIndex = newList.length - 1;
    }
    return copyWith(songIds: newList, currentIndex: newIndex.clamp(0, newList.length - 1));
  }

  PlaybackQueue clear() {
    return const PlaybackQueue(songIds: [], currentIndex: 0);
  }

  @override
  List<Object?> get props => [
        songIds,
        currentIndex,
        originalPlaylistId,
        isShuffled,
        originalOrder,
      ];
}
