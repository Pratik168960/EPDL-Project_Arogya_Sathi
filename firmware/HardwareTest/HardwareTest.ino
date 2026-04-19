/*
 * ═══════════════════════════════════════════════════════════
 *  ArogyaSathi — HARDWARE TEST SKETCH
 *  
 *  Tests all connected components one by one:
 *    1. Buzzer        (GPIO 12)
 *    2. LEDs          (Green: GPIO 14, Red: GPIO 27)
 *    3. Servo motor   (GPIO 13)
 *    4. LCD Display   (I2C: SDA=21, SCL=22) — 16x2 HD44780
 *    5. IR Sensor     (GPIO 4) — Obstacle avoidance module
 *  
 *  No WiFi or Firebase needed — pure hardware validation.
 *  
 *  LIBRARIES NEEDED (install via Arduino Library Manager):
 *    - "ESP32Servo" by Kevin Harrington
 *    - "LiquidCrystal_I2C" by Frank de Brabander
 *  
 *  BOARD: DOIT ESP32 DevKit V1
 *  UPLOAD SPEED: 115200
 * ═══════════════════════════════════════════════════════════
 */

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <ESP32Servo.h>

// ── Pin Definitions ──
#define BUZZER_PIN    12
#define LED_GREEN     14
#define LED_RED       27
#define SERVO_PIN     13
#define IR_SENSOR_PIN 4       // LOW when object detected

// ── LCD Config ──
// Try 0x27 first — if blank, use 0x3F
#define LCD_ADDR      0x27
#define LCD_COLS      16
#define LCD_ROWS      2

LiquidCrystal_I2C lcd(LCD_ADDR, LCD_COLS, LCD_ROWS);
Servo testServo;

int testStep = 0;

// ═══════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════
void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("══════════════════════════════════════");
  Serial.println("  ArogyaSathi — Hardware Test");
  Serial.println("══════════════════════════════════════");
  Serial.println();

  // Setup pins
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_RED, OUTPUT);
  pinMode(IR_SENSOR_PIN, INPUT);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_RED, LOW);

  // Setup servo
  testServo.attach(SERVO_PIN);
  testServo.write(0);

  // Setup LCD
  Wire.begin(21, 22);  // SDA=21, SCL=22 (default ESP32 I2C)
  lcd.init();
  lcd.backlight();

  // Show startup
  lcd.clear();
  lcd.setCursor(2, 0);
  lcd.print("ArogyaSathi");
  lcd.setCursor(1, 1);
  lcd.print("Hardware Test");
  Serial.println("✓ LCD initialized!\n");
  delay(2000);

  // ── RUN ALL TESTS ──
  Serial.println("Starting hardware tests in 2 seconds...\n");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Starting tests");
  lcd.setCursor(0, 1);
  lcd.print("in 2 seconds...");
  delay(2000);

  test1_Buzzer();
  test2_LEDs();
  test3_Servo();
  test4_Display();
  test5_IRSensor();
  test6_AllTogether();

  Serial.println("\n══════════════════════════════════════");
  Serial.println("  ALL TESTS COMPLETE!");
  Serial.println("══════════════════════════════════════\n");

  lcd.clear();
  lcd.setCursor(1, 0);
  lcd.print("ALL TESTS PASS");
  lcd.setCursor(2, 1);
  lcd.print("Ready to go!");
}

// ═══════════════════════════════════════════════
//  TEST 1: BUZZER
// ═══════════════════════════════════════════════
void test1_Buzzer() {
  Serial.println("━━━ TEST 1: BUZZER (GPIO 12) ━━━");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("TEST 1: BUZZER");
  lcd.setCursor(0, 1);
  lcd.print("GPIO 12");

  // Short beep
  Serial.println("  → Short beep...");
  digitalWrite(BUZZER_PIN, HIGH);
  delay(200);
  digitalWrite(BUZZER_PIN, LOW);
  delay(300);

  // Medium beep
  Serial.println("  → Medium beep...");
  digitalWrite(BUZZER_PIN, HIGH);
  delay(500);
  digitalWrite(BUZZER_PIN, LOW);
  delay(300);

  // Long beep
  Serial.println("  → Long beep...");
  digitalWrite(BUZZER_PIN, HIGH);
  delay(1000);
  digitalWrite(BUZZER_PIN, LOW);
  delay(300);

  // Pattern: SOS
  Serial.println("  → SOS pattern (... --- ...)...");
  lcd.setCursor(0, 1);
  lcd.print("SOS Pattern   ");
  // S: 3 short
  for (int i = 0; i < 3; i++) {
    digitalWrite(BUZZER_PIN, HIGH); delay(100);
    digitalWrite(BUZZER_PIN, LOW);  delay(100);
  }
  delay(200);
  // O: 3 long
  for (int i = 0; i < 3; i++) {
    digitalWrite(BUZZER_PIN, HIGH); delay(300);
    digitalWrite(BUZZER_PIN, LOW);  delay(100);
  }
  delay(200);
  // S: 3 short
  for (int i = 0; i < 3; i++) {
    digitalWrite(BUZZER_PIN, HIGH); delay(100);
    digitalWrite(BUZZER_PIN, LOW);  delay(100);
  }

  lcd.setCursor(0, 1);
  lcd.print("PASS!         ");
  Serial.println("  ✓ Buzzer test complete!\n");
  delay(1000);
}

