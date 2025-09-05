import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:typed_data';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    /* try {
      // TODO: Remove this once we have a proper timezone solution

      /* final String localName = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName)); 
      print('Local timezone: $localName'); */
      throw Exception('Local timezone not found');
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('Local timezone: UTC');
    } */

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (_) {}
    }
    _initialized = true;
  }

  Future<void> scheduleVibrationNotification (
    int id,
    DateTime scheduledTime,
    String title,
    String body,
  ) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'game_timer_channel',
      'Game Timer Alerts',
      channelDescription: 'Alerts for half-time and extra-time events',
      importance: Importance.max,
      priority: Priority.high,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      enableVibration: true,
      playSound: false,
      category: AndroidNotificationCategory.alarm,
      ticker: 'Game timer alert',
    );
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();

    /* print('Scheduling notification for ${tz.TZDateTime.from(scheduledTime, tz.getLocation(currentTimeZone))}');
    print(tz.getLocation(currentTimeZone)); */

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.getLocation(currentTimeZone)),
      NotificationDetails(android: androidDetails),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    print(
      '[Notify] Half boundary at ${tz.TZDateTime.from(scheduledTime, tz.getLocation(currentTimeZone))}',
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
