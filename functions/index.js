/**
 * ═══════════════════════════════════════════════════════════
 *  ArogyaSathi — Firebase Cloud Functions
 *
 *  Triggers:
 *    1. onHardwareStatusChange → When ESP32 updates hardware_control,
 *       sends FCM push to the patient and linked caregivers.
 *
 *    2. onAlarmMissed → Scheduled function runs every 5 minutes,
 *       checks for unacknowledged alarms that are 15+ minutes overdue,
 *       marks them as "missed" and notifies caregivers.
 *
 *    3. onAlertCreated → When a new alert is written to a patient's
 *       alerts subcollection, sends FCM push to linked caregivers.
 *
 *  DEPLOY:
 *    cd functions
 *    npm install
 *    firebase deploy --only functions --project arogyasathi-7f2c1
 * ═══════════════════════════════════════════════════════════
 */

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// ═══════════════════════════════════════════
//  1. HARDWARE STATUS CHANGE → Push to Patient
//  Triggers when ESP32 updates hardware_control/{deviceId}
// ═══════════════════════════════════════════
exports.onHardwareStatusChange = onDocumentUpdated(
  "hardware_control/{deviceId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Only trigger if status changed
    if (before.status === after.status) return null;

    const status = after.status;
    const medicine = after.medicine_dispensed || "Medicine";
    const irConfirmed = after.ir_confirmed || false;

    let title, body, type;

    if (status === "dispensed" && irConfirmed) {
      title = "✅ Pill Dispensed";
      body = `${medicine} has been dispensed successfully. IR sensor confirmed.`;
      type = "dispense_success";
    } else if (status === "failed") {
      title = "❌ Dispense Failed!";
      body = `${medicine} was NOT dispensed. Please check the device.`;
      type = "dispense_failed";
    } else {
      return null; // Ignore heartbeat/online status changes
    }

    // Find the patient user who owns this alarm
    // For now, send to all users who have active alarm schedules
    const alarmDocs = await db
      .collection("alarm_schedules")
      .where("is_active", "==", true)
      .limit(10)
      .get();

    const uidsToNotify = new Set();
    alarmDocs.forEach((doc) => {
      const uid = doc.data().uid;
      if (uid) uidsToNotify.add(uid);
    });

    // Send push to each patient
    for (const uid of uidsToNotify) {
      await sendPushToUser(uid, title, body, { type, medicine });

      // Also notify their caregivers
      const userDoc = await db.collection("users").doc(uid).get();
      const caregivers = userDoc.data()?.linked_caregivers || [];
      for (const cgUid of caregivers) {
        await sendPushToUser(
          cgUid,
          `🔔 Patient Alert: ${title}`,
          body,
          { type: "caregiver_alert", medicine, patient_uid: uid }
        );
      }
    }

    console.log(`📱 Push sent for ${status}: ${medicine}`);
    return null;
  }
);

