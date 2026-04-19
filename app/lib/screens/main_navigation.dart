import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart';
import 'adherence_history_screen.dart';
import 'records_screen.dart';
import 'profile_screen.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens — Bottom Nav
// ═══════════════════════════════════════════════
class _N {
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color secondary      = Color(0xFF006399);
  static const Color inactive       = Color(0xFF94A3B8);
  static const Color shadow         = Color(0x0F0F1C2C);
}

// ═══════════════════════════════════════════════
//  MASTER HUB — MAIN NAVIGATION
//  Single Scaffold with IndexedStack + Bottom Nav
// ═══════════════════════════════════════════════
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  void _goTo(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  // ── Tab Definitions ──────────────────────────
  static const _tabs = [
    _NavTab(icon: Icons.home_outlined,        activeIcon: Icons.home,               label: 'HOME'),
    _NavTab(icon: Icons.analytics_outlined,   activeIcon: Icons.analytics,          label: 'HISTORY'),
    _NavTab(icon: Icons.description_outlined, activeIcon: Icons.description,        label: 'HEALTH'),
    _NavTab(icon: Icons.person_outline,       activeIcon: Icons.person,             label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        
        if (_currentIndex != 0) {
          _goTo(0);
          return;
        }
        
        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Press back again to exit', style: GoogleFonts.outfit()),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        
        SystemNavigator.pop();
      },
      child: Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // ── Screen Stack ──────────────────────
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                onNavigateToReminders: () => _goTo(1),
                onNavigateToRecords:   () => _goTo(2),
                onNavigateToProfile:   () => _goTo(3),
              ),
              const AdherenceHistoryScreen(),
              const RecordsScreen(),
              const ProfileScreen(),
            ],
          ),
          // ── Bottom Navigation ─────────────────
          _buildBottomNav(),
        ],
      ),
    ));
  }

  // ═══════════════════════════════════════════════
  //  GLASSMORPHIC BOTTOM NAV BAR
  // ═══════════════════════════════════════════════
  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.only(top: 12, bottom: 28, left: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xE6FFFFFF),   // 90% white glass
              boxShadow: [
                BoxShadow(color: _N.shadow, offset: Offset(0, -8), blurRadius: 24),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == _currentIndex;
                return _buildNavItem(tab, isActive, () => _goTo(i));
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavTab tab, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(isActive ? 1.05 : 1.0),
        transformAlignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? tab.activeIcon : tab.icon,
                  size: 26,
                  color: isActive ? _N.secondary : _N.inactive.withValues(alpha: 0.7),
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
            // Label
            Text(
              tab.label,
              style: GoogleFonts.publicSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? _N.secondary : _N.inactive.withValues(alpha: 0.7),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  NAV TAB MODEL
// ═══════════════════════════════════════════════
class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
  const _NavTab({required this.icon, required this.activeIcon, required this.label, this.badge});
}

