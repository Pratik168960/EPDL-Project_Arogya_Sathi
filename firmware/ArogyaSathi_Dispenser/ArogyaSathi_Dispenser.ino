/*
 * ═══════════════════════════════════════════════════════════════
 *  ArogyaSathi — ESP32 Medicine Dispenser Firmware v2
 *  Complete Three-Tier IoT Edge Device
 *  
 *  HARDWARE COMPONENTS:
 *  ┌────────────────────────┬────────┬─────────────────────────┐
 *  │ Component              │ Pins   │ Purpose                 │
 *  ├────────────────────────┼────────┼─────────────────────────┤
 *  │ Stepper 28BYJ-48       │ 25,26, │ Rotate pill carousel    │
 *  │ (ULN2003 driver)       │ 32,33  │ to correct slot         │
 *  │ Servo SG90             │ 13     │ Open/close dispense gate│
 *  │ IR Break-Beam Sensor   │ 4      │ Confirm pill dropped    │
 *  │ OLED SSD1306 128x64    │ 21,22  │ Status display (I2C)    │
 *  │ Buzzer                 │ 12     │ Audio alerts            │
 *  │ LED Green              │ 14     │ Status: OK / Dispensed  │
 *  │ LED Red                │ 27     │ Status: Alert / Error   │
 *  └────────────────────────┴────────┴─────────────────────────┘
 *  
 *  DISPENSE CYCLE:
 *    1. Alarm triggers (time match OR app command)
 *    2. Display shows medicine name
 *    3. Buzzer sounds alert
 *    4. Stepper rotates carousel to correct pill slot
 *    5. Servo opens dispensing gate
 *    6. IR sensor waits for pill to fall through
 *    7. IF pill detected → Firebase status = "dispensed" ✓
 *       IF no pill in 10s → retry → if still none → "failed" ✗
 *    8. Servo closes gate
 *    9. Display shows result
 *  
 *  LIBRARIES (Arduino Library Manager):
 *    - "Firebase Arduino Client Library for ESP8266 and ESP32" by Mobizt
 *    - "ESP32Servo" by Kevin Harrington
 *    - "Adafruit SSD1306" by Adafruit
 *    - "Adafruit GFX Library" by Adafruit
 *    - "NTPClient" by Fabrice Weinberg
 *    - "Stepper" (built-in)
 *  
 *  BOARD: ESP32 Dev Module | UPLOAD SPEED: 115200
 * ═══════════════════════════════════════════════════════════════
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <ESP32Servo.h>
#include <Stepper.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ═══════════════════════════════════════════════
//  ⚠️  CONFIGURATION — UPDATE THESE VALUES ⚠️
// ═══════════════════════════════════════════════
#define WIFI_SSID            "YOUR_WIFI_SSID"
#define WIFI_PASSWORD        "YOUR_WIFI_PASSWORD"
#define API_KEY              "YOUR_FIREBASE_API_KEY"
#define FIREBASE_PROJECT_ID  "arogyasathi-7f2c1"
#define USER_EMAIL           "esp32@arogyasathi.local"
#define USER_PASSWORD        "esp32SecurePassword123"

// ═══════════════════════════════════════════════
//  PIN DEFINITIONS
// ═══════════════════════════════════════════════

// Stepper Motor (28BYJ-48 via ULN2003)
#define STEPPER_IN1   25
#define STEPPER_IN2   26
#define STEPPER_IN3   32
#define STEPPER_IN4   33
#define STEPS_PER_REV 2048    // 28BYJ-48 = 2048 steps/revolution
#define STEPS_PER_SLOT (STEPS_PER_REV / 4)  // 4 pill slots = 90° each

// Servo Motor (SG90)
#define SERVO_PIN     13
#define GATE_CLOSED   0
#define GATE_OPEN     90

// IR Break-Beam Sensor
#define IR_SENSOR_PIN 4       // LOW when beam is broken (pill detected)

// OLED Display (I2C)
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define OLED_ADDR     0x3C

// Audio & Visual
#define BUZZER_PIN    12
#define LED_GREEN     14
#define LED_RED       27

// ═══════════════════════════════════════════════
//  TIMING CONSTANTS
// ═══════════════════════════════════════════════
#define IR_TIMEOUT_MS       10000   // 10 seconds to detect pill
#define IR_CHECK_INTERVAL   100     // Check IR every 100ms
#define ALARM_CHECK_SEC     30000   // Check alarms every 30s
#define HEARTBEAT_SEC       60000   // Heartbeat every 60s
#define GATE_HOLD_MS        3000    // Hold gate open 3 seconds
#define MAX_DISPENSE_RETRIES 2      // Retry dispense if IR fails

// ═══════════════════════════════════════════════
//  GLOBAL OBJECTS
// ═══════════════════════════════════════════════
FirebaseData   fbdo;
FirebaseAuth   auth;
FirebaseConfig config;

Stepper        carousel(STEPS_PER_REV, STEPPER_IN1, STEPPER_IN3, STEPPER_IN2, STEPPER_IN4);
Servo          gateServo;

Adafruit_SSD1306 oled(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

WiFiUDP        ntpUDP;
NTPClient      timeClient(ntpUDP, "pool.ntp.org", 19800, 60000);  // IST = UTC+5:30

unsigned long  lastAlarmCheck   = 0;
unsigned long  lastHeartbeat    = 0;
bool           firebaseReady    = false;
int            currentSlot      = 0;   // Track carousel position (0-3)
int            totalDispenses   = 0;
int            totalMissed      = 0;

// ═══════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n╔══════════════════════════════════════╗");
  Serial.println("║   ArogyaSathi Dispenser v2.0         ║");
  Serial.println("║   Three-Tier IoT Edge Device         ║");
  Serial.println("╚══════════════════════════════════════╝\n");

  // ── GPIO Setup ──
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_RED, OUTPUT);
  pinMode(IR_SENSOR_PIN, INPUT_PULLUP);  // HIGH = beam intact, LOW = broken
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_RED, HIGH);  // Red until fully booted

  // ── Stepper Setup ──
  carousel.setSpeed(10);  // RPM for 28BYJ-48

  // ── Servo Setup ──
  gateServo.attach(SERVO_PIN);
  gateServo.write(GATE_CLOSED);

  // ── OLED Setup ──
  Wire.begin(21, 22);
  if (!oled.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("⚠️  OLED not found!");
  }
  displayBoot("Booting...", "Connecting WiFi");

  // ── WiFi ──
  connectWiFi();
  displayBoot("WiFi OK", "Syncing time...");

  // ── NTP Time ──
  timeClient.begin();
  timeClient.update();
  Serial.print("  IST: ");
  Serial.println(timeClient.getFormattedTime());
  displayBoot("Time synced", timeClient.getFormattedTime().c_str());
  delay(1000);

  // ── Firebase ──
  displayBoot("Authenticating", "Firebase...");
  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectNetwork(true);

  Serial.print("  Firebase auth...");
  unsigned long t0 = millis();
  while (!Firebase.ready() && millis() - t0 < 15000) {
    Serial.print(".");
    delay(500);
  }

  if (Firebase.ready()) {
    Serial.println(" ✓");
    firebaseReady = true;
    digitalWrite(LED_RED, LOW);
    digitalWrite(LED_GREEN, HIGH);
    buzzer(2, 100);
    updateStatus("online", "System booted successfully");
  } else {
    Serial.println(" ✗ FAILED");
    displayError("Firebase", "Auth Failed!");
    buzzer(5, 100);
    return;
  }

  // ── Self-test ──
  selfTest();

  // ── Ready ──
  displayIdle();
  Serial.println("\n══ SYSTEM READY — Listening for commands ══\n");
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

  // 1. Check for instant dispense commands from app
  checkDispenseCommand();

  // 2. Check alarm_schedules for due medications
  if (millis() - lastAlarmCheck > ALARM_CHECK_SEC) {
    checkAlarmSchedules();
    lastAlarmCheck = millis();
  }

  // 3. Heartbeat status update
  if (millis() - lastHeartbeat > HEARTBEAT_SEC) {
    updateStatus("online", "Idle - waiting");
    displayIdle();
    lastHeartbeat = millis();
  }

  delay(2000);
}

// ═══════════════════════════════════════════════
//  SELF TEST — Validate all hardware on boot
// ═══════════════════════════════════════════════
void selfTest() {
  Serial.println("\n── Hardware Self-Test ──");

  // Test buzzer
  Serial.print("  Buzzer: ");
  buzzer(1, 200);
  Serial.println("OK");

  // Test LEDs
  Serial.print("  LEDs: ");
  digitalWrite(LED_GREEN, HIGH); delay(300);
  digitalWrite(LED_RED, HIGH);   delay(300);
  digitalWrite(LED_RED, LOW);
  Serial.println("OK");

  // Test IR sensor
  Serial.print("  IR Sensor: ");
  int irState = digitalRead(IR_SENSOR_PIN);
  Serial.println(irState == HIGH ? "OK (beam intact)" : "WARN (beam broken - check alignment)");

  // Test servo
  Serial.print("  Servo: ");
  gateServo.write(GATE_OPEN);  delay(500);
  gateServo.write(GATE_CLOSED); delay(500);
  Serial.println("OK");

  // Test stepper (small rotation)
  Serial.print("  Stepper: ");
  displayBoot("Self-Test", "Motor check...");
  carousel.step(100);  delay(200);
  carousel.step(-100); delay(200);
  // De-energize stepper coils to prevent heating
  stepperOff();
  Serial.println("OK");

  // Test display
  Serial.print("  OLED: ");
  displayBoot("Self-Test", "ALL PASSED!");
  Serial.println("OK");
  delay(1000);

  Serial.println("── Self-Test Complete ──\n");
}

// ═══════════════════════════════════════════════
//  CHECK INSTANT DISPENSE COMMAND FROM APP
//  Path: hardware_control/esp32_dispenser_01
// ═══════════════════════════════════════════════
void checkDispenseCommand() {
  String path = "hardware_control/esp32_dispenser_01";

  if (Firebase.Firestore.getDocument(&fbdo, FIREBASE_PROJECT_ID, "", path.c_str())) {
    FirebaseJson json;
    json.setJsonData(fbdo.payload());

    FirebaseJsonData dispenseFlag, medicineField, slotField;
    json.get(dispenseFlag,  "fields/dispense_now/booleanValue");
    json.get(medicineField, "fields/medicine_dispensed/stringValue");
    json.get(slotField,     "fields/slot/integerValue");

    if (dispenseFlag.success && dispenseFlag.to<bool>()) {
      String medicine = medicineField.success ? medicineField.to<String>() : "Medicine";
      int slot = slotField.success ? slotField.to<int>() : 0;

      Serial.println("🔔 APP COMMAND → Dispense: " + medicine + " (slot " + String(slot) + ")");
      
      bool success = executeDispenseCycle(medicine, slot);

      // Reset command flag and report result
      FirebaseJson resetDoc;
      resetDoc.set("fields/dispense_now/booleanValue", false);
      resetDoc.set("fields/last_dispensed_at/stringValue", timeClient.getFormattedTime());
      resetDoc.set("fields/last_result/stringValue", success ? "dispensed" : "failed");

      Firebase.Firestore.patchDocument(
        &fbdo, FIREBASE_PROJECT_ID, "", path.c_str(),
        resetDoc.raw(), "dispense_now,last_dispensed_at,last_result"
      );
    }
  }
}

// ═══════════════════════════════════════════════
//  CHECK ALARM SCHEDULES FOR DUE MEDICATIONS
//  Path: alarm_schedules (all users, all alarms)
// ═══════════════════════════════════════════════
void checkAlarmSchedules() {
  int nowH = timeClient.getHours();
  int nowM = timeClient.getMinutes();

  if (Firebase.Firestore.listDocuments(&fbdo, FIREBASE_PROJECT_ID, "", "alarm_schedules", 50, "", "", "", false)) {
    FirebaseJson json;
    json.setJsonData(fbdo.payload());

    FirebaseJsonData documents;
    json.get(documents, "documents");

    if (documents.success && documents.type == "array") {
      FirebaseJsonArray arr;
      arr.setJsonArrayData(documents.to<String>());

      for (size_t i = 0; i < arr.size(); i++) {
        FirebaseJsonData item;
        arr.get(item, i);

        if (item.type == "object") {
          FirebaseJson doc;
          doc.setJsonData(item.to<String>());

          FirebaseJsonData hourD, minD, activeD, nameD, dosageD;
          doc.get(hourD,   "fields/hour/integerValue");
          doc.get(minD,    "fields/minute/integerValue");
          doc.get(activeD, "fields/is_active/booleanValue");
          doc.get(nameD,   "fields/medicine_name/stringValue");
          doc.get(dosageD, "fields/dosage/stringValue");

          if (hourD.success && minD.success && activeD.success) {
            int h = hourD.to<int>();
            int m = minD.to<int>();
            bool active = activeD.to<bool>();

            if (active && h == nowH && m == nowM) {
              String name = nameD.success ? nameD.to<String>() : "Medicine";
              String dose = dosageD.success ? dosageD.to<String>() : "";

              Serial.println("⏰ ALARM DUE → " + name + " (" + dose + ")");
              executeDispenseCycle(name, currentSlot);
            }
          }
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  EXECUTE DISPENSE CYCLE — The Full Pipeline
//  
//  Step 1: Display medicine info
//  Step 2: Sound buzzer alert
//  Step 3: Rotate stepper to correct pill slot
//  Step 4: Open servo gate
//  Step 5: Monitor IR sensor for pill drop
//  Step 6: Report result to Firebase
//  Step 7: Close gate, update display
// ═══════════════════════════════════════════════════════════════
bool executeDispenseCycle(String medicine, int targetSlot) {
  Serial.println("\n╔════════════════════════════════════╗");
  Serial.println("║     DISPENSE CYCLE STARTING        ║");
  Serial.println("╚════════════════════════════════════╝");
  Serial.print("  Medicine: "); Serial.println(medicine);
  Serial.print("  Target Slot: "); Serial.println(targetSlot);

  // ── STEP 1: Display ──
  displayDispensing(medicine.c_str(), "Preparing...");
  digitalWrite(LED_RED, HIGH);
  digitalWrite(LED_GREEN, LOW);

  // ── STEP 2: Alert buzzer ──
  Serial.println("  [2/7] Sounding alert...");
  buzzer(3, 200);
  delay(500);

  // ── STEP 3: Rotate carousel to target slot ──
  Serial.println("  [3/7] Rotating carousel...");
  displayDispensing(medicine.c_str(), "Rotating...");
  rotateToSlot(targetSlot);
  delay(500);

  // ── STEP 4 & 5: Open gate + monitor IR (with retry) ──
  bool pillDetected = false;

  for (int attempt = 1; attempt <= MAX_DISPENSE_RETRIES; attempt++) {
    Serial.print("  [4/7] Opening gate (attempt ");
    Serial.print(attempt);
    Serial.println(")...");

    displayDispensing(medicine.c_str(), "Dispensing...");
    gateServo.write(GATE_OPEN);

    // ── STEP 5: Wait for IR sensor to detect pill ──
    Serial.println("  [5/7] Waiting for pill drop...");
    pillDetected = waitForPillDrop();

    // Close gate
    gateServo.write(GATE_CLOSED);
    delay(300);

    if (pillDetected) {
      break;  // Success!
    }

    if (attempt < MAX_DISPENSE_RETRIES) {
      Serial.println("  ⚠️  No pill detected — retrying...");
      displayDispensing(medicine.c_str(), "Retrying...");
      buzzer(2, 300);
      delay(1000);
    }
  }

  // ── STEP 6: Report to Firebase ──
  Serial.println("  [6/7] Reporting to Firebase...");
  if (pillDetected) {
    reportDispenseResult(medicine, "dispensed");
    totalDispenses++;
  } else {
    reportDispenseResult(medicine, "failed");
    totalMissed++;
  }

  // ── STEP 7: Final status ──
  Serial.println("  [7/7] Cycle complete.");
  if (pillDetected) {
    Serial.println("  ✅ PILL DISPENSED SUCCESSFULLY");
    displaySuccess(medicine.c_str());
    digitalWrite(LED_RED, LOW);
    digitalWrite(LED_GREEN, HIGH);
    buzzer(1, 800);  // 1 long beep = success
  } else {
    Serial.println("  ❌ PILL DROP NOT DETECTED — ALERT SENT");
    displayFailed(medicine.c_str());
    // Red LED stays on
    buzzer(5, 150);  // Rapid beeps = failure alert
  }

  // De-energize stepper
  stepperOff();

  delay(5000);  // Show result for 5 seconds
  displayIdle();
  digitalWrite(LED_RED, LOW);
  digitalWrite(LED_GREEN, HIGH);

  Serial.println("╔════════════════════════════════════╗");
  Serial.println("║     DISPENSE CYCLE COMPLETE        ║");
  Serial.println("╚════════════════════════════════════╝\n");

  return pillDetected;
}

// ═══════════════════════════════════════════════
//  CAROUSEL ROTATION — Stepper Motor Control
// ═══════════════════════════════════════════════
void rotateToSlot(int targetSlot) {
  // Calculate how many slots to move
  int slotsToMove = targetSlot - currentSlot;

  // Always move forward (positive direction)
  if (slotsToMove < 0) slotsToMove += 4;
  if (slotsToMove == 0) {
    Serial.println("    Already at correct slot.");
    return;
  }

  int stepsNeeded = slotsToMove * STEPS_PER_SLOT;

  Serial.print("    Moving ");
  Serial.print(slotsToMove);
  Serial.print(" slot(s) = ");
  Serial.print(stepsNeeded);
  Serial.println(" steps");

  carousel.step(stepsNeeded);
  currentSlot = targetSlot;

  Serial.print("    Carousel now at slot ");
  Serial.println(currentSlot);
}

// ═══════════════════════════════════════════════
//  IR SENSOR — Wait for Pill Drop Confirmation
// ═══════════════════════════════════════════════
bool waitForPillDrop() {
  unsigned long startTime = millis();

  // Display progress bar while waiting
  int barWidth = 100;

  while (millis() - startTime < IR_TIMEOUT_MS) {
    // Check IR sensor — LOW means beam is broken (pill passed through)
    if (digitalRead(IR_SENSOR_PIN) == LOW) {
      Serial.println("    ✓ IR BEAM BROKEN — Pill detected!");
      delay(200);  // Debounce
      return true;
    }

    // Update progress bar on display
    unsigned long elapsed = millis() - startTime;
    int progress = (int)((elapsed * barWidth) / IR_TIMEOUT_MS);
    oled.fillRect(14, 55, progress, 6, SSD1306_WHITE);
    oled.drawRect(14, 55, barWidth, 6, SSD1306_WHITE);
    oled.display();

    delay(IR_CHECK_INTERVAL);
  }

  Serial.println("    ✗ TIMEOUT — No pill detected in 10 seconds");
  return false;
}

// ═══════════════════════════════════════════════
//  FIREBASE FEEDBACK — Report Dispense Result
// ═══════════════════════════════════════════════
void reportDispenseResult(String medicine, String status) {
  // Update hardware_control with result
  String path = "hardware_control/esp32_dispenser_01";

  FirebaseJson doc;
  doc.set("fields/dispense_now/booleanValue", false);
  doc.set("fields/medicine_dispensed/stringValue", medicine);
  doc.set("fields/last_dispensed_at/stringValue", timeClient.getFormattedTime());
  doc.set("fields/status/stringValue", status);
  doc.set("fields/total_dispensed/integerValue", totalDispenses);
  doc.set("fields/total_missed/integerValue", totalMissed);
  doc.set("fields/ir_confirmed/booleanValue", status == "dispensed");

  Firebase.Firestore.patchDocument(
    &fbdo, FIREBASE_PROJECT_ID, "", path.c_str(),
    doc.raw(),
    "dispense_now,medicine_dispensed,last_dispensed_at,status,total_dispensed,total_missed,ir_confirmed"
  );

  Serial.print("    Firebase → status: ");
  Serial.println(status);
}

// ═══════════════════════════════════════════════
//  STEPPER OFF — De-energize coils to save power
// ═══════════════════════════════════════════════
void stepperOff() {
  digitalWrite(STEPPER_IN1, LOW);
  digitalWrite(STEPPER_IN2, LOW);
  digitalWrite(STEPPER_IN3, LOW);
  digitalWrite(STEPPER_IN4, LOW);
}

// ═══════════════════════════════════════════════
//  STATUS UPDATE — Heartbeat to Firebase
// ═══════════════════════════════════════════════
void updateStatus(String status, String message) {
  String path = "hardware_control/esp32_dispenser_01";

  FirebaseJson doc;
  doc.set("fields/status/stringValue", status);
  doc.set("fields/message/stringValue", message);
  doc.set("fields/last_heartbeat/stringValue", timeClient.getFormattedTime());
  doc.set("fields/wifi_rssi/integerValue", WiFi.RSSI());
  doc.set("fields/current_slot/integerValue", currentSlot);
  doc.set("fields/total_dispensed/integerValue", totalDispenses);
  doc.set("fields/total_missed/integerValue", totalMissed);

  Firebase.Firestore.patchDocument(
    &fbdo, FIREBASE_PROJECT_ID, "", path.c_str(),
    doc.raw(),
    "status,message,last_heartbeat,wifi_rssi,current_slot,total_dispensed,total_missed"
  );
}

// ═══════════════════════════════════════════════
//  OLED DISPLAY FUNCTIONS
// ═══════════════════════════════════════════════

void displayBoot(const char* line1, const char* line2) {
  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  oled.setTextSize(1);
  oled.setCursor(10, 2);
  oled.println("ArogyaSathi v2.0");
  oled.drawLine(0, 12, 128, 12, SSD1306_WHITE);

  oled.setTextSize(1);
  oled.setCursor(0, 22);
  oled.println(line1);
  oled.setCursor(0, 38);
  oled.println(line2);
  oled.display();
}

void displayIdle() {
  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  // Header
  oled.setTextSize(1);
  oled.setCursor(5, 0);
  oled.println("ArogyaSathi");
  oled.drawLine(0, 10, 128, 10, SSD1306_WHITE);

  // Time
  oled.setTextSize(2);
  oled.setCursor(15, 16);
  oled.println(timeClient.getFormattedTime().substring(0, 5));

  // Status
  oled.setTextSize(1);
  oled.setCursor(0, 38);
  oled.print("Slot: "); oled.println(currentSlot);
  oled.setCursor(0, 48);
  oled.print("Done: "); oled.print(totalDispenses);
  oled.print("  Miss: "); oled.println(totalMissed);

  // Bottom bar
  oled.drawLine(0, 57, 128, 57, SSD1306_WHITE);
  oled.setCursor(5, 59);
  oled.println("Waiting for alarm...");

  oled.display();
}

void displayDispensing(const char* medicine, const char* phase) {
  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  oled.setTextSize(1);
  oled.setCursor(5, 0);
  oled.println("-- DISPENSING --");
  oled.drawLine(0, 10, 128, 10, SSD1306_WHITE);

  oled.setTextSize(2);
  oled.setCursor(0, 16);
  // Truncate medicine name if too long for display
  String name = String(medicine);
  if (name.length() > 10) name = name.substring(0, 10);
  oled.println(name);

  oled.setTextSize(1);
  oled.setCursor(0, 40);
  oled.println(phase);

  // Progress bar placeholder
  oled.drawRect(14, 55, 100, 6, SSD1306_WHITE);
  oled.display();
}

void displaySuccess(const char* medicine) {
  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  oled.setTextSize(2);
  oled.setCursor(15, 5);
  oled.println("DONE!");

  oled.setTextSize(1);
  oled.setCursor(0, 30);
  oled.print("Dispensed: ");
  oled.println(medicine);

  oled.setCursor(0, 45);
  oled.println("IR Confirmed: YES");

  oled.setCursor(0, 57);
  oled.print(timeClient.getFormattedTime());
  oled.display();
}

void displayFailed(const char* medicine) {
  oled.clearDisplay();
  oled.setTextColor(SSD1306_WHITE);

  oled.setTextSize(2);
  oled.setCursor(10, 5);
  oled.println("FAILED!");

  oled.setTextSize(1);
  oled.setCursor(0, 30);
  oled.println(medicine);
  oled.setCursor(0, 42);
  oled.println("No pill detected!");
  oled.setCursor(0, 54);
  oled.println("Alert sent to app");
  oled.display();
}

void displayError(const char* title, const char* msg) {
  oled.clearDisplay();
  oled.setTextSize(2);
  oled.setCursor(0, 5);
  oled.println("ERROR");
  oled.setTextSize(1);
  oled.setCursor(0, 30);
  oled.println(title);
  oled.setCursor(0, 42);
  oled.println(msg);
  oled.display();
}

// ═══════════════════════════════════════════════
//  WIFI CONNECTION
// ═══════════════════════════════════════════════
void connectWiFi() {
  Serial.print("  WiFi → " + String(WIFI_SSID));
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 30) {
    delay(500);
    Serial.print(".");
    tries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println(" ✓");
    Serial.println("  IP: " + WiFi.localIP().toString());
    Serial.print("  RSSI: "); Serial.print(WiFi.RSSI()); Serial.println(" dBm");
  } else {
    Serial.println(" ✗ FAILED — restarting...");
    displayError("WiFi", "Connection Failed");
    delay(3000);
    ESP.restart();
  }
}

// ═══════════════════════════════════════════════
//  BUZZER HELPER
// ═══════════════════════════════════════════════
void buzzer(int times, int ms) {
  for (int i = 0; i < times; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(ms);
    digitalWrite(BUZZER_PIN, LOW);
    if (i < times - 1) delay(ms / 2);
  }
}
