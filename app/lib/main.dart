
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Add this exact line
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

  // Initialize Firebase with your generated keys
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ... (leave the rest of the code below here exactly as it is)

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const ArogyasathiApp());
}

class ArogyasathiApp extends StatelessWidget {
  const ArogyasathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arogyasathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainShell(),
    );
  }
}

// ─── Main Shell with Bottom Nav ───────────────────
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
            onNavigateToRecords: () => _goTo(1),
            onNavigateToProfile: () => _goTo(3),
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
      _NavTab(icon: '🏠', label: 'Home'),
      _NavTab(icon: '📋', label: 'Records'),
      _NavTab(icon: '💊', label: 'Reminders', badge: 1),
      _NavTab(icon: '👤', label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.bluePrimary.withOpacity(0.08),
            blurRadius: 20, offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = i == _currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _goTo(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Active indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 36 : 0,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.bluePrimary,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(fontSize: isActive ? 24 : 22),
                              child: Text(tab.icon),
                            ),
                            if (tab.badge != null)
                              Positioned(
                                top: -4, right: -8,
                                child: Container(
                                  width: 16, height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.redAlert,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${tab.badge}',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                            color: isActive ? AppColors.bluePrimary : AppColors.textMuted,
                          ),
                          child: Text(tab.label),
                        ),
                      ],
                    ),
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
  final String icon, label;
  final int? badge;
  const _NavTab({required this.icon, required this.label, this.badge});
}
