# Quick Setup Guide

## Before Running the App

1. **Install Dependencies**

   ```bash
   flutter pub get
   ```

2. **Configure Appwrite**

   - Create an Appwrite account at [appwrite.io](https://appwrite.io)
   - Create a new project
   - Create a database
   - Create a collection named `soccer_games`
   - Update `lib/config/appwrite_config.dart` with your project details

3. **Required Appwrite Collection Attributes**

   ```
   id: string (required)
   homeTeam: string (required)
   awayTeam: string (required)
   startTime: string (required)
   events: string (required) - JSON array
   firstHalfDuration: integer (required)
   secondHalfDuration: integer (required)
   extraTime: integer (required)
   isActive: boolean (required)
   endTime: string (optional)
   ```

4. **Permissions**
   - Vibration permission for alerts
   - Internet permission for Appwrite sync

## Common Issues

- **Linter errors**: Run `flutter pub get` first
- **Appwrite connection**: Check your endpoint and project ID
- **Timer accuracy**: Ensure device has accurate system time
- **Vibration**: Grant vibration permissions in device settings

## Testing

- Use WearOS emulator or physical device
- Test timer functionality
- Verify event recording
- Check Appwrite data synchronization
