import 'package:flutter/material.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';
import '../services/appwrite_service.dart';
import '../widgets/wear_back_button_handler.dart';
import '../widgets/circular_roster_picker.dart';

class RosterManagementScreen extends StatefulWidget {
  final GameSession session;

  const RosterManagementScreen({super.key, required this.session});

  @override
  State<RosterManagementScreen> createState() => _RosterManagementScreenState();
}

class _RosterManagementScreenState extends State<RosterManagementScreen> {
  late GameSession _session;
  late AppwriteService _appwriteService;
  Team _team = Team.home;
  bool _saving = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _customLabelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _appwriteService = AppwriteService();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  void _handleStateChanged(String label, PlayerState state) {
    // Get current state to determine what changes are needed
    final currentState = _getPlayerState(label);

    switch (state) {
      case PlayerState.notExistent:
        // Only remove if currently exists
        if (currentState != PlayerState.notExistent) {
          if (_team == Team.home) {
            _session.homeRoster.remove(label);
            _session.onPitchHomeLabels.remove(label);
          } else {
            _session.awayRoster.remove(label);
            _session.onPitchAwayLabels.remove(label);
          }
        }
        break;
      case PlayerState.existentNotOnPitch:
        // Add to roster if not existent, remove from on-pitch if currently on pitch
        if (currentState == PlayerState.notExistent) {
          // Adding new player to roster
          if (_team == Team.home) {
            _session.homeRoster.add(label);
          } else {
            _session.awayRoster.add(label);
          }
        } else if (currentState == PlayerState.existentOnPitch) {
          // Moving from on-pitch to bench
          if (_team == Team.home) {
            _session.onPitchHomeLabels.remove(label);
          } else {
            _session.onPitchAwayLabels.remove(label);
          }
        }
        // If already existentNotOnPitch, no change needed
        break;
      case PlayerState.existentOnPitch:
        // Add to roster if not existent, add to on-pitch if not already there
        if (currentState == PlayerState.notExistent) {
          // Adding new player to roster and on-pitch
          if (_team == Team.home) {
            _session.homeRoster.add(label);
            _session.onPitchHomeLabels.add(label);
          } else {
            _session.awayRoster.add(label);
            _session.onPitchAwayLabels.add(label);
          }
        } else if (currentState == PlayerState.existentNotOnPitch) {
          // Moving from bench to on-pitch
          if (_team == Team.home) {
            _session.onPitchHomeLabels.add(label);
          } else {
            _session.onPitchAwayLabels.add(label);
          }
        }
        // If already existentOnPitch, no change needed
        break;
    }
    setState(() {});

    // Save instantly to cloud on watch
    _save();
  }

  PlayerState _getPlayerState(String label) {
    final allLabels = _session.getAllRosterLabels(_team);
    if (!allLabels.contains(label)) {
      return PlayerState.notExistent;
    }

    // Check manual on-pitch list directly
    final manualList = _team == Team.home
        ? _session.onPitchHomeLabels
        : _session.onPitchAwayLabels;

    final isOnPitch = manualList.contains(label);
    return isOnPitch
        ? PlayerState.existentOnPitch
        : PlayerState.existentNotOnPitch;
  }

  void _addCustomLabel(String label) {
    if (_team == Team.home) {
      if (!_session.homeRoster.contains(label)) {
        _session.homeRoster.add(label);
      }
    } else {
      if (!_session.awayRoster.contains(label)) {
        _session.awayRoster.add(label);
      }
    }
    setState(() {});

    // Save instantly to cloud on watch
    _save();
  }

  void _handleAddCustomLabel() {
    final label = _customLabelController.text.trim();
    if (label.isNotEmpty) {
      _addCustomLabel(label);
      _customLabelController.clear();
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    // Check if more than 11 players are on pitch
    final onPitchCount = _team == Team.home
        ? _session.onPitchHomeLabels.length
        : _session.onPitchAwayLabels.length;

    if (onPitchCount > 11) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: $onPitchCount players on pitch (max 11)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    setState(() => _saving = true);
    try {
      if (_session.id.isNotEmpty) {
        await _appwriteService.updateGameSession(_session);
      }
      /* if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Roster saved')));
      } */
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving roster: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildTeamButton(Team teamVal) {
    final bool isSelected = _team == teamVal;
    return GestureDetector(
      onTap: () => setState(() => _team = teamVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          teamVal == Team.home ? 'Home' : 'Away',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WearBackButtonHandler(
      onBackPressed: () {
        // No need to save again as each change is saved instantly
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: WearOsScrollView(
          controller: _scrollController,
          autoHide: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Header with team selection
                /* Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Center(
                    child: Text(
                      'Roster - ${_team == Team.home ? "Home" : "Away"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ), */
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTeamButton(Team.home),
                      const SizedBox(width: 8),
                      _buildTeamButton(Team.away),
                    ],
                  ),
                ),
                // const SizedBox(height: 16),

                // Circular roster picker (without custom add button)
                CircularRosterPicker(
                  session: _session,
                  team: _team,
                  onStateChanged: _handleStateChanged,
                  onAddCustomLabel: _addCustomLabel,
                  isWatch: true,
                  showCustomAddButton: false, // Hide the custom add button
                ),

                // Custom add button section
                /* Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customLabelController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add custom label (e.g., Coach)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (value) => _handleAddCustomLabel(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handleAddCustomLabel,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ), */
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _customLabelController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add custom label (e.g., Coach)',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _handleAddCustomLabel(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _handleAddCustomLabel,
                  child: const Text('Add'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
