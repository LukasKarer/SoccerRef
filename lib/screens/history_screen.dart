import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';
import '../services/appwrite_service.dart';
import 'dart:math' as math;
import 'package:heroicons/heroicons.dart';

class HistoryScreen extends StatefulWidget {
  final GameSession session;

  const HistoryScreen({super.key, required this.session});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late GameSession _session;
  late AppwriteService _appwriteService;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _appwriteService = AppwriteService();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<SoccerEvent> events = List<SoccerEvent>.from(_session.events);
    // Sort by timestamp descending (newest first)
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: Colors.black,
      body: WearOsScrollView(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Text(
                  'Event History',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (events.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No events recorded yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ] else ...[
                for (int i = 0; i < events.length; i++) ...[
                  ListTile(
                    onLongPress: () => _confirmDelete(events[i]),
                    leading: _buildLeadingIcon(events[i]),
                    title: Text(
                      _titleFor(events[i]),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _subtitleFor(events[i]),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  if (i < events.length - 1)
                    const Divider(height: 1, color: Colors.white12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(SoccerEvent e) {
    Color bg;
    IconData icon;
    switch (e.type) {
      case EventType.goal:
        return const Icon(LineIcons.futbol, size: 28, color: Colors.green);
      case EventType.yellowCard:
        return Transform.rotate(
          angle: math.pi / 2,
          child: const Icon(
            Icons.rectangle_rounded,
            size: 28,
            color: Colors.amber,
          ),
        );
      case EventType.redCard:
        return Transform.rotate(
          angle: math.pi / 2,
          child: const Icon(
            Icons.rectangle_rounded,
            size: 28,
            color: Colors.red,
          ),
        );
      case EventType.substitution:
        return const HeroIcon(
          HeroIcons.arrowPathRoundedSquare,
          size: 28,
          style: HeroIconStyle.solid,
          color: Colors.blue,
        );
      case EventType.penalty:
        bg = Colors.orange;
        icon = Icons.sports_soccer;
        break;
    }
    return CircleAvatar(
      backgroundColor: bg,
      child: Icon(icon, color: Colors.white),
    );
  }

  String _titleFor(SoccerEvent e) {
    final String team = e.teamName;
    final String who = e.playerName.isNotEmpty
        ? e.playerName
        : (e.actorNumber?.toString() ?? '');
    final String main = '${_typeLabel(e.type)} • $team';
    if (e.type == EventType.substitution) return main;
    if (who.isEmpty) return main;
    return '$main • $who';
  }

  String _subtitleFor(SoccerEvent e) {
    final String minute = _formatMinute(e);
    final String desc = e.description.trim();
    if (e.type == EventType.substitution) {
      final List<String> parts = <String>[];
      if (e.substitutionOutNumber != null) {
        parts.add('OUT: ${e.substitutionOutNumber}');
      }
      if (e.substitutionInNumber != null) {
        parts.add('IN: ${e.substitutionInNumber}');
      }
      final String nums = parts.isNotEmpty
          ? parts.join(' ')
          : (e.playerName.isNotEmpty ? e.playerName : 'Sub');
      if (desc.isEmpty) return '$minute • $nums';
      return '$minute • $nums • $desc';
    }
    if (desc.isEmpty) return minute;
    return '$minute • $desc';
  }

  String _formatMinute(SoccerEvent e) {
    final int baseMinCeil = ((e.gameTime + 59) ~/ 60);
    final String extra = e.extraTime > 0
        ? '+${((e.extraTime + 59) ~/ 60)}'
        : '';
    return "${baseMinCeil.toString()}$extra'";
  }

  String _typeLabel(EventType t) {
    switch (t) {
      case EventType.goal:
        return 'Goal';
      case EventType.yellowCard:
        return 'Yellow';
      case EventType.redCard:
        return 'Red';
      case EventType.substitution:
        return 'Sub';
      case EventType.penalty:
        return 'Penalty';
    }
  }

  Future<void> _confirmDelete(SoccerEvent e) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Delete event?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove ${e.displayName} (${_formatMinute(e)})?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _deleteEvent(e);
    }
  }

  Future<void> _deleteEvent(SoccerEvent e) async {
    final List<SoccerEvent> before = List<SoccerEvent>.from(_session.events);
    setState(() {
      _session.events.removeWhere((x) => x.id == e.id);
    });
    try {
      await _appwriteService.updateGameSession(_session);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event deleted')));
      }
    } catch (err) {
      setState(() {
        _session = _session.copyWith(events: before);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $err')));
      }
    } finally {
      // no-op
    }
  }
}
