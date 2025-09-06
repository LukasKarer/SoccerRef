import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import '../services/appwrite_service.dart';
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
  final AppwriteService _appwrite = AppwriteService();
  bool _loading = true;
  List<GameSession> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = await _appwrite.getAllGameSessions();
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soccer Referee'),
        actions: [
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
