import 'package:flutter/material.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import '../services/game_timer.dart';
import '../widgets/wear_back_button_handler.dart';

class TimeSettingsScreen extends StatefulWidget {
  final GameTimer gameTimer;

  const TimeSettingsScreen({super.key, required this.gameTimer});

  @override
  State<TimeSettingsScreen> createState() => _TimeSettingsScreenState();
}

class _TimeSettingsScreenState extends State<TimeSettingsScreen> {
  late int _currentMinutes;
  late int _currentSeconds;
  late int _currentHalf;
  late int _extraTime;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentMinutes = widget.gameTimer.getCurrentHalfTime() ~/ 60;
    _currentSeconds = widget.gameTimer.getCurrentHalfTime() % 60;
    _currentHalf = widget.gameTimer.currentHalf;
    _extraTime = widget.gameTimer.extraTime;

    // When in 2nd half, display minutes as match time (add first-half minutes)
    final int firstHalfMinutes = widget.gameTimer.firstHalfDuration ~/ 60;
    if (_currentHalf == 2) {
      _currentMinutes += firstHalfMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WearBackButtonHandler(
      onBackPressed: () {
        // Go back to settings screen
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              // Swipe up - go back to referee screen
              Navigator.of(context).pop();
            }
          },
          child: SafeArea(
            child: WearOsScrollView(
              controller: _scrollController,
              /* physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, */
              autoHide: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          /* IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ), */
                          const Expanded(
                            child: Text(
                              'Time Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Current time display
                          /* Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Current Time',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_currentMinutes.toString().padLeft(2, '0')}:${_currentSeconds.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24), */

                          // Time adjustment controls
                          Container(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildTimeAdjustment(
                              'Minutes',
                              _currentMinutes,
                              (value) =>
                                  setState(() => _currentMinutes = value),
                              _currentHalf == 2
                                  ? (widget.gameTimer.firstHalfDuration ~/ 60)
                                  : 0,
                              _currentHalf == 2
                                  ? ((widget.gameTimer.firstHalfDuration ~/
                                            60) +
                                        (widget.gameTimer.secondHalfDuration ~/
                                            60))
                                  : (widget.gameTimer.firstHalfDuration ~/ 60),
                            ),
                          ),

                          const SizedBox(width: 24),

                          Container(
                            child: _buildTimeAdjustment(
                              'Seconds',
                              _currentSeconds,
                              (value) =>
                                  setState(() => _currentSeconds = value),
                              0,
                              59,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Half selection
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Current Half',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildHalfButton(1),
                                    const SizedBox(width: 8),
                                    _buildHalfButton(2),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Extra time adjustment
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Extra Time',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _extraTime > 0
                                          ? () => setState(() => _extraTime--)
                                          : null,
                                      icon: const Icon(
                                        Icons.remove,
                                        color: Colors.white,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withOpacity(0.1),
                                        shape: const CircleBorder(),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        '$_extraTime min',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          setState(() => _extraTime++),
                                      icon: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white
                                            .withOpacity(0.1),
                                        shape: const CircleBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Pause/Resume control (not on main screen)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.gameTimer.isReady
                                  ? () {
                                      if (widget.gameTimer.isPaused) {
                                        widget.gameTimer.resume();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Timer resumed'),
                                          ),
                                        );
                                      } else if (widget.gameTimer.isRunning) {
                                        widget.gameTimer.pause();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Timer paused'),
                                          ),
                                        );
                                      }
                                      setState(() {});
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.gameTimer.isPaused
                                    ? Colors.green
                                    : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                !widget.gameTimer.isReady
                                    ? 'GAME NOT STARTED YET'
                                    : (widget.gameTimer.isPaused
                                          ? 'RESUME TIMER'
                                          : 'PAUSE TIMER'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Apply button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _applyTimeSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'APPLY SETTINGS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildTimeAdjustment(
    String label,
    int value,
    Function(int) onChanged,
    int min,
    int max,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: const CircleBorder(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  value.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHalfButton(int half) {
    final isSelected = _currentHalf == half;
    return GestureDetector(
      onTap: () => setState(() {
        if (_currentHalf != half) {
          final int firstHalfMinutes = widget.gameTimer.firstHalfDuration ~/ 60;
          if (half == 2) {
            // Switch to 2nd half: display minutes as match time
            _currentMinutes += firstHalfMinutes;
            if (_currentMinutes < firstHalfMinutes) {
              _currentMinutes = firstHalfMinutes;
            }
          } else {
            // Switch to 1st half: show minutes within the half
            final int adjusted = _currentMinutes - firstHalfMinutes;
            final int clamped = adjusted.clamp(0, firstHalfMinutes).toInt();
            _currentMinutes = clamped;
          }
          _currentHalf = half;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          /* border: Border.all(
            color: isSelected ? Colors.blue : Colors.white.withOpacity(0.3),
          ) */
        ),
        child: Text(
          'Half $half',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _applyTimeSettings() {
    // Apply the time settings to the game timer
    final int firstHalfSeconds = widget.gameTimer.firstHalfDuration;
    int newTimeWithinHalf;
    if (_currentHalf == 2) {
      // Convert displayed match time back to seconds within the 2nd half
      final int totalMatchSeconds = _currentMinutes * 60 + _currentSeconds;
      newTimeWithinHalf = totalMatchSeconds - firstHalfSeconds;
      if (newTimeWithinHalf < 0) newTimeWithinHalf = 0;
    } else {
      newTimeWithinHalf = _currentMinutes * 60 + _currentSeconds;
    }
    widget.gameTimer.setTime(newTimeWithinHalf, _currentHalf, _extraTime);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time settings applied successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
