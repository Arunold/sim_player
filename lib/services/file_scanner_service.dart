import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../data/models/song.dart';
import '../data/repositories/song_repository.dart';
import '../core/constants/app_constants.dart';
import 'metadata_service.dart';

/// Service for scanning local files and extracting metadata
class FileScannerService {
  final SongRepository _songRepository;
  final MetadataService _metadataService;
  final _uuid = const Uuid();
  String? _artworkCacheDir;

  final _progressController = StreamController<ScanProgress>.broadcast();
  final _completeController = StreamController<ScanResult>.broadcast();
  final _isScanningController = StreamController<bool>.broadcast();

  Stream<ScanProgress> get progressStream => _progressController.stream;
  Stream<ScanResult> get completeStream => _completeController.stream;
  Stream<bool> get isScanningStream => _isScanningController.stream;

  bool _isScanning = false;
  bool _cancelRequested = false;

  bool get isScanning => _isScanning;

  FileScannerService(this._songRepository, {MetadataService? metadataService})
      : _metadataService = metadataService ?? MetadataService();

  /// Initialize artwork cache directory
  Future<String> _getArtworkCacheDir() async {
    if (_artworkCacheDir != null) return _artworkCacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    final artworkDir = Directory('${appDir.path}/artwork');
    if (!await artworkDir.exists()) {
      await artworkDir.create(recursive: true);
    }
    _artworkCacheDir = artworkDir.path;
    return _artworkCacheDir!;
  }

  /// Extract artwork from ID3 tag and save to cache
  Future<String?> _extractArtwork(Uint8List? imageData, String songId) async {
    try {
      if (imageData != null && imageData.isNotEmpty) {
        final cacheDir = await _getArtworkCacheDir();
        final artworkFile = File('$cacheDir/$songId.jpg');
        await artworkFile.writeAsBytes(imageData);
        return artworkFile.path;
      }
    } catch (_) {
      // Artwork extraction failed
    }
    return null;
  }

  /// Scan common music directories on the device
  Future<ScanResult> scanDevice() async {
    // Common music directories on Android
    final musicDirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Music',
      '/sdcard/Download',
    ];

    int totalNew = 0;
    int totalUpdated = 0;
    int totalFailed = 0;
    int totalFound = 0;
    final stopwatch = Stopwatch()..start();

