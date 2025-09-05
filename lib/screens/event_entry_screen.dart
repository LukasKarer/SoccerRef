import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:heroicons/heroicons.dart';
import 'package:line_icons/line_icons.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';
import '../services/game_timer.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';

// Editable options for reasons/types after number input
const List<String> kYellowCardReasonOptions = <String>[
  'Faul',
  'Unsportsmanlike behaviour',
  'Criticism',
  'Other',
];

const List<String> kRedCardReasonOptions = <String>[
  'DOGSO',
  'Faul',
  'Abusive/insulting language',
  'Unsportsmanlike behaviour',
  'Threat',
  'Violent conduct',
  'Other',
];

const List<String> kGoalTypeOptions = <String>[
  'Normal',
  'Penalty',
  'Own goal',
];

// Event Entry Screen for WearOS
class EventEntryScreen extends StatefulWidget {
  final GameTimer gameTimer;
  final GameSession gameSession;
  final Function(SoccerEvent) onEventAdded;

  const EventEntryScreen({
    super.key,
    required this.gameTimer,
    required this.gameSession,
    required this.onEventAdded,
  });

  @override
  State<EventEntryScreen> createState() => _EventEntryScreenState();
}

class _EventEntryScreenState extends State<EventEntryScreen> {
  Team? _selectedTeam;
  EventType? _selectedEventType;
  final TextEditingController _playerController = TextEditingController();
  // New state for roster-based picking
  int? _selectedNumber; // for non-substitution events
  int? _subOutNumber;
  int? _subInNumber;
  String? _selectedStaffToken; // HCO or ACO for coaches without numbers
  FixedExtentScrollController? _numberScrollController;
  bool _isReasonStep = false; // step after number selection for cards/goals
  String? _selectedReason;
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _reasonScrollController = ScrollController();

