import 'package:uuid/uuid.dart';
import 'soccer_event.dart';

class GameSession {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime startTime;
  List<SoccerEvent> events;
  final int firstHalfDuration; // in minutes
  final int secondHalfDuration; // in minutes
  final int firstHalfExtraTime; // in minutes
  final int secondHalfExtraTime; // in minutes
  final bool isActive;
  final bool isGameStarted;
  final DateTime? endTime;
  final DateTime? firstHalfStartTime;
  final DateTime? secondHalfStartTime;
  // Team rosters as labels (numbers or names)
  final List<String> homeRoster;
  final List<String> awayRoster;
  // Manual on-pitch overrides (labels). If empty, derived from events
  final List<String> onPitchHomeLabels;
  final List<String> onPitchAwayLabels;
  // Customizable team colors (24-bit RGB, e.g., 0xFF0000 for red)
  final int homeTeamColorRgb;
  final int awayTeamColorRgb;
  // Persisted sent-off state per team (actor numbers)
  final List<int> sentOffHomeNumbers;
  final List<int> sentOffAwayNumbers;
  // Explicitly persisted score values (calculated from events)
  final int homeTeamScore;
  final int awayTeamScore;
  // Device ID to track which watch started the game
  final String? deviceId;
  // Timestamp for tracking when the session was last modified
  final DateTime lastDateChanged;

