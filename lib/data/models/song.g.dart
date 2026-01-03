// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      albumArtist: fields[4] as String?,
      filePath: fields[5] as String,
      duration: fields[6] as Duration,
      artworkPath: fields[7] as String?,
      trackNumber: fields[8] as int?,
      year: fields[9] as int?,
      genre: fields[10] as String?,
      bitrate: fields[11] as int?,
      fileExtension: fields[12] as String?,
      fileSize: fields[13] as int,
      dateAdded: fields[14] as DateTime,
      lastPlayed: fields[15] as DateTime?,
      playCount: fields[16] as int,
      isFavorite: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.albumArtist)
      ..writeByte(5)
      ..write(obj.filePath)
      ..writeByte(6)
      ..write(obj.duration)
      ..writeByte(7)
      ..write(obj.artworkPath)
      ..writeByte(8)
      ..write(obj.trackNumber)
      ..writeByte(9)
      ..write(obj.year)
      ..writeByte(10)
      ..write(obj.genre)
      ..writeByte(11)
      ..write(obj.bitrate)
      ..writeByte(12)
      ..write(obj.fileExtension)
      ..writeByte(13)
      ..write(obj.fileSize)
      ..writeByte(14)
      ..write(obj.dateAdded)
      ..writeByte(15)
      ..write(obj.lastPlayed)
      ..writeByte(16)
      ..write(obj.playCount)
      ..writeByte(17)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 10;

  @override
  Duration read(BinaryReader reader) {
    return Duration(microseconds: reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}
