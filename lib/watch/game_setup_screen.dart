import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/game_session.dart';
import '../services/appwrite_service.dart';
import '../services/local_storage_service.dart';
import 'referee_screen.dart';
import '../widgets/wear_back_button_handler.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _appwriteService = AppwriteService();
  final _localStorageService = LocalStorageService();
  bool _isLoading = false;
  GameSession? _gameSession;
  final TextEditingController _homePlayersCtrl = TextEditingController();
  final TextEditingController _awayPlayersCtrl = TextEditingController();
  // Coach number controllers removed

  @override
  void initState() {
    super.initState();
    _createNewGame();
  }

  void _createNewGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get device ID for this watch
      final deviceId = await _localStorageService.getDeviceId();

      // Create a default game session with basic info
      final gameSession = GameSession(
        homeTeam: 'Home Team',
        awayTeam: 'Away Team',
        firstHalfDuration: 45,
        secondHalfDuration: 45,
        deviceId: deviceId,
      );

      // Save to Appwrite
      final id = await _appwriteService.createGameSession(gameSession);
      print('Saved session id: $id');
      final savedSession = gameSession.copyWith(id: id);
      print('Saved session: ${savedSession.toJson()}');

      // Also save to local storage
      await _localStorageService.saveGameSession(savedSession);

      setState(() {
        _gameSession = savedSession;
        _isLoading = false;
        // Initialize text fields
        _homePlayersCtrl.text = '';
        _awayPlayersCtrl.text = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating game: $e')));
        print('Error creating game: $e');
      }
    }
  }

  void _switchToGameScreen() {
    if (_gameSession != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RefereeScreen(gameSession: _gameSession!),
        ),
      );
    }
  }

  // Number list parsing removed with roster UI

  // Roster saving UI removed for coaches; QR-only setup retained.

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_gameSession != null) {
      return WearBackButtonHandler(
        onBackPressed: () {
          // Go back to home screen
          Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: _switchToGameScreen,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: QrImageView(
                  data: _gameSession!.id,
                  version: QrVersions.auto,
                  size: MediaQuery.of(context).size.shortestSide * 0.6,
                  backgroundColor: Colors.black,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              /* Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // QR for pairing
                
                const SizedBox(height: 16),
                const Text(
                  'Home Roster (comma or space separated numbers)',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _homePlayersCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., 1 4 7 10 11 23',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _homeCoachCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Home Coach #',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _homeAssistantCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Home Assistant #',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Away Roster (comma or space separated numbers)',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _awayPlayersCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g., 2, 5, 8, 9, 12',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _awayCoachCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Away Coach #',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _awayAssistantCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Away Assistant #',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveRoster,
                  child: const Text('Save Roster'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _switchToGameScreen,
                  child: const Text('Start Game'),
                ), 
              ],
            ),*/
            ),
          ),
        ),
      );
    }

    // This should never be reached, but just in case
    return Scaffold(
      appBar: AppBar(title: const Text('Game Setup')),
      body: const Center(
        child: Text('Something went wrong. Please try again.'),
      ),
    );
  }
}
