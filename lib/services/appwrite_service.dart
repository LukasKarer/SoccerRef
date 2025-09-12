import 'package:appwrite/appwrite.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';

class AppwriteService {
  static const String endpoint = 'https://appwrite.karer.tech/v1';
  static const String projectId = '68b4eab20008b3666a69';
  static const String databaseId = '68b4f1550014d6cc1ff2';
  static const String collectionId = '68b4f15b00093806878f';

  late Client client;
  late Databases databases;

  AppwriteService() {
    client = Client();
    client.setEndpoint(endpoint);
    client.setProject(projectId);
    databases = Databases(client);
  }

  // Create a new game session
  Future<String> createGameSession(GameSession session) async {
    try {
      final sessionData = session.toJson();
      print('Creating game session: $sessionData');

      // Validate session data before sending
      _validateSessionData(sessionData);

      final response = await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: session.id,
        data: sessionData,
      );
      print('Game session created successfully with ID: ${response.$id}');
      return response.$id;
    } catch (e) {
      print('Error in createGameSession: $e');
      print('Session data: ${session.toJson()}');
      throw Exception('Failed to create game session: $e');
    }
  }

  // Validate session data to ensure no null values in required fields
  void _validateSessionData(Map<String, dynamic> data) {
    final requiredFields = [
      'id',
      'homeTeam',
      'awayTeam',
      'startTime',
      'firstHalfDuration',
      'secondHalfDuration',
      'firstHalfExtraTime',
      'secondHalfExtraTime',
      'isActive',
    ];

    for (final field in requiredFields) {
      if (data[field] == null) {
        throw Exception('Required field "$field" is null in session data');
      }
    }

    // Validate integer fields
    final intFields = [
      'firstHalfDuration',
      'secondHalfDuration',
      'firstHalfExtraTime',
      'secondHalfExtraTime',
    ];
    for (final field in intFields) {
      if (data[field] is! int) {
        throw Exception(
          'Field "$field" must be an integer, got: ${data[field]} (${data[field].runtimeType})',
        );
      }
    }
  }

  // Update an existing game session
  Future<void> updateGameSession(GameSession session) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: session.id,
        data: session.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update game session: $e');
    }
  }

  // Get a game session by ID
  Future<GameSession?> getGameSession(String id) async {
    try {
      final response = await databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
      );

      // print('Retrieved session data: ${response.data}');
      try {
        return GameSession.fromJson(response.data);
      } catch (parseError) {
        print('Error parsing game session: $parseError');
        // Try to create a basic session with available data
        return _createFallbackSession(response.data, id);
      }
    } catch (e) {
      print('Error getting game session: $e');
      // Document not found or other error
      return null;
    }
  }

  // Create a fallback session when parsing fails
  GameSession _createFallbackSession(Map<String, dynamic> data, String id) {
    try {
      return GameSession(
        id: id,
        homeTeam: data['homeTeam']?.toString() ?? 'Home Team',
        awayTeam: data['awayTeam']?.toString() ?? 'Away Team',
        startTime: data['startTime'] != null
            ? DateTime.tryParse(data['startTime'].toString()) ?? DateTime.now()
            : DateTime.now(),
        events: [], // Start with empty events to avoid parsing issues
        firstHalfDuration: 45,
        secondHalfDuration: 45,
        firstHalfExtraTime: 0,
        secondHalfExtraTime: 0,
        isActive: true,
      );
    } catch (e) {
      print('Error creating fallback session: $e');
      // Return a completely default session
      return GameSession(id: id, homeTeam: 'Home Team', awayTeam: 'Away Team');
    }
  }

  // Get all game sessions
  Future<List<GameSession>> getAllGameSessions() async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
      );

      return response.documents.map((doc) {
        try {
          return GameSession.fromJson(doc.data);
        } catch (e) {
          print('Error parsing document ${doc.$id}: $e');
          print('Document data: ${doc.data}');
          // Try to create a fallback session instead of rethrowing
          return _createFallbackSession(doc.data, doc.$id);
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to get game sessions: $e');
    }
  }

  // Delete a game session
  Future<void> deleteGameSession(String id) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
      );
    } catch (e) {
      throw Exception('Failed to delete game session: $e');
    }
  }

  // Add an event to a game session
  Future<void> addEventToSession(String sessionId, SoccerEvent event) async {
    try {
      final session = await getGameSession(sessionId);
      if (session != null) {
        // Use withEvent to create a new session with updated scores
        final updatedSession = session.withEvent(event);
        await updateGameSession(updatedSession);
      }
    } catch (e) {
      throw Exception('Failed to add event: $e');
    }
  }

  // Update persisted scores for a session (useful for existing sessions)
  Future<void> updateSessionScores(String sessionId) async {
    try {
      final session = await getGameSession(sessionId);
      if (session != null) {
        final updatedSession = session.copyWith(
          homeTeamScore: session.homeTeamGoals,
          awayTeamScore: session.awayTeamGoals,
        );
        await updateGameSession(updatedSession);
      }
    } catch (e) {
      throw Exception('Failed to update session scores: $e');
    }
  }

  // Search game sessions by date range
  Future<List<GameSession>> searchSessionsByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.greaterThanEqual('startTime', startDate.toIso8601String()),
          Query.lessThanEqual('startTime', endDate.toIso8601String()),
        ],
      );

      return response.documents.map((doc) {
        try {
          return GameSession.fromJson(doc.data);
        } catch (e) {
          print('Error parsing document ${doc.$id}: $e');
          print('Document data: ${doc.data}');
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to search sessions: $e');
    }
  }

  // Get active game sessions
  Future<List<GameSession>> getActiveSessions() async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [Query.equal('isActive', true)],
      );

      return response.documents.map((doc) {
        try {
          return GameSession.fromJson(doc.data);
        } catch (e) {
          print('Error parsing document ${doc.$id}: $e');
          print('Document data: ${doc.data}');
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to get active sessions: $e');
    }
  }
}
