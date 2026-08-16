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
  final handler = ref.watch(audioPlayerHandlerProvider);
  return handler.currentSongStream.startWith(handler.currentSong);
});

/// Player state provider - starts with current value then listens to stream
final playerStateProvider = StreamProvider<AppPlayerState>((ref) {
  final handler = ref.watch(audioPlayerHandlerProvider);
  return handler.playerStateStream.startWith(handler.playerState);
});

/// Playback queue provider - starts with current value then listens to stream
final playbackQueueProvider = StreamProvider<PlaybackQueue>((ref) {
  final handler = ref.watch(audioPlayerHandlerProvider);
  return handler.queueStream.startWith(handler.currentQueue);
});

/// Is playing provider (convenience)
final isPlayingProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.isPlaying,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Current position provider
final currentPositionProvider = Provider<Duration>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.position,
    loading: () => Duration.zero,
    error: (_, _) => Duration.zero,
  );
});

/// Current duration provider
final currentDurationProvider = Provider<Duration>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.duration,
    loading: () => Duration.zero,
    error: (_, _) => Duration.zero,
  );
});

/// Repeat mode provider
final repeatModeProvider = Provider<RepeatMode>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.repeatMode,
    loading: () => RepeatMode.off,
    error: (_, _) => RepeatMode.off,
  );
});

/// Shuffle enabled provider
final shuffleEnabledProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerStateProvider);
  return playerState.when(
    data: (state) => state.isShuffleEnabled,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// Audio controller for UI actions — thin wrapper around AudioPlayerHandler
class AudioController {
  final AudioPlayerHandler _handler;

  AudioController(this._handler);

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> togglePlayPause() => _handler.togglePlayPause();
  Future<void> stop() => _handler.stop();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> seekForward([int seconds = 10]) => _handler.fastForward(seconds);
  Future<void> seekBackward([int seconds = 10]) => _handler.rewind(seconds);
  Future<void> skipToNext() => _handler.skipToNext();
  Future<void> skipToPrevious() => _handler.skipToPrevious();
  Future<void> setVolume(double volume) => _handler.setVolume(volume);
  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);
  Future<void> setSkipSilence(bool enabled) => _handler.setSkipSilence(enabled);
  void setFadeOnPausePlay(bool enabled) => _handler.setFadeOnPausePlay(enabled);
  void setRepeatMode(RepeatMode mode) => _handler.setAppRepeatMode(mode);
  void cycleRepeatMode() => _handler.cycleRepeatMode();
  Future<void> toggleShuffle() => _handler.toggleShuffle();
  Future<void> playSong(Song song) => _handler.playSong(song);
  Future<void> playSongs(List<Song> songs, {int startIndex = 0}) =>
      _handler.playSongs(songs, startIndex: startIndex);
  Future<void> addToQueue(Song song) => _handler.addToQueue(song);
  Future<void> addToQueueNext(Song song) => _handler.addToQueueNext(song);
  Future<void> playFromQueue(int index) => _handler.playFromQueue(index);
  Future<void> removeFromQueue(int index) => _handler.removeFromQueue(index);
  Future<void> clearQueue() => _handler.clearQueue();
  Future<void> reorderQueue(int oldIndex, int newIndex) =>
      _handler.reorderQueue(oldIndex, newIndex);
}

final audioControllerProvider = Provider<AudioController>((ref) {
  final handler = ref.watch(audioPlayerHandlerProvider);
  return AudioController(handler);
});
