# 📋 Bill of Materials (BOM) - ArogyaSathi

This document outlines all the hardware and software components required to build the ArogyaSathi smart pill dispenser, along with their purpose and estimated costs.

## 1. Hardware Components

| Category | Component | Purpose | Est. Price (INR) |
| :--- | :--- | :--- | :--- |
| **Core Processing** | ESP32 Development Board (NodeMCU-32S) | Main microcontroller handling mechanical logic, sensors, and Wi-Fi/Bluetooth cloud sync. | ₹350 - ₹450 |
| **Dispensing Mechanism** | 28BYJ-48 Stepper Motor + ULN2003 Driver | Provides precise angular rotation to align and drop pills from the cartridge. | ₹120 - ₹150 |
| **Sensors & Interface** | IR Obstacle Avoidance Sensor | Detects the physical drop of the pill to verify successful dispensing to the cloud. | ₹30 - ₹50 |
| **Sensors & Interface** | DS3231 RTC Module | Maintains exact local time during internet outages for fail-safe, offline dispensing. | ₹120 - ₹170 |
| **Sensors & Interface** | 0.96" I2C OLED Display | Shows current time, next scheduled dose, and Wi-Fi connection status. | ₹180 - ₹250 |
| **Sensors & Interface** | 5V Active Buzzer & Push Buttons | Sounds audio alarms for dosage times and provides manual trigger buttons for dispensing. | ₹20 - ₹40 |
| **Power & Wiring** | TP4056 Module & 18650 Li-ion Battery | Acts as a mini UPS to keep the system running securely during power cuts. | ₹185 - ₹200 |
| **Power & Wiring** | 5V/2A DC Power Adapter & Barrel Jack | Primary wall-power source providing sufficient current for the ESP32 and motor. | ₹150 - ₹200 |
| **Power & Wiring** | 400-Point Breadboard & Jumper Wires | Essential for phase 1 prototyping and testing connections before permanent soldering. | ₹150 - ₹200 |

> **Note:** Prices are estimated based on standard electronics vendors in India (e.g., Robu.in, MakerBazar, Amazon) and may fluctuate.

---

## 2. Software & Cloud Stack

| Category | Technology / Platform | Purpose |
| :--- | :--- | :--- |
| **Core Firmware Language** | C++ (Arduino IDE or PlatformIO) | Primary programming language for writing the logic on the ESP32. |
| **Essential Libraries** | `RTClib`, `Stepper.h`, `PubSubClient`, `Adafruit_SSD1306` | Code modules handling timekeeping, motor stepping, MQTT communication, and OLED rendering. |
| **Cloud / IoT Backend** | Firebase Realtime Database OR Blynk IoT | Acts as the bridge to synchronize scheduling data, log adherence events, and trigger remote alerts. |
| **Mobile Frontend** | Flutter (Dart) OR React Native | Cross-platform frameworks to build a single caregiver dashboard app for both Android and iOS. |
