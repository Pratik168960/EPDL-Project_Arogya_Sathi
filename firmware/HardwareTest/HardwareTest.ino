/*
 * ═══════════════════════════════════════════════════════════
 *  ArogyaSathi — HARDWARE TEST SKETCH
 *  
 *  Tests all connected components one by one:
 *    1. Buzzer        (GPIO 12)
 *    2. LEDs          (Green: GPIO 14, Red: GPIO 27)
 *    3. Servo motor   (GPIO 13)
 *    4. OLED Display  (I2C: SDA=21, SCL=22) — SSD1306 128x64
 *  
 *  No WiFi or Firebase needed — pure hardware validation.
 *  
 *  LIBRARIES NEEDED (install via Arduino Library Manager):
 *    - "ESP32Servo" by Kevin Harrington
 *    - "Adafruit SSD1306" by Adafruit
 *    - "Adafruit GFX Library" by Adafruit
 *  
 *  BOARD: ESP32 Dev Module
 *  UPLOAD SPEED: 115200
 * ═══════════════════════════════════════════════════════════
 */

#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ESP32Servo.h>

// ── Pin Definitions ──
#define BUZZER_PIN    12
#define LED_GREEN     14
#define LED_RED       27
#define SERVO_PIN     13

// ── OLED Config ──
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1      // No reset pin
#define OLED_ADDR     0x3C    // Common I2C address (try 0x3D if this doesn't work)

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
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
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_RED, LOW);

  // Setup servo
  testServo.attach(SERVO_PIN);
  testServo.write(0);

  // Setup OLED
  Wire.begin(21, 22);  // SDA=21, SCL=22 (default ESP32 I2C)
  
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println("⚠️  OLED not found at 0x3C — trying 0x3D...");
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3D)) {
      Serial.println("❌ OLED not found! Check wiring (SDA→21, SCL→22)");
      Serial.println("   Continuing without display...\n");
    } else {
      Serial.println("✓ OLED found at 0x3D!\n");
    }
  } else {
    Serial.println("✓ OLED found at 0x3C!\n");
  }

  // Show startup screen
  showOnDisplay("ArogyaSathi", "Hardware Test", "Starting...");
  delay(2000);

  // ── RUN ALL TESTS ──
  Serial.println("Starting hardware tests in 2 seconds...\n");
  delay(2000);

  test1_Buzzer();
  test2_LEDs();
  test3_Servo();
  test4_Display();
  test5_AllTogether();

  Serial.println("\n══════════════════════════════════════");
  Serial.println("  ALL TESTS COMPLETE!");
  Serial.println("══════════════════════════════════════\n");

  showOnDisplay("ALL TESTS", "PASSED!", "Ready to go");
}

// ═══════════════════════════════════════════════
//  TEST 1: BUZZER
// ═══════════════════════════════════════════════
void test1_Buzzer() {
  Serial.println("━━━ TEST 1: BUZZER (GPIO 12) ━━━");
  showOnDisplay("TEST 1", "BUZZER", "GPIO 12");

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

  Serial.println("  ✓ Buzzer test complete!\n");
  delay(1000);
}

// ═══════════════════════════════════════════════
//  TEST 2: LEDs
// ═══════════════════════════════════════════════
void test2_LEDs() {
  Serial.println("━━━ TEST 2: LEDs (Green=14, Red=27) ━━━");
  showOnDisplay("TEST 2", "LEDs", "Green=14 Red=27");

  // Green ON
  Serial.println("  → Green LED ON...");
  digitalWrite(LED_GREEN, HIGH);
  delay(1500);
  digitalWrite(LED_GREEN, LOW);
  delay(500);

  // Red ON
  Serial.println("  → Red LED ON...");
  digitalWrite(LED_RED, HIGH);
  delay(1500);
  digitalWrite(LED_RED, LOW);
  delay(500);

  // Both ON
  Serial.println("  → Both LEDs ON...");
  digitalWrite(LED_GREEN, HIGH);
  digitalWrite(LED_RED, HIGH);
  delay(1500);
  digitalWrite(LED_GREEN, LOW);
  digitalWrite(LED_RED, LOW);
  delay(500);

  // Alternating blink
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

  Serial.println("  ✓ LED test complete!\n");
  delay(1000);
}

// ═══════════════════════════════════════════════
//  TEST 3: SERVO MOTOR
// ═══════════════════════════════════════════════
void test3_Servo() {
  Serial.println("━━━ TEST 3: SERVO (GPIO 13) ━━━");
  showOnDisplay("TEST 3", "SERVO", "GPIO 13");

  // Sweep 0 → 90 → 180 → 0
  Serial.println("  → Moving to 0°...");
  testServo.write(0);
  delay(1000);

  Serial.println("  → Moving to 45°...");
  testServo.write(45);
  delay(1000);

  Serial.println("  → Moving to 90° (dispense position)...");
  testServo.write(90);
  delay(1500);

  Serial.println("  → Moving to 135°...");
  testServo.write(135);
  delay(1000);

  Serial.println("  → Moving to 180°...");
  testServo.write(180);
  delay(1000);

  Serial.println("  → Returning to 0° (closed)...");
  testServo.write(0);
  delay(1000);

  // Simulate dispense cycle
  Serial.println("  → Simulating dispense (open→wait→close)...");
  testServo.write(90);
  delay(2000);
  testServo.write(0);
  delay(500);

  Serial.println("  ✓ Servo test complete!\n");
  delay(1000);
}