  GameSession({
    String? id,
    required this.homeTeam,
    required this.awayTeam,
    DateTime? startTime,
    List<SoccerEvent>? events,
    this.firstHalfDuration = 45,
    this.secondHalfDuration = 45,
    this.firstHalfExtraTime = 0,
    this.secondHalfExtraTime = 0,
    this.isActive = true,
    this.isGameStarted = false,
    this.endTime,
    this.firstHalfStartTime,
    this.secondHalfStartTime,
    List<String>? homeRoster,
    List<String>? awayRoster,
    List<String>? onPitchHomeLabels,
    List<String>? onPitchAwayLabels,
    this.homeTeamColorRgb = 0x0000FF,
    this.awayTeamColorRgb = 0xFF0000,
    List<int>? sentOffHomeNumbers,
    List<int>? sentOffAwayNumbers,
    int? homeTeamScore,
    int? awayTeamScore,
    this.deviceId,
    DateTime? lastDateChanged,
  }) : id = id ?? const Uuid().v4(),
       startTime = startTime ?? DateTime.now(),
       events = events ?? [],
       homeRoster = homeRoster ?? <String>[],
       awayRoster = awayRoster ?? <String>[],
       onPitchHomeLabels = onPitchHomeLabels ?? <String>[],
       onPitchAwayLabels = onPitchAwayLabels ?? <String>[],
       sentOffHomeNumbers = sentOffHomeNumbers ?? <int>[],
       sentOffAwayNumbers = sentOffAwayNumbers ?? <int>[],
       homeTeamScore = homeTeamScore ?? 0,
       awayTeamScore = awayTeamScore ?? 0,
       lastDateChanged = lastDateChanged ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'startTime': startTime.toIso8601String(),
      // Appwrite collection expects events to be stored as strings
      // to avoid nested object schema issues. We serialize each
      // event map into a JSON string here.
      'events': events.map((e) => e.toJsonString()).toList(),
      'firstHalfDuration': firstHalfDuration,
      'secondHalfDuration': secondHalfDuration,
      'firstHalfExtraTime': firstHalfExtraTime,
      'secondHalfExtraTime': secondHalfExtraTime,
      'isActive': isActive,
      'isGameStarted': isGameStarted,
      'endTime': endTime?.toIso8601String(),
      'firstHalfStartTime': firstHalfStartTime?.toIso8601String(),
      'secondHalfStartTime': secondHalfStartTime?.toIso8601String(),
      // Rosters/staff (string-based)
      'homeRoster': homeRoster,
      'awayRoster': awayRoster,
      'onPitchHomeLabels': onPitchHomeLabels,
      'onPitchAwayLabels': onPitchAwayLabels,
      // coach numbers removed
      // Store as hex strings to satisfy Appwrite string schema
      'homeTeamColorRgb': _rgbToHex(homeTeamColorRgb),
      'awayTeamColorRgb': _rgbToHex(awayTeamColorRgb),
      'sentOffHomeNumbers': sentOffHomeNumbers,
      'sentOffAwayNumbers': sentOffAwayNumbers,
      'homeTeamScore': homeTeamScore,
      'awayTeamScore': awayTeamScore,
      'deviceId': deviceId,
      'lastDateChanged': lastDateChanged.toIso8601String(),
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    try {
      return GameSession(
        id: json['id']?.toString() ?? '',
        homeTeam: json['homeTeam']?.toString() ?? '',
        awayTeam: json['awayTeam']?.toString() ?? '',
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'].toString())
            : DateTime.now(),
        events: json['events'] != null
            ? (json['events'] as List)
                  .map((e) {
                    // Support both JSON strings and already-parsed maps
                    if (e is String) {
                      try {
                        return SoccerEvent.fromJsonString(e);
                      } catch (_) {
                        // Fallback: ignore malformed entries
                        return null;
                      }
                    } else if (e is Map<String, dynamic>) {
                      return SoccerEvent.fromJson(e);
                    } else {
                      return null;
                    }
                  })
                  .whereType<SoccerEvent>()
                  .toList()
            : [],
        firstHalfDuration: json['firstHalfDuration'] is int
            ? json['firstHalfDuration']
            : int.tryParse(json['firstHalfDuration']?.toString() ?? '45') ?? 45,
        secondHalfDuration: json['secondHalfDuration'] is int
            ? json['secondHalfDuration']
            : int.tryParse(json['secondHalfDuration']?.toString() ?? '45') ??
                  45,
        firstHalfExtraTime: json['firstHalfExtraTime'] is int
            ? json['firstHalfExtraTime']
            : int.tryParse(json['firstHalfExtraTime']?.toString() ?? '0') ?? 0,
        secondHalfExtraTime: json['secondHalfExtraTime'] is int
            ? json['secondHalfExtraTime']
            : int.tryParse(json['secondHalfExtraTime']?.toString() ?? '0') ?? 0,
        isActive: json['isActive'] is bool ? json['isActive'] : true,
        isGameStarted: json['isGameStarted'] is bool
            ? json['isGameStarted']
            : false,
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'].toString())
            : null,
        firstHalfStartTime: json['firstHalfStartTime'] != null
            ? DateTime.parse(json['firstHalfStartTime'].toString())
            : null,
        secondHalfStartTime: json['secondHalfStartTime'] != null
            ? DateTime.parse(json['secondHalfStartTime'].toString())
            : null,
        // Rosters/staff with null/legacy-safe parsing
        homeRoster: json.containsKey('homeRoster')
            ? _parseStringList(json['homeRoster'])
            : _parseIntList(
                json['homePlayerNumbers'],
              ).map((e) => e.toString()).toList(),
        awayRoster: json.containsKey('awayRoster')
            ? _parseStringList(json['awayRoster'])
            : _parseIntList(
                json['awayPlayerNumbers'],
              ).map((e) => e.toString()).toList(),
        onPitchHomeLabels: _parseStringList(json['onPitchHomeLabels']),
        onPitchAwayLabels: _parseStringList(json['onPitchAwayLabels']),

        homeTeamColorRgb: _parseRgb(json['homeTeamColorRgb']) ?? 0x0000FF,
        awayTeamColorRgb: _parseRgb(json['awayTeamColorRgb']) ?? 0xFF0000,
        sentOffHomeNumbers: _parseIntList(json['sentOffHomeNumbers']),
        sentOffAwayNumbers: _parseIntList(json['sentOffAwayNumbers']),
        homeTeamScore: json['homeTeamScore'] is int
            ? json['homeTeamScore']
            : int.tryParse(json['homeTeamScore']?.toString() ?? '0') ?? 0,
        awayTeamScore: json['awayTeamScore'] is int
            ? json['awayTeamScore']
            : int.tryParse(json['awayTeamScore']?.toString() ?? '0') ?? 0,
        deviceId: json['deviceId']?.toString(),
        lastDateChanged: json['lastDateChanged'] != null
            ? DateTime.parse(json['lastDateChanged'].toString())
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing GameSession from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  GameSession copyWith({
    String? id,
    String? homeTeam,
    String? awayTeam,
    DateTime? startTime,
    List<SoccerEvent>? events,
    int? firstHalfDuration,
    int? secondHalfDuration,
    int? firstHalfExtraTime,
    int? secondHalfExtraTime,
    bool? isActive,
    bool? isGameStarted,
    DateTime? endTime,
    DateTime? firstHalfStartTime,
    DateTime? secondHalfStartTime,
    List<String>? homeRoster,
    List<String>? awayRoster,
    List<String>? onPitchHomeLabels,
    List<String>? onPitchAwayLabels,
    int? homeTeamColorRgb,
    int? awayTeamColorRgb,
    List<int>? sentOffHomeNumbers,
    List<int>? sentOffAwayNumbers,
    int? homeTeamScore,
    int? awayTeamScore,
    String? deviceId,
    DateTime? lastDateChanged,
  }) {
    return GameSession(
      id: id ?? this.id,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      startTime: startTime ?? this.startTime,
      events: events ?? this.events,
      firstHalfDuration: firstHalfDuration ?? this.firstHalfDuration,
      secondHalfDuration: secondHalfDuration ?? this.secondHalfDuration,
      firstHalfExtraTime: firstHalfExtraTime ?? this.firstHalfExtraTime,
      secondHalfExtraTime: secondHalfExtraTime ?? this.secondHalfExtraTime,
      isActive: isActive ?? this.isActive,
      isGameStarted: isGameStarted ?? this.isGameStarted,
      endTime: endTime ?? this.endTime,
      firstHalfStartTime: firstHalfStartTime ?? this.firstHalfStartTime,
      secondHalfStartTime: secondHalfStartTime ?? this.secondHalfStartTime,
      homeRoster: homeRoster ?? this.homeRoster,
      awayRoster: awayRoster ?? this.awayRoster,
      onPitchHomeLabels: onPitchHomeLabels ?? this.onPitchHomeLabels,
      onPitchAwayLabels: onPitchAwayLabels ?? this.onPitchAwayLabels,

      homeTeamColorRgb: homeTeamColorRgb ?? this.homeTeamColorRgb,
      awayTeamColorRgb: awayTeamColorRgb ?? this.awayTeamColorRgb,
      sentOffHomeNumbers: sentOffHomeNumbers ?? this.sentOffHomeNumbers,
      sentOffAwayNumbers: sentOffAwayNumbers ?? this.sentOffAwayNumbers,
      homeTeamScore: homeTeamScore ?? this.homeTeamScore,
      awayTeamScore: awayTeamScore ?? this.awayTeamScore,
      deviceId: deviceId ?? this.deviceId,
      lastDateChanged: lastDateChanged ?? this.lastDateChanged,
    );
  }

  void addEvent(SoccerEvent event) {
    events.add(event);
    if (event.type == EventType.redCard && event.actorNumber != null) {
      _addSentOffInternal(event.team, event.actorNumber!);
    }

    // Handle substitution and red card events by updating manual on-pitch lists
    if (event.type == EventType.substitution) {
      final outNumber = event.substitutionOutNumber?.toString();
      final inNumber = event.substitutionInNumber?.toString();

      if (event.team == Team.home) {
        if (outNumber != null && onPitchHomeLabels.contains(outNumber)) {
          onPitchHomeLabels.remove(outNumber);
        }
        if (inNumber != null && !onPitchHomeLabels.contains(inNumber)) {
          onPitchHomeLabels.add(inNumber);
        }
      } else {
        if (outNumber != null && onPitchAwayLabels.contains(outNumber)) {
          onPitchAwayLabels.remove(outNumber);
        }
        if (inNumber != null && !onPitchAwayLabels.contains(inNumber)) {
          onPitchAwayLabels.add(inNumber);
        }
      }
    } else if (event.type == EventType.redCard && event.actorNumber != null) {
      // Remove sent-off player from on-pitch list
      final playerNumber = event.actorNumber.toString();
      if (event.team == Team.home) {
        onPitchHomeLabels.remove(playerNumber);
      } else {
        onPitchAwayLabels.remove(playerNumber);
      }
    }
  }

  void removeEvent(SoccerEvent event) {
    events.removeWhere((x) => x.id == event.id);

    // Handle red card event deletion
    if (event.type == EventType.redCard && event.actorNumber != null) {
      _removeSentOffInternal(event.team, event.actorNumber!);
    }

    // Handle substitution and red card event deletion by updating manual on-pitch lists
    if (event.type == EventType.substitution) {
      final outNumber = event.substitutionOutNumber?.toString();
      final inNumber = event.substitutionInNumber?.toString();

      if (event.team == Team.home) {
        // Reverse the substitution: remove the incoming player, add back the outgoing player
        if (inNumber != null && onPitchHomeLabels.contains(inNumber)) {
          onPitchHomeLabels.remove(inNumber);
        }
        if (outNumber != null && !onPitchHomeLabels.contains(outNumber)) {
          onPitchHomeLabels.add(outNumber);
        }
      } else {
        // Reverse the substitution: remove the incoming player, add back the outgoing player
        if (inNumber != null && onPitchAwayLabels.contains(inNumber)) {
          onPitchAwayLabels.remove(inNumber);
        }
        if (outNumber != null && !onPitchAwayLabels.contains(outNumber)) {
          onPitchAwayLabels.add(outNumber);
        }
      }
    } else if (event.type == EventType.redCard && event.actorNumber != null) {
      // Add back the sent-off player to on-pitch list
      final playerNumber = event.actorNumber.toString();
      if (event.team == Team.home) {
        if (!onPitchHomeLabels.contains(playerNumber)) {
          onPitchHomeLabels.add(playerNumber);
        }
      } else {
        if (!onPitchAwayLabels.contains(playerNumber)) {
          onPitchAwayLabels.add(playerNumber);
        }
      }
    }
  }

  GameSession withEvent(SoccerEvent event) {
    final newEvents = List<SoccerEvent>.from(events)..add(event);
    // Calculate new scores after adding the event
    final newHomeScore = newEvents
        .where(
          (e) =>
              e.type == EventType.goal &&
              ((e.team == Team.home && !e.isOwnGoal) ||
                  (e.team == Team.away && e.isOwnGoal)),
        )
        .length;
    final newAwayScore = newEvents
        .where(
          (e) =>
              e.type == EventType.goal &&
              ((e.team == Team.away && !e.isOwnGoal) ||
                  (e.team == Team.home && e.isOwnGoal)),
        )
        .length;

    // Handle substitution and red card events by updating manual on-pitch lists
    List<String> updatedHomeOnPitch = List<String>.from(onPitchHomeLabels);
    List<String> updatedAwayOnPitch = List<String>.from(onPitchAwayLabels);

    if (event.type == EventType.substitution) {
      final outNumber = event.substitutionOutNumber?.toString();
      final inNumber = event.substitutionInNumber?.toString();

      if (event.team == Team.home) {
        if (outNumber != null && updatedHomeOnPitch.contains(outNumber)) {
          updatedHomeOnPitch.remove(outNumber);
        }
        if (inNumber != null && !updatedHomeOnPitch.contains(inNumber)) {
          updatedHomeOnPitch.add(inNumber);
        }
      } else {
        if (outNumber != null && updatedAwayOnPitch.contains(outNumber)) {
          updatedAwayOnPitch.remove(outNumber);
        }
        if (inNumber != null && !updatedAwayOnPitch.contains(inNumber)) {
          updatedAwayOnPitch.add(inNumber);
        }
      }
    } else if (event.type == EventType.redCard && event.actorNumber != null) {
      // Remove sent-off player from on-pitch list
      final playerNumber = event.actorNumber.toString();
      if (event.team == Team.home) {
        updatedHomeOnPitch.remove(playerNumber);
      } else {
        updatedAwayOnPitch.remove(playerNumber);
      }
    }

    return copyWith(
      events: newEvents,
      homeTeamScore: newHomeScore,
      awayTeamScore: newAwayScore,
      onPitchHomeLabels: updatedHomeOnPitch,
      onPitchAwayLabels: updatedAwayOnPitch,
      lastDateChanged: DateTime.now(),
    );
  }

  int get homeTeamGoals => events
      .where(
        (e) =>
            e.type == EventType.goal &&
            ((e.team == Team.home && !e.isOwnGoal) ||
                (e.team == Team.away && e.isOwnGoal)),
      )
      .length;

  int get awayTeamGoals => events
      .where(
        (e) =>
            e.type == EventType.goal &&
            ((e.team == Team.away && !e.isOwnGoal) ||
                (e.team == Team.home && e.isOwnGoal)),
      )
      .length;

  int get homeTeamYellowCards => events
      .where((e) => e.type == EventType.yellowCard && e.team == Team.home)
      .length;

  int get awayTeamYellowCards => events
      .where((e) => e.type == EventType.yellowCard && e.team == Team.away)
      .length;

  int get homeTeamRedCards => events
      .where((e) => e.type == EventType.redCard && e.team == Team.home)
      .length;

  int get awayTeamRedCards => events
      .where((e) => e.type == EventType.redCard && e.team == Team.away)
      .length;

  String get score {
    // Use calculated goals from events if available, otherwise fall back to persisted scores
    final homeGoals = events.isNotEmpty ? homeTeamGoals : homeTeamScore;
    final awayGoals = events.isNotEmpty ? awayTeamGoals : awayTeamScore;
    return '$homeGoals : $awayGoals';
  }

  // Helpers
  static List<int> _parseIntList(dynamic value) {
    if (value == null) return <int>[];
    if (value is List) {
      return value
          .map((e) => e is int ? e : int.tryParse(e?.toString() ?? ''))
          .whereType<int>()
          .toSet() // de-dup
          .toList()
        ..sort();
    }
    return <int>[];
  }

  static int? _parseRgb(dynamic value) {
    if (value == null) return null;
    if (value is int) return value & 0xFFFFFF;
    final String s = value.toString().trim();
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

  static String _rgbToHex(int rgb) {
    final int v = rgb & 0xFFFFFF;
    final String hex = v.toRadixString(16).padLeft(6, '0').toUpperCase();
    return '#$hex';
  }

  // Numeric players derived from roster labels (fallback to 1..99 if empty)
  List<int> getTeamPlayers(Team team) {
    final List<String> labels = team == Team.home ? homeRoster : awayRoster;
    final nums = labels
        .map((e) => int.tryParse(e.toString().trim()))
        .whereType<int>()
        .toList();
    nums.sort();
    return nums;
  }

  // Numbers available to pick for non-substitution events (players only).
  // If empty, default 1..99.
  List<int> getEventPickList(Team team) {
    final List<int> picks = getTeamPlayers(team);
    if (picks.isEmpty) {
      return List<int>.generate(99, (i) => i + 1);
    }
    final list = picks.toSet().toList()..sort();
    return list;
  }

  // Numbers available to pick for substitutions (players only). If empty, default 1..99.
  List<int> getSubstitutionPickList(Team team) {
    final List<int> players = getTeamPlayers(team);
    if (players.isEmpty) {
      return List<int>.generate(99, (i) => i + 1);
    }
    final list = players.toSet().toList()..sort();
    return list;
  }

  // --- Card and discipline helpers ---
  int yellowCountForPlayer(Team team, int playerNumber) {
    return events
        .where((e) => e.team == team && e.type == EventType.yellowCard)
        .where((e) => e.actorNumber == playerNumber)
        .length;
  }

  bool hasRedForPlayer(Team team, int playerNumber) {
    return events.any(
      (e) =>
          e.team == team &&
          e.type == EventType.redCard &&
          e.actorNumber == playerNumber,
    );
  }

  bool isPlayerSentOff(Team team, int playerNumber) =>
      hasRedForPlayer(team, playerNumber);

  Set<int> playersWithYellow(Team team) {
    final Map<int, int> counts = <int, int>{};
    for (final e in events) {
      if (e.team == team &&
          e.type == EventType.yellowCard &&
          e.actorNumber != null) {
        final n = e.actorNumber!;
        counts[n] = (counts[n] ?? 0) + 1;
      }
    }
    return counts.keys.toSet();
  }

  // --- Staff (string-label) card helpers ---
  int yellowCountForLabel(Team team, String label) {
    final String key = label.trim();
    if (key.isEmpty) return 0;
    return events
        .where((e) => e.team == team && e.type == EventType.yellowCard)
        .where((e) => (e.actorNumber == null))
        .where((e) => e.playerName.trim() == key)
        .length;
  }

  bool hasRedForLabel(Team team, String label) {
    final String key = label.trim();
    if (key.isEmpty) return false;
    return events.any(
      (e) =>
          e.team == team &&
          e.type == EventType.redCard &&
          e.actorNumber == null &&
          e.playerName.trim() == key,
    );
  }

  Set<String> staffWithYellow(Team team) {
    final Set<String> labels = <String>{};
    for (final e in events) {
      if (e.team == team &&
          e.type == EventType.yellowCard &&
          e.actorNumber == null) {
        final String name = e.playerName.trim();
        if (name.isNotEmpty) labels.add(name);
      }
    }
    return labels;
  }

  // --- Roster categorization: on-pitch, bench, sent-off ---
  List<int> getAllRosterNumbers(Team team) {
    final List<int> base = getTeamPlayers(team);
    if (base.isEmpty) {
      return List<int>.generate(99, (i) => i + 1);
    }
    final list = base.toSet().toList()..sort();
    return list;
  }

  List<String> getAllRosterLabels(Team team) {
    final List<String> base = team == Team.home ? homeRoster : awayRoster;
    final list = base
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    list.sort((a, b) {
      final ai = int.tryParse(a);
      final bi = int.tryParse(b);
      if (ai != null && bi != null) return ai.compareTo(bi);
      if (ai != null) return -1;
      if (bi != null) return 1;
      return a.compareTo(b);
    });
    return list;
  }

  Set<int> getSentOffPlayers(Team team) {
    final Set<int> sent = <int>{
      ...(team == Team.home ? sentOffHomeNumbers : sentOffAwayNumbers),
    };
    // Include any red-carded players from events to be backward-compatible
    for (final e in events) {
      if (e.team == team &&
          e.type == EventType.redCard &&
          e.actorNumber != null) {
        sent.add(e.actorNumber!);
      }
    }
    return sent;
  }

  List<int> getOnPitchPlayers(Team team) {
    // Manual override via labels
    final List<String> manual = team == Team.home
        ? onPitchHomeLabels
        : onPitchAwayLabels;
    if (manual.isNotEmpty) {
      final on = manual
          .map((e) => int.tryParse(e.toString().trim()))
          .whereType<int>()
          .toSet();
      // Remove any sent-off players just in case
      on.removeWhere((n) => hasRedForPlayer(team, n));
      final list = on.toList()..sort();
      return list;
    }

    final List<int> roster = getAllRosterNumbers(team);
    final Set<int> onPitch = <int>{};
    // Start with first 11 or as many as available
    for (int i = 0; i < roster.length && i < 11; i++) {
      onPitch.add(roster[i]);
    }
    // Apply substitutions chronologically
    for (final e in events) {
      if (e.team != team) continue;
      if (e.type == EventType.substitution) {
        final int? outN = e.substitutionOutNumber;
        final int? inN = e.substitutionInNumber;
        if (outN != null) {
          onPitch.remove(outN);
        }
        if (inN != null) {
          onPitch.add(inN);
        }
      }
      if (e.type == EventType.redCard && e.actorNumber != null) {
        onPitch.remove(e.actorNumber);
      }
    }
    // Remove any sent-off players just in case
    onPitch.removeWhere((n) => hasRedForPlayer(team, n));
    final list = onPitch.toList()..sort();
    return list;
  }

  List<int> getBenchPlayers(Team team) {
    final List<int> roster = getAllRosterNumbers(team);
    final Set<int> on = getOnPitchPlayers(team).toSet();
    final Set<int> sent = getSentOffPlayers(team);
    final List<int> bench = roster
        .where((n) => !on.contains(n) && !sent.contains(n))
        .toList();
    bench.sort();
    return bench;
  }

  // --- Mutators for sent-off state ---
  void addSentOffPlayer(Team team, int playerNumber) {
    _addSentOffInternal(team, playerNumber);
  }

  void removeSentOffPlayer(Team team, int playerNumber) {
    _removeSentOffInternal(team, playerNumber);
  }

  void _addSentOffInternal(Team team, int playerNumber) {
    if (team == Team.home) {
      if (!sentOffHomeNumbers.contains(playerNumber)) {
        sentOffHomeNumbers.add(playerNumber);
      }
    } else {
      if (!sentOffAwayNumbers.contains(playerNumber)) {
        sentOffAwayNumbers.add(playerNumber);
      }
    }
  }

  void _removeSentOffInternal(Team team, int playerNumber) {
    if (team == Team.home) {
      sentOffHomeNumbers.remove(playerNumber);
    } else {
      sentOffAwayNumbers.remove(playerNumber);
    }
  }

  // --- Manual on-pitch control & roster editing ---
  void setOnPitchLabels(Team team, List<String> labels) {
    final target = team == Team.home ? onPitchHomeLabels : onPitchAwayLabels;
    target
      ..clear()
      ..addAll(
        labels.map((e) => e.toString().trim()).where((e) => e.isNotEmpty),
      );
  }

  void addRosterLabel(Team team, String label) {
    final target = team == Team.home ? homeRoster : awayRoster;
    final trimmed = label.toString().trim();
    if (trimmed.isEmpty) return;
    if (!target.contains(trimmed)) {
      target.add(trimmed);
    }
  }

  bool isLabelOnPitch(Team team, String label) {
    final List<String> manual = team == Team.home
        ? onPitchHomeLabels
        : onPitchAwayLabels;
    if (manual.isNotEmpty) {
      return manual.contains(label);
    }
    final int? asNum = int.tryParse(label);
    if (asNum == null) return false;
    return getOnPitchPlayers(team).contains(asNum);
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    return <String>[];
  }
}
