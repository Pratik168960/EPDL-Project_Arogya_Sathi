import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════
///  ROLE SELECTION SCREEN
///  Shown once after first signup— user picks Patient or Caregiver.
///  Role is stored in Firestore; user is never shown this again.
/// ═══════════════════════════════════════════════════════════
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selected; // 'patient' or 'caregiver'
  bool _saving = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await AuthService.setUserRole(_selected!);
      // main.dart's StreamBuilder will detect the role and navigate
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Icon ──
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.teal, Color(0xFF00B4D8)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.4),
                          blurRadius: 24, offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 32),

                  // ── Title ──
                  Text('Who are you?',
                    style: GoogleFonts.outfit(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Choose your role to personalize your experience',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14, color: Colors.white54, height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Patient Card ──
                  _roleCard(
                    role: 'patient',
                    icon: Icons.favorite_rounded,
                    title: 'I am a Patient',
                    subtitle: 'Track medicines, get reminders,\nmanage your health',
                    gradient: const [Color(0xFF006399), Color(0xFF0091EA)],
                  ),
                  const SizedBox(height: 16),

                  // ── Caregiver Card ──
                  _roleCard(
                    role: 'caregiver',
                    icon: Icons.volunteer_activism_rounded,
                    title: 'I am a Caregiver',
                    subtitle: 'Manage medication for your\nfamily members remotely',
                    gradient: const [Color(0xFF00897B), Color(0xFF26A69A)],
                  ),

                  const Spacer(flex: 1),

                  // ── Confirm Button ──
                  AnimatedOpacity(
                    opacity: _selected != null ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _selected != null && !_saving ? _confirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5,
                                ),
                              )
                            : Text('Continue',
                                style: GoogleFonts.outfit(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    final isSelected = _selected == role;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = role);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: gradient)
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: gradient[0].withValues(alpha: 0.4),
                  blurRadius: 20, offset: const Offset(0, 8),
                )]
              : [],
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                color: isSelected ? Colors.white : Colors.white54,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12, color: Colors.white70, height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded,
                      color: gradient[0], size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
