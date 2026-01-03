import 'package:equatable/equatable.dart';

/// Represents the current playback state
enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  stopped,
  buffering,
  error,
}

/// Represents repeat mode
enum RepeatMode {
  off,
  all,
  one,
}

/// Complete player state
class AppPlayerState extends Equatable {
  final PlaybackStatus status;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final double volume;
  final double speed;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final String? errorMessage;

  const AppPlayerState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.repeatMode = RepeatMode.off,
    this.isShuffleEnabled = false,
    this.errorMessage,
  });

  AppPlayerState copyWith({
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
    return AppPlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      errorMessage: errorMessage,
    );
  }

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isLoading => status == PlaybackStatus.loading || status == PlaybackStatus.buffering;
  bool get hasError => status == PlaybackStatus.error;
  bool get isIdle => status == PlaybackStatus.idle;

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  double get bufferedProgress {
    if (duration.inMilliseconds == 0) return 0;
    return bufferedPosition.inMilliseconds / duration.inMilliseconds;
  }

  String get positionFormatted => _formatDuration(position);
  String get durationFormatted => _formatDuration(duration);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        status,
        position,
        bufferedPosition,
        duration,
        volume,
        speed,
        repeatMode,
        isShuffleEnabled,
        errorMessage,
      ];
}
