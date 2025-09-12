import 'package:flutter/material.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import '../services/game_timer.dart';
import '../models/game_session.dart';
import '../services/appwrite_service.dart';
import '../services/sync_service.dart';
import 'time_settings_screen.dart';
import 'roster_management_screen.dart';
import 'history_screen.dart';
import '../widgets/wear_back_button_handler.dart';

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
  final SyncService _syncService = SyncService();
  bool _isLoadingCloud = false;
  bool _isSyncing = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize sync service first
    await _syncService.initialize();

    // Get initial connectivity state
    _isOnline = _syncService.isOnline;

    // Listen to connectivity changes
    _syncService.connectivityStream.listen((isOnline) {
      print('Connectivity changed: $isOnline');
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _syncService.dispose();
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

  Future<void> _manualSync() async {
    print('Manual sync called. _isOnline: $_isOnline');
    if (!_isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await _syncService.manualSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTimer = widget.gameTimer != null;
    final bool hasSession = widget.gameSession != null;
    return WearBackButtonHandler(
      onBackPressed: () {
        // Go back to referee screen
        Navigator.of(context).pop();
      },
      child: Scaffold(
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
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      child: ElevatedButton(
                        onPressed: !_isSyncing ? _manualSync : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOnline
                              ? Colors.blue
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSyncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  print(
                                    'Building button. _isOnline: $_isOnline, _isSyncing: $_isSyncing',
                                  );
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isOnline
                                            ? Icons.sync
                                            : Icons.cloud_off,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isOnline ? 'SYNC DATA' : 'OFFLINE',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
      ),
    );
  }
}
