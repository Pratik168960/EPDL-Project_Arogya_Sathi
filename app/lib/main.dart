import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/records_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
            return const Scaffold(backgroundColor: AppColors.navy, body: Center(child: CircularProgressIndicator(color: AppColors.teal)));
          }
          // If user is logged in, show the Dashboard
          if (snapshot.hasData) {
            return const MainShell();
          }
          // Otherwise, show Login Screen
          return const LoginScreen();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  MAIN SHELL — INDEXED STACK NAVIGATION
// ═══════════════════════════════════════════════
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _goTo(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                onNavigateToReminders: () => _goTo(1),
                onNavigateToRecords:   () => _goTo(2),
                onNavigateToProfile:   () => _goTo(3),
              ),
              const RemindersScreen(),
              const RecordsScreen(),
              const ProfileScreen(),
            ],
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const tabs = [
      _NavTab(icon: Icons.home_max, activeIcon: Icons.home_max, label: 'HOME'),
      _NavTab(icon: Icons.medication_outlined, activeIcon: Icons.medication, label: 'MEDS', badge: 1),
      _NavTab(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'HEALTH'),
      _NavTab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'PROFILE'),
    ];

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.only(top: 12, bottom: 24, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xCCFFFFFF),
              boxShadow: [
                BoxShadow(color: Color(0x0F0F1C2C), offset: Offset(0, -8), blurRadius: 24),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isActive = i == _currentIndex;
                return GestureDetector(
                  onTap: () => _goTo(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    transform: Matrix4.identity()..scale(isActive ? 1.05 : 1.0),
                    transformAlignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isActive ? tab.activeIcon : tab.icon,
                              size: 26,
                              color: isActive ? const Color(0xFF006399) : const Color(0xFF94A3B8).withOpacity(0.7),
                            ),
                            if (tab.badge != null)
                              Positioned(
                                top: -2, right: -4,
                                child: Container(
                                  width: 14, height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${tab.badge}',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive ? const Color(0xFF006399) : const Color(0xFF94A3B8).withOpacity(0.7),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
  const _NavTab({required this.icon, required this.activeIcon, required this.label, this.badge});
}
