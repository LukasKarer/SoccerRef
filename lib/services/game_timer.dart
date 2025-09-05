import 'dart:async';
import 'package:vibration/vibration.dart';

class GameTimer {
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _lastResumeTime;
  int _elapsedSeconds = 0; // Elapsed within current half
  int _accruedSecondsBeforeCurrentRun =
      0; // Sum of all previous running intervals
  int _currentHalf = 1;
  int _firstHalfExtraTime = 0;
  int _secondHalfExtraTime = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  // Track extra time state
  bool _hasEnteredExtraTime = false;
  bool _hasExitedExtraTime = false;
  int _extraTimeElapsed = 0;

  // One-shot triggers for half/full time
  bool _halfTimeSignaled = false;
  bool _fullTimeSignaled = false;

  // Callbacks
  Function(int seconds, int half, int extraTime)? onTick;
  Function()? onHalfTime;
  Function()? onFullTime;

  // Configurable half durations (in minutes)
  int _firstHalfDurationMinutes = 45;
  int _secondHalfDurationMinutes = 45;

  // Get half durations in seconds
  int get firstHalfDuration => _firstHalfDurationMinutes * 60;
  int get secondHalfDuration => _secondHalfDurationMinutes * 60;

  int get elapsedSeconds => _elapsedSeconds;
  int get currentHalf => _currentHalf;
  int get extraTime =>
      _currentHalf == 1 ? _firstHalfExtraTime : _secondHalfExtraTime;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get hasEnteredExtraTime => _hasEnteredExtraTime;
  bool get hasExitedExtraTime => _hasExitedExtraTime;

  String get formattedTime {
    int totalSeconds = getMatchTimeSeconds();
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;

    String halfIndicator = _currentHalf == 1 ? '1H' : '2H';
    String extraTimeIndicator = extraTime > 0 ? '+$extraTime' : '';

    return '${halfIndicator} ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} $extraTimeIndicator';
  }

  // Returns the match time in seconds (0..90+). At second-half start returns 45*60.
  int getMatchTimeSeconds() {
    if (_currentHalf == 1) {
      return getCurrentHalfTime();
    }
    return firstHalfDuration + getCurrentHalfTime();
  }

  void start() {
    if (_isRunning) return;

    _startTime = DateTime.now();
    _lastResumeTime = _startTime;
    _accruedSecondsBeforeCurrentRun = 0;
    _isRunning = true;
    _isPaused = false;

    // Reset extra time state
    _hasEnteredExtraTime = false;
    _hasExitedExtraTime = false;
    _extraTimeElapsed = 0;

    _startTimer();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;

    _isPaused = true;
    _timer?.cancel();

    // Calculate elapsed time up to pause
    if (_lastResumeTime != null) {
      _accruedSecondsBeforeCurrentRun += DateTime.now()
          .difference(_lastResumeTime!)
          .inSeconds;
      _elapsedSeconds = _accruedSecondsBeforeCurrentRun;
    }
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;

    _isPaused = false;
    _lastResumeTime = DateTime.now();

    _startTimer();
  }

  void stop() {
    _isRunning = false;
    _isPaused = false;
    _timer?.cancel();

    // Calculate final elapsed time
    if (_lastResumeTime != null) {
      _accruedSecondsBeforeCurrentRun += DateTime.now()
          .difference(_lastResumeTime!)
          .inSeconds;
      _elapsedSeconds = _accruedSecondsBeforeCurrentRun;
    }
  }

  void reset() {
    stop();
    _elapsedSeconds = 0;
    _accruedSecondsBeforeCurrentRun = 0;
    _currentHalf = 1;
    _firstHalfExtraTime = 0;
    _secondHalfExtraTime = 0;
    _startTime = null;
    _lastResumeTime = null;
    _hasEnteredExtraTime = false;
    _hasExitedExtraTime = false;
    _extraTimeElapsed = 0;
    _halfTimeSignaled = false;
    _fullTimeSignaled = false;
  }

