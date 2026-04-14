import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/role_selection_screen.dart';
import 'screens/caregiver_navigation.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await NotificationService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ArogyasathiApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ArogyasathiApp extends StatelessWidget {
  const ArogyasathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arogyasathi',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      // ── THE AUTH ROUTER ──
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If Firebase is checking...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.navy,
              body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
            );
          }
          // If user is logged in → check role
          if (snapshot.hasData) {
            return const _RoleRouter();
          }
          // Otherwise → Login
          return const LoginScreen();
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════
///  ROLE ROUTER
///  Reads the user's role from Firestore and routes:
///    - No role → RoleSelectionScreen (first login)
///    - "patient" → MainNavigation (existing patient UI)
///    - "caregiver" → CaregiverNavigation (new caregiver UI)
/// ═══════════════════════════════════════════════
class _RoleRouter extends StatelessWidget {
  const _RoleRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService.getUserRole(),
      builder: (context, snapshot) {
        // Loading...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.navy,
            body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
          );
        }

        final role = snapshot.data;

        // No role set → first login → pick role
        if (role == null) {
          return const RoleSelectionScreen();
        }

        // Route based on role
        if (role == 'caregiver') {
          return const CaregiverNavigation();
        }

        // Default: patient
        return const MainNavigation();
      },
    );
  }
}
