import 'package:uuid/uuid.dart';
import 'dart:convert';

enum EventType { goal, yellowCard, redCard, substitution, penalty }

enum Team { home, away }

class SoccerEvent {
  final String id;
  final EventType type;
  final Team team;
  final String playerName;
  final String description;
  final DateTime timestamp;
  final int gameTime; // Time in seconds from game start
  final int half; // 1 for first half, 2 for second half
  final int extraTime; // Extra time elapsed in seconds
  // Optional numeric selectors for roster/staff
  final int? actorNumber; // For most events (goal/card)
  final int? substitutionOutNumber; // For substitution: player leaving
  final int? substitutionInNumber; // For substitution: player entering
  // Distinguish a straight red from a second-yellow red
  final bool isSecondYellow;
  // Track if this is an own goal (counts for opposing team)
  final bool isOwnGoal;

  SoccerEvent({
    String? id,
    required this.type,
    required this.team,
    required this.playerName,
    required this.description,
    DateTime? timestamp,
    required this.gameTime,
    required this.half,
    this.extraTime = 0,
    this.actorNumber,
    this.substitutionOutNumber,
    this.substitutionInNumber,
    this.isSecondYellow = false,
    this.isOwnGoal = false,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'team': team.name,
      'playerName': playerName,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'gameTime': gameTime,
      'half': half,
      'extraTime': extraTime,
      'actorNumber': actorNumber,
      'substitutionOutNumber': substitutionOutNumber,
      'substitutionInNumber': substitutionInNumber,
      'isSecondYellow': isSecondYellow,
      'isOwnGoal': isOwnGoal,
    };
  }

  // Serialize to a compact JSON string for storage in Appwrite as string array
  String toJsonString() => jsonEncode(toJson());

  factory SoccerEvent.fromJson(Map<String, dynamic> json) {
    try {
      return SoccerEvent(
        id: json['id']?.toString() ?? '',
        type: EventType.values.firstWhere(
          (e) => e.name == json['type']?.toString(),
        ),
        team: Team.values.firstWhere((t) => t.name == json['team']?.toString()),
        playerName: json['playerName']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'].toString())
            : DateTime.now(),
        gameTime: json['gameTime'] is int
            ? json['gameTime']
            : int.tryParse(json['gameTime']?.toString() ?? '0') ?? 0,
        half: json['half'] is int
            ? json['half']
            : int.tryParse(json['half']?.toString() ?? '1') ?? 1,
        extraTime: json['extraTime'] is int
            ? json['extraTime']
            : int.tryParse(json['extraTime']?.toString() ?? '0') ?? 0,
        actorNumber: _parseOptionalInt(json['actorNumber']),
        substitutionOutNumber: _parseOptionalInt(json['substitutionOutNumber']),
        substitutionInNumber: _parseOptionalInt(json['substitutionInNumber']),
        isSecondYellow:
            json['isSecondYellow'] == true ||
            (json['isSecondYellow']?.toString().toLowerCase() == 'true'),
        isOwnGoal:
            json['isOwnGoal'] == true ||
            (json['isOwnGoal']?.toString().toLowerCase() == 'true'),
      );
    } catch (e) {
      print('Error parsing SoccerEvent from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Parse from a JSON string wrapper used when events are stored as strings
  factory SoccerEvent.fromJsonString(String source) {
    final dynamic decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return SoccerEvent.fromJson(decoded);
    }
    // If decoded is not a map, attempt to coerce by converting to string map
    return SoccerEvent.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  String get displayName {
    switch (type) {
      case EventType.goal:
        return '⚽ Goal';
      case EventType.yellowCard:
        return '🟨 Yellow Card';
      case EventType.redCard:
        return isSecondYellow ? '🟨🟥 Yellow-Red Card' : '🟥 Red Card';
      case EventType.substitution:
        return '🔄 Substitution';
      case EventType.penalty:
        return '⚽ Penalty';
    }
  }

  String get teamName => team == Team.home ? 'Home' : 'Away';

  static int? _parseOptionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
