/*
 * ═══════════════════════════════════════════════════════════
 *  ArogyaSathi — ESP32 Medicine Dispenser Firmware
 *  
 *  This firmware connects the ESP32 to Firebase Firestore
 *  and performs two core functions:
 *  
 *  1. LISTEN for dispense commands from the app
 *     (hardware_control/esp32_dispenser_01 → dispense_now)
 *  
 *  2. POLL alarm_schedules to check if any medicine is due
 *     and auto-dispense based on timing
 *  
 *  Hardware:
 *    - ESP32 DevKit V1
 *    - Servo motor on GPIO 13 (dispenser gate)
 *    - Buzzer on GPIO 12
 *    - LED indicators: Green (GPIO 14), Red (GPIO 27)
 *  
 *  Libraries Required (install via Arduino Library Manager):
 *    - Firebase_ESP_Client by Mobizt
 *    - WiFi (built-in)
 *    - ESP32Servo
 *    - NTPClient + WiFiUdp (for real-time clock)
 * ═══════════════════════════════════════════════════════════
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// ── Provide the token generation and RTDB helper ──
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ═══════════════════════════════════════════════
//  CONFIGURATION — CHANGE THESE VALUES
// ═══════════════════════════════════════════════

// Wi-Fi Credentials
#define WIFI_SSID     "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Firebase Project Credentials
#define API_KEY       "AIzaSy..."                    // From Firebase Console → Project Settings
#define FIREBASE_PROJECT_ID "arogyasathi-7f2c1"      // Your Firebase Project ID

// Firebase Auth — Service account or anonymous auth
// For production, use a service account email/password
#define USER_EMAIL    "esp32@arogyasathi.local"       // Create this user in Firebase Auth
#define USER_PASSWORD "esp32SecurePassword123"         // Set a strong password

// ═══════════════════════════════════════════════
//  HARDWARE PIN DEFINITIONS
// ═══════════════════════════════════════════════
#define SERVO_PIN     13    // Servo motor (dispenser gate)
#define BUZZER_PIN    12    // Piezo buzzer
#define LED_GREEN     14    // Status: Ready / Dispensed
#define LED_RED       27    // Status: Error / Dispensing

// ═══════════════════════════════════════════════
//  GLOBAL OBJECTS
// ═══════════════════════════════════════════════
FirebaseData   fbdo;
FirebaseAuth   auth;
FirebaseConfig config;

Servo dispenserServo;

WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 19800, 60000);  // IST offset = 19800s (5:30)

unsigned long lastAlarmCheck    = 0;
unsigned long lastStatusUpdate = 0;
const unsigned long ALARM_CHECK_INTERVAL  = 30000;   // Check alarms every 30 seconds
const unsigned long STATUS_UPDATE_INTERVAL = 60000;  // Update status every 60 seconds

bool firebaseReady = false;

// ═══════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  Serial.println("\n═══ ArogyaSathi ESP32 Dispenser ═══");

  // ── Pin Setup ──
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_RED, OUTPUT);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_RED, HIGH);   // Red until connected

  // ── Servo Setup ──
  dispenserServo.attach(SERVO_PIN);
  dispenserServo.write(0);  // Closed position

  // ── WiFi Connect ──
  connectWiFi();

  // ── NTP Time Sync ──
  timeClient.begin();
  timeClient.update();
  Serial.print("Current IST Time: ");
  Serial.println(timeClient.getFormattedTime());

  // ── Firebase Init ──
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);

  // Wait for Firebase auth
  Serial.print("Authenticating with Firebase...");
  while (!Firebase.ready()) {
    Serial.print(".");
    delay(500);
  }
  Serial.println(" ✓ Connected!");
  firebaseReady = true;

  // Success indicator
  digitalWrite(LED_RED, LOW);
  digitalWrite(LED_GREEN, HIGH);
  buzzerBeep(2, 100);  // Two short beeps = ready

  // Set initial hardware status
  updateHardwareStatus("online");

  Serial.println("═══ System Ready — Listening for commands ═══\n");
}

// ═══════════════════════════════════════════════
//  MAIN LOOP
// ═══════════════════════════════════════════════
void loop() {
  if (!firebaseReady || !Firebase.ready()) {
    delay(1000);
    return;
  }

  timeClient.update();

  // ── 1. Listen for INSTANT dispense commands from app ──
  checkDispenseCommand();

  // ── 2. Check alarm_schedules for due alarms ──
  if (millis() - lastAlarmCheck > ALARM_CHECK_INTERVAL) {
    checkAlarmSchedules();
    lastAlarmCheck = millis();
  }

  // ── 3. Periodic status heartbeat ──
  if (millis() - lastStatusUpdate > STATUS_UPDATE_INTERVAL) {
    updateHardwareStatus("online");
    lastStatusUpdate = millis();
  }

  delay(2000);  // Main loop delay
}

// ═══════════════════════════════════════════════
//  1. CHECK INSTANT DISPENSE COMMAND
//     Path: hardware_control/esp32_dispenser_01
// ═══════════════════════════════════════════════
void checkDispenseCommand() {
  String docPath = "hardware_control/esp32_dispenser_01";

  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", docPath.c_str())) {
    FirebaseJson payload;
    payload.setJsonData(fbdo.payload());

    FirebaseJsonData dispenseNow;
    FirebaseJsonData medicineName;

    payload.get(dispenseNow, "fields/dispense_now/booleanValue");
    payload.get(medicineName, "fields/medicine_dispensed/stringValue");

    if (dispenseNow.success && dispenseNow.to<bool>() == true) {
      String medicine = medicineName.success ? medicineName.to<String>() : "Unknown";

      Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      Serial.println("🔔 DISPENSE COMMAND RECEIVED!");
      Serial.print("   Medicine: ");
      Serial.println(medicine);
      Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      // Dispense!
      dispenseMedicine(medicine);

      // Reset the command flag in Firebase
      FirebaseJson resetDoc;
      resetDoc.set("fields/dispense_now/booleanValue", false);
      resetDoc.set("fields/medicine_dispensed/stringValue", medicine);
      resetDoc.set("fields/last_dispensed_at/stringValue", timeClient.getFormattedTime());

      Firebase.Firestore.patchDocument(
        &fbdo, FIREBASE_PROJECT_ID, "",
        docPath.c_str(),
        resetDoc.raw(),
        "dispense_now,medicine_dispensed,last_dispensed_at"
      );

      Serial.println("✓ Command flag reset to false\n");
    }
  }
}

// ═══════════════════════════════════════════════
//  2. CHECK ALARM SCHEDULES FOR DUE ALARMS
//     Path: alarm_schedules (all users)
// ═══════════════════════════════════════════════
void checkAlarmSchedules() {
  int currentHour   = timeClient.getHours();
  int currentMinute = timeClient.getMinutes();
  
  // NTPClient returns 0 for Sunday, 1 for Monday.
  // Dart DateTime returns 1 for Monday, 7 for Sunday.
  int currentWeekday = timeClient.getDay() == 0 ? 7 : timeClient.getDay();

  Serial.print("[Alarm Check] Current time: ");
  Serial.print(currentHour);
  Serial.print(":");
  if (currentMinute < 10) Serial.print("0");
  Serial.println(currentMinute);

  // Query Firestore for all active alarm_schedules
  // We check all documents and compare hour:minute locally
  String collectionPath = "projects/" + String(FIREBASE_PROJECT_ID)
                        + "/databases/(default)/documents/alarm_schedules";

  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", "alarm_schedules")) {
    // Parse the documents
    FirebaseJson payload;
    payload.setJsonData(fbdo.payload());

    // The response contains an array of documents
    size_t docCount = payload.iteratorBegin();
    FirebaseJson::IteratorValue value;

    for (size_t i = 0; i < docCount; i++) {
      value = payload.valueAt(i);

      if (value.type == FirebaseJson::JSON_OBJECT) {
        FirebaseJson docJson;
        docJson.setJsonData(value.value);

        FirebaseJsonData hourData, minuteData, activeData, medicineData, dosageData;
        docJson.get(hourData,     "fields/hour/integerValue");
        docJson.get(minuteData,   "fields/minute/integerValue");
        docJson.get(activeData,   "fields/is_active/booleanValue");
        docJson.get(medicineData, "fields/medicine_name/stringValue");
        docJson.get(dosageData,   "fields/dosage/stringValue");

        if (hourData.success && minuteData.success && activeData.success) {
          int alarmHour   = hourData.to<int>();
          int alarmMinute = minuteData.to<int>();
          bool isActive   = activeData.to<bool>();

          // Backward compatibility: If no selected_days is provided, assume daily (true)
          bool dayMatched = true;
          FirebaseJsonData daysData;
          docJson.get(daysData, "fields/selected_days/arrayValue/values");
          if (daysData.success) {
            String arrayStr = daysData.to<String>();
            // Search for the JSON representation of the current weekday's integer
            String searchStr = "\"integerValue\":\"" + String(currentWeekday) + "\"";
            if (arrayStr.indexOf(searchStr) == -1) {
              dayMatched = false;
            }
          }

          // Check if this alarm is due (within 1-minute window)
          if (isActive && dayMatched &&
              alarmHour == currentHour &&
              alarmMinute == currentMinute) {

            String medicine = medicineData.success ? medicineData.to<String>() : "Medicine";
            String dosage   = dosageData.success ? dosageData.to<String>() : "";

            Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Serial.println("⏰ ALARM TRIGGERED BY SCHEDULE!");
            Serial.print("   Medicine: ");
            Serial.print(medicine);
            Serial.print(" (");
            Serial.print(dosage);
            Serial.println(")");
            Serial.print("   Time: ");
            Serial.print(alarmHour);
            Serial.print(":");
            if (alarmMinute < 10) Serial.print("0");
            Serial.println(alarmMinute);
            Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

            dispenseMedicine(medicine);
          }
        }
      }
    }
    payload.iteratorEnd();
  }
}

// ═══════════════════════════════════════════════
//  DISPENSE MECHANISM
// ═══════════════════════════════════════════════
void dispenseMedicine(String medicineName) {
  Serial.println("💊 Dispensing: " + medicineName);

  // Visual + Audio alert
  digitalWrite(LED_RED, HIGH);
  digitalWrite(LED_GREEN, LOW);
  buzzerBeep(3, 200);  // 3 beeps

  // Open dispensing gate (servo to 90°)
  dispenserServo.write(90);
  Serial.println("   Servo → 90° (OPEN)");
  delay(3000);  // Hold open for 3 seconds

  // Close dispensing gate (servo back to 0°)
  dispenserServo.write(0);
  Serial.println("   Servo → 0° (CLOSED)");

  // Success indicator
  digitalWrite(LED_RED, LOW);
  digitalWrite(LED_GREEN, HIGH);
  buzzerBeep(1, 500);  // 1 long beep = success

  // Log to Firestore
  logDispenseEvent(medicineName);

  Serial.println("✓ Dispense complete!\n");
}

// ═══════════════════════════════════════════════
//  LOG DISPENSE EVENT TO FIRESTORE
// ═══════════════════════════════════════════════
void logDispenseEvent(String medicineName) {
  String docPath = "hardware_control/esp32_dispenser_01";

  FirebaseJson doc;
  doc.set("fields/dispense_now/booleanValue", false);
  doc.set("fields/medicine_dispensed/stringValue", medicineName);
  doc.set("fields/last_dispensed_at/stringValue", timeClient.getFormattedTime());
  doc.set("fields/dispense_count/integerValue", 1);   // Increment logic can be added
  doc.set("fields/status/stringValue", "dispensed");

  Firebase.Firestore.patchDocument(
    &fbdo, FIREBASE_PROJECT_ID, "",
    docPath.c_str(),
    doc.raw(),
    "dispense_now,medicine_dispensed,last_dispensed_at,dispense_count,status"
  );
}

// ═══════════════════════════════════════════════
//  UPDATE HARDWARE STATUS (heartbeat)
// ═══════════════════════════════════════════════
void updateHardwareStatus(String status) {
  String docPath = "hardware_control/esp32_dispenser_01";

  FirebaseJson doc;
  doc.set("fields/status/stringValue", status);
  doc.set("fields/last_heartbeat/stringValue", timeClient.getFormattedTime());
  doc.set("fields/wifi_rssi/integerValue", WiFi.RSSI());

  Firebase.Firestore.patchDocument(
    &fbdo, FIREBASE_PROJECT_ID, "",
    docPath.c_str(),
    doc.raw(),
    "status,last_heartbeat,wifi_rssi"
  );
}

// ═══════════════════════════════════════════════
//  WIFI CONNECTION
// ═══════════════════════════════════════════════
void connectWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.print(WIFI_SSID);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;

  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(" ✓ Connected!");
    Serial.print("   IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("   RSSI: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
  } else {
    Serial.println(" ✗ FAILED!");
    Serial.println("   Restarting in 5 seconds...");
    delay(5000);
    ESP.restart();
  }
}

// ═══════════════════════════════════════════════
//  BUZZER HELPER
// ═══════════════════════════════════════════════
void buzzerBeep(int times, int duration) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(duration);
    digitalWrite(BUZZER_PIN, LOW);
    if (i < times - 1) delay(duration / 2);  // Gap between beeps
  }
}
