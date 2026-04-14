import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'caregiver_patients_screen.dart';
import 'caregiver_alerts_screen.dart';
import 'profile_screen.dart';

/// ═══════════════════════════════════════════════
///  CAREGIVER NAVIGATION
///  Bottom nav: Patients | Alerts | Profile
/// ═══════════════════════════════════════════════
class CaregiverNavigation extends StatefulWidget {
  const CaregiverNavigation({super.key});

  @override
  State<CaregiverNavigation> createState() => _CaregiverNavigationState();
}

class _CaregiverNavigationState extends State<CaregiverNavigation> {
  int _currentIndex = 0;

  static const _navColor      = Color(0xFFFFFFFF);
  static const _activeColor   = Color(0xFF00897B);
  static const _inactiveColor = Color(0xFF94A3B8);

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          CaregiverPatientsScreen(),
          CaregiverAlertsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16, offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.people_outline, Icons.people, 'PATIENTS'),
                    _navItem(1, Icons.notifications_outlined, Icons.notifications, 'ALERTS'),
                    _navItem(2, Icons.person_outline, Icons.person, 'PROFILE'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _goTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: _activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? _activeColor : _inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _activeColor : _inactiveColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
