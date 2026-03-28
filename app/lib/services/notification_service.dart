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

  // ── 🎯 ADD THIS NEW BLOCK RIGHT HERE ──
  // Kills a specific medicine alarm AND its SOS backup
  static Future<void> cancelSpecificAlarm(int id) async {
    await _notificationsPlugin.cancel(id); // Kills the main relentless alarm
    await _notificationsPlugin.cancel(id + 100000); // Kills the 5-minute SOS backup
  }
  // ──────────────────────────────────────

  // 1. Initialize the plugin and ask for permissions
  static Future<void> initialize() async {
  // ... (rest of your code stays exactly the same) ...

    tz.initializeTimeZones(); // Required for scheduling future alarms

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

  // 2. Schedule the specific medicine alarm
  static Future<void> scheduleMedicineNotification({
    required int id, 
    required String name, 
    required String dosage, 
    required TimeOfDay time
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    
    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // ── NEW: We use 'final' instead of 'const' here so we can inject the relentless flag ──
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'relentless_medicine_alarm_1', // CHANGED ID so Android accepts the new relentless rules
      'Continuous Medicine Alarms', 
      channelDescription: 'Alarms that ring continuously until dismissed',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, 
      sound: const RawResourceAndroidNotificationSound('alarm'), 
      enableVibration: true,
      visibility: NotificationVisibility.public, 
      fullScreenIntent: true, 
      // ── THE MAGIC LINE: Forces the alarm to loop until stopped ──
      additionalFlags: Int32List.fromList(<int>[4]), // 4 = FLAG_INSISTENT
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // ── 1. THE MAIN ALARM (Relentless) ──
    await _notificationsPlugin.zonedSchedule(
      id,
      '💊 Time for your Medicine!',
      'Tap here to dismiss.', 
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, 
      payload: '$name|$dosage|$id', // Added the ID so we know which one to cancel
    );

    // ── 2. THE CAREGIVER SOS (Dead Man's Switch) ──
    // We schedule this for exactly 5 minutes AFTER the main alarm
    final sosTime = scheduledDate.add(const Duration(minutes: 5));
    
    const AndroidNotificationDetails sosDetails = AndroidNotificationDetails(
      'sos_channel', 
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red, // Makes the notification red
    );

    await _notificationsPlugin.zonedSchedule(
      id + 100000, // We offset the ID so it doesn't overwrite the main alarm
      '🚨 CAREGIVER ALERT',
      'Patient has not acknowledged their $dosage of $name!',
      tz.TZDateTime.from(sosTime, tz.local),
      const NotificationDetails(android: sosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}