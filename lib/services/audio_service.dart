import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../core/constants/app_constants.dart';
import '../data/models/models.dart';
import '../data/repositories/song_repository.dart';

/// Audio service for managing playback
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final SongRepository _songRepository;

  PlaybackQueue _queue = const PlaybackQueue(songIds: []);
  AppPlayerState _playerState = const AppPlayerState();

  // Settings
  bool _fadeOnPausePlay = false;
  static const Duration _fadeDuration = Duration(milliseconds: 300);

  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // Persistence box
  late Box _queueBox;

  final _queueController = StreamController<PlaybackQueue>.broadcast();
  final _playerStateController = StreamController<AppPlayerState>.broadcast();
  final _currentSongController = StreamController<Song?>.broadcast();

  Stream<PlaybackQueue> get queueStream => _queueController.stream;
  Stream<AppPlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  PlaybackQueue get queue => _queue;
  AppPlayerState get playerState => _playerState;
  Song? get currentSong {
    final songId = _queue.currentSongId;
    if (songId == null) return null;
    return _songRepository.getSongById(songId);
  }

  AudioService(this._songRepository);

  Future<void> init() async {
    // Open persistence box
    _queueBox = await Hive.openBox(AppConstants.queueBox);

    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to player state changes
    _subscriptions.add(_player.playerStateStream.listen((state) {
      _updatePlayerState(status: _mapProcessingState(state.processingState));
    }));

    // Listen to position changes
    _subscriptions.add(_player.positionStream.listen((position) {
      _updatePlayerState(position: position);
    }));

    // Listen to buffered position
    _subscriptions.add(_player.bufferedPositionStream.listen((buffered) {
      _updatePlayerState(bufferedPosition: buffered);
    }));

    // Listen to duration changes
    _subscriptions.add(_player.durationStream.listen((duration) {
      if (duration != null) {
        _updatePlayerState(duration: duration);
      }
    }));

    // Listen for playback completion
    _subscriptions.add(_player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _onTrackCompleted();
      }
    }));

    // Restore saved queue
    await _restoreQueue();
  }

  /// Save current queue to persistent storage
  Future<void> _saveQueue() async {
    await _queueBox.put('songIds', _queue.songIds);
    await _queueBox.put('currentIndex', _queue.currentIndex);
    await _queueBox.put('isShuffled', _queue.isShuffled);
    await _queueBox.put('originalOrder', _queue.originalOrder);
    await _queueBox.put('repeatMode', _playerState.repeatMode.index);
    await _queueBox.put('shuffleEnabled', _playerState.isShuffleEnabled);
  }

  /// Restore queue from persistent storage
  Future<void> _restoreQueue() async {
    final songIds = _queueBox.get('songIds', defaultValue: <String>[]);
    final currentIndex = _queueBox.get('currentIndex', defaultValue: 0);
    final isShuffled = _queueBox.get('isShuffled', defaultValue: false);
    final originalOrder = _queueBox.get('originalOrder');
    final repeatModeIndex = _queueBox.get('repeatMode', defaultValue: 0);
    final shuffleEnabled = _queueBox.get('shuffleEnabled', defaultValue: false);

    if (songIds is List && songIds.isNotEmpty) {
      final validSongIds = songIds.cast<String>().where((id) {
        return _songRepository.getSongById(id) != null;
      }).toList();

      if (validSongIds.isNotEmpty) {
        final adjustedIndex = currentIndex.clamp(0, validSongIds.length - 1);

        _queue = PlaybackQueue(
          songIds: validSongIds,
          currentIndex: adjustedIndex,
          isShuffled: isShuffled,
          originalOrder: originalOrder != null
              ? (originalOrder as List).cast<String>()
              : null,
        );

        _playerState = _playerState.copyWith(
          repeatMode: RepeatMode
              .values[repeatModeIndex.clamp(0, RepeatMode.values.length - 1)],
          isShuffleEnabled: shuffleEnabled,
        );

        _queueController.add(_queue);
        _playerStateController.add(_playerState);

        // Load the song but don't auto-play
        await _loadCurrentSong();
      }
    }
  }

  PlaybackStatus _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return PlaybackStatus.idle;
      case ProcessingState.loading:
        return PlaybackStatus.loading;
      case ProcessingState.buffering:
        return PlaybackStatus.buffering;
      case ProcessingState.ready:
        return _player.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
      case ProcessingState.completed:
        return PlaybackStatus.stopped;
    }
  }

  void _updatePlayerState({
    PlaybackStatus? status,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    double? volume,
    double? speed,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    String? errorMessage,
  }) {
    _playerState = _playerState.copyWith(
      status: status,
      position: position,
      bufferedPosition: bufferedPosition,
      duration: duration,
      volume: volume,
      speed: speed,
      repeatMode: repeatMode,
      isShuffleEnabled: isShuffleEnabled,
      errorMessage: errorMessage,
    );
    _playerStateController.add(_playerState);
  }

  void _updateQueue(PlaybackQueue newQueue) {
    _queue = newQueue;
    _queueController.add(_queue);
    _currentSongController.add(currentSong);
    _saveQueue(); // Persist queue changes
  }

  Future<void> _onTrackCompleted() async {
    switch (_playerState.repeatMode) {
      case RepeatMode.one:
        await seek(Duration.zero);
        await play();
        break;
      case RepeatMode.all:
        if (_queue.hasNext) {
          await skipToNext();
        } else {
          _updateQueue(_queue.copyWith(currentIndex: 0));
          await _loadCurrentSong();
          await play();
        }
        break;
      case RepeatMode.off:
        if (_queue.hasNext) {
          await skipToNext();
        } else {
          _updatePlayerState(status: PlaybackStatus.stopped);
        }
        break;
    }
  }

  Future<void> _loadCurrentSong() async {
    final song = currentSong;
    if (song == null) return;

    try {
      _updatePlayerState(status: PlaybackStatus.loading);
      await _player.setFilePath(song.filePath);
      _currentSongController.add(song);
    } catch (e) {
      _updatePlayerState(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to load: ${e.toString()}',
      );
    }
  }

  // Playback Controls

  Future<void> play() async {
    if (_queue.isEmpty) return;
    
    if (_fadeOnPausePlay) {
      // Start at low volume and fade in
      await _player.setVolume(0.0);
      await _player.play();
      _updatePlayerState(status: PlaybackStatus.playing);
      await _fadeVolume(0.0, _playerState.volume);
    } else {
      await _player.play();
      _updatePlayerState(status: PlaybackStatus.playing);
    }

    // Record play count
    final songId = _queue.currentSongId;
    if (songId != null) {
      await _songRepository.recordPlay(songId);
    }
  }

  Future<void> pause() async {
    if (_fadeOnPausePlay) {
      // Fade out before pausing
      final currentVolume = _playerState.volume;
      await _fadeVolume(currentVolume, 0.0);
      await _player.pause();
      // Restore volume for next play
      await _player.setVolume(currentVolume);
    } else {
      await _player.pause();
    }
    _updatePlayerState(status: PlaybackStatus.paused);
  }

  /// Smoothly fade volume from one level to another
  Future<void> _fadeVolume(double from, double to) async {
    const steps = 10;
    final stepDuration = _fadeDuration ~/ steps;
    final volumeStep = (to - from) / steps;

    for (int i = 1; i <= steps; i++) {
      final volume = from + (volumeStep * i);
      await _player.setVolume(volume.clamp(0.0, 1.0));
      await Future.delayed(stepDuration);
    }
  }

  Future<void> togglePlayPause() async {
    if (_playerState.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _updatePlayerState(status: PlaybackStatus.stopped);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> seekForward([int seconds = 10]) async {
    final newPosition = _playerState.position + Duration(seconds: seconds);
    final maxPosition = _playerState.duration;
    await seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  Future<void> seekBackward([int seconds = 10]) async {
    final newPosition = _playerState.position - Duration(seconds: seconds);
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(clampedVolume);
    _updatePlayerState(volume: clampedVolume);
  }

  Future<void> setSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 2.0);
    await _player.setSpeed(clampedSpeed);
    _updatePlayerState(speed: clampedSpeed);
  }

  /// Enable or disable skip silence feature
  Future<void> setSkipSilence(bool enabled) async {
    await _player.setSkipSilenceEnabled(enabled);
  }

  /// Enable or disable fade on play/pause
  void setFadeOnPausePlay(bool enabled) {
    _fadeOnPausePlay = enabled;
  }

  void setRepeatMode(RepeatMode mode) {
    _updatePlayerState(repeatMode: mode);
    _saveQueue(); // Persist mode change
  }

  void cycleRepeatMode() {
    final modes = RepeatMode.values;
    final currentIndex = modes.indexOf(_playerState.repeatMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    setRepeatMode(modes[nextIndex]);
  }

  Future<void> toggleShuffle() async {
    final isShuffled = !_playerState.isShuffleEnabled;
    _updatePlayerState(isShuffleEnabled: isShuffled);
    _saveQueue(); // Persist shuffle state

    if (isShuffled) {
      final currentSongId = _queue.currentSongId;
      final shuffledIds = List<String>.from(_queue.songIds)..shuffle(Random());

      // Move current song to the front
      if (currentSongId != null) {
        shuffledIds.remove(currentSongId);
        shuffledIds.insert(0, currentSongId);
      }

      _updateQueue(
        _queue.copyWith(
          songIds: shuffledIds,
          currentIndex: 0,
          isShuffled: true,
          originalOrder: _queue.songIds,
        ),
      );
    } else {
      // Restore original order
      if (_queue.originalOrder != null) {
        final currentSongId = _queue.currentSongId;
        final newIndex = _queue.originalOrder!.indexOf(currentSongId ?? '');
        _updateQueue(
          _queue.copyWith(
            songIds: _queue.originalOrder,
            currentIndex: newIndex >= 0 ? newIndex : 0,
            isShuffled: false,
            originalOrder: null,
          ),
        );
      }
    }
  }

  // Queue Management

  Future<void> playFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _updateQueue(_queue.copyWith(currentIndex: index));
    await _loadCurrentSong();
    await play();
  }

  Future<void> skipToNext() async {
    if (!_queue.hasNext) return;
    _updateQueue(_queue.moveToNext());
    await _loadCurrentSong();
    await play();
  }

  Future<void> skipToPrevious() async {
    // If more than 3 seconds into the song, restart it
    if (_playerState.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (!_queue.hasPrevious) return;
    _updateQueue(_queue.moveToPrevious());
    await _loadCurrentSong();
    await play();
  }

  Future<void> playSong(Song song) async {
    _updateQueue(PlaybackQueue(songIds: [song.id], currentIndex: 0));
    await _loadCurrentSong();
    await play();
  }

  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    var songIds = songs.map((s) => s.id).toList();
    var index = startIndex.clamp(0, songs.length - 1);

    if (_playerState.isShuffleEnabled) {
      final originalOrder = List<String>.from(songIds);
      songIds = List<String>.from(songIds)..shuffle(Random());
      final startSongId = songs[startIndex].id;
      songIds.remove(startSongId);
      songIds.insert(0, startSongId);

      _updateQueue(
        PlaybackQueue(
          songIds: songIds,
          currentIndex: 0,
          isShuffled: true,
          originalOrder: originalOrder,
        ),
      );
    } else {
      _updateQueue(PlaybackQueue(songIds: songIds, currentIndex: index));
    }

    await _loadCurrentSong();
    await play();
  }

  Future<void> addToQueue(Song song) async {
    _updateQueue(_queue.addSong(song.id));
  }

  Future<void> addToQueueNext(Song song) async {
    _updateQueue(_queue.addSongNext(song.id));
  }

  Future<void> removeFromQueue(int index) async {
    _updateQueue(_queue.removeSong(index));
  }

  Future<void> clearQueue() async {
    await stop();
    _updateQueue(_queue.clear());
    _currentSongController.add(null);
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;
    if (newIndex < 0 || newIndex >= _queue.length) return;

    final songIds = List<String>.from(_queue.songIds);
    final songId = songIds.removeAt(oldIndex);
    songIds.insert(newIndex, songId);

    var newCurrentIndex = _queue.currentIndex;
    if (oldIndex == _queue.currentIndex) {
      newCurrentIndex = newIndex;
    } else if (oldIndex < _queue.currentIndex &&
        newIndex >= _queue.currentIndex) {
      newCurrentIndex--;
    } else if (oldIndex > _queue.currentIndex &&
        newIndex <= _queue.currentIndex) {
      newCurrentIndex++;
    }

    _updateQueue(
      _queue.copyWith(songIds: songIds, currentIndex: newCurrentIndex),
    );
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _player.dispose();
    _queueController.close();
    _playerStateController.close();
    _currentSongController.close();
  }
}
