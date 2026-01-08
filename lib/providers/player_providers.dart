import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../services/audio_service.dart';
import 'service_providers.dart';

/// Stream extension to prepend a value
extension StartWithExtension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    await for (final item in this) {
      yield item;
    }
  }
}

/// Current song provider - starts with current value then listens to stream
final currentSongProvider = StreamProvider<Song?>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.currentSongStream.startWith(audioService.currentSong);
});

/// Player state provider - starts with current value then listens to stream
final playerStateProvider = StreamProvider<AppPlayerState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.playerStateStream.startWith(audioService.playerState);
});

/// Playback queue provider - starts with current value then listens to stream
final playbackQueueProvider = StreamProvider<PlaybackQueue>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.queueStream.startWith(audioService.queue);
});

/// Is playing provider (convenience)
final isPlayingProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.isPlaying,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Current position provider
final currentPositionProvider = Provider<Duration>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.position,
    loading: () => Duration.zero,
    error: (_, __) => Duration.zero,
  );
});

/// Current duration provider
final currentDurationProvider = Provider<Duration>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.duration,
    loading: () => Duration.zero,
    error: (_, __) => Duration.zero,
  );
});

/// Repeat mode provider
final repeatModeProvider = Provider<RepeatMode>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.repeatMode,
    loading: () => RepeatMode.off,
    error: (_, __) => RepeatMode.off,
  );
});

/// Shuffle enabled provider
final shuffleEnabledProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.isShuffleEnabled,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Audio service controller for UI actions
class AudioController {
  final AudioService _audioService;

  AudioController(this._audioService);

  Future<void> play() => _audioService.play();
  Future<void> pause() => _audioService.pause();
  Future<void> togglePlayPause() => _audioService.togglePlayPause();
  Future<void> stop() => _audioService.stop();
  Future<void> seek(Duration position) => _audioService.seek(position);
  Future<void> seekForward([int seconds = 10]) => _audioService.seekForward(seconds);
  Future<void> seekBackward([int seconds = 10]) => _audioService.seekBackward(seconds);
  Future<void> skipToNext() => _audioService.skipToNext();
  Future<void> skipToPrevious() => _audioService.skipToPrevious();
  Future<void> setVolume(double volume) => _audioService.setVolume(volume);
  Future<void> setSpeed(double speed) => _audioService.setSpeed(speed);
  Future<void> setSkipSilence(bool enabled) => _audioService.setSkipSilence(enabled);
  void setFadeOnPausePlay(bool enabled) => _audioService.setFadeOnPausePlay(enabled);
  void setRepeatMode(RepeatMode mode) => _audioService.setRepeatMode(mode);
  void cycleRepeatMode() => _audioService.cycleRepeatMode();
  Future<void> toggleShuffle() => _audioService.toggleShuffle();
  Future<void> playSong(Song song) => _audioService.playSong(song);
  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) =>
      _audioService.playSongs(songs, startIndex: startIndex);
  Future<void> addToQueue(Song song) => _audioService.addToQueue(song);
  Future<void> addToQueueNext(Song song) => _audioService.addToQueueNext(song);
  Future<void> playFromQueue(int index) => _audioService.playFromQueue(index);
  Future<void> removeFromQueue(int index) => _audioService.removeFromQueue(index);
  Future<void> clearQueue() => _audioService.clearQueue();
  Future<void> reorderQueue(int oldIndex, int newIndex) =>
      _audioService.reorderQueue(oldIndex, newIndex);
}

final audioControllerProvider = Provider<AudioController>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return AudioController(audioService);
});