// ═══════════════════════════════════════════════
//  TEST 4: OLED DISPLAY
// ═══════════════════════════════════════════════
void test4_Display() {
  Serial.println("━━━ TEST 4: OLED DISPLAY (I2C) ━━━");

  // Screen 1: Large text
  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(10, 5);
  display.println("Arogya");
  display.setCursor(20, 28);
  display.println("Sathi");
  display.setTextSize(1);
  display.setCursor(15, 52);
  display.println("Medicine Buddy");
  display.display();
  Serial.println("  → Screen 1: App name");
  delay(2000);

  // Screen 2: Medicine info
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("---- NEXT ALARM ----");
  display.println();
  display.setTextSize(2);
  display.setCursor(15, 16);
  display.println("8:00 AM");
  display.setTextSize(1);
  display.setCursor(0, 40);
  display.println("Medicine: Metformin");
  display.setCursor(0, 52);
  display.println("Dosage:   500mg");
  display.display();
  Serial.println("  → Screen 2: Alarm info");
  delay(3000);

  // Screen 3: Dispensing animation
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(5, 8);
  display.println("DISPENSING");
  display.setTextSize(1);
  display.setCursor(20, 35);
  display.println("Metformin 500mg");
  display.display();
  delay(500);

  // Progress bar animation
  for (int i = 0; i <= 100; i += 5) {
    display.fillRect(14, 50, (int)(i * 1.0), 8, SSD1306_WHITE);
    display.drawRect(14, 50, 100, 8, SSD1306_WHITE);
    display.display();
    delay(80);
  }
  Serial.println("  → Screen 3: Dispensing animation");
  delay(1000);

  // Screen 4: Done
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(30, 10);
  display.println("DONE!");
  display.setTextSize(1);
  display.setCursor(10, 38);
  display.println("Medicine dispensed");
  display.setCursor(15, 52);
  display.println("Take with food");
  display.display();
  Serial.println("  → Screen 4: Complete");
  delay(2000);

  Serial.println("  ✓ Display test complete!\n");
}

// ═══════════════════════════════════════════════
//  TEST 5: ALL TOGETHER — Full Dispense Cycle
// ═══════════════════════════════════════════════
void test5_AllTogether() {
  Serial.println("━━━ TEST 5: FULL DISPENSE SIMULATION ━━━");

  // Alert phase
  showOnDisplay("ALARM!", "Metformin", "8:00 AM - Take now!");
  digitalWrite(LED_RED, HIGH);
  for (int i = 0; i < 5; i++) {
    digitalWrite(BUZZER_PIN, HIGH); delay(200);
    digitalWrite(BUZZER_PIN, LOW);  delay(200);
  }
  Serial.println("  → Alert sounding...");
  delay(1000);

  // Dispensing phase
  showOnDisplay("DISPENSING", "Metformin", "500mg");
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

  showOnDisplay("DISPENSED!", "Metformin 500mg", "Take with food");
  Serial.println("  → Dispense complete!");
  delay(3000);

  digitalWrite(LED_GREEN, LOW);
  Serial.println("  ✓ Full simulation complete!\n");
}

// ═══════════════════════════════════════════════
//  HELPER: Show text on OLED
// ═══════════════════════════════════════════════
void showOnDisplay(const char* line1, const char* line2, const char* line3) {
  display.clearDisplay();

  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 2);
  display.println(line1);

  display.setTextSize(1);
  display.setCursor(0, 28);
  display.println(line2);

  display.setCursor(0, 45);
  display.println(line3);

  display.display();
}

// ═══════════════════════════════════════════════
//  LOOP — Idle display after tests
// ═══════════════════════════════════════════════
void loop() {
  // After tests, show a clock-like idle screen
  static unsigned long lastUpdate = 0;
  static bool toggle = false;

  if (millis() - lastUpdate > 1000) {
    lastUpdate = millis();
    toggle = !toggle;

    unsigned long secs = millis() / 1000;
    int mm = (secs / 60) % 60;
    int ss = secs % 60;

    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(0, 0);
    display.println("ArogyaSathi Ready");
    display.drawLine(0, 10, 128, 10, SSD1306_WHITE);

    display.setTextSize(2);
    display.setCursor(15, 20);
    char timeStr[10];
    sprintf(timeStr, "%02d:%02d", mm, ss);
    display.println(timeStr);

    display.setTextSize(1);
    display.setCursor(0, 45);
    display.println("Waiting for alarm...");
    display.setCursor(0, 56);
    display.println("All tests PASSED");

    // Blinking indicator
    if (toggle) {
      display.fillCircle(120, 56, 3, SSD1306_WHITE);
    }

    display.display();

    // Blink green LED slowly
    digitalWrite(LED_GREEN, toggle ? HIGH : LOW);
  }
}
