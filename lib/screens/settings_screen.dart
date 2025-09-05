import 'package:flutter/material.dart';
import '../services/game_timer.dart';
import '../models/game_session.dart';
import 'time_settings_screen.dart';
import 'roster_management_screen.dart';
import 'history_screen.dart';

class SettingsScreen extends StatelessWidget {
  final GameTimer? gameTimer;
  final GameSession? gameSession;

  const SettingsScreen({super.key, this.gameTimer, this.gameSession});

  @override
  Widget build(BuildContext context) {
    final bool hasTimer = gameTimer != null;
    final bool hasSession = gameSession != null;
    return Scaffold(
      backgroundColor: Colors.black,
      /* appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // title: const Text('Settings'),
      ), */
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: Colors.white),
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
                          builder: (context) =>
                              TimeSettingsScreen(gameTimer: gameTimer!),
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
                          builder: (context) =>
                              RosterManagementScreen(session: gameSession!),
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
                              HistoryScreen(session: gameSession!),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
