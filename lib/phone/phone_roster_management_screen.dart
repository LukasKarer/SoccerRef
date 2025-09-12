import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';
import '../services/appwrite_service.dart';
import '../widgets/circular_roster_picker.dart';

class PhoneRosterManagementScreen extends StatefulWidget {
  final GameSession session;
  final Team team;

  const PhoneRosterManagementScreen({
    super.key,
    required this.session,
    required this.team,
  });

  @override
  State<PhoneRosterManagementScreen> createState() =>
      _PhoneRosterManagementScreenState();
}

class _PhoneRosterManagementScreenState
    extends State<PhoneRosterManagementScreen> {
  late GameSession _session;
  late AppwriteService _appwriteService;
  bool _saving = false;
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

  void _handleStateChanged(String label, PlayerState state) {
    // Get current state to determine what changes are needed
    final currentState = _getPlayerState(label);

    switch (state) {
      case PlayerState.notExistent:
        // Only remove if currently exists
        if (currentState != PlayerState.notExistent) {
          if (widget.team == Team.home) {
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
          if (widget.team == Team.home) {
            _session.homeRoster.add(label);
          } else {
            _session.awayRoster.add(label);
          }
        } else if (currentState == PlayerState.existentOnPitch) {
          // Moving from on-pitch to bench
          if (widget.team == Team.home) {
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
          if (widget.team == Team.home) {
            _session.homeRoster.add(label);
            _session.onPitchHomeLabels.add(label);
          } else {
            _session.awayRoster.add(label);
            _session.onPitchAwayLabels.add(label);
          }
        } else if (currentState == PlayerState.existentNotOnPitch) {
          // Moving from bench to on-pitch
          if (widget.team == Team.home) {
            _session.onPitchHomeLabels.add(label);
          } else {
            _session.onPitchAwayLabels.add(label);
          }
        }
        // If already existentOnPitch, no change needed
        break;
    }
    setState(() {});
  }

  PlayerState _getPlayerState(String label) {
    final allLabels = _session.getAllRosterLabels(widget.team);
    if (!allLabels.contains(label)) {
      return PlayerState.notExistent;
    }

    // Check manual on-pitch list directly
    final manualList = widget.team == Team.home
        ? _session.onPitchHomeLabels
        : _session.onPitchAwayLabels;

    final isOnPitch = manualList.contains(label);
    return isOnPitch
        ? PlayerState.existentOnPitch
        : PlayerState.existentNotOnPitch;
  }

  void _addCustomLabel(String label) {
    if (widget.team == Team.home) {
      if (!_session.homeRoster.contains(label)) {
        _session.homeRoster.add(label);
      }
    } else {
      if (!_session.awayRoster.contains(label)) {
        _session.awayRoster.add(label);
      }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;

    // Check if more than 11 players are on pitch
    final onPitchCount = widget.team == Team.home
        ? _session.onPitchHomeLabels.length
        : _session.onPitchAwayLabels.length;

    if (onPitchCount > 11) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Too Many Players'),
          content: Text(
            'You have $onPitchCount players on the pitch. '
            'Only 11 players are allowed. Do you want to save anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    try {
      if (_session.id.isNotEmpty) {
        await _appwriteService.updateGameSession(_session);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Roster saved successfully')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.team == Team.home ? "Home" : "Away"} Team Roster',
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: CircularRosterPicker(
                session: _session,
                team: widget.team,
                onStateChanged: _handleStateChanged,
                onAddCustomLabel: _addCustomLabel,
                isWatch: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Roster'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