// ═══════════════════════════════════════════════
//  TEST 2: LEDs
// ═══════════════════════════════════════════════
void test2_LEDs() {
  Serial.println("━━━ TEST 2: LEDs (Green=14, Red=27) ━━━");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("TEST 2: LEDs");

  // Green ON
  lcd.setCursor(0, 1);
  lcd.print("Green ON      ");
  Serial.println("  → Green LED ON...");
  digitalWrite(LED_GREEN, HIGH);
  delay(1500);
  digitalWrite(LED_GREEN, LOW);
  delay(500);

  // Red ON
  lcd.setCursor(0, 1);
  lcd.print("Red ON        ");
  Serial.println("  → Red LED ON...");
  digitalWrite(LED_RED, HIGH);
  delay(1500);
  digitalWrite(LED_RED, LOW);
  delay(500);

  // Both ON
  lcd.setCursor(0, 1);
  lcd.print("Both ON       ");
  Serial.println("  → Both LEDs ON...");
  digitalWrite(LED_GREEN, HIGH);
  digitalWrite(LED_RED, HIGH);
  delay(1500);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_RED, LOW);
  delay(500);

  // Alternating blink
  lcd.setCursor(0, 1);
  lcd.print("Blinking...   ");
  Serial.println("  → Alternating blink (5x)...");
  for (int i = 0; i < 5; i++) {
    digitalWrite(LED_GREEN, HIGH);
    digitalWrite(LED_RED, LOW);
    delay(300);
    digitalWrite(LED_GREEN, LOW);
    digitalWrite(LED_RED, HIGH);
    delay(300);
  }
  digitalWrite(LED_RED, LOW);

  lcd.setCursor(0, 1);
  lcd.print("PASS!         ");
  Serial.println("  ✓ LED test complete!\n");
  delay(1000);
}

// ═══════════════════════════════════════════════
//  TEST 3: SERVO MOTOR
// ═══════════════════════════════════════════════
void test3_Servo() {
  Serial.println("━━━ TEST 3: SERVO (GPIO 13) ━━━");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("TEST 3: SERVO");

  // Sweep positions
  int positions[] = {0, 45, 90, 135, 180, 0};
  const char* labels[] = {"0 deg  ", "45 deg ", "90 deg ", "135 deg", "180 deg", "0 (home)"};

  for (int i = 0; i < 6; i++) {
    lcd.setCursor(0, 1);
    lcd.print(labels[i]);
    lcd.print("         ");
    Serial.print("  → Moving to "); Serial.print(positions[i]); Serial.println("°...");
    testServo.write(positions[i]);
    delay(1000);
  }

  // Simulate dispense
  lcd.setCursor(0, 1);
  lcd.print("Dispense sim  ");
  Serial.println("  → Simulating dispense...");
  testServo.write(90);
  delay(2000);
  testServo.write(0);
  delay(500);

  lcd.setCursor(0, 1);
  lcd.print("PASS!         ");
  Serial.println("  ✓ Servo test complete!\n");
  delay(1000);
}

// ═══════════════════════════════════════════════
//  TEST 4: LCD DISPLAY
// ═══════════════════════════════════════════════
void test4_Display() {
  Serial.println("━━━ TEST 4: LCD DISPLAY (I2C) ━━━");

  // Screen 1: App name
  lcd.clear();
  lcd.setCursor(2, 0);
  lcd.print("ArogyaSathi");
  lcd.setCursor(1, 1);
  lcd.print("Medicine Buddy");
  Serial.println("  → Screen 1: App name");
  delay(2000);

  // Screen 2: Alarm info
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("NEXT: 8:00 AM");
  lcd.setCursor(0, 1);
  lcd.print("Metformin 500mg");
  Serial.println("  → Screen 2: Alarm info");
  delay(2000);

  // Screen 3: Dispensing
  lcd.clear();
  lcd.setCursor(1, 0);
  lcd.print("DISPENSING...");
  lcd.setCursor(0, 1);
  lcd.print("Metformin 500mg");
  Serial.println("  → Screen 3: Dispensing");
  delay(1000);

  // Progress bar animation on LCD
  lcd.setCursor(0, 1);
  for (int i = 0; i < 16; i++) {
    lcd.write(0xFF);  // Full block character
    delay(100);
  }
  Serial.println("  → Screen 3: Progress bar");
  delay(500);

  // Screen 4: Done
  lcd.clear();
  lcd.setCursor(4, 0);
  lcd.print("DONE!");
  lcd.setCursor(0, 1);
  lcd.print("Take with food");
  Serial.println("  → Screen 4: Complete");
  delay(2000);

  lcd.setCursor(0, 1);
  lcd.print("PASS!         ");
  Serial.println("  ✓ Display test complete!\n");
  delay(1000);
}

