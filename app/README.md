# 🌿 Arogyasathi — Health Companion App

A mobile-first health companion app built with Flutter. Trustworthy, calming, and highly accessible — designed for all age groups.

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point + Bottom Navigation Shell
├── theme/
│   └── app_theme.dart           # Colors, typography, component styles
├── models/
│   └── models.dart              # Data models + dummy data
├── widgets/
│   └── common_widgets.dart      # Reusable UI components
└── screens/
    ├── home_screen.dart         # Dashboard / Home
    ├── records_screen.dart      # Health Locker
    ├── reminders_screen.dart    # Medication Reminders
    └── profile_screen.dart      # User Profile
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter extension

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Run on device / emulator
```bash
flutter run
```

### 3. Build release APK
```bash
flutter build apk --release
```

### 4. Build iOS
```bash
flutter build ios --release
```

---

## 📱 Screens Implemented (MVP)

| Screen | Features |
|--------|----------|
| **Home** | Greeting, next-med countdown, health stats (HR, BP, SpO₂), today's meds, water tracker, appointments, health tip, SOS |
| **Records** | Search, folder categories, recent files list, upload button |
| **Reminders** | Adherence ring chart, add medicine sheet, schedule with toggles, water goal progress |
| **Profile** | Avatar, health badges, quick stats, emergency contact, past meds, settings, logout |

---

## 🎨 Design System

### Color Palette
```dart
bluePrimary   = #1A6FC4   // Healthcare Blue — primary actions
blueDark      = #0D4F8C   // Header gradients
greenPrimary  = #2EAE82   // Calming Green — success, taken
redAlert      = #E53E3E   // Emergency, missed doses
orange        = #F6820D   // Warnings, upcoming
purple        = #7C5CBF   // Reminders accent
```

### Typography
- **Nunito** (Google Fonts) — All weights from 600–900
- Highly legible, friendly, accessible at all sizes

---

## 🔧 Next Steps to Implement

### Firebase Integration
```bash
flutterfire configure
```
Then add to `main.dart`:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### Push Notifications (Local)
```dart
// Initialize in main()
final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
```

### SOS Real Implementation
```dart
// In home_screen.dart _showSOSDialog:
await url_launcher.launchUrl(Uri.parse('tel:108'));
final position = await Geolocator.getCurrentPosition();
// Send SMS with position via Twilio or SMS plugin
```

### Appointment Booking Screen
Create `lib/screens/appointments_screen.dart` with:
- Doctor directory with specialties
- Calendar date picker (`table_calendar` package)
- Time slot grid
- Booking confirmation

### Hindi Language Support
Add to `pubspec.yaml`:
```yaml
flutter_localizations:
  sdk: flutter
intl: any
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `google_fonts` | Nunito typography |
| `fl_chart` | Adherence & health charts |
| `firebase_auth` | Authentication |
| `cloud_firestore` | User data & records |
| `firebase_storage` | Health document storage |
| `flutter_local_notifications` | Pill reminders |
| `geolocator` | SOS location |
| `url_launcher` | Emergency calling |
| `file_picker` | Upload health records |
| `provider` | State management |

---

## 🏗️ Architecture Notes

- **State Management**: `Provider` (ready for upgrade to Riverpod/Bloc)
- **Offline First**: `Hive` for local caching of records + preferences
- **Navigation**: `IndexedStack` bottom nav (no page rebuilds)
- **Theme**: Centralized in `AppTheme` — easy to add dark mode

---

*© 2025 Arogyasathi. Your Health, Your Companion.*
