import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../data/models/rich_metadata.dart';

/// Service for extracting comprehensive audio metadata from files
/// Supports MP3, MP4/M4A, FLAC, OGG, Opus, and WAV formats
class MetadataService {
  /// Extract rich metadata from an audio file
  /// Returns null if extraction fails completely
  RichMetadata? extractMetadata(File file, {bool getImage = false}) {
    try {
      final extension = path.extension(file.path);
      final audioFormat = AudioFormat.fromExtension(extension);

      // Use readAllMetadata for format-specific fields
      final rawMetadata = readAllMetadata(file, getImage: getImage);

      return _mapToRichMetadata(rawMetadata, audioFormat);
    } catch (e) {
      debugPrint('MetadataService: Failed to extract metadata: $e');
      return null;
    }
  }

  /// Extract basic metadata using the simpler API (faster, less detailed)
  RichMetadata? extractBasicMetadata(File file, {bool getImage = false}) {
    try {
      final extension = path.extension(file.path);
      final audioFormat = AudioFormat.fromExtension(extension);
      final metadata = readMetadata(file, getImage: getImage);

      return RichMetadata(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        duration: metadata.duration,
        year: metadata.year?.year,
        trackNumber: metadata.trackNumber,
        trackTotal: metadata.trackTotal,
        discNumber: metadata.discNumber,
        discTotal: metadata.totalDisc,
        genres: metadata.genres,
        bitrate: metadata.bitrate,
        sampleRate: metadata.sampleRate,
        lyrics: metadata.lyrics,
        artworkBytes: metadata.pictures.isNotEmpty
            ? metadata.pictures.first.bytes
            : null,
        artworkMimeType: metadata.pictures.isNotEmpty
            ? metadata.pictures.first.mimetype
            : null,
        audioFormat: audioFormat,
      );
    } catch (e) {
      debugPrint('MetadataService: Failed to extract basic metadata: $e');
      return null;
    }
  }

  /// Map format-specific metadata to our unified RichMetadata model
  RichMetadata _mapToRichMetadata(Object rawMetadata, AudioFormat format) {
    if (rawMetadata is Mp3Metadata) {
      return _fromMp3Metadata(rawMetadata, format);
    } else if (rawMetadata is Mp4Metadata) {
      return _fromMp4Metadata(rawMetadata, format);
    } else if (rawMetadata is VorbisMetadata) {
      return _fromVorbisMetadata(rawMetadata, format);
    } else if (rawMetadata is RiffMetadata) {
      return _fromRiffMetadata(rawMetadata, format);
    } else {
      // Fallback - shouldn't happen but handle gracefully
      return RichMetadata(audioFormat: format);
    }
  }

  /// Extract metadata from MP3 files (ID3v2 tags)
  RichMetadata _fromMp3Metadata(Mp3Metadata m, AudioFormat format) {
    return RichMetadata(
      // Basic Info
      title: m.songName,
      artist: m.leadPerformer ?? m.originalArtist,
      album: m.album,
      albumArtist: m.bandOrOrchestra,
      duration: m.duration,
      year: m.year ?? m.originalReleaseYear,
      trackNumber: m.trackNumber,
      trackTotal: m.trackTotal,
      discNumber: m.discNumber,
      discTotal: m.totalDics,
      genres: m.genres,

      // Technical Info
      bitrate: m.bitrate,
      sampleRate: m.samplerate,
      format: format.displayName,

      // Credits
      composer: m.composer,
      lyricist: m.textWriter,
      conductor: m.conductor,
      band: m.bandOrOrchestra,
      performer: m.interpreted,
      publisher: m.publisher,
      encodedBy: m.encodedBy,
      encoder: m.encoderSoftware,

      // Additional Info
      bpm: m.bpm,
      lyrics: m.lyric,
      comment: m.comments.isNotEmpty ? m.comments.first.text : null,
      copyright: m.copyrightMessage,
      originalArtist: m.originalArtist,
      originalAlbum: m.originalAlbum,
      originalYear: m.originalReleaseYear,
      isrc: m.isrc,

      // Artwork
      artworkBytes: m.pictures.isNotEmpty ? m.pictures.first.bytes : null,
      artworkMimeType: m.pictures.isNotEmpty ? m.pictures.first.mimetype : null,

      audioFormat: format,
    );
  }

