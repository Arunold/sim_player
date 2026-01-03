import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String? albumArtist;

  @HiveField(5)
  final String filePath;

  @HiveField(6)
  final Duration duration;

  @HiveField(7)
  final String? artworkPath;

  @HiveField(8)
  final int? trackNumber;

  @HiveField(9)
  final int? year;

  @HiveField(10)
  final String? genre;

  @HiveField(11)
  final int? bitrate;

  @HiveField(12)
  final String? fileExtension;

  @HiveField(13)
  final int fileSize;

  @HiveField(14)
  final DateTime dateAdded;

  @HiveField(15)
  final DateTime? lastPlayed;

  @HiveField(16)
  final int playCount;

  @HiveField(17)
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    required this.filePath,
    required this.duration,
    this.artworkPath,
    this.trackNumber,
    this.year,
    this.genre,
    this.bitrate,
    this.fileExtension,
    required this.fileSize,
    required this.dateAdded,
    this.lastPlayed,
    this.playCount = 0,
    this.isFavorite = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? filePath,
    Duration? duration,
    String? artworkPath,
    int? trackNumber,
    int? year,
    String? genre,
    int? bitrate,
    String? fileExtension,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? lastPlayed,
    int? playCount,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      bitrate: bitrate ?? this.bitrate,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      playCount: playCount ?? this.playCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get durationFormatted {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        albumArtist,
        filePath,
        duration,
        artworkPath,
        trackNumber,
        year,
        genre,
        bitrate,
        fileExtension,
        fileSize,
        dateAdded,
        lastPlayed,
        playCount,
        isFavorite,
      ];

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';
}
