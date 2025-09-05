import 'package:flutter/material.dart';
import 'package:wear_os_plugin/wear_os_scroll_view.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';
import '../services/appwrite_service.dart';

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
  final TextEditingController _newLabelController = TextEditingController();
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
    _newLabelController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _labelsForTeam(Team team) => _session.getAllRosterLabels(team);

  bool _isOnPitchLabel(Team team, String label) =>
      _session.isLabelOnPitch(team, label);

  void _toggleLabel(Team team, String label) {
    final List<String> current = List<String>.from(
      team == Team.home
          ? _session.onPitchHomeLabels
          : _session.onPitchAwayLabels,
    );
    if (current.contains(label)) {
      current.remove(label);
    } else {
      current.add(label);
    }
    _session.setOnPitchLabels(team, current);
    setState(() {});
  }

  void _addLabel(Team team) {
    final String label = _newLabelController.text.trim();
    if (label.isEmpty) return;
    _session.addRosterLabel(team, label);
    // If fewer than 11 currently set, auto-add to on-pitch until 11
    final onPitch = List<String>.from(
      team == Team.home
          ? _session.onPitchHomeLabels
          : _session.onPitchAwayLabels,
    );
    if (onPitch.length < 11 && !onPitch.contains(label)) {
      onPitch.add(label);
      _session.setOnPitchLabels(team, onPitch);
    }
    _newLabelController.clear();
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (_session.id.isNotEmpty) {
        await _appwriteService.updateGameSession(_session);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Roster saved')));
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
    final labels = _labelsForTeam(_team);
    return Scaffold(
      backgroundColor: Colors.black,
      body: WearOsScrollView(
        controller: _scrollController,
        autoHide: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Center(
                    child: Text(
                      'Roster',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
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
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: labels.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final label = labels[index];
                    final bool isOn = _isOnPitchLabel(_team, label);
                    return ListTile(
                      title: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _toggleLabel(_team, label),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOn ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
                        ),
                        child: Text(isOn ? 'On Pitch' : 'Bench'),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newLabelController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add player/person (e.g., 10 or John)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _addLabel(_team),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