  @override
  void dispose() {
    _playerController.dispose();
    _numberScrollController?.dispose();
    _noteController.dispose();
    _reasonScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      /* appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Add Event'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ), */
      body: GestureDetector(
        onVerticalDragEnd: (_selectedTeam != null && _selectedEventType != null)
            ? null // do not register a vertical-drag recognizer when picker is active
            : (details) {
                if (details.primaryVelocity! > 0) {
                  // Swipe up - go back to referee screen
                  Navigator.of(context).pop();
                }
              },
        child: SafeArea(
          child: Column(
            children: [
              // Time display
              /* Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${_formatTime(widget.gameTimer.isReady ? widget.gameTimer.getCurrentHalfTime() : 0)} - Half ${widget.gameTimer.currentHalf}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ), */
              Expanded(child: _buildEventEntryContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventEntryContent() {
    if (_selectedTeam == null) {
      return _buildTeamSelection();
    } else if (_selectedEventType == null) {
      return _buildEventTypeSelection();
    } else if (_isReasonStep) {
      return _buildReasonNoteSelection();
    } else {
      return _buildNumberSelection();
    }
  }

  Widget _buildTeamSelection() {
    // Two full-screen buttons that occupy the entire available space
    return Row(
      children: [
        Expanded(
          child: SizedBox.expand(
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedTeam = Team.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  0xFF000000 | (widget.gameSession.homeTeamColorRgb & 0xFFFFFF),
                ),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /* const Icon(LineIcons.home, size: 36), */
                  HeroIcon(HeroIcons.home, size: 36, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    widget.gameSession.homeTeam,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SizedBox.expand(
            child: ElevatedButton(
              onPressed: () => setState(() => _selectedTeam = Team.away),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(
                  0xFF000000 | (widget.gameSession.awayTeamColorRgb & 0xFFFFFF),
                ),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: -math.pi / 2,
                    child: HeroIcon(
                      HeroIcons.paperAirplane,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.gameSession.awayTeam,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventTypeSelection() {
    // Full-screen grid with no penalty option
    final availableTypes = EventType.values
        .where((e) => e != EventType.penalty)
        .toList();

    return GridView.count(
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      children: availableTypes.map((eventType) {
        return SizedBox.expand(child: _buildEventTypeButton(eventType));
      }).toList(),
    );
  }

  Widget _buildEventTypeButton(EventType eventType) {
    Widget iconWidget;
    Color color;

    switch (eventType) {
      case EventType.goal:
        iconWidget = const Icon(
          LineIcons.futbol,
          size: 28,
          color: Colors.white,
        );
        color = Colors.green;
        break;
      case EventType.yellowCard:
        iconWidget = Transform.rotate(
          angle: math.pi / 2,
          child: const Icon(
            Icons.rectangle_rounded,
            size: 28,
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
            size: 28,
            color: Colors.white,
          ),
        );
        color = Colors.red;
        break;
      case EventType.substitution:
        iconWidget = const HeroIcon(
          HeroIcons.arrowPathRoundedSquare,
          size: 28,
          style: HeroIconStyle.solid,
          color: Colors.white,
        );
        color = Colors.blue;
        break;
      case EventType.penalty:
        iconWidget = const Icon(
          LineIcons.futbol,
          size: 28,
          color: Colors.white,
        );
        color = Colors.orange;
        break;
    }

    return ElevatedButton(
      onPressed: () => setState(() => _selectedEventType = eventType),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 6),
          Text(
            _getEventTypeLabel(eventType),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSelection() {
    final Team team = _selectedTeam!;
    final EventType eventType = _selectedEventType!;

    // Build pick list depending on event type
    List<int> numbers;
    List<String> staffLabels = <String>[];
    String title;

    final List<int> onPitch = widget.gameSession.getOnPitchPlayers(team);
    final List<int> bench = widget.gameSession.getBenchPlayers(team);
    final List<int> roster = widget.gameSession.getAllRosterNumbers(team);
    final Set<int> sentOff = widget.gameSession.getSentOffPlayers(team);
    final List<String> rosterLabels = widget.gameSession.getAllRosterLabels(
      team,
    );
    final List<String> nonNumericLabels = rosterLabels
        .where((e) => int.tryParse(e) == null)
        .toList();

    if (eventType == EventType.substitution) {
      if (_subOutNumber == null) {
        // Sub OUT: only on-pitch players
        numbers = onPitch;
        title = 'Select OUT';
      } else {
        // Sub IN: only bench players
        numbers = bench;
        title = 'Select IN';
      }
    } else if (eventType == EventType.goal) {
      // Goals: only on-pitch players
      numbers = onPitch;
      title = 'Select Scorer';
    } else {
      // Cards: keep as before, but never show sent-off people
      numbers = roster.where((n) => !sentOff.contains(n)).toList();
      // Staff labels that are not already sent off
      staffLabels = nonNumericLabels
          .where((label) => !widget.gameSession.hasRedForLabel(team, label))
          .toList();
      if (numbers.isEmpty && staffLabels.isEmpty) {
        // Fallback when roster is empty after filtering
        numbers = List<int>.generate(
          99,
          (i) => i + 1,
        ).where((n) => !sentOff.contains(n)).toList();
      }
      title = 'Select Person';
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildNumberSlider(
                  numbers,
                  maxHeight: constraints.maxHeight,
                  staffLabels: staffLabels,
                );
              },
            ),
          ),
          /* if (eventType != EventType.substitution) ...[
            const SizedBox(height: 8),
            _buildStaffChips(team),
          ], */
          const SizedBox(height: 8),
          if (eventType == EventType.substitution &&
              _subOutNumber != null &&
              _subInNumber == null)
            Text(
              'OUT: $_subOutNumber  →  pick IN',
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 8),
          SizedBox(
            child: ElevatedButton(
              onPressed: () {
                if (eventType == EventType.substitution) {
                  // Use current slider position to set OUT first, then IN
                  final current = _selectedNumber ?? numbers.first;
                  // Guard: ensure sent-off player cannot be subbed out
                  if (_subOutNumber == null &&
                      widget.gameSession
                          .getSentOffPlayers(team)
                          .contains(current)) {
                    return;
                  }
                  if (_subOutNumber == null) {
                    setState(() => _subOutNumber = current);
                    return;
                  }
                  if (_subInNumber == null) {
                    setState(() {
                      _subInNumber = current;
                      // After selecting IN, open note-only screen (no reasons)
                      _isReasonStep = true;
                      _selectedReason = null;
                      _noteController.text = '';
                    });
                    return;
                  }
                }
                if (_requiresReasonStep()) {
                  if (_canConfirmEvent()) {
                    setState(() {
                      _isReasonStep = true;
                      _selectedReason = null;
                      _noteController.text = '';
                    });
                  }
                  return;
                }
                if (_canConfirmEvent()) _createEvent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                eventType == EventType.substitution
                    ? (_subOutNumber == null
                          ? 'NEXT'
                          : (_subInNumber == null ? 'ADD IN' : 'ADD SUB'))
                    : (_requiresReasonStep() ? 'NEXT' : 'ADD EVENT'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _requiresReasonStep() {
    if (_selectedEventType == null) return false;
    return _selectedEventType == EventType.goal ||
        _selectedEventType == EventType.yellowCard ||
        _selectedEventType == EventType.redCard;
  }

  Widget _buildReasonNoteSelection() {
    final EventType eventType = _selectedEventType!;
    final List<String> options = eventType == EventType.goal
        ? kGoalTypeOptions
        : (eventType == EventType.yellowCard
              ? kYellowCardReasonOptions
              : (eventType == EventType.redCard
                    ? kRedCardReasonOptions
                    : const <String>[]));

    return Padding(
      padding: const EdgeInsets.all(12),
      child: WearOsScrollView(
        controller: _reasonScrollController,
        child: SingleChildScrollView(
          controller: _reasonScrollController,
          child: Column(
            children: [
              if (eventType != EventType.substitution) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    eventType == EventType.goal
                        ? 'Select Type'
                        : 'Select Reason',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: options.map((opt) {
                    final bool selected = _selectedReason == opt;
                    return ElevatedButton(
                      onPressed: () => setState(() => _selectedReason = opt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected
                            ? Colors.blue
                            : Colors.white.withOpacity(0.12),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      child: Text(
                        opt,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Select Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add note (optional)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                // width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (eventType == EventType.substitution ||
                          _selectedReason != null)
                      ? () {
                          _createEvent();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'ADD EVENT',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberSlider(
    List<int> allowed, {
    double? maxHeight,
    List<String> staffLabels = const <String>[],
  }) {
    // Initialize selection if null
    if (_selectedNumber == null && _selectedStaffToken == null) {
      _selectedNumber = allowed.isNotEmpty ? allowed.first : 1;
    }

    // Build unified choice list (numbers [+ HCO/ACO for non-substitution or goal])
    final bool isSub = _selectedEventType == EventType.substitution;
    final bool isGoal = _selectedEventType == EventType.goal;
    final List<String> choices = allowed.map((n) => n.toString()).toList();
    // For cards, append staff labels from roster so staff can get cards
    if (!isSub && !isGoal) {
      for (final label in staffLabels) {
        if (!choices.contains(label)) {
          choices.add(label);
        }
      }
    }

    // Ensure current selection exists in choices
    String currentLabel =
        _selectedStaffToken ?? (_selectedNumber ?? 1).toString();
    int idx = choices.indexOf(currentLabel);
    if (idx == -1) {
      // Fallback to first choice
      idx = 0;
      currentLabel = choices[idx];
      if (int.tryParse(currentLabel) != null) {
        _selectedNumber = int.tryParse(currentLabel);
        _selectedStaffToken = null;
      } else {
        _selectedStaffToken = currentLabel;
        _selectedNumber = null;
      }
    }

    String displayLabel(String? label) => label ?? '';

    // Ensure the rotary-enabled wheel starts on the current index
    if (_numberScrollController == null) {
      _numberScrollController = FixedExtentScrollController(initialItem: idx);
    } else {
      // Keep wheel in sync with current selection
      if (_numberScrollController!.selectedItem != idx &&
          _numberScrollController!.hasClients) {
        _numberScrollController!.animateToItem(
          idx,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    }

    if (choices.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('No options', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    // Cap height to avoid overshooting Wear OS screen; leave some headroom (128px)
    final double screenHeight = MediaQuery.of(context).size.height;
    final double available = maxHeight ?? (screenHeight - 128.0);
    final double targetHeight = math.max(72.0, math.min(140.0, available));
    final double wheelItemExtent = math.max(
      22.0,
      math.min(36.0, targetHeight / 3.0),
    );

    // Precompute with existing yellows for highlight in yellow-card flow
    final Set<int> playersWithYellow =
        (_selectedEventType == EventType.yellowCard && _selectedTeam != null)
        ? widget.gameSession.playersWithYellow(_selectedTeam!)
        : <int>{};
    final Set<String> staffWithYellow =
        (_selectedEventType == EventType.yellowCard && _selectedTeam != null)
        ? widget.gameSession.staffWithYellow(_selectedTeam!)
        : <String>{};

    return WearOsScrollView(
      controller: _numberScrollController!,
      autoHide: true,
      child: SizedBox(
        height: targetHeight,
        child: ListWheelScrollView.useDelegate(
          controller: _numberScrollController,
          physics: const FixedExtentScrollPhysics(),
          itemExtent: wheelItemExtent,
          overAndUnderCenterOpacity: 0.5,
          useMagnifier: true,
          magnification: 1.2,
          onSelectedItemChanged: (newIdx) {
            final String label = choices[newIdx];
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
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: choices.length,
            builder: (context, index) {
              final String label = choices[index];
              final bool isSelected =
                  index == (_numberScrollController?.selectedItem ?? idx);
              final int? asNum = int.tryParse(label);
              final bool highlightYellow =
                  (_selectedEventType == EventType.yellowCard) &&
                  ((asNum != null && playersWithYellow.contains(asNum)) ||
                      (asNum == null && staffWithYellow.contains(label)));
              final Color? bgColor = highlightYellow
                  ? Colors.yellow.withOpacity(isSelected ? 0.45 : 0.28)
                  : null;
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: bgColor,
                ),
                child: Text(
                  displayLabel(label),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: isSelected ? 28 : 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Staff chips removed; staff tokens are part of the unified list

  bool _canConfirmEvent() {
    if (_selectedTeam == null || _selectedEventType == null) return false;
    if (_selectedEventType == EventType.substitution) {
      // Require both OUT and IN before saving
      return _subOutNumber != null && _subInNumber != null;
    }
    return _selectedNumber != null || _selectedStaffToken != null;
  }

  String _getEventTypeLabel(EventType eventType) {
    switch (eventType) {
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

  void _createEvent() {
    if (!_canConfirmEvent()) return;

    // Derive base half duration and overtime seconds at the moment of event
    final int currentHalfTime = widget.gameTimer.getCurrentHalfTime();
    final int halfDurationSeconds = widget.gameTimer.currentHalf == 1
        ? widget.gameTimer.firstHalfDuration
        : widget.gameTimer.secondHalfDuration;

    final bool isInExtraTime = currentHalfTime >= halfDurationSeconds;
    final int overtimeSeconds = isInExtraTime
        ? (currentHalfTime - halfDurationSeconds)
        : 0;

    final int cappedHalfTime = isInExtraTime
        ? halfDurationSeconds
        : currentHalfTime;

    SoccerEvent event;
    if (_selectedEventType == EventType.substitution) {
      // Block invalid substitution where OUT is sent off (safety check)
      if (_subOutNumber != null &&
          widget.gameSession
              .getSentOffPlayers(_selectedTeam!)
              .contains(_subOutNumber)) {
        return;
      }
      final String note = _noteController.text.trim();
      event = SoccerEvent(
        type: _selectedEventType!,
        team: _selectedTeam!,
        playerName:
            '${_subOutNumber?.toString() ?? ''}->${_subInNumber?.toString() ?? ''}',
        description: note,
        gameTime: cappedHalfTime,
        half: widget.gameTimer.currentHalf,
        extraTime: overtimeSeconds,
        substitutionOutNumber: _subOutNumber,
        substitutionInNumber: _subInNumber,
      );
    } else {
      String description = '';
      if (_requiresReasonStep()) {
        final String reason = (_selectedReason ?? '').trim();
        final String note = _noteController.text.trim();
        description = note.isEmpty ? reason : '$reason - $note';
      }
      // If adding a yellow card and the person already has one, convert to yellow-red
      if (_selectedEventType == EventType.yellowCard) {
        if (_selectedStaffToken != null) {
          final int priorYellowsForStaff = widget.gameSession
              .yellowCountForLabel(_selectedTeam!, _selectedStaffToken!);
          if (priorYellowsForStaff >= 1) {
            event = SoccerEvent(
              type: EventType.redCard,
              team: _selectedTeam!,
              playerName: _selectedStaffToken!,
              description: description,
              gameTime: cappedHalfTime,
              half: widget.gameTimer.currentHalf,
              extraTime: overtimeSeconds,
              actorNumber: null,
              isSecondYellow: true,
            );
          } else {
            event = SoccerEvent(
              type: _selectedEventType!,
              team: _selectedTeam!,
              playerName: _selectedStaffToken!,
              description: description,
              gameTime: cappedHalfTime,
              half: widget.gameTimer.currentHalf,
              extraTime: overtimeSeconds,
              actorNumber: null,
            );
          }
        } else if (_selectedNumber != null) {
          final int priorYellowsForPlayer = widget.gameSession
              .yellowCountForPlayer(_selectedTeam!, _selectedNumber!);
          if (priorYellowsForPlayer >= 1) {
            event = SoccerEvent(
              type: EventType.redCard,
              team: _selectedTeam!,
              playerName: (_selectedNumber ?? '').toString(),
              description: description,
              gameTime: cappedHalfTime,
              half: widget.gameTimer.currentHalf,
              extraTime: overtimeSeconds,
              actorNumber: _selectedNumber,
              isSecondYellow: true,
            );
          } else {
            event = SoccerEvent(
              type: _selectedEventType!,
              team: _selectedTeam!,
              playerName: (_selectedNumber ?? '').toString(),
              description: description,
              gameTime: cappedHalfTime,
              half: widget.gameTimer.currentHalf,
              extraTime: overtimeSeconds,
              actorNumber: _selectedNumber,
            );
          }
        } else {
          // No selection; fall through to generic
          event = SoccerEvent(
            type: _selectedEventType!,
            team: _selectedTeam!,
            playerName:
                _selectedStaffToken ?? (_selectedNumber ?? '').toString(),
            description: description,
            gameTime: cappedHalfTime,
            half: widget.gameTimer.currentHalf,
            extraTime: overtimeSeconds,
            actorNumber: _selectedStaffToken == null ? _selectedNumber : null,
          );
        }
      } else {
        event = SoccerEvent(
          type: _selectedEventType!,
          team: _selectedTeam!,
          playerName: _selectedStaffToken ?? (_selectedNumber ?? '').toString(),
          description: description,
          gameTime: cappedHalfTime,
          half: widget.gameTimer.currentHalf,
          extraTime: overtimeSeconds,
          actorNumber: _selectedStaffToken == null ? _selectedNumber : null,
        );
      }
    }

    widget.onEventAdded(event);
    Navigator.of(context).pop();
  }
}
