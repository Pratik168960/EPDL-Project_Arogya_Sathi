
# ArogyaSathi: System Architecture and Design

## Overview
ArogyaSathi is an IoT-enabled smart pill dispenser designed to solve medication non-adherence. It automates the physical dispensing of pills at precise times, provides audio-visual alerts, and syncs adherence logs to a caregiver's mobile app to ensure patient safety.

---

## 1. High-Level System Architecture
The ArogyaSathi system operates on a three-tier IoT architecture to ensure reliability both locally and remotely:

* **Edge Layer (Hardware):** The physical dispenser residing with the patient. It handles localized storage, mechanical dispensing, alerts, and sensor-based verification. It is designed to run semi-autonomously if internet connectivity drops.
* **Cloud/Connectivity Layer:** An MQTT-based IoT backend (e.g., AWS IoT, Firebase) that synchronizes scheduling data, logs daily dispensing events, and triggers remote alerts.
* **Application Layer:** A mobile or web dashboard. Caregivers use it to input medication schedules, while both patients and caregivers can view adherence metrics and receive push notifications.



---

## 2. Component Breakdown (Subsystems)

### Microcontroller Unit (MCU)
* **Component:** ESP32 or ESP8266 (NodeMCU)
* **Role:** Acts as the brain of the edge device, providing processing power for mechanical logic and built-in Wi-Fi/Bluetooth for cloud connectivity.

### Dispensing Mechanism
* **Component:** 28BYJ-48 Stepper Motors with ULN2003 drivers
* **Role:** Provides precise angular control to rotate a multi-compartment pill cartridge exactly one slot at a time.

### Verification Subsystem
* **Component:** IR (Infrared) obstacle sensors
* **Role:** Positioned inside the dispensing chute to confirm a pill has successfully fallen into the delivery tray, preventing false-positive dispensing logs.

### User Interface & Alert Subsystem
* **Component:** I2C OLED/LCD display, active buzzer, LED indicators
* **Role:** Shows the time/status locally, sounds audio alarms, and provides visual cues (e.g., Red = missed dose, Green = time to take).

### Power & Timing Management
* **Component:** 5V/9V DC adapter, Li-ion battery backup (TP4056), DS3231 RTC
* **Role:** Ensures continuous operation during power outages. The RTC module keeps exact local time independent of internet time servers.

---

## 3. Data & Control Flow

1. **Scheduling:** Caregiver sets a dosage schedule (e.g., 8:00 AM) via the mobile app. Data is pushed to the cloud and stored in the ESP32's local memory.
2. **Trigger:** At 8:00 AM, the local RTC module triggers an interrupt. The MCU activates the buzzer and LED alerts.
3. **Dispensing:** The patient presses a physical "Dispense" button. The stepper motor rotates the cartridge one slot.
4. **Verification:** The pill falls through the chute, breaking the IR sensor beam.
5. **Logging:** The MCU detects the IR beam break, registers a "Successful Dispense," stops the alarm, and sends a data payload to the cloud.
6. **Notification:** The cloud updates the database and pushes a confirmation notification to the caregiver's app.



---

## 4. Design Prototype Roadmap

* **Phase 1: Proof of Concept (PoC) – The Breadboard Stage**
  * *Focus:* Validating core electronics and logic. Wiring the ESP32, RTC, stepper motor, and IR sensor on a breadboard. Writing initial C++ firmware.
* **Phase 2: "Looks-like" Prototype – The Mechanical Stage**
  * *Focus:* Physical form factor and ergonomics. Using CAD software to design a circular pill cartridge and outer housing, then 3D printing with food-safe filament (e.g., PETG).
* **Phase 3: "Works-like" Prototype – Integration (MVP)**
  * *Focus:* Combining hardware, software, and cloud. Mounting electronics inside the 3D-printed enclosure and testing the closed-loop system from app-scheduling to physical dispensing.

---

## 5. Potential Risks & Mitigation Strategies

| Risk | Description | Mitigation Strategy |
| :--- | :--- | :--- |
| **Pill Jamming** | Variable pill shapes can jam mechanical parts. | Design chute with steep angles/smooth corners. Implement "retry" logic in code to reverse motor slightly if IR sensor isn't triggered. |
| **Connectivity Loss** | Wi-Fi drops prevent cloud syncing. | Rely on DS3231 RTC for exact local time. Store schedules locally and cache log data on the ESP32 to push when connection returns. |
| **Accidental Overdose** | Patients may attempt to access bulk pills. | Implement a physical lock on the main storage. Ensure only the scheduled dose drops into the accessible tray. |
