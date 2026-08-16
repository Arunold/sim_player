import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../core/constants/app_constants.dart';
import '../data/models/models.dart';
import '../data/repositories/song_repository.dart';
import '../providers/settings_providers.dart';

/// Audio player handler for background playback and media notifications.
///
/// Extends [BaseAudioHandler] so that playback continues when the app is in
/// the background and media controls appear on the lockscreen / notification
/// shade.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final SongRepository _songRepository;

  PlaybackQueue _queue = const PlaybackQueue(songIds: []);
  AppPlayerState _playerState = const AppPlayerState();
  ConcatenatingAudioSource? _playlist;

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

  PlaybackQueue get currentQueue => _queue;
  AppPlayerState get playerState => _playerState;
  Song? get currentSong {
    final songId = _queue.currentSongId;
    if (songId == null) return null;
    return _songRepository.getSongById(songId);
  }

  AudioPlayerHandler(this._songRepository);

  Future<void> init() async {
    // Open persistence box
    _queueBox = await Hive.openBox(AppConstants.queueBox);

    // Configure audio session
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Listen to audio session interruptions (ducking / disconnect)
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        final settingsBox = Hive.box(SettingsKeys.boxName);
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              if (settingsBox.get(
                SettingsKeys.audioDucking,
                defaultValue: true,
              )) {
                _applyVolume(_playerState.volume * 0.2);
              }
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              if (settingsBox.get(
                SettingsKeys.pauseOnDisconnect,
                defaultValue: true,
              )) {
                pause();
              }
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              if (settingsBox.get(
                SettingsKeys.audioDucking,
                defaultValue: true,
              )) {
                _applyVolume(_playerState.volume);
              }
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              break;
          }
        }
      }),
    );

    // Listen to device connection events (auto-play)
    _subscriptions.add(
      session.devicesChangedEventStream.listen((event) {
        final settingsBox = Hive.box(SettingsKeys.boxName);
        if (settingsBox.get(
          SettingsKeys.autoPlayOnConnect,
          defaultValue: false,
        )) {
          final hasNewHeadset = event.devicesAdded.any(
            (device) =>
                device.isOutput &&
                (device.type == AudioDeviceType.bluetoothA2dp ||
                    device.type == AudioDeviceType.wiredHeadphones ||
                    device.type == AudioDeviceType.wiredHeadset),
          );

          if (hasNewHeadset) {
            if (_playerState.status == PlaybackStatus.paused &&
                _queue.isNotEmpty) {
              play();
            }
          }
        }
      }),
    );

    // Listen to player state changes
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        _updatePlayerState(status: _mapProcessingState(state.processingState));
      }),
    );

    // Listen to position changes
    _subscriptions.add(
      _player.positionStream.listen((position) {
        _updatePlayerState(position: position);
      }),
    );

    // Listen to buffered position
    _subscriptions.add(
      _player.bufferedPositionStream.listen((buffered) {
        _updatePlayerState(bufferedPosition: buffered);
      }),
    );

    // Listen to duration changes
    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration != null) {
          _updatePlayerState(duration: duration);
        }
      }),
    );

    // Listen for playback completion
    _subscriptions.add(
      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _onTrackCompleted();
        }
      }),
    );

    // Listen for gapless track transitions
    // Listen to replayGain settings changes
    _subscriptions.add(
      Hive.box(SettingsKeys.boxName)
          .watch(key: SettingsKeys.replayGain)
          .listen((_) => _applyVolume(_playerState.volume)),
    );

    _subscriptions.add(
      _player.currentIndexStream.listen((index) async {
        final settingsBox = Hive.box(SettingsKeys.boxName);
        final gapless = settingsBox.get(
          SettingsKeys.gaplessPlayback,
          defaultValue: true,
        );

        if (gapless &&
            index == 1 &&
            _playlist != null &&
            _playlist!.length > 1) {
          // Seamlessly transitioned to the next track

          if (_playerState.repeatMode == RepeatMode.one) {
            // Keep same index
          } else if (_queue.hasNext) {
            _updateQueue(_queue.moveToNext());
          } else if (_playerState.repeatMode == RepeatMode.all) {
            _updateQueue(_queue.copyWith(currentIndex: 0));
          }

          final song = currentSong;
          if (song != null) {
            _currentSongController.add(song);
            _broadcastMediaItem(song);
            _songRepository.recordPlay(song.id);

            await _applyVolume(_playerState.volume);

            final nextSongId = _getNextSongIdForGapless();
            if (nextSongId != null) {
              final nextSong = _songRepository.getSongById(nextSongId);
              if (nextSong != null) {
                await _playlist!.add(
                  AudioSource.uri(
                    Uri.file(nextSong.filePath),
                    tag: nextSong.id,
                  ),
                );
              }
            }

            await _playlist!.removeAt(0);
          }
        }
      }),
    );

    // Restore saved queue
    await _restoreQueue();
  }

  // ---------------------------------------------------------------------------
  // BaseAudioHandler overrides — these are called by the system media controls
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() async {
    if (_queue.isEmpty) return;

    if (_fadeOnPausePlay) {
      final currentVolume = _playerState.volume;
      await _applyVolume(0.0);
      _player.play(); // unawaited
      _updatePlayerState(status: PlaybackStatus.playing);
      await _fadeVolume(0.0, currentVolume);
    } else {
      _player.play(); // unawaited
      _updatePlayerState(status: PlaybackStatus.playing);
    }

    // Record play count
    final songId = _queue.currentSongId;
    if (songId != null) {
      await _songRepository.recordPlay(songId);
    }
  }

  @override
  Future<void> pause() async {
    if (_fadeOnPausePlay) {
      final currentVolume = _playerState.volume;
      await _fadeVolume(currentVolume, 0.0);
      await _player.pause();
      await _applyVolume(currentVolume);
    } else {
      await _player.pause();
    }
    _queueBox.put('lastPosition', _playerState.position.inSeconds);
    _updatePlayerState(status: PlaybackStatus.paused);
  }

  @override
  Future<void> stop() async {
    _queueBox.put('lastPosition', _playerState.position.inSeconds);
    await _player.stop();
    _updatePlayerState(status: PlaybackStatus.stopped);
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (!_queue.hasNext) return;
    _updateQueue(_queue.moveToNext());
    await _loadCurrentSong();
    await play();
  }

  @override
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

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

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
    final settingsBox = Hive.box(SettingsKeys.boxName);
    final songIds = _queueBox.get('songIds', defaultValue: <String>[]);
    final currentIndex = _queueBox.get('currentIndex', defaultValue: 0);
    var isShuffled = _queueBox.get('isShuffled', defaultValue: false);
    final originalOrder = _queueBox.get('originalOrder');
    final repeatModeIndex = _queueBox.get('repeatMode', defaultValue: 0);
    final shuffleEnabled = _queueBox.get('shuffleEnabled', defaultValue: false);

    // Keep shuffle queue logic
    final keepShuffleQueue = settingsBox.get(
      SettingsKeys.keepShuffleQueue,
      defaultValue: false,
    );
    if (!keepShuffleQueue && isShuffled) {
      isShuffled = false; // Discard shuffle
    }

    if (songIds is List && songIds.isNotEmpty) {
      final validSongIds =
          (keepShuffleQueue || originalOrder == null ? songIds : originalOrder)
              .cast<String>()
              .where((id) {
                return _songRepository.getSongById(id) != null;
              })
              .toList();

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

        // Seek to last position if enabled
        final rememberPos = settingsBox.get(
          SettingsKeys.rememberLastPosition,
          defaultValue: true,
        );
        if (rememberPos) {
          final lastPosSeconds = _queueBox.get('lastPosition');
          if (lastPosSeconds is int && lastPosSeconds > 0) {
            await seek(Duration(seconds: lastPosSeconds));
          }
        }
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

    // Broadcast to system media notification
    _broadcastPlaybackState();
  }

  /// Broadcast current playback state to the system for media notification
  /// controls (play/pause button, seekbar, etc.)
  void _broadcastPlaybackState() {
    final isPlaying = _playerState.isPlaying;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapToAudioProcessingState(_playerState.status),
        playing: isPlaying,
        updatePosition: _playerState.position,
        bufferedPosition: _playerState.bufferedPosition,
        speed: _playerState.speed,
        queueIndex: _queue.currentIndex,
      ),
    );
  }

  /// Map our PlaybackStatus to audio_service's AudioProcessingState
  AudioProcessingState _mapToAudioProcessingState(PlaybackStatus status) {
    switch (status) {
      case PlaybackStatus.idle:
        return AudioProcessingState.idle;
      case PlaybackStatus.loading:
        return AudioProcessingState.loading;
      case PlaybackStatus.buffering:
        return AudioProcessingState.buffering;
      case PlaybackStatus.playing:
      case PlaybackStatus.paused:
        return AudioProcessingState.ready;
      case PlaybackStatus.stopped:
        return AudioProcessingState.completed;
      case PlaybackStatus.error:
        return AudioProcessingState.error;
    }
  }

  void _updateQueue(PlaybackQueue newQueue) {
    _queue = newQueue;
    _queueController.add(_queue);
    _currentSongController.add(currentSong);
    _saveQueue(); // Persist queue changes
  }

  /// Broadcast the current song's metadata to the system media notification
  void _broadcastMediaItem(Song song) {
    final settingsBox = Hive.box(SettingsKeys.boxName);
    final showArt = settingsBox.get(
      SettingsKeys.showAlbumArtOnLockscreen,
      defaultValue: true,
    );

    final artUri = (showArt && song.artworkPath != null)
        ? Uri.file(song.artworkPath!)
        : null;

    mediaItem.add(
      MediaItem(
        id: song.id,
        album: song.album,
        title: song.title,
        artist: song.artist,
        duration: song.duration,
        artUri: artUri,
        extras: {'filePath': song.filePath},
      ),
    );
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

      final settingsBox = Hive.box(SettingsKeys.boxName);
      final gapless = settingsBox.get(
        SettingsKeys.gaplessPlayback,
        defaultValue: true,
      );

      if (gapless) {
        final children = [
          AudioSource.uri(Uri.file(song.filePath), tag: song.id),
        ];

        final nextSongId = _getNextSongIdForGapless();
        if (nextSongId != null) {
          final nextSong = _songRepository.getSongById(nextSongId);
          if (nextSong != null) {
            children.add(
              AudioSource.uri(Uri.file(nextSong.filePath), tag: nextSong.id),
            );
          }
        }

        _playlist = ConcatenatingAudioSource(children: children);
        await _player.setAudioSource(_playlist!);
      } else {
        _playlist = null;
        await _player.setFilePath(song.filePath);
      }

      _currentSongController.add(song);

      await _applyVolume(_playerState.volume);

      // Update system media notification with song info
      _broadcastMediaItem(song);
    } catch (e) {
      _updatePlayerState(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to load: ${e.toString()}',
      );
    }
  }

  String? _getNextSongIdForGapless() {
    if (_playerState.repeatMode == RepeatMode.one) {
      return _queue.currentSongId;
    } else if (_queue.hasNext) {
      return _queue.songIds[_queue.currentIndex + 1];
    } else if (_playerState.repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      return _queue.songIds.first;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Public API — called from UI via AudioController
  // ---------------------------------------------------------------------------

  Future<void> _fadeVolume(double from, double to) async {
    print('==================== fadeVolume from: $from, to: $to');
    const steps = 10;
    final stepDuration = _fadeDuration ~/ steps;
    final volumeStep = (to - from) / steps;

    for (int i = 1; i <= steps; i++) {
      final volume = from + (volumeStep * i);
      await _applyVolume(volume);
      await Future.delayed(stepDuration);
    }
  }

  Future<void> _applyVolume(double baseVolume) async {
    final settingsBox = Hive.box(SettingsKeys.boxName);
    final rgMode = settingsBox.get(
      SettingsKeys.replayGain,
      defaultValue: 'off',
    );

    double scalar = 1.0;
    if (rgMode != 'off') {
      final song = currentSong;
      if (song != null && song.replayGain != null) {
        scalar = pow(10, song.replayGain! / 20).toDouble();
      }
    }

    // Clamp to 1.0 to ensure platform stability (some crash >1.0)
    final finalVolume = (baseVolume * scalar).clamp(0.0, 1.0);
    print('==================== applyVolume finalVolume: $finalVolume');
    await _player.setVolume(finalVolume);
  }

  Future<void> togglePlayPause() async {
    if (_playerState.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<void> fastForward([int seconds = 10]) async {
    final newPosition = _playerState.position + Duration(seconds: seconds);
    final maxPosition = _playerState.duration;
    await seek(newPosition > maxPosition ? maxPosition : newPosition);
  }

  @override
  Future<void> rewind([int seconds = 10]) async {
    final newPosition = _playerState.position - Duration(seconds: seconds);
    await seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    _updatePlayerState(volume: clampedVolume);
    await _applyVolume(clampedVolume);
  }

  @override
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

  void setAppRepeatMode(RepeatMode mode) {
    _updatePlayerState(repeatMode: mode);
    _saveQueue(); // Persist mode change
  }

  void cycleRepeatMode() {
    final modes = RepeatMode.values;
    final currentIndex = modes.indexOf(_playerState.repeatMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    setAppRepeatMode(modes[nextIndex]);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        setAppRepeatMode(RepeatMode.off);
        break;
      case AudioServiceRepeatMode.one:
        setAppRepeatMode(RepeatMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        setAppRepeatMode(RepeatMode.all);
        break;
    }
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

    // Clear media notification
    mediaItem.add(null);
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
