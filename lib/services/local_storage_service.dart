import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';

class LocalStorageService {
  static const String _gameHistoryKey = 'local_game_history';
  static const String _deviceIdKey = 'device_id';

  // Get or create a unique device ID for this watch
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      // Generate a new device ID using timestamp and random
      deviceId =
          'watch_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000).toString().padLeft(4, '0')}';
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  // Save a game session to local storage
  Future<void> saveGameSession(GameSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing game history
      final List<GameSession> history = await getGameHistory();

      // Add or update the session in history
      final existingIndex = history.indexWhere((s) => s.id == session.id);
      if (existingIndex >= 0) {
        history[existingIndex] = session;
      } else {
        history.add(session);
      }

      // Sort by start time (most recent first)
      history.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Keep only the last 50 games to prevent storage bloat
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      // Save to shared preferences
      final historyJson = history.map((s) => s.toJson()).toList();
      await prefs.setString(_gameHistoryKey, jsonEncode(historyJson));

      print('Saved game session to local storage: ${session.id}');
    } catch (e) {
      print('Error saving game session to local storage: $e');
    }
  }

  // Get all game sessions from local storage
  Future<List<GameSession>> getGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_gameHistoryKey);

      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList.map((json) => GameSession.fromJson(json)).toList();
    } catch (e) {
      print('Error loading game history from local storage: $e');
      return [];
    }
  }

  // Get games started on this specific watch
  Future<List<GameSession>> getLocalGameHistory() async {
    try {
      final deviceId = await _getDeviceId();
      final allHistory = await getGameHistory();

      // Filter to only show games that were started on this watch
      return allHistory.where((session) {
        return session.deviceId == deviceId;
      }).toList();
    } catch (e) {
      print('Error getting local game history: $e');
      return [];
    }
  }

  // Delete a game session from local storage
  Future<void> deleteGameSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getGameHistory();

      history.removeWhere((session) => session.id == sessionId);

      final historyJson = history.map((s) => s.toJson()).toList();
      await prefs.setString(_gameHistoryKey, jsonEncode(historyJson));

      print('Deleted game session from local storage: $sessionId');
    } catch (e) {
      print('Error deleting game session from local storage: $e');
    }
  }

  // Clear all local game history
  Future<void> clearGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_gameHistoryKey);
      print('Cleared all local game history');
    } catch (e) {
      print('Error clearing game history: $e');
    }
  }

  // Get device ID for debugging
  Future<String> getDeviceId() async {
    return await _getDeviceId();
  }

  // Save game session with lastDateChanged timestamp
  Future<void> saveGameSessionWithTimestamp(GameSession session) async {
    try {
      // Update the session with current timestamp
      final updatedSession = session.copyWith(lastDateChanged: DateTime.now());
      await saveGameSession(updatedSession);
    } catch (e) {
      print('Error saving game session with timestamp: $e');
    }
  }

  // Get the most recent game session based on lastDateChanged
  Future<GameSession?> getMostRecentGameSession() async {
    try {
      final history = await getGameHistory();
      if (history.isEmpty) return null;

      // Sort by lastDateChanged descending (most recent first)
      history.sort((a, b) => b.lastDateChanged.compareTo(a.lastDateChanged));
      return history.first;
    } catch (e) {
      print('Error getting most recent game session: $e');
      return null;
    }
  }

  // Get game sessions sorted by lastDateChanged
  Future<List<GameSession>> getGameHistorySortedByLastChanged() async {
    try {
      final history = await getGameHistory();
      // Sort by lastDateChanged descending (most recent first)
      history.sort((a, b) => b.lastDateChanged.compareTo(a.lastDateChanged));
      return history;
    } catch (e) {
      print('Error getting sorted game history: $e');
      return [];
    }
  }

  // Merge local and remote game sessions, keeping the most recent version
  Future<List<GameSession>> mergeGameSessions(
    List<GameSession> localSessions,
    List<GameSession> remoteSessions,
  ) async {
    try {
      final Map<String, GameSession> mergedSessions = {};

      // Add local sessions
      for (final session in localSessions) {
        mergedSessions[session.id] = session;
      }

      // Merge with remote sessions, keeping the most recent version
      for (final remoteSession in remoteSessions) {
        final localSession = mergedSessions[remoteSession.id];

        if (localSession == null) {
          // Remote session doesn't exist locally, add it
          mergedSessions[remoteSession.id] = remoteSession;
        } else {
          // Compare lastDateChanged timestamps
          if (remoteSession.lastDateChanged.isAfter(
            localSession.lastDateChanged,
          )) {
            // Remote is more recent, use remote version
            mergedSessions[remoteSession.id] = remoteSession;
          }
          // If local is more recent or equal, keep local version
        }
      }

      final mergedList = mergedSessions.values.toList();
      // Sort by lastDateChanged descending
      mergedList.sort((a, b) => b.lastDateChanged.compareTo(a.lastDateChanged));

      return mergedList;
    } catch (e) {
      print('Error merging game sessions: $e');
      return localSessions; // Fallback to local sessions
    }
  }

  // Save merged sessions back to local storage
  Future<void> saveMergedSessions(List<GameSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Keep only the last 50 games to prevent storage bloat
      final limitedSessions = sessions.length > 50
          ? sessions.take(50).toList()
          : sessions;

      // Save to shared preferences
      final historyJson = limitedSessions.map((s) => s.toJson()).toList();
      await prefs.setString(_gameHistoryKey, jsonEncode(historyJson));

      print(
        'Saved ${limitedSessions.length} merged game sessions to local storage',
      );
    } catch (e) {
      print('Error saving merged sessions: $e');
    }
  }
}