  /// Extract metadata from MP4/M4A files (iTunes-style ilst)
  RichMetadata _fromMp4Metadata(Mp4Metadata m, AudioFormat format) {
    return RichMetadata(
      // Basic Info
      title: m.title,
      artist: m.artist,
      album: m.album,
      duration: m.duration,
      year: m.year?.year,
      trackNumber: m.trackNumber,
      trackTotal: m.totalTracks,
      discNumber: m.discNumber,
      discTotal: m.totalDiscs,
      genres: m.genre != null ? [m.genre!] : [],

      // Technical Info
      bitrate: m.bitrate,
      sampleRate: m.sampleRate,
      format: format.displayName,

      // Additional Info
      lyrics: m.lyrics,

      // Artwork
      artworkBytes: m.picture?.bytes,
      artworkMimeType: m.picture?.mimetype,

      audioFormat: format,
    );
  }

  /// Extract metadata from FLAC/OGG/Opus files (Vorbis Comments)
  RichMetadata _fromVorbisMetadata(VorbisMetadata m, AudioFormat format) {
    return RichMetadata(
      // Basic Info
      title: m.title.isNotEmpty ? m.title.first : null,
      artist: m.artist.isNotEmpty ? m.artist.first : null,
      album: m.album.isNotEmpty ? m.album.first : null,
      albumArtist: m.performer.isNotEmpty ? m.performer.first : null,
      duration: m.duration,
      year: m.date.isNotEmpty ? m.date.first.year : null,
      trackNumber: m.trackNumber.isNotEmpty ? m.trackNumber.first : null,
      trackTotal: m.trackTotal,
      discNumber: m.discNumber,
      discTotal: m.discTotal,
      genres: m.genres,

      // Technical Info
      bitrate: m.bitrate,
      sampleRate: m.sampleRate,
      format: format.displayName,

      // Credits
      composer: m.composer.isNotEmpty ? m.composer.first : null,
      performer: m.performer.isNotEmpty ? m.performer.first : null,
      encodedBy: m.encodedBy.isNotEmpty ? m.encodedBy.first : null,
      encoder: m.encoder.isNotEmpty ? m.encoder.first : null,

      // Additional Info
      lyrics: m.lyric,
      comment: m.comment.isNotEmpty ? m.comment.first : null,
      copyright: m.copyright.isNotEmpty ? m.copyright.first : null,
      isrc: m.isrc.isNotEmpty ? m.isrc.first : null,

      // Artwork
      artworkBytes: m.pictures.isNotEmpty ? m.pictures.first.bytes : null,
      artworkMimeType: m.pictures.isNotEmpty ? m.pictures.first.mimetype : null,

      audioFormat: format,
    );
  }

  /// Extract metadata from WAV files (RIFF tags)
  RichMetadata _fromRiffMetadata(RiffMetadata m, AudioFormat format) {
    return RichMetadata(
      // Basic Info
      title: m.title,
      artist: m.artist,
      album: m.album,
      duration: m.duration,
      year: m.year?.year,
      trackNumber: m.trackNumber,
      genres: m.genre != null ? [m.genre!] : [],

      // Technical Info
      bitrate: m.bitrate,
      sampleRate: m.samplerate,
      format: format.displayName,

      // Credits
      publisher: m.publisher,
      encoder: m.encoder,

      // Additional Info
      comment: m.comment,
      copyright: m.copyright,

      // Artwork
      artworkBytes: m.pictures.isNotEmpty ? m.pictures.first.bytes : null,
      artworkMimeType: m.pictures.isNotEmpty ? m.pictures.first.mimetype : null,

      audioFormat: format,
    );
  }
}
