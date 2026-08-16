import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_providers.dart';

class SleepTimerState {
  final Duration? remainingTime;
  final bool isActive;

  SleepTimerState({this.remainingTime, this.isActive = false});
}

class SleepTimerService extends Notifier<SleepTimerState> {
  Timer? _timer;

  @override
  SleepTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return SleepTimerState();
  }

  void start(Duration duration) {
    _timer?.cancel();
    state = SleepTimerState(remainingTime: duration, isActive: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime == null) {
        cancel();
        return;
      }
      
      final nextTime = state.remainingTime! - const Duration(seconds: 1);
      if (nextTime.inSeconds <= 0) {
        ref.read(audioControllerProvider).pause();
        cancel();
      } else {
        state = SleepTimerState(remainingTime: nextTime, isActive: true);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = SleepTimerState(remainingTime: null, isActive: false);
  }
}

final sleepTimerProvider = NotifierProvider<SleepTimerService, SleepTimerState>(() {
  return SleepTimerService();
});
