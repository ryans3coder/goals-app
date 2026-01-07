import 'dart:async';

import 'package:flutter/foundation.dart';

enum RoutineRunTimerStatus {
  idle,
  running,
  paused,
  completed,
}

class RoutineRunTimerController extends ChangeNotifier {
  RoutineRunTimerController({Future<void> Function()? onStepCompleted})
      : _onStepCompleted = onStepCompleted;

  final Future<void> Function()? _onStepCompleted;

  Timer? _timer;
  Duration? _remaining;
  RoutineRunTimerStatus _status = RoutineRunTimerStatus.idle;
  int _currentStepIndex = 0;

  RoutineRunTimerStatus get status => _status;
  Duration? get remaining => _remaining;
  int get currentStepIndex => _currentStepIndex;

  void startStep(int index, int durationSeconds) {
    _cancelTimer();
    _currentStepIndex = index;
    _remaining = Duration(seconds: durationSeconds);
    if (durationSeconds <= 0) {
      _status = RoutineRunTimerStatus.paused;
      notifyListeners();
      return;
    }
    _status = RoutineRunTimerStatus.running;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), _handleTick);
  }

  void pause() {
    if (_status != RoutineRunTimerStatus.running) {
      return;
    }
    _cancelTimer();
    _status = RoutineRunTimerStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status == RoutineRunTimerStatus.running) {
      return;
    }
    if (_remaining == null || _remaining!.inSeconds <= 0) {
      return;
    }
    _status = RoutineRunTimerStatus.running;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), _handleTick);
  }

  void markCompleted() {
    _cancelTimer();
    _status = RoutineRunTimerStatus.completed;
    notifyListeners();
  }

  void reset() {
    _cancelTimer();
    _remaining = null;
    _status = RoutineRunTimerStatus.idle;
    _currentStepIndex = 0;
    notifyListeners();
  }

  Future<void> _handleTick(Timer timer) async {
    if (_remaining == null) {
      timer.cancel();
      return;
    }
    if (_remaining!.inSeconds <= 1) {
      _remaining = Duration.zero;
      _status = RoutineRunTimerStatus.completed;
      notifyListeners();
      timer.cancel();
      if (_onStepCompleted != null) {
        await _onStepCompleted!.call();
      }
      return;
    }
    _remaining = _remaining! - const Duration(seconds: 1);
    notifyListeners();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
