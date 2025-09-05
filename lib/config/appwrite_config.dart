class AppwriteConfig {
  // Replace these with your actual Appwrite project details
  static const String endpoint = 'https://appwrite.karer.tech/v1';
  static const String projectId = '68b4eab20008b3666a69';
  static const String databaseId = '68b4f1550014d6cc1ff2';
  static const String collectionId = '68b4f15b00093806878f';

  // Optional: Add authentication if needed
  static const String apiKey = 'your-api-key';

  // Collection attributes that should be created in Appwrite
  static const Map<String, String> collectionAttributes = {
    'id': 'string',
    'homeTeam': 'string',
    'awayTeam': 'string',
    'startTime': 'string',
    'events': 'string', // JSON string
    'firstHalfDuration': 'integer',
    'secondHalfDuration': 'integer',
    'extraTime': 'integer',
    'isActive': 'boolean',
    'endTime': 'string',
  };

  // Indexes for better query performance
  static const List<String> collectionIndexes = [
    'startTime',
    'isActive',
    'homeTeam',
    'awayTeam',
  ];
}
