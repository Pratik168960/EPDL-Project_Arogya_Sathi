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
      home: const MainShell(),
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToReminders: () => _goTo(2),
            onNavigateToRecords:   () => _goTo(1),
            onNavigateToProfile:   () => _goTo(3),
          ),
          const RecordsScreen(),
          const RemindersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const tabs = [
      _NavTab(icon: Icons.home_outlined,        activeIcon: Icons.home_rounded,         label: 'Home'),
      _NavTab(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Records'),
      _NavTab(icon: Icons.medication_outlined,   activeIcon: Icons.medication_rounded,   label: 'Reminders', badge: 1),
      _NavTab(icon: Icons.person_outline,        activeIcon: Icons.person_rounded,       label: 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: AppColors.navShadow,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _goTo(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top indicator line
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 20 : 0,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            size: 22,
                            color: isActive ? AppColors.teal : AppColors.textMuted,
                          ),
                          if (tab.badge != null)
                            Positioned(
                              top: -3, right: -8,
                              child: Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Center(
                                  child: Text('${tab.badge}',
                                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppColors.teal : AppColors.textMuted,
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
