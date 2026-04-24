import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════
///  HARDWARE SYNC SERVICE
///  Maintains the "Next Alarm Pointer" for the ESP32 dispenser.
///
///  Architecture:
///    The ESP32 only reads ONE document to know when to dispense:
///      users/{uid}/hardware/current_alarm
///
///    This service listens to ALL of the user's medications,
///    determines which alarm is chronologically NEXT,
///    and writes that single pointer document.
///
///  Document schema:
///    {
///      "status":     "PENDING",
///      "time":       "08:30",       // 24-hour military format
///      "medication": "Metformin"    // Max 16 chars for LCD
///    }
/// ═══════════════════════════════════════════════════════════
class HardwareSyncService {
  static final _db = FirebaseFirestore.instance;
  static StreamSubscription<QuerySnapshot>? _subscription;

  /// Start listening to the user's medications and auto-sync
  /// the next alarm pointer whenever the collection changes.
  static void startListening() {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    // Cancel any existing listener
    _subscription?.cancel();

    _subscription = _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .snapshots()
        .listen((snapshot) {
      _recalculateNextAlarm(uid, snapshot.docs);
    });
  }

  /// Stop listening (call on logout).
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Core algorithm: find the chronologically next alarm
  /// from the user's medications and write the pointer.
  static Future<void> _recalculateNextAlarm(
    String uid,
    List<QueryDocumentSnapshot> docs,
  ) async {
    if (docs.isEmpty) {
      // No medications — clear the pointer
      await _clearPointer(uid);
      return;
    }

    final now = DateTime.now();
    DateTime? earliestTime;
    String? earliestMedName;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timeStr = data['time'] as String?; // e.g. "8:00 AM"
      final name = data['name'] as String? ?? 'Medicine';

      if (timeStr == null) continue;

      final parsed = _parseTimeString(timeStr);
      if (parsed == null) continue;

      // Build candidate DateTime for today
      var candidate = DateTime(
        now.year, now.month, now.day,
        parsed.hour, parsed.minute,
      );

      // If the time already passed today, roll to tomorrow
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }

      // Track the earliest
      if (earliestTime == null || candidate.isBefore(earliestTime)) {
        earliestTime = candidate;
        earliestMedName = name;
      }
    }

    if (earliestTime == null || earliestMedName == null) {
      await _clearPointer(uid);
      return;
    }

    // Format to 24-hour military time: "08:30" or "14:45"
    final militaryTime =
        '${earliestTime.hour.toString().padLeft(2, '0')}:'
        '${earliestTime.minute.toString().padLeft(2, '0')}';

    // Truncate medication name to 16 chars for the LCD
    final lcdName = earliestMedName.length > 16
        ? earliestMedName.substring(0, 16)
        : earliestMedName;

    // Write the pointer document
    await _db
        .collection('users')
        .doc(uid)
        .collection('hardware')
        .doc('current_alarm')
        .set({
      'status': 'PENDING',
      'time': militaryTime,
      'medication': lcdName,
    });
  }

  /// Manually trigger a recalculation (e.g. after adding or
  /// completing a medication). Useful for one-shot calls.
  static Future<void> syncNow() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('medications')
        .get();

    await _recalculateNextAlarm(uid, snapshot.docs);
  }

  /// Mark the current alarm as DONE and recalculate the next one.
  /// Call this when the user confirms "I took it".
  static Future<void> markCurrentDone() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('hardware')
        .doc('current_alarm')
        .set({'status': 'DONE', 'time': '', 'medication': ''});

    // Immediately recalculate the next alarm
    await syncNow();
  }

  /// Clear the pointer (no alarms pending).
  static Future<void> _clearPointer(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('hardware')
        .doc('current_alarm')
        .set({
      'status': 'IDLE',
      'time': '',
      'medication': '',
    });
  }

  /// Parse time strings like "8:00 AM", "2:30 PM", "14:45"
  /// into a TimeOfDay. Returns null on failure.
  static TimeOfDay? _parseTimeString(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();

    try {
      // Try 12-hour format first: "8:00 AM" or "12:30 PM"
      final match12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(timeStr);
      if (match12 != null) {
        var hour = int.parse(match12.group(1)!);
        final minute = int.parse(match12.group(2)!);
        final period = match12.group(3)!;

        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        return TimeOfDay(hour: hour, minute: minute);
      }

      // Try 24-hour format: "14:45" or "08:30"
      final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeStr);
      if (match24 != null) {
        final hour = int.parse(match24.group(1)!);
        final minute = int.parse(match24.group(2)!);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}

    return null;
  }
}
