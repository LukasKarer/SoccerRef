class SupabaseConfig {
  // Replace with your Supabase project values.
  static const String url = 'https://hpzifszrbzbymtkxxbvu.supabase.co';
  static const String anonKey = 'sb_publishable_kW_7T2LU0dxXDrLippHPxw_mxsAJWOu';

  static const String gameSessionsTable = 'game_sessions';

  static bool get isConfigured =>
      url != 'https://your-project.supabase.co' && anonKey != 'your-anon-key';

  // Table columns expected by GameSession.toJson().
  static const Map<String, String> gameSessionColumns = {
    'id': 'text primary key',
    'homeTeam': 'text',
    'awayTeam': 'text',
    'startTime': 'timestamptz',
    'events': 'text[]',
    'firstHalfDuration': 'integer',
    'secondHalfDuration': 'integer',
    'firstHalfExtraTime': 'integer',
    'secondHalfExtraTime': 'integer',
    'isActive': 'boolean',
    'isGameStarted': 'boolean',
    'endTime': 'timestamptz',
    'firstHalfStartTime': 'timestamptz',
    'secondHalfStartTime': 'timestamptz',
    'homeRoster': 'text[]',
    'awayRoster': 'text[]',
    'onPitchHomeLabels': 'text[]',
    'onPitchAwayLabels': 'text[]',
    'homeTeamColorRgb': 'text',
    'awayTeamColorRgb': 'text',
    'sentOffHomeNumbers': 'integer[]',
    'sentOffAwayNumbers': 'integer[]',
    'homeTeamScore': 'integer',
    'awayTeamScore': 'integer',
    'deviceId': 'text',
    'lastDateChanged': 'timestamptz',
  };
}
