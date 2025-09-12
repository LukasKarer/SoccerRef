import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../services/sync_service.dart';
import '../models/game_session.dart';
import 'phone_scan_screen.dart';
import 'settings_screen_phone.dart';
import 'phone_session_screen.dart';

class PhoneHomeScreen extends StatefulWidget {
  const PhoneHomeScreen({super.key});

  @override
  State<PhoneHomeScreen> createState() => _PhoneHomeScreenState();
}

class _PhoneHomeScreenState extends State<PhoneHomeScreen> {
  final SyncService _syncService = SyncService();
  bool _loading = true;
  bool _isOnline = false;
  List<GameSession> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _syncService.initialize();
    _load();

    // Listen to connectivity changes
    _syncService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  Future<void> _load() async {
    try {
      final sessions = await _syncService.getAllGameSessions();
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _manualSync() async {
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
      _loading = true;
    });

    try {
      await _syncService.manualSync();
      await _load();

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
          _loading = false;
        });
      }
    }
  }

  void _scanQrForGame() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PhoneScanScreen()));
  }

  void _openSession(GameSession s) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhoneSessionScreen(gameSession: s)),
    );
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soccer Referee'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _manualSync,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    _isOnline ? Icons.sync : Icons.cloud_off,
                    color: _isOnline ? Colors.green : Colors.orange,
                  ),
            tooltip: 'Sync',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PhoneSettingsScreen()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanQrForGame,
        child: const Icon(LineIcons.qrcode),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _sessions.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No sessions yet')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = _sessions[i];
                        return ListTile(
                          title: Text('${s.homeTeam} vs ${s.awayTeam}'),
                          subtitle: Text(s.startTime.toLocal().toString()),
                          trailing: s.isActive
                              ? const Chip(label: Text('Active'))
                              : const SizedBox.shrink(),
                          onTap: () => _openSession(s),
                        );
                      },
                    ),
            ),
    );
  }
}
