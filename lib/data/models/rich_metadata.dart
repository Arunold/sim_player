import 'dart:typed_data';

/// Comprehensive audio metadata model containing all available metadata fields
/// across different audio formats (MP3, MP4, FLAC, OGG, WAV)
class RichMetadata {
  // Basic Info
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final Duration? duration;
  final int? year;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final List<String> genres;

  // Technical Info
  final int? bitrate;
  final int? sampleRate;
  final String? format;

  // Credits
  final String? composer;
  final String? lyricist;
  final String? conductor;
  final String? band;
  final String? performer;
  final String? publisher;
  final String? encodedBy;
  final String? encoder;

  // Additional Info
  final String? bpm;
  final String? lyrics;
  final String? comment;
  final String? copyright;
  final String? originalArtist;
  final String? originalAlbum;
  final int? originalYear;
  final String? isrc;
  final double? replayGain;

  // Artwork
  final Uint8List? artworkBytes;
  final String? artworkMimeType;

  // Source Format
  final AudioFormat audioFormat;

  const RichMetadata({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.duration,
    this.year,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.genres = const [],
    this.bitrate,
    this.sampleRate,
    this.format,
    this.composer,
    this.lyricist,
    this.conductor,
    this.band,
    this.performer,
    this.publisher,
    this.encodedBy,
    this.encoder,
    this.bpm,
    this.lyrics,
    this.comment,
    this.copyright,
    this.originalArtist,
    this.originalAlbum,
    this.originalYear,
    this.isrc,
    this.replayGain,
    this.artworkBytes,
    this.artworkMimeType,
    this.audioFormat = AudioFormat.unknown,
  });

  /// Check if this metadata has rich info beyond basic fields
  bool get hasRichInfo =>
      composer != null ||
      lyricist != null ||
      conductor != null ||
      band != null ||
      performer != null ||
      bpm != null ||
      lyrics != null ||
      copyright != null ||
      isrc != null;

  /// Get formatted bitrate string (e.g., "320 kbps")
  String? get bitrateFormatted {
    if (bitrate == null) return null;
    return '${(bitrate! / 1000).round()} kbps';
  }

  /// Get formatted sample rate string (e.g., "44.1 kHz")
  String? get sampleRateFormatted {
    if (sampleRate == null) return null;
    if (sampleRate! >= 1000) {
      return '${(sampleRate! / 1000).toStringAsFixed(1)} kHz';
    }
    return '$sampleRate Hz';
  }

  /// Get formatted duration string (e.g., "3:45")
  String? get durationFormatted {
    if (duration == null) return null;
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'RichMetadata('
        'title: $title, '
        'artist: $artist, '
        'album: $album, '
        'format: ${audioFormat.name}'
        ')';
  }
}

/// Supported audio formats
enum AudioFormat {
  mp3,
  mp4,
  m4a,
  flac,
  ogg,
  opus,
  wav,
  unknown;

  static AudioFormat fromExtension(String ext) {
    switch (ext.toLowerCase().replaceFirst('.', '')) {
      case 'mp3':
        return AudioFormat.mp3;
      case 'mp4':
      case 'm4a':
      case 'aac':
        return AudioFormat.mp4;
      case 'flac':
        return AudioFormat.flac;
      case 'ogg':
      case 'oga':
        return AudioFormat.ogg;
      case 'opus':
        return AudioFormat.opus;
      case 'wav':
      case 'wave':
        return AudioFormat.wav;
      default:
        return AudioFormat.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case AudioFormat.mp3:
        return 'MP3';
      case AudioFormat.mp4:
      case AudioFormat.m4a:
        return 'AAC/MP4';
      case AudioFormat.flac:
        return 'FLAC';
      case AudioFormat.ogg:
        return 'OGG Vorbis';
      case AudioFormat.opus:
        return 'Opus';
      case AudioFormat.wav:
        return 'WAV';
      case AudioFormat.unknown:
        return 'Unknown';
    }
  }
}