// ═══════════════════════════════════════════
//  2. MISSED DOSE CHECKER — Runs every 5 minutes
//  Checks alarm_schedules for overdue, unacknowledged alarms
// ═══════════════════════════════════════════
exports.checkMissedDoses = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Asia/Kolkata",
  },
  async () => {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    // Get all active alarms
    const alarms = await db
      .collection("alarm_schedules")
      .where("is_active", "==", true)
      .get();

    for (const doc of alarms.docs) {
      const data = doc.data();
      const h = data.hour;
      const m = data.minute;
      const uid = data.uid;
      const medicineName = data.medicine_name || "Medicine";
      const status = data.status || "pending";

      // Skip if already missed or taken
      if (status === "missed" || status === "taken") continue;

      // Calculate if the alarm is 15+ minutes overdue
      const alarmTimeMinutes = h * 60 + m;
      const nowMinutes = currentHour * 60 + currentMinute;
      const diff = nowMinutes - alarmTimeMinutes;

      // Overdue by 15-120 minutes (same day, within 2 hours)
      if (diff >= 15 && diff <= 120) {
        console.log(`⚠️ MISSED: ${medicineName} for user ${uid} (${h}:${m})`);

        // Mark as missed
        await doc.ref.update({ status: "missed" });

        // Log to patient's history
        await db
          .collection("users")
          .doc(uid)
          .collection("history")
          .add({
            name: medicineName,
            status: "Missed",
            taken_at: FieldValue.serverTimestamp(),
            scheduled_time: `${h}:${String(m).padStart(2, "0")}`,
          });

        // Create alert for patient
        await db
          .collection("users")
          .doc(uid)
          .collection("alerts")
          .add({
            type: "missed_dose",
            message: `${medicineName} was missed (${h}:${String(m).padStart(2, "0")})`,
            medicine: medicineName,
            timestamp: FieldValue.serverTimestamp(),
            read: false,
          });

        // Notify patient
        await sendPushToUser(
          uid,
          "⚠️ Missed Dose",
          `You missed ${medicineName} scheduled for ${h}:${String(m).padStart(2, "0")}`,
          { type: "missed_dose", medicine: medicineName }
        );

        // Notify linked caregivers
        const userDoc = await db.collection("users").doc(uid).get();
        const caregivers = userDoc.data()?.linked_caregivers || [];
        for (const cgUid of caregivers) {
          await sendPushToUser(
            cgUid,
            "🚨 Patient Missed a Dose!",
            `${medicineName} was missed at ${h}:${String(m).padStart(2, "0")}`,
            { type: "caregiver_alert", medicine: medicineName, patient_uid: uid }
          );
        }
      }
    }

    console.log("✅ Missed dose check complete");
    return null;
  }
);

// ═══════════════════════════════════════════
//  3. ALERT CREATED → Push to Caregivers
//  Triggers when a new alert is added to any patient
// ═══════════════════════════════════════════
exports.onAlertCreated = onDocumentCreated(
  "users/{userId}/alerts/{alertId}",
  async (event) => {
    const userId = event.params.userId;
    const data = event.data.data();

    const type = data.type || "alert";
    const message = data.message || "New alert";
    const medicine = data.medicine || "";

    // Get patient's linked caregivers
    const userDoc = await db.collection("users").doc(userId).get();
    const caregivers = userDoc.data()?.linked_caregivers || [];

    if (caregivers.length === 0) return null;

    // Send push to each caregiver
    for (const cgUid of caregivers) {
      await sendPushToUser(
        cgUid,
        `🔔 Patient Alert`,
        message,
        { type: "caregiver_alert", medicine, patient_uid: userId }
      );
    }

    console.log(`📱 Alert pushed to ${caregivers.length} caregiver(s)`);
    return null;
  }
);

// ═══════════════════════════════════════════
//  HELPER: Send FCM push to a specific user
// ═══════════════════════════════════════════
async function sendPushToUser(uid, title, body, dataPayload = {}) {
  try {
    const userDoc = await db.collection("users").doc(uid).get();
    const fcmToken = userDoc.data()?.fcm_token;

    if (!fcmToken) {
      console.log(`⚠️ No FCM token for user ${uid}`);
      return;
    }

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: dataPayload,
      android: {
        priority: "high",
        notification: {
          channelId: dataPayload.type === "sos" ? "sos_ch" : "alert_ch",
          priority: "max",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    };

    await messaging.send(message);
    console.log(`📱 Push sent to ${uid}: ${title}`);
  } catch (error) {
    // Token might be expired — clean it up
    if (
      error.code === "messaging/invalid-registration-token" ||
      error.code === "messaging/registration-token-not-registered"
    ) {
      console.log(`🗑️ Removing stale FCM token for ${uid}`);
      await db
        .collection("users")
        .doc(uid)
        .update({ fcm_token: FieldValue.delete() });
    } else {
      console.error(`❌ Push error for ${uid}:`, error);
    }
  }
}
