import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/game_session.dart';
import '../models/soccer_event.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || !SupabaseConfig.isConfigured) return;

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
  }

  SupabaseClient get _client {
    if (!_initialized) {
      throw Exception(
        'Supabase is not configured. Set SupabaseConfig.url and SupabaseConfig.anonKey.',
      );
    }
    return Supabase.instance.client;
  }

  // Create a new game session.
  Future<String> createGameSession(GameSession session) async {
    try {
      final sessionData = session.toJson();
      print('Creating game session: $sessionData');

      _validateSessionData(sessionData);

      final response = await _client
          .from(SupabaseConfig.gameSessionsTable)
          .insert(sessionData)
          .select('id')
          .single();

      final id = response['id']?.toString() ?? session.id;
      print('Game session created successfully with ID: $id');
      return id;
    } catch (e) {
      print('Error in createGameSession: $e');
      print('Session data: ${session.toJson()}');
      throw Exception('Failed to create game session: $e');
    }
  }

  // Validate session data to ensure no null values in required fields.
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

  // Update an existing game session.
  Future<void> updateGameSession(GameSession session) async {
    try {
      await _client
          .from(SupabaseConfig.gameSessionsTable)
          .upsert(session.toJson(), onConflict: 'id');
    } catch (e) {
      throw Exception('Failed to update game session: $e');
    }
  }

  // Get a game session by ID.
  Future<GameSession?> getGameSession(String id) async {
    try {
      final response = await _client
          .from(SupabaseConfig.gameSessionsTable)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      try {
        return GameSession.fromJson(response);
      } catch (parseError) {
        print('Error parsing game session: $parseError');
        return _createFallbackSession(response, id);
      }
    } catch (e) {
      print('Error getting game session: $e');
      return null;
    }
  }

  // Create a fallback session when parsing fails.
  GameSession _createFallbackSession(Map<String, dynamic> data, String id) {
    try {
      return GameSession(
        id: id,
        homeTeam: data['homeTeam']?.toString() ?? 'Home Team',
        awayTeam: data['awayTeam']?.toString() ?? 'Away Team',
        startTime: data['startTime'] != null
            ? DateTime.tryParse(data['startTime'].toString()) ?? DateTime.now()
            : DateTime.now(),
        events: [],
        firstHalfDuration: 45,
        secondHalfDuration: 45,
        firstHalfExtraTime: 0,
        secondHalfExtraTime: 0,
        isActive: true,
      );
    } catch (e) {
      print('Error creating fallback session: $e');
      return GameSession(id: id, homeTeam: 'Home Team', awayTeam: 'Away Team');
    }
  }

  // Get all game sessions.
  Future<List<GameSession>> getAllGameSessions() async {
    try {
      final response = await _client
          .from(SupabaseConfig.gameSessionsTable)
          .select()
          .order('startTime', ascending: false);

      return response.map((doc) {
        try {
          return GameSession.fromJson(doc);
        } catch (e) {
          final id = doc['id']?.toString() ?? '';
          print('Error parsing document $id: $e');
          print('Document data: $doc');
          return _createFallbackSession(doc, id);
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to get game sessions: $e');
    }
  }

  // Delete a game session.
  Future<void> deleteGameSession(String id) async {
    try {
      await _client
          .from(SupabaseConfig.gameSessionsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete game session: $e');
    }
  }

  // Add an event to a game session.
  Future<void> addEventToSession(String sessionId, SoccerEvent event) async {
    try {
      final session = await getGameSession(sessionId);
      if (session != null) {
        final updatedSession = session.withEvent(event);
        await updateGameSession(updatedSession);
      }
    } catch (e) {
      throw Exception('Failed to add event: $e');
    }
  }

  // Update persisted scores for a session.
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

  // Search game sessions by date range.
  Future<List<GameSession>> searchSessionsByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from(SupabaseConfig.gameSessionsTable)
          .select()
          .gte('startTime', startDate.toIso8601String())
          .lte('startTime', endDate.toIso8601String());

      return response.map((doc) {
        try {
          return GameSession.fromJson(doc);
        } catch (e) {
          final id = doc['id']?.toString() ?? '';
          print('Error parsing document $id: $e');
          print('Document data: $doc');
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to search sessions: $e');
    }
  }

  // Get active game sessions.
  Future<List<GameSession>> getActiveSessions() async {
    try {
      final response = await _client
          .from(SupabaseConfig.gameSessionsTable)
          .select()
          .eq('isActive', true);

      return response.map((doc) {
        try {
          return GameSession.fromJson(doc);
        } catch (e) {
          final id = doc['id']?.toString() ?? '';
          print('Error parsing document $id: $e');
          print('Document data: $doc');
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to get active sessions: $e');
    }
  }
}
