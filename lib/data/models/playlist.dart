import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final List<String> songIds;

  @HiveField(4)
  final String? artworkPath;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final bool isSmartPlaylist;

  const Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.songIds,
    this.artworkPath,
    required this.createdAt,
    required this.updatedAt,
    this.isSmartPlaylist = false,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    String? artworkPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSmartPlaylist,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      artworkPath: artworkPath ?? this.artworkPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSmartPlaylist: isSmartPlaylist ?? this.isSmartPlaylist,
    );
  }

  int get songCount => songIds.length;

  bool get isEmpty => songIds.isEmpty;

  bool containsSong(String songId) => songIds.contains(songId);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        songIds,
        artworkPath,
        createdAt,
        updatedAt,
        isSmartPlaylist,
      ];

  @override
  String toString() => 'Playlist(id: $id, name: $name, songCount: $songCount)';
}
