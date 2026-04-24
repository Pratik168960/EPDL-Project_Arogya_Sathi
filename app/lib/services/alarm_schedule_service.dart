import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════
///  ALARM SCHEDULE SERVICE
///  Manages a dedicated top-level Firestore collection that
///  ONLY stores the NEXT upcoming alarm for each medicine.
///
///  Behaviour:
///    • When a medicine is added → calculate the next alarm
///      time and save it to alarm_schedules.
///    • When the alarm FIRES (user taps "I took it") →
///      DELETE the current record, then CREATE a new record
///      for the next occurrence (next day, same time).
///    • Only stores upcoming/imminent alarms — NOT far-future.
///
///  Firestore path:
///    alarm_schedules/{uid}_{alarmId}
///      ├── uid
///      ├── medicine_name
///      ├── dosage
///      ├── frequency
///      ├── meal_timing
///      ├── alarm_time       (string, e.g. "8:00 AM")
///      ├── hour             (int, 0–23)
///      ├── minute           (int, 0–59)
///      ├── alarm_id         (int)
///      ├── next_alarm_at    (Timestamp — exact next fire time)
///      ├── is_active        (bool)
///      └── updated_at       (Timestamp)
/// ═══════════════════════════════════════════════════════════
class AlarmScheduleService {
  static final _col = FirebaseFirestore.instance.collection('alarm_schedules');

  /// Calculate the NEXT alarm DateTime from a TimeOfDay.
  /// If the time has already passed today, it returns tomorrow.
  static DateTime _nextAlarmTime(TimeOfDay time, List<int> selectedDays) {
    if (selectedDays.isEmpty) selectedDays = [1, 2, 3, 4, 5, 6, 7];
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    // Fast-forward until the weekday matches one of the selectedDays
    while (!selectedDays.contains(next.weekday)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  /// Save the NEXT upcoming alarm when a medicine is first added.
  static Future<void> saveAlarmSchedule({
    required String medicineName,
    required String dosage,
    required String frequency,
    required String mealTiming,
    required TimeOfDay time,
    required int alarmId,
    required List<int> selectedDays,
  }) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final nextAlarm = _nextAlarmTime(time, selectedDays);
    final timeStr =
        '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:'
        '${time.minute.toString().padLeft(2, '0')} '
        '${time.period.name.toUpperCase()}';

    await _col.doc('${uid}_$alarmId').set({
      'uid': uid,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'meal_timing': mealTiming,
      'alarm_time': timeStr,
      'hour': time.hour,
      'minute': time.minute,
      'alarm_id': alarmId,
      'selected_days': selectedDays,
      'next_alarm_at': Timestamp.fromDate(nextAlarm),
      'is_active': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Called when alarm FIRES — marks the alarm as inactive
  /// in the database so the fired state is reflected.
  static Future<void> onAlarmFired(int alarmId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final docRef = _col.doc('${uid}_$alarmId');
    final snapshot = await docRef.get();

    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final hour = data['hour'] as int;
    final minute = data['minute'] as int;
    
    final dynamic rawDays = data['selected_days'];
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];
    if (rawDays != null && rawDays is List) {
      selectedDays = rawDays.map((e) => e as int).toList();
    }

    // Calculate the NEXT occurrence based on selected days
    final now = DateTime.now();
    var nextAlarm = DateTime(now.year, now.month, now.day + 1, hour, minute);
    while (!selectedDays.contains(nextAlarm.weekday)) {
      nextAlarm = nextAlarm.add(const Duration(days: 1));
    }

    // Mark the alarm as inactive and store the next occurrence time
    await docRef.update({
      'is_active': false,
      'next_alarm_at': Timestamp.fromDate(nextAlarm),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Deactivate an alarm (toggle off without deleting).
  static Future<void> deactivateAlarm(int alarmId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final docRef = _col.doc('${uid}_$alarmId');
    if ((await docRef.get()).exists) {
      await docRef.update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Reactivate an alarm (toggle on) and recalculate next alarm time.
  static Future<void> activateAlarm(int alarmId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final docRef = _col.doc('${uid}_$alarmId');
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final dynamic rawDays = data['selected_days'];
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7];
    if (rawDays != null && rawDays is List) {
      selectedDays = rawDays.map((e) => e as int).toList();
    }

    final nextAlarm = _nextAlarmTime(
      TimeOfDay(hour: data['hour'], minute: data['minute']),
      selectedDays,
    );

    await docRef.update({
      'is_active': true,
      'next_alarm_at': Timestamp.fromDate(nextAlarm),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Delete an alarm schedule entry permanently (medicine removed).
  static Future<void> deleteAlarm(int alarmId) async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await _col.doc('${uid}_$alarmId').delete();
  }

  /// Get all alarms for the current user, ordered by next fire time.
  static Stream<QuerySnapshot> getMyAlarms() {
    final uid = AuthService.currentUserId;
    if (uid == null) return const Stream.empty();

    return _col
        .where('uid', isEqualTo: uid)
        .where('is_active', isEqualTo: true)
        .orderBy('next_alarm_at')
        .snapshots();
  }

  /// Get ALL alarm schedules across all users (hardware/admin).
  static Stream<QuerySnapshot> getAllAlarms() {
    return _col
        .where('is_active', isEqualTo: true)
        .orderBy('next_alarm_at')
        .snapshots();
  }
}
