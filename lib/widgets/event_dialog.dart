import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:heroicons/heroicons.dart';
import 'dart:math' as math;
import '../models/game_session.dart';
import '../models/soccer_event.dart';

class EventDialog extends StatefulWidget {
  final int currentHalf;
  final int gameTime;
  final GameSession? gameSession; // Optional roster context from companion app

  const EventDialog({
    super.key,
    required this.currentHalf,
    required this.gameTime,
    this.gameSession,
  });

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  Team? _selectedTeam;
  EventType? _selectedEventType;
  final TextEditingController _playerController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int? _selectedNumber; // for non-substitution events
  int? _subOutNumber;
  int? _subInNumber;
  String? _selectedStaffToken; // HCO/ACO

  @override
  void dispose() {
    _playerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Event'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Step 1: Team Selection
            if (_selectedTeam == null) ...[
              const Text(
                'Select Team',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTeamButton(
                      Team.home,
                      'Home Team',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTeamButton(Team.away, 'Away Team', Colors.red),
                  ),
                ],
              ),
            ],

            // Step 2: Event Type Selection
            if (_selectedTeam != null && _selectedEventType == null) ...[
              const SizedBox(height: 16),
              const Text(
                'Select Event Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildEventTypeGrid(),
            ],

            // Step 3: Number selection or input (with roster support)
            if (_selectedTeam != null && _selectedEventType != null)
              _buildNumberSelection(),

            // Game Time Display (always visible)
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer),
                  const SizedBox(width: 8),
                  Text(
                    'Time: ${_formatGameTime(widget.gameTime)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text('Half ${widget.currentHalf}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_selectedTeam != null && _selectedEventType != null)
          ElevatedButton(
            onPressed: _canCreateEvent() ? _createEvent : null,
            child: const Text('Add Event'),
          ),
      ],
    );
  }

  Widget _buildTeamButton(Team team, String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTeam = team;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      ),
      child: Column(
        children: [
          Icon(team == Team.home ? Icons.home : Icons.flight, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeGrid() {
    final availableTypes = EventType.values
        .where((e) => e != EventType.penalty)
        .toList();

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: availableTypes.map((eventType) {
        return _buildEventTypeButton(eventType);
      }).toList(),
    );
  }

  Widget _buildEventTypeButton(EventType eventType) {
    Widget iconWidget;
    Color color;

    switch (eventType) {
      case EventType.goal:
        iconWidget = const Icon(
          Icons.sports_soccer,
          size: 32,
          color: Colors.white,
        );
        color = Colors.green;
        break;
      case EventType.yellowCard:
        iconWidget = Transform.rotate(
          angle: math.pi / 2,
          child: const Icon(
            Icons.rectangle_rounded,
            size: 32,
            color: Colors.white,
          ),
        );
        color = Colors.amber;
        break;
      case EventType.redCard:
        iconWidget = Transform.rotate(
          angle: math.pi / 2,
          child: const Icon(
            Icons.rectangle_rounded,
            size: 32,
            color: Colors.white,
          ),
        );
        color = Colors.red;
        break;
      case EventType.substitution:
        iconWidget = const HeroIcon(
          HeroIcons.arrowPathRoundedSquare,
          size: 32,
          style: HeroIconStyle.solid,
          color: Colors.white,
        );
        color = Colors.blue;
        break;
      case EventType.penalty:
        iconWidget = const Icon(
          Icons.sports_soccer,
          size: 32,
          color: Colors.white,
        );
        color = Colors.orange;
        break;
    }

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedEventType = eventType;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 8),
          Text(
            _getEventTypeLabel(eventType),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _canCreateEvent() {
    if (_selectedTeam == null || _selectedEventType == null) return false;
    if (_selectedEventType == EventType.substitution) {
      return _subOutNumber != null && _subInNumber != null;
    }
    // Use roster picker when available; fallback to free text
    if (widget.gameSession != null) {
      return _selectedNumber != null || _selectedStaffToken != null;
    }
    return _playerController.text.trim().isNotEmpty;
  }

  String _getEventTypeLabel(EventType eventType) {
    switch (eventType) {
      case EventType.goal:
        return 'Goal';
      case EventType.yellowCard:
        return 'Yellow Card';
      case EventType.redCard:
        return 'Red Card';
      case EventType.substitution:
        return 'Substitution';
      case EventType.penalty:
        return 'Penalty';
    }
  }

  void _createEvent() {
    if (!_canCreateEvent()) return;

    SoccerEvent event;
    if (_selectedEventType == EventType.substitution) {
      event = SoccerEvent(
        type: _selectedEventType!,
        team: _selectedTeam!,
        playerName:
            '${_subOutNumber?.toString() ?? ''}->${_subInNumber?.toString() ?? ''}',
        description: _descriptionController.text.trim(),
        gameTime: widget.gameTime,
        half: widget.currentHalf,
        substitutionOutNumber: _subOutNumber,
        substitutionInNumber: _subInNumber,
      );
    } else {
      final display = widget.gameSession != null
          ? (_selectedStaffToken ?? (_selectedNumber ?? '').toString())
          : _playerController.text.trim();
      event = SoccerEvent(
        type: _selectedEventType!,
        team: _selectedTeam!,
        playerName: display,
        description: _descriptionController.text.trim(),
        gameTime: widget.gameTime,
        half: widget.currentHalf,
        actorNumber: widget.gameSession != null && _selectedStaffToken == null
            ? _selectedNumber
            : null,
      );
    }

    Navigator.of(context).pop(event);
  }

  String _formatGameTime(int gameTime) {
    int minutes = gameTime ~/ 60;
    int seconds = gameTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildNumberSelection() {
    // If no gameSession, show legacy text inputs
    if (widget.gameSession == null) {
      return Column(
        children: [
          const SizedBox(height: 16),
          TextField(
            controller: _playerController,
            decoration: const InputDecoration(
              labelText: 'Player Number or Coach',
              border: OutlineInputBorder(),
              hintText: 'e.g., 10 or Coach Name',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Additional Notes (Optional)',
              border: OutlineInputBorder(),
              hintText: 'Any additional details...',
            ),
            maxLines: 2,
          ),
        ],
      );
    }

    final Team team = _selectedTeam!;
    final EventType eventType = _selectedEventType!;
    List<int> numbers;
    String title;
    if (eventType == EventType.substitution) {
      if (_subOutNumber == null) {
        numbers = widget.gameSession!.getSubstitutionPickList(team);
        title = 'Select OUT number';
      } else {
        numbers = widget.gameSession!.getSubstitutionPickList(team);
        title = 'Select IN number';
      }
    } else {
      final players = widget.gameSession!.getTeamPlayers(team);
      numbers = players.isEmpty
          ? List<int>.generate(99, (i) => i + 1)
          : players;
      title = 'Select Number';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildSlider(numbers),
        if (eventType != EventType.substitution) ...[
          const SizedBox(height: 8),
          _buildStaffChips(team),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes (Optional)',
            border: OutlineInputBorder(),
            hintText: 'Any additional details...',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildStaffChips(Team team) {
    final String token = team == Team.home ? 'HCO' : 'ACO';
    final bool selected = _selectedStaffToken == token;
    return ChoiceChip(
      label: Text(token),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedStaffToken = selected ? null : token;
          if (_selectedStaffToken != null) _selectedNumber = null;
        });
      },
    );
  }

  Widget _buildSlider(List<int> allowed) {
    if (_selectedNumber == null) {
      _selectedNumber = allowed.isNotEmpty ? allowed.first : 1;
    }
    // Unified choices list (numbers + HCO/ACO for non-sub events)
    final bool isSub = _selectedEventType == EventType.substitution;
    final List<String> choices = allowed.map((n) => n.toString()).toList();
    if (!isSub) {
      final List<String> staffTokens = ['HCO', 'ACO'];
      for (final t in staffTokens.reversed) {
        if (!choices.contains(t)) choices.insert(0, t);
      }
    }

    String currentLabel =
        _selectedStaffToken ?? (_selectedNumber ?? 1).toString();
    int idx = choices.indexOf(currentLabel);
    if (idx == -1) {
      idx = 0;
      currentLabel = choices[idx];
      final int? asNum = int.tryParse(currentLabel);
      if (asNum != null) {
        _selectedNumber = asNum;
        _selectedStaffToken = null;
      } else {
        _selectedStaffToken = currentLabel;
        _selectedNumber = null;
      }
    }

    final String? prevLabel = idx > 0 ? choices[idx - 1] : null;
    final String? nextLabel = idx < choices.length - 1
        ? choices[idx + 1]
        : null;

    void applyIndex(int newIdx) {
      final int clamped = newIdx.clamp(0, choices.length - 1);
      final String label = choices[clamped];
      final int? asNum = int.tryParse(label);
      setState(() {
        if (asNum != null) {
          _selectedNumber = asNum;
          _selectedStaffToken = null;
        } else {
          _selectedStaffToken = label;
          _selectedNumber = null;
        }
      });
    }

    void stepUp() => applyIndex(idx + 1);
    void stepDown() => applyIndex(idx - 1);

    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          final dy = signal.scrollDelta.dy;
          if (dy > 0) {
            stepDown();
          } else if (dy < 0) {
            stepUp();
          }
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) {},
        onVerticalDragUpdate: (details) {
          final double delta = details.primaryDelta ?? 0.0;
          const double stepThreshold = 6.0;
          if (delta < -stepThreshold) {
            stepUp();
          } else if (delta > stepThreshold) {
            stepDown();
          }
        },
        child: SizedBox(
          height: 140,
          child: Column(
            children: [
              if (prevLabel != null)
                Text(
                  prevLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                currentLabel,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (nextLabel != null)
                Text(
                  nextLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
