import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/game_session.dart';
import '../services/game_timer.dart';
import '../services/appwrite_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/qr_code_dialog.dart';
import 'event_entry_screen.dart';
import 'settings_screen.dart';
import '../widgets/wear_back_button_handler.dart';

class RefereeScreen extends StatefulWidget {
  final GameSession? gameSession;

  const RefereeScreen({super.key, this.gameSession});

  @override
  State<RefereeScreen> createState() => _RefereeScreenState();
}

class _RefereeScreenState extends State<RefereeScreen> {
  late GameSession _gameSession;
  late GameTimer _gameTimer;
  late AppwriteService _appwriteService;
  late LocalStorageService _localStorageService;
  late NotificationService _notificationService;

  bool _isGameStarted = false;
  bool _isLoadingGameSettings = false;
  bool _waitingSecondHalf = false;
  int _displaySeconds = 0;
  bool _fullTimeSignaled = false;

  @override
  void initState() {
    super.initState();
    _appwriteService = AppwriteService();
    _localStorageService = LocalStorageService();
    _notificationService = NotificationService();
    _notificationService.initialize();

    if (widget.gameSession != null) {
      _gameSession = widget.gameSession!;
      // If the game has already started (has firstHalfStartTime), initialize it
      if (_gameSession.firstHalfStartTime != null) {
        _isGameStarted = true;
      } else {
        _isGameStarted = false;
      }
    } else {
      _gameSession = GameSession(homeTeam: 'Home Team', awayTeam: 'Away Team');
      _isGameStarted = false;
    }

    _gameTimer = GameTimer();
    _gameTimer.onTick = _onTimerTick;
    _gameTimer.onHalfTime = _onHalfTime;
    _gameTimer.onFullTime = _onFullTime;

    // If loading from history and game is already started, initialize timer
    if (widget.gameSession != null && _gameSession.firstHalfStartTime != null) {
      _initializeTimerFromSavedTimes();
    }
  }

  void _onTimerTick(int seconds, int half, int extraTime) {
    setState(() {
      _displaySeconds = _gameTimer.getMatchTimeSeconds();
    });
  }

  void _initializeTimerFromSavedTimes() {
    // If we have saved half start times, calculate the current game state
    if (_gameSession.firstHalfStartTime != null) {
      final now = DateTime.now();
      final firstHalfStart = _gameSession.firstHalfStartTime!;

      // Set up the timer with the saved durations
      _gameTimer.setHalfDurations(
        _gameSession.firstHalfDuration,
        _gameSession.secondHalfDuration,
      );

      if (_gameSession.secondHalfStartTime != null) {
        // Second half has started - calculate elapsed time in second half
        final secondHalfStart = _gameSession.secondHalfStartTime!;
        final secondHalfElapsed = now.difference(secondHalfStart).inSeconds;

        // Set timer to second half with calculated elapsed time
        _gameTimer.setTime(
          secondHalfElapsed,
          2,
          _gameSession.secondHalfExtraTime,
        );
        _waitingSecondHalf = false;
        _isGameStarted = true;
      } else {
        // Still in first half - calculate elapsed time in first half
        final firstHalfElapsed = now.difference(firstHalfStart).inSeconds;

        // Check if first half should be finished
        final firstHalfDurationSeconds = _gameSession.firstHalfDuration * 60;
        if (firstHalfElapsed >= firstHalfDurationSeconds) {
          // First half is over, waiting for second half
          _gameTimer.setTime(
            firstHalfDurationSeconds,
            1,
            _gameSession.firstHalfExtraTime,
          );
          _waitingSecondHalf = true;
          _isGameStarted = true;
        } else {
          // Still in first half
          _gameTimer.setTime(
            firstHalfElapsed,
            1,
            _gameSession.firstHalfExtraTime,
          );
          _isGameStarted = true;
        }
      }

      // Start the timer if the game is active
      if (_gameSession.isActive) {
        _gameTimer.restart();
      }

      // Update display
      setState(() {
        _displaySeconds = _gameTimer.getMatchTimeSeconds();
      });
    }
  }

