import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:heroicons/heroicons.dart';
import 'dart:math' as math;
import '../models/game_session.dart';
import '../models/soccer_event.dart';
import '../services/game_timer.dart';
import '../services/appwrite_service.dart';
import 'phone_edit_session_screen.dart';

class PhoneSessionScreen extends StatefulWidget {
  final GameSession gameSession;
  final GameTimer? gameTimer;

  const PhoneSessionScreen({
    super.key,
    required this.gameSession,
    this.gameTimer,
  });

  @override
  State<PhoneSessionScreen> createState() => _PhoneSessionScreenState();
}

class _PhoneSessionScreenState extends State<PhoneSessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GameSession _session;
  final AppwriteService _appwriteService = AppwriteService();
  bool _isRefreshing = false;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _session = widget.gameSession;
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh every 5 seconds to get latest events
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 60));
      if (mounted) {
        await _refreshSession();
      }
      return mounted;
    });

    // Update timestamp display every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          // Trigger rebuild to update timestamp
        });
      }
      return mounted;
    });
  }

  Future<void> _refreshSession() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final updatedSession = await _appwriteService.getGameSession(_session.id);
      if (updatedSession != null && mounted) {
        setState(() {
          _session = updatedSession;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      // Silently fail - don't show error for background refresh
      print('Failed to refresh session: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_session.homeTeam} vs ${_session.awayTeam}'),
        /* actions: [
          IconButton(
            onPressed: _refreshSession,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ], */
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Match' /* , icon: Icon(Icons.sports_soccer) */),
            Tab(text: 'Settings' /* , icon: Icon(Icons.settings) */),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMatchTab(), _buildSettingsTab()],
      ),
    );
  }

  Widget _buildMatchTab() {
    return RefreshIndicator(
      onRefresh: _refreshSession,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _session.score,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Game time and status
            /* Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _getGameTime(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getGameStatus(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24), */

            // Event history
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Event History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Updated ${_formatLastUpdated()}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_session.events.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No events yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._buildEventList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () async {
              final updated = await Navigator.of(context).push<GameSession>(
                MaterialPageRoute(
                  builder: (_) => PhoneEditSessionScreen(session: _session),
                ),
              );
              if (updated != null) {
                setState(() {
                  _session = updated;
                });
              }
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Game Settings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
          const SizedBox(height: 24),

          // Game info display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    'Kickoff',
                    _session.startTime.toLocal().toString(),
                  ),
                  _buildInfoRow('Home Team', _session.homeTeam),
                  _buildInfoRow('Away Team', _session.awayTeam),
                  _buildInfoRow(
                    '1st Half Duration',
                    '${_session.firstHalfDuration} min',
                  ),
                  _buildInfoRow(
                    '2nd Half Duration',
                    '${_session.secondHalfDuration} min',
                  ),
                  _buildInfoRow(
                    '1st Half Extra Time',
                    '${_session.firstHalfExtraTime} min',
                  ),
                  _buildInfoRow(
                    '2nd Half Extra Time',
                    '${_session.secondHalfExtraTime} min',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  List<Widget> _buildEventList() {
    final List<SoccerEvent> events = List<SoccerEvent>.from(_session.events);
    // Sort by timestamp ascending (oldest first)
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return events
        .map(
          (event) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onLongPress: () => _confirmDelete(event),
              leading: _buildLeadingIcon(event),
              title: Text(_titleFor(event)),
              subtitle: Text(_subtitleFor(event)),
              trailing: Text(
                _formatMinute(event),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildLeadingIcon(SoccerEvent e) {
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
        return CircleAvatar(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.sports_soccer, color: Colors.white),
        );
    }
  }

  String _titleFor(SoccerEvent e) {
    final String team = e.teamName;
    final String who = e.playerName.isNotEmpty
        ? e.playerName
        : (e.actorNumber?.toString() ?? '');
    final String main = '${_typeLabel(e)} • $team';
    if (e.type == EventType.substitution) return main;
    if (who.isEmpty) return main;
    return '$main • Nr.$who';
  }

  String _subtitleFor(SoccerEvent e) {
    final String minute = _formatMinute(e);
    final String desc = e.description.trim();
    if (e.type == EventType.substitution) {
      final List<String> parts = <String>[];
      if (e.substitutionOutNumber != null) {
        parts.add('OUT: Nr.${e.substitutionOutNumber}');
      }
      if (e.substitutionInNumber != null) {
        parts.add('IN: Nr.${e.substitutionInNumber}');
      }
      final String nums = parts.isNotEmpty
          ? parts.join(' ')
          : (e.playerName.isNotEmpty ? e.playerName : 'Sub');
      if (desc.isEmpty) return '$minute • $nums';
      return '$minute • $nums • $desc';
    }
    if (desc.isEmpty) return minute;
    return desc;
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

  String _getGameTime() {
    if (widget.gameTimer != null) {
      return widget.gameTimer!.formattedTime;
    }
    return 'No timer active';
  }

  String _getGameStatus() {
    if (widget.gameTimer != null) {
      if (widget.gameTimer!.isRunning) {
        return widget.gameTimer!.isPaused ? 'Paused' : 'Running';
      } else {
        return 'Stopped';
      }
    }
    return 'Timer not available';
  }

  String _formatLastUpdated() {
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  Future<void> _confirmDelete(SoccerEvent e) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Remove ${e.displayName} (${_formatMinute(e)})?'),
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
    }
  }
}