  void addExtraTime(int minutes) {
    if (_currentHalf == 1) {
      _firstHalfExtraTime += minutes;
    } else {
      _secondHalfExtraTime += minutes;
    }

    // If we're already in extra time and adding more, no need to vibrate again
    if (_hasEnteredExtraTime && !_hasExitedExtraTime) {
      // still in extra time
    } else if (_hasExitedExtraTime) {
      // We've exited extra time. Re-enter if the newly configured extra time
      // (in seconds) is now greater than the already elapsed extra time.
      int newExtraTimeTotalSeconds = extraTime * 60;
      int extraTimeAlreadyElapsedSeconds = _extraTimeElapsed;

      if (extraTimeAlreadyElapsedSeconds < newExtraTimeTotalSeconds) {
        _vibrate();
        _hasEnteredExtraTime = true;
        _hasExitedExtraTime = false;
      }
    }
  }

  void nextHalf() {
    if (_currentHalf == 1) {
      _currentHalf = 2;
      _elapsedSeconds = 0;
      _accruedSecondsBeforeCurrentRun = 0;
      _secondHalfExtraTime = 0; // Reset second half extra time
      _startTime = DateTime.now();
      _lastResumeTime = _startTime;
      _hasEnteredExtraTime = false;
      _hasExitedExtraTime = false;
      _extraTimeElapsed = 0;
      _halfTimeSignaled = false;
      _fullTimeSignaled = false;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning || _isPaused) return;

      // Calculate elapsed time from system clock for accuracy within current half
      if (_lastResumeTime != null) {
        final int sinceLastResume = DateTime.now()
            .difference(_lastResumeTime!)
            .inSeconds;
        _elapsedSeconds = _accruedSecondsBeforeCurrentRun + sinceLastResume;
      }

      // Check for entering extra time (per half)
      int currentHalfTime = getCurrentHalfTime();
      int halfDuration = _currentHalf == 1
          ? firstHalfDuration
          : secondHalfDuration;

      // Enter extra time at 45/90 regardless of configured extraTime
      if (!_hasEnteredExtraTime && currentHalfTime >= halfDuration) {
        _hasEnteredExtraTime = true;
        _hasExitedExtraTime = false;
        _extraTimeElapsed = 0;
        _vibrate();
      }

      // Track extra time elapsed
      if (_hasEnteredExtraTime && !_hasExitedExtraTime) {
        _extraTimeElapsed = currentHalfTime - halfDuration;

        // Check if configured extra time window has ended (if any)
        if (_extraTimeElapsed >= extraTime * 60) {
          _hasExitedExtraTime = true;
          if (extraTime > 0) {
            _vibrate();
          }
        }
      }

      // Never auto-finish: remove auto half/full time triggers
      // UI will call finishHalf() when appropriate

      onTick?.call(_elapsedSeconds, _currentHalf, extraTime);
    });
  }

  void _triggerHalfTime() {
    _vibrate();
    onHalfTime?.call();
  }

  void _triggerFullTime() {
    _vibrate();
    onFullTime?.call();
  }

  void _vibrate() async {
    print('Vibrating');
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 1000, pattern: [0, 500, 200, 500]);
    }
  }

  // Get current game time in seconds for the current half
  int getCurrentHalfTime() {
    return _elapsedSeconds;
  }

  // Get remaining time for current half
  int getRemainingTime() {
    int currentHalfTime = getCurrentHalfTime();
    int halfDuration = _currentHalf == 1
        ? firstHalfDuration
        : secondHalfDuration;

    if (_hasEnteredExtraTime && !_hasExitedExtraTime) {
      // In extra time
      return (extraTime * 60) - _extraTimeElapsed;
    } else if (_hasExitedExtraTime) {
      // Extra time has ended, but timer keeps running
      return 0;
    } else {
      // Regular time
      return (halfDuration + (extraTime * 60)) - currentHalfTime;
    }
  }

  // Get current extra time status for display
  String getExtraTimeStatus() {
    if (extraTime == 0) return '';

    if (_hasEnteredExtraTime && !_hasExitedExtraTime) {
      // In extra time
      int remainingExtraTime = (extraTime * 60) - _extraTimeElapsed;
      int remainingMinutes = remainingExtraTime ~/ 60;
      int remainingSeconds = remainingExtraTime % 60;
      return '+${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else if (_hasExitedExtraTime) {
      // Extra time has ended
      return '+${extraTime}min (ended)';
    } else {
      // Extra time not yet reached
      return '+${extraTime}min';
    }
  }

  // Get current extra time elapsed in seconds
  int getExtraTimeElapsed() {
    return _extraTimeElapsed;
  }

  // Check if timer is ready and initialized
  bool get isReady {
    return _startTime != null;
  }

  // Check if we're in the last minute of regular time (before extra time)
  bool get isInLastMinuteOfRegularTime {
    if (!_isRunning || _hasEnteredExtraTime) return false;
    int halfDuration = _currentHalf == 1
        ? firstHalfDuration
        : secondHalfDuration;
    int currentHalfTime = getCurrentHalfTime();
    return currentHalfTime >= (halfDuration - 60) &&
        currentHalfTime < halfDuration;
  }

  // Finish the current half
  void finishHalf() {
    if (_currentHalf == 1) {
      _halfTimeSignaled = true;
      _triggerHalfTime();
    } else {
      _fullTimeSignaled = true;
      _triggerFullTime();
    }
  }

  // Get current game status for display
  String getGameStatus() {
    if (_currentHalf == 1) {
      if (_hasEnteredExtraTime && !_hasExitedExtraTime) {
        return '1st Half - Extra Time';
      } else if (_hasExitedExtraTime) {
        return '1st Half - Extra Time Ended';
      } else {
        return '1st Half';
      }
    } else {
      if (_hasEnteredExtraTime && !_hasExitedExtraTime) {
        return '2nd Half - Extra Time';
      } else if (_hasExitedExtraTime) {
        return '2nd Half - Extra Time Ended';
      } else {
        return '2nd Half';
      }
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  // Set half durations (in minutes)
  void setHalfDurations(int firstHalfMinutes, int secondHalfMinutes) {
    _firstHalfDurationMinutes = firstHalfMinutes;
    _secondHalfDurationMinutes = secondHalfMinutes;
  }

  // Set time manually (for time settings)
  void setTime(int seconds, int half, int extraTime) {
    // Preserve current running/paused state
    final bool wasRunning = _isRunning;
    final bool wasPaused = _isPaused;

    // Stop ticking while we reconfigure
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;

    // Apply new base values
    _currentHalf = half;
    _elapsedSeconds = seconds;
    _accruedSecondsBeforeCurrentRun = seconds;

    // Set extra time for the selected half
    if (_currentHalf == 1) {
      _firstHalfExtraTime = extraTime;
    } else {
      _secondHalfExtraTime = extraTime;
    }

    // Calibrate base timestamps; next resume will add from now
    _startTime = DateTime.now();
    _lastResumeTime = DateTime.now();

    // Reset transient state
    _hasEnteredExtraTime = false;
    _hasExitedExtraTime = false;
    _extraTimeElapsed = 0;
    _halfTimeSignaled = false;
    _fullTimeSignaled = false;

    // Restore previous state
    if (wasRunning && !wasPaused) {
      _isRunning = true;
      _isPaused = false;
      _startTimer();
    } else if (wasPaused) {
      // Keep paused but mark as running to preserve semantics
      _isRunning = true;
      _isPaused = true;
    }

    // Emit an immediate tick so UI reflects the new settings right away
    onTick?.call(_elapsedSeconds, _currentHalf, extraTime);
  }
}