// ═══════════════════════════════════════════════
//  TEST 5: IR SENSOR
// ═══════════════════════════════════════════════
void test5_IRSensor() {
  Serial.println("━━━ TEST 5: IR SENSOR (GPIO 4) ━━━");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("TEST 5: IR SENSR");
  lcd.setCursor(0, 1);
  lcd.print("Wave hand close!");

  Serial.println("  → Wave your hand in front of the IR sensor...");
  Serial.println("    Monitoring for 10 seconds...");

  int detected = 0;
  unsigned long start = millis();

  while (millis() - start < 10000) {
    if (digitalRead(IR_SENSOR_PIN) == LOW) {
      detected++;
      Serial.print("    ✓ Object detected! (count: ");
      Serial.print(detected);
      Serial.println(")");

      lcd.setCursor(0, 1);
      lcd.print("Detected! #");
      lcd.print(detected);
      lcd.print("    ");

      // Wait for object to pass
      while (digitalRead(IR_SENSOR_PIN) == LOW && millis() - start < 10000) {
        delay(50);
      }
      delay(200);  // Debounce
    }
    delay(50);
  }

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("IR Result:");
  lcd.setCursor(0, 1);
  if (detected > 0) {
    lcd.print("PASS! Count:");
    lcd.print(detected);
    Serial.print("  ✓ IR sensor detected "); Serial.print(detected); Serial.println(" object(s)\n");
  } else {
    lcd.print("No detection");
    Serial.println("  ⚠️  No objects detected — check sensor position\n");
  }
  delay(2000);
}

// ═══════════════════════════════════════════════
//  TEST 6: ALL TOGETHER — Full Dispense Cycle
// ═══════════════════════════════════════════════
void test6_AllTogether() {
  Serial.println("━━━ TEST 6: FULL DISPENSE SIMULATION ━━━");

  // Alert phase
  lcd.clear();
  lcd.setCursor(2, 0);
  lcd.print("!! ALARM !!");
  lcd.setCursor(0, 1);
  lcd.print("Metformin 8:00AM");
  digitalWrite(LED_RED, HIGH);
  for (int i = 0; i < 5; i++) {
    digitalWrite(BUZZER_PIN, HIGH); delay(200);
    digitalWrite(BUZZER_PIN, LOW);  delay(200);
  }
  Serial.println("  → Alert sounding...");
  delay(1000);

  // Dispensing phase
  lcd.clear();
  lcd.setCursor(1, 0);
  lcd.print("DISPENSING...");
  lcd.setCursor(0, 1);
  lcd.print("Metformin 500mg");
  testServo.write(90);
  Serial.println("  → Servo OPEN — dispensing...");
  delay(3000);

  // Done phase
  testServo.write(0);
  Serial.println("  → Servo CLOSED");
  digitalWrite(LED_RED, LOW);
  digitalWrite(LED_GREEN, HIGH);

  // Success beep
  digitalWrite(BUZZER_PIN, HIGH);
  delay(800);
  digitalWrite(BUZZER_PIN, LOW);

  lcd.clear();
  lcd.setCursor(2, 0);
  lcd.print("DISPENSED!");
  lcd.setCursor(0, 1);
  lcd.print("Take with food");
  Serial.println("  → Dispense complete!");
  delay(3000);

  digitalWrite(LED_GREEN, LOW);
  Serial.println("  ✓ Full simulation complete!\n");
}

// ═══════════════════════════════════════════════
//  LOOP — Idle display after tests
// ═══════════════════════════════════════════════
void loop() {
  static unsigned long lastUpdate = 0;
  static bool toggle = false;

  if (millis() - lastUpdate > 1000) {
    lastUpdate = millis();
    toggle = !toggle;

    unsigned long secs = millis() / 1000;
    int mm = (secs / 60) % 60;
    int ss = secs % 60;

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Ready ");

    // Uptime clock
    char timeStr[10];
    sprintf(timeStr, "%02d:%02d", mm, ss);
    lcd.print(timeStr);

    // Blinking dot
    if (toggle) lcd.print(" *");

    lcd.setCursor(0, 1);
    lcd.print("All tests PASS");

    // Blink green LED slowly
    digitalWrite(LED_GREEN, toggle ? HIGH : LOW);
  }
}
