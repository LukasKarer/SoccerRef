import 'package:flutter/material.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import '../services/game_timer.dart';
import '../models/game_session.dart';
import '../services/appwrite_service.dart';
import 'time_settings_screen.dart';
import 'roster_management_screen.dart';
import 'history_screen.dart';

class SettingsScreen extends StatefulWidget {
  final GameTimer? gameTimer;
  final GameSession? gameSession;

  const SettingsScreen({super.key, this.gameTimer, this.gameSession});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final AppwriteService _appwriteService = AppwriteService();
  bool _isLoadingCloud = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsFromCloud() async {
    if (widget.gameSession == null || widget.gameSession!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open during a game to load settings')),
      );
      return;
    }
    setState(() {
      _isLoadingCloud = true;
    });
    try {
      final latest = await _appwriteService.getGameSession(
        widget.gameSession!.id,
      );
      if (latest != null && widget.gameTimer != null) {
        // Update half durations and extra time while preserving current elapsed time and half
        widget.gameTimer!.setHalfDurations(
          latest.firstHalfDuration,
          latest.secondHalfDuration,
        );
        final int currentHalf = widget.gameTimer!.currentHalf;
        final int currentSeconds = widget.gameTimer!.elapsedSeconds;
        final int newExtra = currentHalf == 1
            ? latest.firstHalfExtraTime
            : latest.secondHalfExtraTime;
        widget.gameTimer!.setTime(currentSeconds, currentHalf, newExtra);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings loaded from cloud'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCloud = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTimer = widget.gameTimer != null;
    final bool hasSession = widget.gameSession != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WearOsScrollView(
          controller: _scrollController,
          autoHide: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Time Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: !hasTimer
                      ? const Text(
                          'Available during a game',
                          style: TextStyle(color: Colors.white70),
                        )
                      : null,
                  enabled: hasTimer,
                  onTap: hasTimer
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TimeSettingsScreen(
                                gameTimer: widget.gameTimer!,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.group, color: Colors.white),
                  title: const Text(
                    'Roster Management',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: !hasSession
                      ? const Text(
                          'Open during a game to manage rosters',
                          style: TextStyle(color: Colors.white70),
                        )
                      : null,
                  enabled: hasSession,
                  onTap: hasSession
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RosterManagementScreen(
                                session: widget.gameSession!,
                              ),
                            ),
                          );
                        }
                      : null,
                ),
                const Divider(height: 1, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.white),
                  title: const Text(
                    'Event History',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: !hasSession
                      ? const Text(
                          'Open during a game to view/delete events',
                          style: TextStyle(color: Colors.white70),
                        )
                      : null,
                  enabled: hasSession,
                  onTap: hasSession
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  HistoryScreen(session: widget.gameSession!),
                            ),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    child: ElevatedButton(
                      onPressed: (hasSession && !_isLoadingCloud)
                          ? _loadSettingsFromCloud
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoadingCloud
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'RELOAD SETTINGS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
