# Soccer Referee App for WearOS

A comprehensive soccer referee application designed specifically for WearOS devices, featuring game timing, event recording, and data synchronization with Appwrite backend.

## Features

- **Accurate Game Timer**: 45-minute half timer with system clock fallback for precision
- **Event Recording**: Track goals, cards, fouls, substitutions, and more
- **Vibration Alerts**: Automatic vibration when half-time and full-time are reached
- **Extra Time Management**: Add and track additional time for each half
- **QR Code Sharing**: Generate QR codes for game session IDs
- **Appwrite Integration**: Cloud-based data storage and synchronization
- **WearOS Optimized**: Designed specifically for smartwatch interfaces

## Prerequisites

- Flutter SDK 3.9.0 or higher
- Android Studio / VS Code
- WearOS device or emulator
- Appwrite backend instance

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Appwrite

1. Create an Appwrite project at [appwrite.io](https://appwrite.io)
2. Create a database and collection for soccer games
3. Update `lib/config/appwrite_config.dart` with your project details:

```dart
class AppwriteConfig {
  static const String endpoint = 'https://your-appwrite-endpoint.com';
  static const String projectId = 'your-project-id';
  static const String databaseId = 'your-database-id';
  static const String collectionId = 'soccer_games';
}
```

4. Create the collection with the following attributes:
   - `id` (string, required)
   - `homeTeam` (string, required)
   - `awayTeam` (string, required)
   - `startTime` (string, required)
   - `events` (string, required) - JSON array of events
   - `firstHalfDuration` (integer, required)
   - `secondHalfDuration` (integer, required)
   - `extraTime` (integer, required)
   - `isActive` (boolean, required)
   - `endTime` (string, optional)

### 3. Build and Run

```bash
# For WearOS device
flutter build apk --target-platform android-arm64

# For WearOS emulator
flutter run
```

## App Structure

```
lib/
├── config/
│   └── appwrite_config.dart      # Appwrite configuration
├── models/
│   ├── soccer_event.dart         # Event data model
│   └── game_session.dart         # Game session model
├── screens/
│   ├── home_screen.dart          # Main home screen
│   ├── game_setup_screen.dart    # New game configuration
│   └── referee_screen.dart       # Main referee interface
├── services/
│   ├── appwrite_service.dart     # Backend data service
│   └── game_timer.dart          # Game timer service
├── widgets/
│   ├── event_dialog.dart         # Event recording dialog
│   └── qr_code_dialog.dart      # QR code display
└── main.dart                     # App entry point
```

## Usage

### Starting a New Game

1. Open the app on your WearOS device
2. Tap "New Game"
3. Enter team names and configure half durations
4. Tap "Start Game"

### During the Game

- **Timer Controls**: Start, pause, resume, and add extra time
- **Event Recording**: Tap "Add Event" to record goals, cards, fouls, etc.
- **Half Management**: Automatically prompts for second half when first half ends
- **Vibration Alerts**: Device vibrates at half-time and full-time

### Recording Events

1. Tap "Add Event" during gameplay
2. Select event type (goal, card, foul, etc.)
3. Choose team (home/away)
4. Enter player name
5. Add optional description
6. Tap "Add Event"

### Sharing Game Data

- Tap the QR code icon in the app bar
- Scan the QR code with the companion phone app (coming soon)
- Or copy the game ID manually

## Timer Features

- **System Clock Fallback**: Timer automatically syncs with system time for accuracy
- **Pause/Resume**: Timer can be paused and resumed without losing accuracy
- **Extra Time**: Add minutes to each half as needed
- **Half Management**: Automatic half-time detection and second half support

## Data Model

### SoccerEvent

- Event type (goal, card, foul, etc.)
- Team (home/away)
- Player name
- Description
- Timestamp
- Game time
- Half number
- Extra time

### GameSession

- Game ID (UUID)
- Team names
- Start/end times
- Half durations
- Extra time
- Active status
- List of events

## Permissions

The app requires the following permissions:

- Vibration (for half-time/full-time alerts)
- Internet (for Appwrite synchronization)

## Troubleshooting

### Timer Issues

- Ensure the device has accurate system time
- Check that the app isn't being killed in the background
- Verify vibration permissions are granted

### Appwrite Connection Issues

- Verify endpoint URL and project ID
- Check internet connectivity
- Ensure collection attributes match the expected schema

### Build Issues

- Run `flutter clean` and `flutter pub get`
- Ensure Flutter SDK version is 3.9.0+
- Check that all dependencies are properly installed

## Future Enhancements

- Companion phone app for detailed game analysis
- Statistics and analytics dashboard
- Multiple game support
- Offline mode with local storage
- Export game data to various formats
- Team and player management
- League and tournament support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Create an issue on GitHub
- Check the troubleshooting section
- Review Appwrite documentation for backend issues