    for (final dirPath in musicDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        final result = await scanDirectory(dirPath);
        totalNew += result.newSongs;
        totalUpdated += result.updatedSongs;
        totalFailed += result.failedFiles;
        totalFound += result.totalFound;
      }
    }

    stopwatch.stop();

    return ScanResult(
      totalFound: totalFound,
      newSongs: totalNew,
      updatedSongs: totalUpdated,
      failedFiles: totalFailed,
      duration: stopwatch.elapsed,
      cancelled: _cancelRequested,
    );
  }

  /// Scan a directory for music files
  Future<ScanResult> scanDirectory(String directoryPath) async {
    if (_isScanning) {
      return ScanResult(
        totalFound: 0,
        newSongs: 0,
        updatedSongs: 0,
        failedFiles: 0,
        duration: Duration.zero,
        cancelled: true,
      );
    }

    _isScanning = true;
    _isScanningController.add(true);
    _cancelRequested = false;

    final stopwatch = Stopwatch()..start();
    int totalFound = 0;
    int newSongs = 0;
    int updatedSongs = 0;
    int failedFiles = 0;
    final List<Song> songsToSave = [];

    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        throw Exception('Directory does not exist: $directoryPath');
      }

      // Collect all audio files
      final audioFiles = <FileSystemEntity>[];
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (_cancelRequested) break;
        if (entity is File && _isAudioFile(entity.path)) {
          audioFiles.add(entity);
        }
      }

      totalFound = audioFiles.length;
      _progressController.add(
        ScanProgress(
          current: 0,
          total: totalFound,
          currentFile: '',
          phase: ScanPhase.counting,
        ),
      );

      // Process files
      for (int i = 0; i < audioFiles.length; i++) {
        if (_cancelRequested) break;

        final file = audioFiles[i] as File;

        try {
          final existingSong = _songRepository.getSongByPath(file.path);
          final song = await _extractBasicMetadata(
            file,
            existingSongId: existingSong?.id,
          );

          if (song != null) {
            songsToSave.add(song);
            if (existingSong != null) {
              updatedSongs++;
            } else {
              newSongs++;
            }
          }

          // Save in batches
          if (songsToSave.length >= AppConstants.scanBatchSize) {
            await _songRepository.saveSongs(songsToSave);
            songsToSave.clear();
            // Emit progress after saving batch (reduces stream pressure)
            _progressController.add(
              ScanProgress(
                current: i + 1,
                total: totalFound,
                currentFile: path.basename(file.path),
                phase: ScanPhase.scanning,
                songsAdded: newSongs,
              ),
            );
            // Small delay to let UI breathe and prevent memory pressure
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          failedFiles++;
        }
      }

      // Save remaining songs
      if (songsToSave.isNotEmpty) {
        await _songRepository.saveSongs(songsToSave);
      }
    } catch (e) {
      // Handle directory errors
    } finally {
      _isScanning = false;
      _isScanningController.add(false);
      stopwatch.stop();
    }

    final result = ScanResult(
      totalFound: totalFound,
      newSongs: newSongs,
      updatedSongs: updatedSongs,
      failedFiles: failedFiles,
      duration: stopwatch.elapsed,
      cancelled: _cancelRequested,
    );

    _completeController.add(result);
    return result;
  }

  /// Cancel ongoing scan
  void cancelScan() {
    _cancelRequested = true;
  }

  bool _isAudioFile(String filePath) {
    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceFirst('.', '');
    return AppConstants.supportedAudioFormats.contains(extension);
  }

  /// Extract metadata from audio file using MetadataService
  Future<Song?> _extractBasicMetadata(
    File file, {
    String? existingSongId,
  }) async {
    try {
      final fileStat = await file.stat();
      final extension = path
          .extension(file.path)
          .toLowerCase()
          .replaceFirst('.', '');
      final basename = path.basenameWithoutExtension(file.path);
      final songId = existingSongId ?? _uuid.v4();

      // Try to extract metadata using MetadataService
      String? title;
      String? artist;
      String? album;
      String? albumArtist;
      int? trackNumber;
      int? year;
      String? genre;
      String? artworkPath;
      Duration duration = Duration.zero;
      int? bitrate;

      // Use MetadataService for extraction (handles all formats gracefully)
      final metadata = _metadataService.extractBasicMetadata(file, getImage: true);
      
      if (metadata != null) {
        title = metadata.title;
        artist = metadata.artist;
        album = metadata.album;
        albumArtist = metadata.albumArtist;
        bitrate = metadata.bitrate;
        duration = metadata.duration ?? Duration.zero;
        trackNumber = metadata.trackNumber;
        year = metadata.year;
        
        if (metadata.genres.isNotEmpty) {
          genre = metadata.genres.first;
        }
        
        // Extract artwork
        if (metadata.artworkBytes != null) {
          artworkPath = await _extractArtwork(metadata.artworkBytes, songId);
        }
      }

      // Fall back to filename parsing if tags are missing
      if (title == null || title.isEmpty) {
        if (basename.contains('-')) {
          final parts = basename.split('-');
          artist ??= parts[0].trim();
          title = parts.sublist(1).join('-').trim();
        } else {
          title = basename;
        }
      }

      artist ??= 'Unknown Artist';
      album ??= 'Unknown Album';

      return Song(
        id: songId,
        title: title,
        artist: artist,
        album: album,
        albumArtist: albumArtist,
        filePath: file.path,
        duration: duration,
        artworkPath: artworkPath,
        trackNumber: trackNumber,
        year: year,
        genre: genre,
        fileExtension: extension,
        bitrate: bitrate,
        fileSize: fileStat.size,
        dateAdded: existingSongId != null
            ? _songRepository.getSongById(existingSongId)?.dateAdded ??
                  DateTime.now()
            : DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Scan a single file
  Future<Song?> scanFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    if (!_isAudioFile(filePath)) return null;

    final existingSong = _songRepository.getSongByPath(filePath);
    final song = await _extractBasicMetadata(
      file,
      existingSongId: existingSong?.id,
    );

    if (song != null) {
      await _songRepository.saveSong(song);
    }

    return song;
  }

  /// Remove songs whose files no longer exist
  Future<int> cleanupMissingSongs() async {
    final allSongs = _songRepository.getAllSongs();
    final missingIds = <String>[];

    for (final song in allSongs) {
      if (!await File(song.filePath).exists()) {
        missingIds.add(song.id);
      }
    }

    if (missingIds.isNotEmpty) {
      await _songRepository.deleteSongs(missingIds);
    }

    return missingIds.length;
  }

  void dispose() {
    _progressController.close();
    _completeController.close();
    _isScanningController.close();
  }
}

/// Represents scan progress
class ScanProgress {
  final int current;
  final int total;
  final String currentFile;
  final ScanPhase phase;
  final int songsAdded;

  const ScanProgress({
    required this.current,
    required this.total,
    required this.currentFile,
    required this.phase,
    this.songsAdded = 0,
  });

  double get progress => total > 0 ? current / total : 0;
}

enum ScanPhase { counting, scanning, complete }

/// Represents scan result
class ScanResult {
  final int totalFound;
  final int newSongs;
  final int updatedSongs;
  final int failedFiles;
  final Duration duration;
  final bool cancelled;

  const ScanResult({
    required this.totalFound,
    required this.newSongs,
    required this.updatedSongs,
    required this.failedFiles,
    required this.duration,
    this.cancelled = false,
  });

  int get successfulScans => newSongs + updatedSongs;
}
