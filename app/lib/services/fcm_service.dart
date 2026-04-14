import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import '../screens/alarm_screen.dart';
import 'auth_service.dart';

/// ═══════════════════════════════════════════════════════════
///  FCM PUSH NOTIFICATION SERVICE
///
///  Handles:
///    1. FCM token management (save to Firestore per user)
///    2. Foreground push → local notification display
///    3. Background push handling
///    4. Push notification tap → navigate to alarm/detail screen
///    5. Missed dose detection & alerting
///
///  Notification Types:
///    - "dispense_success" → ESP32 confirmed pill dispensed
///    - "dispense_failed"  → ESP32 IR sensor didn't detect pill
///    - "missed_dose"      → Patient didn't acknowledge alarm
///    - "caregiver_alert"  → Alert sent to linked caregivers
///    - "sos"              → Emergency triggered
/// ═══════════════════════════════════════════════════════════
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM — call once from main.dart after Firebase.initializeApp
  static Future<void> initialize() async {
    // 1. Request permission (Android 13+ / iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
    );
    debugPrint('🔔 FCM: Permission = ${settings.authorizationStatus}');

    // 2. Get & save FCM token
    await _saveToken();

    // 3. Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    // 4. Handle foreground messages (app is open)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle notification taps (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 6. Check if app was opened from a terminated-state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('🔔 FCM: Initialized successfully');
  }

  // ═══════════════════════════════════════════
  //  TOKEN MANAGEMENT
  // ═══════════════════════════════════════════

  /// Get the FCM token and save to Firestore
  static Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        debugPrint('🔔 FCM Token: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('🔔 FCM Token error: $e');
    }
  }

  /// Write token to the user's Firestore document
  static Future<void> _saveTokenToFirestore(String token) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'fcm_token': token,
      'fcm_updated_at': FieldValue.serverTimestamp(),
      'platform': 'android',
    }, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════
  //  FOREGROUND MESSAGE HANDLER
  //  Shows a local notification when the app is open
  // ═══════════════════════════════════════════

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 FCM Foreground: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Determine notification style based on type
    final type = message.data['type'] ?? 'general';
    final channelId = _getChannelId(type);
    final channelName = _getChannelName(type);
    final color = _getNotificationColor(type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      color: color,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  // ═══════════════════════════════════════════
  //  NOTIFICATION TAP HANDLER
  //  Navigate to the right screen when tapped
  // ═══════════════════════════════════════════

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 FCM Tap: ${message.data}');

    final type = message.data['type'] ?? 'general';
    final medicineName = message.data['medicine'] ?? '';
    final dosage = message.data['dosage'] ?? '';

    switch (type) {
      case 'dispense_success':
      case 'dispense_failed':
      case 'missed_dose':
        // Navigate to alarm screen
        if (medicineName.isNotEmpty) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AlarmScreen(
                payload: '$medicineName|$dosage|0',
              ),
            ),
          );
        }
        break;
      default:
        // Just bring app to foreground (handled automatically)
        break;
    }
  }

  // ═══════════════════════════════════════════
  //  MISSED DOSE DETECTION
  //  Check alarm_schedules for overdue alarms
  //  and send alerts to caregivers
  // ═══════════════════════════════════════════

  /// Check for missed doses — call periodically from the app
  static Future<void> checkMissedDoses() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 15));

    // Query alarm_schedules for overdue alarms
    try {
      final alarms = await _db
          .collection('alarm_schedules')
          .where('uid', isEqualTo: uid)
          .where('is_active', isEqualTo: true)
          .get();

      for (final doc in alarms.docs) {
        final data = doc.data();
        final hour = data['hour'] as int? ?? 0;
        final minute = data['minute'] as int? ?? 0;
        final medicineName = data['medicine_name'] as String? ?? 'Medicine';
        final acknowledged = data['acknowledged'] as bool? ?? false;

        // Build the alarm time for today
        final alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

        // Check if alarm was due (15+ mins ago) and not acknowledged
        if (!acknowledged &&
            alarmTime.isBefore(cutoff) &&
            alarmTime.isAfter(now.subtract(const Duration(hours: 2)))) {
          debugPrint('⚠️ MISSED DOSE: $medicineName at $hour:$minute');

          // Mark as missed in the alarm doc
          await doc.reference.update({'status': 'missed'});

          // Log to history
          await _db
              .collection('users')
              .doc(uid)
              .collection('history')
              .add({
            'name': medicineName,
            'status': 'Missed',
            'taken_at': FieldValue.serverTimestamp(),
            'scheduled_time': '$hour:${minute.toString().padLeft(2, '0')}',
          });

          // Create alert for linked caregivers
          await _createCaregiverAlert(
            patientUid: uid,
            type: 'missed_dose',
            message: '$medicineName was missed (scheduled for '
                '$hour:${minute.toString().padLeft(2, '0')})',
            medicineName: medicineName,
          );
        }
      }
    } catch (e) {
      debugPrint('🔔 Missed dose check error: $e');
    }
  }

  /// Create an alert document for linked caregivers
  static Future<void> _createCaregiverAlert({
    required String patientUid,
    required String type,
    required String message,
    String? medicineName,
  }) async {
    // Write alert to patient's alerts collection
    await _db.collection('users').doc(patientUid).collection('alerts').add({
      'type': type,
      'message': message,
      'medicine': medicineName ?? '',
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Get linked caregivers
    final patientDoc = await _db.collection('users').doc(patientUid).get();
    final caregiverUids =
        List<String>.from(patientDoc.data()?['linked_caregivers'] ?? []);

    // Send push notification to each caregiver's FCM token
    for (final caregiverUid in caregiverUids) {
      final caregiverDoc =
          await _db.collection('users').doc(caregiverUid).get();
      final fcmToken = caregiverDoc.data()?['fcm_token'] as String?;

      if (fcmToken != null) {
        debugPrint('🔔 Alerting caregiver $caregiverUid');
        // Note: Server-side push is handled by the Cloud Function.
        // This stores the alert in Firestore, and the Cloud Function
        // triggers the FCM push to the caregiver's device.
      }
    }
  }

  // ═══════════════════════════════════════════
  //  DISPENSE RESULT HANDLER
  //  Called when ESP32 updates hardware_control
  // ═══════════════════════════════════════════

  /// Listen to hardware_control for dispense results
  static void listenToDispenserStatus() {
    _db
        .collection('hardware_control')
        .doc('esp32_dispenser_01')
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String? ?? '';
      final medicine = data['medicine_dispensed'] as String? ?? 'Medicine';
      final irConfirmed = data['ir_confirmed'] as bool? ?? false;

      if (status == 'dispensed' && irConfirmed) {
        _showLocalNotification(
          title: '✅ Pill Dispensed',
          body: '$medicine has been dispensed successfully.',
          type: 'dispense_success',
        );
      } else if (status == 'failed') {
        _showLocalNotification(
          title: '❌ Dispense Failed',
          body: '$medicine was NOT dispensed. Check the device.',
          type: 'dispense_failed',
        );
      }
    });
  }

  /// Show a local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final color = _getNotificationColor(type);
    final androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      importance: Importance.max,
      priority: Priority.high,
      color: color,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  // ═══════════════════════════════════════════
  //  HELPERS — Channel & Color Config
  // ═══════════════════════════════════════════

  static String _getChannelId(String type) {
    switch (type) {
      case 'dispense_success':
        return 'dispense_ch';
      case 'dispense_failed':
      case 'missed_dose':
        return 'alert_ch';
      case 'caregiver_alert':
        return 'caregiver_ch';
      case 'sos':
        return 'sos_ch';
      default:
        return 'general_ch';
    }
  }

  static String _getChannelName(String type) {
    switch (type) {
      case 'dispense_success':
        return 'Dispense Notifications';
      case 'dispense_failed':
      case 'missed_dose':
        return 'Alert Notifications';
      case 'caregiver_alert':
        return 'Caregiver Alerts';
      case 'sos':
        return 'Emergency SOS';
      default:
        return 'General';
    }
  }

  static Color _getNotificationColor(String type) {
    switch (type) {
      case 'dispense_success':
        return const Color(0xFF2E7D32); // Green
      case 'dispense_failed':
      case 'sos':
        return const Color(0xFFBA1A1A); // Red
      case 'missed_dose':
        return const Color(0xFFE65100); // Orange
      case 'caregiver_alert':
        return const Color(0xFF006399); // Blue
      default:
        return const Color(0xFF00897B); // Teal
    }
  }
}

/// ═══════════════════════════════════════════════
///  BACKGROUND MESSAGE HANDLER
///  Must be a top-level function (not inside a class)
///  Called when app is terminated/background
/// ═══════════════════════════════════════════════
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 FCM Background: ${message.notification?.title}');
  // Firebase is already initialized by the time this runs.
  // The notification is automatically shown by the system.
}
