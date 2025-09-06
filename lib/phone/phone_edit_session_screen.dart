import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../services/appwrite_service.dart';

class PhoneEditSessionScreen extends StatefulWidget {
  final GameSession session;
  const PhoneEditSessionScreen({super.key, required this.session});

  @override
  State<PhoneEditSessionScreen> createState() => _PhoneEditSessionScreenState();
}

class _PhoneEditSessionScreenState extends State<PhoneEditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _homeTeamController;
  late TextEditingController _awayTeamController;
  late TextEditingController _homeColorController;
  late TextEditingController _awayColorController;
  late TextEditingController _firstHalfMinutesController;
  late TextEditingController _secondHalfMinutesController;
  late TextEditingController _firstHalfExtraController;
  late TextEditingController _secondHalfExtraController;
  late TextEditingController _homeRosterController;
  late TextEditingController _awayRosterController;
  late TextEditingController _onPitchHomeController;
  late TextEditingController _onPitchAwayController;

  bool _saving = false;
  final AppwriteService _appwrite = AppwriteService();

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _homeTeamController = TextEditingController(text: s.homeTeam);
    _awayTeamController = TextEditingController(text: s.awayTeam);
    _homeColorController = TextEditingController(
      text: _rgbToHex(s.homeTeamColorRgb),
    );
    _awayColorController = TextEditingController(
      text: _rgbToHex(s.awayTeamColorRgb),
    );
    _firstHalfMinutesController = TextEditingController(
      text: s.firstHalfDuration.toString(),
    );
    _secondHalfMinutesController = TextEditingController(
      text: s.secondHalfDuration.toString(),
    );
    _firstHalfExtraController = TextEditingController(
      text: s.firstHalfExtraTime.toString(),
    );
    _secondHalfExtraController = TextEditingController(
      text: s.secondHalfExtraTime.toString(),
    );
    _homeRosterController = TextEditingController(
      text: s.homeRoster.join(', '),
    );
    _awayRosterController = TextEditingController(
      text: s.awayRoster.join(', '),
    );
    _onPitchHomeController = TextEditingController(
      text: s.onPitchHomeLabels.join(', '),
    );
    _onPitchAwayController = TextEditingController(
      text: s.onPitchAwayLabels.join(', '),
    );
  }

  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _homeColorController.dispose();
    _awayColorController.dispose();
    _firstHalfMinutesController.dispose();
    _secondHalfMinutesController.dispose();
    _firstHalfExtraController.dispose();
    _secondHalfExtraController.dispose();
    _homeRosterController.dispose();
    _awayRosterController.dispose();
    _onPitchHomeController.dispose();
    _onPitchAwayController.dispose();
    super.dispose();
  }

  List<String> _splitLabels(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  int? _parseRgb(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) {
      return int.tryParse(s.substring(1), radix: 16);
    }
    if (s.startsWith('0x')) {
      return int.tryParse(s.substring(2), radix: 16);
    }
    final int? asDec = int.tryParse(s);
    if (asDec != null) return asDec & 0xFFFFFF;
    return null;
  }

  String _rgbToHex(int rgb) {
    final int v = rgb & 0xFFFFFF;
    final String hex = v.toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final String homeTeam = _homeTeamController.text.trim();
      final String awayTeam = _awayTeamController.text.trim();
      final int? homeRgb = _parseRgb(_homeColorController.text);
      final int? awayRgb = _parseRgb(_awayColorController.text);
      final int? firstHalf = int.tryParse(
        _firstHalfMinutesController.text.trim(),
      );
      final int? secondHalf = int.tryParse(
        _secondHalfMinutesController.text.trim(),
      );
      final int? firstExtra = int.tryParse(
        _firstHalfExtraController.text.trim(),
      );
      final int? secondExtra = int.tryParse(
        _secondHalfExtraController.text.trim(),
      );

      if (homeRgb == null || awayRgb == null) {
        _showSnack('Invalid color format. Use #RRGGBB or decimal.');
        setState(() => _saving = false);
        return;
      }
      if (firstHalf == null ||
          secondHalf == null ||
          firstExtra == null ||
          secondExtra == null) {
        _showSnack('Durations and extra time must be integers.');
        setState(() => _saving = false);
        return;
      }

      final List<String> homeRoster = _splitLabels(_homeRosterController.text);
      final List<String> awayRoster = _splitLabels(_awayRosterController.text);
      final List<String> onPitchHome = _splitLabels(
        _onPitchHomeController.text,
      );
      final List<String> onPitchAway = _splitLabels(
        _onPitchAwayController.text,
      );

      final updated = widget.session.copyWith(
        homeTeam: homeTeam.isEmpty ? widget.session.homeTeam : homeTeam,
        awayTeam: awayTeam.isEmpty ? widget.session.awayTeam : awayTeam,
        firstHalfDuration: firstHalf,
        secondHalfDuration: secondHalf,
        firstHalfExtraTime: firstExtra,
        secondHalfExtraTime: secondExtra,
        homeRoster: homeRoster,
        awayRoster: awayRoster,
        onPitchHomeLabels: onPitchHome,
        onPitchAwayLabels: onPitchAway,
        homeTeamColorRgb: homeRgb,
        awayTeamColorRgb: awayRgb,
      );

      await _appwrite.updateGameSession(updated);
      if (!mounted) return;
      Navigator.of(context).pop<GameSession>(updated);
    } catch (e) {
      _showSnack('Failed to save: $e');
      setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Game'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Teams', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _homeTeamController,
              decoration: const InputDecoration(labelText: 'Home team name'),
            ),
            TextFormField(
              controller: _awayTeamController,
              decoration: const InputDecoration(labelText: 'Away team name'),
            ),
            const SizedBox(height: 16),
            Text(
              'Team Colors (#RRGGBB or decimal)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _homeColorController,
              decoration: const InputDecoration(labelText: 'Home color'),
            ),
            TextFormField(
              controller: _awayColorController,
              decoration: const InputDecoration(labelText: 'Away color'),
            ),
            const SizedBox(height: 16),
            Text(
              'Durations (minutes)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstHalfMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '1st half'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _secondHalfMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '2nd half'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Extra Time (minutes)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstHalfExtraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '1st half extra',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _secondHalfExtraController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '2nd half extra',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Rosters (comma separated labels or numbers)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _homeRosterController,
              decoration: const InputDecoration(labelText: 'Home roster'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _awayRosterController,
              decoration: const InputDecoration(labelText: 'Away roster'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'On-pitch labels (manual override, comma separated)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _onPitchHomeController,
              decoration: const InputDecoration(labelText: 'On-pitch home'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _onPitchAwayController,
              decoration: const InputDecoration(labelText: 'On-pitch away'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
