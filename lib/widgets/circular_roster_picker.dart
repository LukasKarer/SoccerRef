import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';

enum PlayerState {
  notExistent, // Light grey background
  existentNotOnPitch, // Red background
  existentOnPitch, // Green background
}

class CircularRosterPicker extends StatefulWidget {
  final GameSession session;
  final Team team;
  final Function(String label, PlayerState state) onStateChanged;
  final Function(String label) onAddCustomLabel;
  final bool isWatch;
  final bool showCustomAddButton;

  const CircularRosterPicker({
    super.key,
    required this.session,
    required this.team,
    required this.onStateChanged,
    required this.onAddCustomLabel,
    this.isWatch = false,
    this.showCustomAddButton = true,
  });

  @override
  State<CircularRosterPicker> createState() => _CircularRosterPickerState();
}

class _CircularRosterPickerState extends State<CircularRosterPicker> {
  final TextEditingController _customLabelController = TextEditingController();
  final List<int> _availableNumbers = List.generate(99, (i) => i + 1);

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  PlayerState _getPlayerState(String label) {
    final allLabels = widget.session.getAllRosterLabels(widget.team);
    if (!allLabels.contains(label)) {
      return PlayerState.notExistent;
    }

    // Check manual on-pitch list directly
    final manualList = widget.team == Team.home
        ? widget.session.onPitchHomeLabels
        : widget.session.onPitchAwayLabels;

    final isOnPitch = manualList.contains(label);
    return isOnPitch
        ? PlayerState.existentOnPitch
        : PlayerState.existentNotOnPitch;
  }

  void _cyclePlayerState(String label) {
    final currentState = _getPlayerState(label);
    PlayerState newState;

    switch (currentState) {
      case PlayerState.notExistent:
        newState = PlayerState.existentOnPitch;
        break;
      case PlayerState.existentOnPitch:
        newState = PlayerState.existentNotOnPitch;
        break;
      case PlayerState.existentNotOnPitch:
        newState = PlayerState.notExistent;
        break;
    }

    widget.onStateChanged(label, newState);
  }

  Color _getStateColor(PlayerState state) {
    switch (state) {
      case PlayerState.notExistent:
        return Colors.grey.shade400;
      case PlayerState.existentNotOnPitch:
        return Colors.red.shade400;
      case PlayerState.existentOnPitch:
        return Colors.green.shade400;
    }
  }

  void _addCustomLabel() {
    final label = _customLabelController.text.trim();
    if (label.isNotEmpty) {
      widget.onAddCustomLabel(label);
      _customLabelController.clear();
    }
  }

  Widget _buildPlayerAvatar(String label, PlayerState state) {
    final color = _getStateColor(state);
    final size = widget.isWatch ? 40.0 : 50.0;

    return GestureDetector(
      onTap: () => _cyclePlayerState(label),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: widget.isWatch ? 14 : 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grid of player avatars - non-scrollable
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildNonScrollableGrid(),
        ),

        // Custom label input (only show if showCustomAddButton is true)
        if (widget.showCustomAddButton)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customLabelController,
                    style: TextStyle(
                      color: widget.isWatch ? Colors.white : null,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add custom label (e.g., Coach)',
                      hintStyle: TextStyle(
                        color: widget.isWatch
                            ? Colors.white.withOpacity(0.6)
                            : null,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCustomLabel,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNonScrollableGrid() {
    final crossAxisCount = widget.isWatch ? 4 : 6;
    final rows = (_availableNumbers.length / crossAxisCount).ceil();

    return Column(
      children: List.generate(rows, (rowIndex) {
        final startIndex = rowIndex * crossAxisCount;
        final endIndex = (startIndex + crossAxisCount).clamp(
          0,
          _availableNumbers.length,
        );
        final rowNumbers = _availableNumbers.sublist(startIndex, endIndex);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              for (int i = 0; i < crossAxisCount; i++)
                Expanded(
                  child: i < rowNumbers.length
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildPlayerAvatar(
                            rowNumbers[i].toString(),
                            _getPlayerState(rowNumbers[i].toString()),
                          ),
                        )
                      : const SizedBox(), // Empty space for incomplete rows
                ),
            ],
          ),
        );
      }),
    );
  }
}
