import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';
import '../services/supabase_service.dart';
import 'dart:math' as math;
import 'package:heroicons/heroicons.dart';
import '../widgets/wear_back_button_handler.dart';

class HistoryScreen extends StatefulWidget {
  final GameSession session;

  const HistoryScreen({super.key, required this.session});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late GameSession _session;
  late SupabaseService _supabaseService;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _supabaseService = SupabaseService();
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

    return WearBackButtonHandler(
      onBackPressed: () {
        // Go back to settings screen
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        /* appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ],
        ), */
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
        if (e.isSecondYellow) {
          // Second yellow card (yellow-red card) - layered effect
          return Stack(
            children: [
              // Yellow card as base
              Transform.rotate(
                angle: math.pi / 2,
                child: const Icon(
                  Icons.rectangle_rounded,
                  size: 28,
                  color: Colors.amber,
                ),
              ),
              // Red card on top, slightly offset
              Positioned(
                top: -2,
                right: -2,
                child: Transform.rotate(
                  angle: math.pi / 2,
                  child: const Icon(
                    Icons.rectangle_rounded,
                    size: 28,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        } else {
          // Straight red card - single red card
          return Transform.rotate(
            angle: math.pi / 2,
            child: const Icon(
              Icons.rectangle_rounded,
              size: 28,
              color: Colors.red,
            ),
          );
        }
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
    final String main = '${_typeLabel(e)} • $team';
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

  String _typeLabel(SoccerEvent e) {
    switch (e.type) {
      case EventType.goal:
        return e.isOwnGoal ? 'Own Goal' : 'Goal';
      case EventType.yellowCard:
        return 'Yellow';
      case EventType.redCard:
        return e.isSecondYellow ? 'Yellow-Red' : 'Red';
      case EventType.substitution:
        return 'Sub';
      case EventType.penalty:
        return 'Penalty';
    }
  }

  Future<void> _confirmDelete(SoccerEvent e) async {
    final bool? confirmed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => _DeleteConfirmationScreen(event: e),
      ),
    );
    if (confirmed == true && mounted) {
      _deleteEvent(e);
    }
  }

  Future<void> _deleteEvent(SoccerEvent e) async {
    final List<SoccerEvent> before = List<SoccerEvent>.from(_session.events);
    setState(() {
      _session.removeEvent(e);
    });
    try {
      await _supabaseService.updateGameSession(_session);
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
    }
  }
}

class _DeleteConfirmationScreen extends StatelessWidget {
  final SoccerEvent event;

  const _DeleteConfirmationScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    return WearBackButtonHandler(
      onBackPressed: () {
        Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 36,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Delete Event?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Remove ${event.displayName} (${_formatMinute(event)})?',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'DELETE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMinute(SoccerEvent e) {
    final int baseMinCeil = ((e.gameTime + 59) ~/ 60);
    final String extra = e.extraTime > 0
        ? '+${((e.extraTime + 59) ~/ 60)}'
        : '';
    return "${baseMinCeil.toString()}$extra'";
  }
}
