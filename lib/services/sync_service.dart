import '../models/game_session.dart';
import '../models/soccer_event.dart';
import 'appwrite_service.dart';
import 'local_storage_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AppwriteService _appwriteService = AppwriteService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Initialize the sync service
  Future<void> initialize() async {
    await _connectivityService.initialize();
  }

  // Save a game session (always save locally, sync to remote if online)
  Future<void> saveGameSession(GameSession session) async {
    try {
      // Always save locally with updated timestamp
      await _localStorageService.saveGameSessionWithTimestamp(session);

      // Try to sync to remote if online
      if (_connectivityService.isConnected) {
        try {
          await _appwriteService.updateGameSession(session);
          print('Game session synced to remote: ${session.id}');
        } catch (e) {
          print('Failed to sync to remote, saved locally only: $e');
        }
      } else {
        print('Offline mode: Game session saved locally only: ${session.id}');
      }
    } catch (e) {
      print('Error saving game session: $e');
      rethrow;
    }
  }

  // Create a new game session (always save locally, sync to remote if online)
  Future<String> createGameSession(GameSession session) async {
    try {
      // Always save locally with updated timestamp
      await _localStorageService.saveGameSessionWithTimestamp(session);

      // Try to sync to remote if online
      if (_connectivityService.isConnected) {
        try {
          final remoteId = await _appwriteService.createGameSession(session);
          print('Game session created on remote: $remoteId');
          return remoteId;
        } catch (e) {
          print('Failed to create on remote, using local ID: $e');
        }
      } else {
        print('Offline mode: Game session created locally only: ${session.id}');
      }

      return session.id;
    } catch (e) {
      print('Error creating game session: $e');
      rethrow;
    }
  }

  // Get a game session by ID (check local first, then remote if online)
  Future<GameSession?> getGameSession(String id) async {
    try {
      // First check local storage
      final localHistory = await _localStorageService.getGameHistory();
      final localSession = localHistory.firstWhere(
        (session) => session.id == id,
        orElse: () => throw StateError('Session not found'),
      );

      // If online, try to get from remote and compare
      if (_connectivityService.isConnected) {
        try {
          final remoteSession = await _appwriteService.getGameSession(id);
          if (remoteSession != null) {
            // Compare timestamps and return the most recent
            if (remoteSession.lastDateChanged.isAfter(
              localSession.lastDateChanged,
            )) {
              // Remote is more recent, update local storage
              await _localStorageService.saveGameSessionWithTimestamp(
                remoteSession,
              );
              return remoteSession;
            }
          }
        } catch (e) {
          print('Failed to get from remote, using local: $e');
        }
      }

      return localSession;
    } catch (e) {
      print('Session not found locally: $e');

      // If not found locally and online, try remote
      if (_connectivityService.isConnected) {
        try {
          final remoteSession = await _appwriteService.getGameSession(id);
          if (remoteSession != null) {
            // Save to local storage for future offline access
            await _localStorageService.saveGameSessionWithTimestamp(
              remoteSession,
            );
            return remoteSession;
          }
        } catch (e) {
          print('Failed to get from remote: $e');
        }
      }

      return null;
    }
  }

  // Get all game sessions (merge local and remote if online)
  Future<List<GameSession>> getAllGameSessions() async {
    try {
      // Get local sessions
      final localSessions = await _localStorageService
          .getGameHistorySortedByLastChanged();

      // If online, try to get remote sessions and merge
      if (_connectivityService.isConnected) {
        try {
          final remoteSessions = await _appwriteService.getAllGameSessions();
          final mergedSessions = await _localStorageService.mergeGameSessions(
            localSessions,
            remoteSessions,
          );

          // Save merged sessions back to local storage
          await _localStorageService.saveMergedSessions(mergedSessions);
          return mergedSessions;
        } catch (e) {
          print('Failed to get remote sessions, using local: $e');
        }
      }

      return localSessions;
    } catch (e) {
      print('Error getting game sessions: $e');
      return [];
    }
  }

  // Get local game sessions only (for offline mode)
  Future<List<GameSession>> getLocalGameSessions() async {
    try {
      return await _localStorageService.getLocalGameHistory();
    } catch (e) {
      print('Error getting local game sessions: $e');
      return [];
    }
  }

  // Sync all local sessions to remote (when coming back online)
  Future<void> syncLocalToRemote() async {
    if (!_connectivityService.isConnected) {
      print('No internet connection, cannot sync');
      return;
    }

    try {
      final localSessions = await _localStorageService.getGameHistory();
      print('Syncing ${localSessions.length} local sessions to remote...');

      for (final session in localSessions) {
        try {
          // Try to update existing session
          await _appwriteService.updateGameSession(session);
          print('Synced session: ${session.id}');
        } catch (e) {
          // If update fails, try to create new
          try {
            await _appwriteService.createGameSession(session);
            print('Created new session: ${session.id}');
          } catch (createError) {
            print('Failed to sync session ${session.id}: $createError');
          }
        }
      }

      print('Sync completed');
    } catch (e) {
      print('Error during sync: $e');
    }
  }

  // Manual sync - sync local to remote and then fetch all remote sessions
  Future<void> manualSync() async {
    if (!_connectivityService.isConnected) {
      throw Exception('No internet connection available');
    }

    try {
      print('Starting manual sync...');

      // First, sync all local sessions to remote
      await syncLocalToRemote();

      // Then fetch all remote sessions and merge with local
      final remoteSessions = await _appwriteService.getAllGameSessions();
      final localSessions = await _localStorageService.getGameHistory();

      // Merge sessions (remote takes precedence for conflicts)
      final mergedSessions = await _localStorageService.mergeGameSessions(
        localSessions,
        remoteSessions,
      );

      // Save merged sessions back to local storage
      await _localStorageService.saveMergedSessions(mergedSessions);

      print('Manual sync completed successfully');
    } catch (e) {
      print('Error during manual sync: $e');
      rethrow;
    }
  }

  // Delete a game session (delete locally and remotely if online)
  Future<void> deleteGameSession(String id) async {
    try {
      // Always delete locally
      await _localStorageService.deleteGameSession(id);

      // Try to delete from remote if online
      if (_connectivityService.isConnected) {
        try {
          await _appwriteService.deleteGameSession(id);
          print('Game session deleted from remote: $id');
        } catch (e) {
          print('Failed to delete from remote: $e');
        }
      } else {
        print('Offline mode: Game session deleted locally only: $id');
      }
    } catch (e) {
      print('Error deleting game session: $e');
      rethrow;
    }
  }

  // Add an event to a session (update locally and remotely if online)
  Future<void> addEventToSession(String sessionId, SoccerEvent event) async {
    try {
      // Get the current session
      final session = await getGameSession(sessionId);
      if (session == null) {
        throw Exception('Session not found: $sessionId');
      }

      // Add the event using withEvent (which updates lastDateChanged)
      final updatedSession = session.withEvent(event);

      // Save the updated session
      await saveGameSession(updatedSession);
    } catch (e) {
      print('Error adding event to session: $e');
      rethrow;
    }
  }

  // Check if we're currently online
  bool get isOnline => _connectivityService.isConnected;

  // Get connectivity stream for UI updates
  Stream<bool> get connectivityStream =>
      _connectivityService.connectivityStream;

  // Dispose resources
  void dispose() {
    _connectivityService.dispose();
  }
}