  void _showAmoleDQr() {
    try {
      if (_gameSession.id.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AMOLEDQrOverlay(data: _gameSession.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error showing QR: $e')));
      }
    }
  }

  void _onHalfTime() {
    // Pause and wait for explicit start of second half
    _gameTimer.pause();
    setState(() {
      _waitingSecondHalf = true;
    });

    // Cancel any pending alerts for this half
    _cancelAlertsForCurrentHalf();
  }

  void _onFullTime() {
    setState(() {
      _fullTimeSignaled = true;
    });
    _finishGame();
  }

  void _startSecondHalf() {
    _gameTimer.nextHalf();
    // Immediately reflect 45:00 on UI before the first tick arrives
    setState(() {
      _displaySeconds = _gameTimer.getMatchTimeSeconds();
      _waitingSecondHalf = false;
    });
    _gameTimer.resume();

    // Save second half start time
    _gameSession = _gameSession.copyWith(secondHalfStartTime: DateTime.now());
    _saveGameSession();

    // Schedule notifications for the new half
    _scheduleHalfBoundaryAlert();
    _scheduleExtraTimeEndAlert();
  }

  void _finishGame() async {
    _gameTimer.stop();
    await _notificationService.cancelAll();
    _gameSession = _gameSession.copyWith(
      isActive: false,
      isGameStarted: false,
      endTime: DateTime.now(),
    );

    try {
      await _appwriteService.updateGameSession(_gameSession);
      // Also save to local storage
      await _localStorageService.saveGameSession(_gameSession);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game finished successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error finishing game: $e')));
      }
    }
  }

