import 'dart:typed_data'; // Required for the relentless alarm flag
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

import '../main.dart'; // Required to use the navigatorKey
import '../screens/alarm_screen.dart'; // Required to open the giant red screen

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // ── NEW: Kills the alarm when the Giant Button is pressed ──
  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> cancelSpecificAlarm(int baseId) async {
    // Attempt to cancel for all 7 possible days based on baseId mapping
    for (int i = 1; i <= 7; i++) {
      final uniqueId = baseId * 10 + i;
      await _notificationsPlugin.cancel(uniqueId); // Kills the main relentless alarm
      await _notificationsPlugin.cancel(uniqueId + 100000); // Kills the 5-minute SOS backup
    }
  }
  // ──────────────────────────────────────

  // 1. Initialize the plugin and ask for permissions
  static Future<void> initialize() async {
  // ... (rest of your code stays exactly the same) ...

    tz.initializeTimeZones(); // Required for scheduling future alarms
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // India timezone

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      // ── NEW: Listens for the user tapping the notification ──
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // Force the app to jump to the Giant Button screen!
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => AlarmScreen(payload: response.payload!)),
          );
        }
      },
    );
    
    // Request permission to send notifications (Android 13+) and exact alarms
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  // ── Helper Time Calculators ──
  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfWeekdayAndTime(int targetWeekday, TimeOfDay time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != targetWeekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // 2. Schedule the specific medicine alarm
  static Future<void> scheduleMedicineNotification({
    required int id, 
    required String name, 
    required String dosage, 
    required TimeOfDay time,
    required List<int> selectedDays, // 1 = Mon, 7 = Sun
  }) async {
    if (selectedDays.isEmpty) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'continuous_alarm_ch_002',
      'Continuous Medicine Alarms', 
      channelDescription: 'Alarms that ring continuously until dismissed',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, 
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      visibility: NotificationVisibility.public, 
      fullScreenIntent: true, 
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
    );
    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    const AndroidNotificationDetails sosDetails = AndroidNotificationDetails(
      'sos_channel', 
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
    );
    const NotificationDetails platformSosDetails = NotificationDetails(android: sosDetails);

    final bool isDaily = selectedDays.length == 7;
    final component = isDaily ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime;

    // Loop over each selected day and schedule
    for (int day in selectedDays) {
      final int uniqueId = id * 10 + day; // e.g. base=55, Mon=1 -> 551
      final tz.TZDateTime scheduledDate = isDaily 
          ? _nextInstanceOfTime(time) 
          : _nextInstanceOfWeekdayAndTime(day, time);

      // ── 1. THE MAIN ALARM ──
      await _notificationsPlugin.zonedSchedule(
        uniqueId,
        '💊 Time for your Medicine!',
        'Tap here to dismiss.', 
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: component, 
        payload: '$name|$dosage|$uniqueId', 
      );

      // ── 2. THE CAREGIVER SOS ──
      final sosTime = scheduledDate.add(const Duration(minutes: 5));
      await _notificationsPlugin.zonedSchedule(
        uniqueId + 100000, 
        '🚨 CAREGIVER ALERT',
        'Patient has not acknowledged their $dosage of $name!',
        sosTime,
        platformSosDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: component,
      );
      
      // If Daily, we only need to schedule once with DateTimeComponents.time
      if (isDaily) break;
    }
  }
}