# 💊 ArogyaSathi: Smart IoT Pill Dispenser

> An automated, IoT-enabled medication adherence system designed to ensure patients take the right medication at the right time, while keeping caregivers informed.

## 📖 Overview
Medication non-adherence is a major health risk, particularly for the elderly and those with chronic conditions. **ArogyaSathi** solves this by combining a mechanical, automated pill dispenser with IoT connectivity. The system locally stores medication, dispenses it precisely according to a scheduled time, alerts the user, and synchronizes adherence data with a cloud dashboard.

## ✨ Key Features
* **Automated Dispensing:** Precisely dispenses scheduled doses using a stepper motor-driven cartridge.
* **Fail-Safe Operation:** Built-in RTC (Real-Time Clock) ensures the device dispenses on time even if Wi-Fi connectivity drops.
* **Smart Verification:** IR sensors detect the physical drop of the pill to prevent false adherence logging.
* **Audio-Visual Alerts:** Integrated OLED display, active buzzer, and LED indicators to notify the patient.
* **Caregiver Tracking:** Syncs dispensing logs to the cloud (MQTT/Firebase) and sends remote push notifications for missed doses.

## 🧰 Tech Stack
* **Microcontroller:** ESP32 / ESP8266 (NodeMCU)
* **Hardware:** 28BYJ-48 Stepper Motor, ULN2003 Driver, DS3231 RTC, IR Obstacle Sensor
* **Firmware:** C/C++ (Arduino IDE / PlatformIO)
* **Cloud/IoT:** [Insert your cloud platform, e.g., AWS IoT, Firebase, or Blynk]
* **Mechanical CAD:** [Insert your CAD tool, e.g., Fusion 360, SolidWorks]

## 📂 Repository Structure
```text
arogyasathi/
├── docs/                     # System architecture and project roadmap
├── firmware/                 # C++ code for the ESP32 microcontroller
├── hardware/                 # CAD files (.stl) and circuit schematics
└── app/                      # Source code for the mobile/web dashboard