  void _startGame() async {
    setState(() {
      _isLoadingGameSettings = true;
    });

    try {
      // Load latest game settings from cloud before starting
      if (_gameSession.id.isNotEmpty) {
        final latestGameSession = await _appwriteService.getGameSession(
          _gameSession.id,
        );
        if (latestGameSession != null) {
          _gameSession = latestGameSession;

          // Update GameTimer with the loaded settings
          _gameTimer.setHalfDurations(
            _gameSession.firstHalfDuration,
            _gameSession.secondHalfDuration,
          );

          // If we don't have saved half start times, start fresh
          if (_gameSession.firstHalfStartTime == null) {
            // Set extra times for both halves and start fresh
            _gameTimer.setTime(0, 1, _gameSession.firstHalfExtraTime);
            _gameTimer.setTime(0, 2, _gameSession.secondHalfExtraTime);

            // Set back to first half to start
            _gameTimer.setTime(
              0, // Start at 0 seconds
              1, // Start at first half
              _gameSession
                  .firstHalfExtraTime, // Use the first half extra time from cloud settings
            );
          } else {
            // Re-initialize from saved times - this will calculate the correct elapsed time
            _initializeTimerFromSavedTimes();
          }

          setState(() {});
        }
      }

      // Start the timer - either fresh or from saved state
      if (!_gameTimer.isRunning) {
        _gameTimer.start();
      }

      // Only save first half start time if it's not already saved
      if (_gameSession.firstHalfStartTime == null) {
        _gameSession = _gameSession.copyWith(
          firstHalfStartTime: DateTime.now(),
          isGameStarted: true,
        );
      } else {
        // If loading from history, ensure isGameStarted is true
        _gameSession = _gameSession.copyWith(isGameStarted: true);
      }

      setState(() {
        _isGameStarted = true;
        _isLoadingGameSettings = false;
      });

      // Schedule background alerts for this half
      _scheduleHalfBoundaryAlert();
      _scheduleExtraTimeEndAlert();

      // Save initial game session
      _saveGameSession();

      // Show success message if settings were loaded from cloud
      if (_gameSession.id.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Game settings loaded successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingGameSettings = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading game settings: $e')),
        );
      }
    }
  }

  void _addExtraTime() {
    _gameTimer.addExtraTime(1);
    setState(() {});

    // Re-schedule the extra time end alert with new duration
    _scheduleExtraTimeEndAlert();
  }

  void _finishHalf() {
    _gameTimer.finishHalf();
    setState(() {});

    // Cancel any pending alerts for this half
    _cancelAlertsForCurrentHalf();
  }

  Future<void> _saveGameSession() async {
    try {
      if (_gameSession.id.isNotEmpty) {
        await _appwriteService.updateGameSession(_gameSession);
        // Also save to local storage
        await _localStorageService.saveGameSession(_gameSession);
      } else {
        final id = await _appwriteService.createGameSession(_gameSession);
        _gameSession = _gameSession.copyWith(id: id);
        // Also save to local storage
        await _localStorageService.saveGameSession(_gameSession);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving game: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WearBackButtonHandler(
      onBackPressed: () {
        // Go back to home screen
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            try {
              if (details.primaryVelocity! < 0) {
                // Swipe up - show event entry screen
                _showEventEntryScreen();
              } else if (details.primaryVelocity! > 0) {
                // Swipe down - show time settings screen
                _openSettings();
              }
            } catch (e) {
              // Show error message if navigation fails
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Navigation error: $e')));
              }
            }
          },
          child: SafeArea(
            child: Column(
              children: [
                // Small score display at top + settings icon
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _gameSession.score,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      /* const SizedBox(width: 8),
                    IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings, color: Colors.white),
                    ), */
                    ],
                  ),
                ),

                // Large time display in center
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Main time display
                        Text(
                          _formatTimeForDisplay(_displaySeconds),
                          style: TextStyle(
                            color:
                                (_gameTimer.isReady &&
                                    _gameTimer
                                        .hasEnteredExtraTime /* &&
                                  !_gameTimer.hasExitedExtraTime */ )
                                ? Colors.orange
                                : Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Extra time indicator
                            if (_gameTimer.isReady &&
                                _gameTimer.extraTime > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (_gameTimer.isReady &&
                                          _gameTimer.hasEnteredExtraTime &&
                                          !_gameTimer.hasExitedExtraTime)
                                      ? Colors.orange.withOpacity(0.8)
                                      : (_gameTimer.isReady &&
                                                _gameTimer.hasExitedExtraTime
                                            ? Colors.grey.withOpacity(0.3)
                                            : Colors.orange.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _gameTimer.isReady
                                      ? _gameTimer.getExtraTimeStatus()
                                      : '+${_gameTimer.extraTime}min',
                                  style: TextStyle(
                                    color:
                                        (_gameTimer.isReady &&
                                            _gameTimer.hasEnteredExtraTime &&
                                            !_gameTimer.hasExitedExtraTime)
                                        ? Colors.white
                                        : (_gameTimer.isReady &&
                                                  _gameTimer.hasExitedExtraTime
                                              ? Colors.grey
                                              : Colors.orange),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Control buttons at bottom
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      // Action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show start game button when game hasn't started
                          if (!_isGameStarted) ...[
                            ElevatedButton(
                              onPressed: _isLoadingGameSettings
                                  ? null
                                  : _startGame,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoadingGameSettings
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Start Game',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ] else ...[
                            // Show finish half button in last minute of regular time or during extra time
                            if (_gameTimer.isReady &&
                                !_waitingSecondHalf &&
                                !_fullTimeSignaled &&
                                (_gameTimer.isInLastMinuteOfRegularTime ||
                                    _gameTimer.hasEnteredExtraTime)) ...[
                              ElevatedButton(
                                onPressed: _finishHalf,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Finish Half',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Start second half button when waiting
                            if (_waitingSecondHalf) ...[
                              ElevatedButton(
                                onPressed: _startSecondHalf,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.withOpacity(
                                    0.8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Start 2. Half',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            // Extra time button
                            if (!_waitingSecondHalf &&
                                _isGameStarted &&
                                !_fullTimeSignaled) ...[
                              IconButton(
                                onPressed: _addExtraTime,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.withOpacity(
                                    0.8,
                                  ),
                                  shape: const CircleBorder(),
                                ),
                                icon: const Text(
                                  '+1m',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],

                            // QR Code button
                            if (_fullTimeSignaled) ...[
                              IconButton(
                                onPressed: _showAmoleDQr,
                                icon: const HeroIcon(
                                  HeroIcons.qrCode,
                                  size: 32,
                                  color: Colors.white,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: const CircleBorder(),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeForDisplay(int gameTime) {
    int minutes = gameTime ~/ 60;
    int seconds = gameTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showEventEntryScreen() {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EventEntryScreen(
            gameTimer: _gameTimer,
            gameSession: _gameSession,
            onEventAdded: (event) async {
              setState(() {
                _gameSession.addEvent(event);
              });
              await _saveGameSession();
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening event screen: $e')),
        );
      }
    }
  }

  void _openSettings() {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              SettingsScreen(gameTimer: _gameTimer, gameSession: _gameSession),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening settings: $e')));
      }
    }
  }

  @override
  void dispose() {
    _gameTimer.dispose();
    super.dispose();
  }

  int _halfAlertId(int half) => 100 + half;
  int _extraAlertId(int half) => 200 + half;

  void _scheduleHalfBoundaryAlert() {
    if (!_gameTimer.isReady) return;
    final int half = _gameTimer.currentHalf;
    final int halfDuration = half == 1
        ? _gameTimer.firstHalfDuration
        : _gameTimer.secondHalfDuration;
    final int remainingRaw = halfDuration - _gameTimer.elapsedSeconds;
    if (remainingRaw <= 0) {
      // Already at/past boundary
      return;
    }
    final int remaining = remainingRaw.clamp(1, 1 << 31);
    final DateTime when = DateTime.now().add(Duration(seconds: remaining));

    _notificationService.scheduleVibrationNotification(
      _halfAlertId(half),
      when,
      half == 1 ? 'Half-time' : 'Full-time',
      'Time boundary reached',
    );

    // ignore: avoid_print
    print(
      '[Notify] Half boundary in ${remaining}s at ${when.toIso8601String()} (half=$half)',
    );
  }

  void _scheduleExtraTimeEndAlert() {
    if (!_gameTimer.isReady) return;
    final int half = _gameTimer.currentHalf;
    final int halfDuration = half == 1
        ? _gameTimer.firstHalfDuration
        : _gameTimer.secondHalfDuration;
    final int configuredExtraSeconds = _gameTimer.extraTime * 60;
    if (configuredExtraSeconds <= 0) {
      // Nothing to schedule, ensure previous is canceled
      _notificationService.cancel(_extraAlertId(half));
      return;
    }

    final int targetSinceHalfStart = halfDuration + configuredExtraSeconds;
    final int remainingRaw = targetSinceHalfStart - _gameTimer.elapsedSeconds;
    if (remainingRaw <= 0) {
      _notificationService.cancel(_extraAlertId(half));
      return;
    }
    final int remaining = remainingRaw.clamp(1, 1 << 31);
    final DateTime when = DateTime.now().add(Duration(seconds: remaining));
    // ignore: avoid_print
    print(
      '[Notify] Extra-time end in ${remaining}s at ${when.toIso8601String()} (half=$half)',
    );

    // Re-schedule (cancel previous if any)
    _notificationService.cancel(_extraAlertId(half));
    _notificationService.scheduleVibrationNotification(
      _extraAlertId(half),
      when,
      'Extra time finished',
      'Configured extra time window ended',
    );
  }

  void _cancelAlertsForCurrentHalf() {
    final int half = _gameTimer.currentHalf;
    _notificationService.cancel(_halfAlertId(half));
    _notificationService.cancel(_extraAlertId(half));
  }
}
