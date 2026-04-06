import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import 'hardware_screen.dart';
import 'emergency_sos_screen.dart';
import 'medical_id_basic_health_screen.dart';
import 'analytics_screen.dart';
import 'care_team_screen.dart';
import 'pill_inventory_screen.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens (exact from HTML)
// ═══════════════════════════════════════════════
class _S {
  static const Color surface           = Color(0xFFF7FAFD);
  static const Color surfContainerLow  = Color(0xFFF1F4F7);
  static const Color surfContainerHigh = Color(0xFFE5E8EB);
  static const Color surfContainer     = Color(0xFFEBEEF1);
  static const Color surfVariant       = Color(0xFFE0E3E6);
  static const Color surfLowest        = Color(0xFFFFFFFF);
  static const Color primaryContainer  = Color(0xFF0F1C2C);
  static const Color secondary         = Color(0xFF006399);
  static const Color secondaryContainer= Color(0xFF67BAFD);
  static const Color onSecondaryContainer = Color(0xFF004972);
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outline           = Color(0xFF74777D);
  static const Color outlineVariant    = Color(0xFFC4C6CC);
  static const Color error             = Color(0xFFBA1A1A);
  static const Color errorContainer    = Color(0xFFFFDAD6);
  static const Color onErrorContainer  = Color(0xFF93000A);
  static const Color primaryFixed      = Color(0xFFD6E4F9);
}

// ═══════════════════════════════════════════════
//  PROFILE & CAREGIVERS SCREEN
// ═══════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfile user = DummyData.user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: [
                  _buildProfileSummary(),
                  const SizedBox(height: 32),
                  _buildMedicalIdentity(),
                  const SizedBox(height: 32),
                  _buildCaregivers(),
                  const SizedBox(height: 32),
                  _buildAccountSettings(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_back, color: _S.secondary, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Text('Profile',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: -0.3)),
            ],
          ),
          GestureDetector(
            onTap: () => _snack('Settings'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.settings_outlined, color: _S.secondary, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ── PROFILE SUMMARY ──────────────────────────────
  Widget _buildProfileSummary() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _S.surfContainerHigh,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 2), blurRadius: 8)],
              ),
              child: Center(
                child: Text(
                  user.name.split(' ').map((w) => w[0]).take(2).join(),
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: _S.primaryContainer),
                ),
              ),
            ),
            Positioned(
              bottom: -4, right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _S.secondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _S.surface, width: 2),
                ),
                child: const Icon(Icons.verified, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800,
                      color: _S.primaryContainer, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('PATIENT ID: AS-9920-X12',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _S.onSurfaceVariant, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              // Edit Profile Button
              GestureDetector(
                onTap: () => _snack('Edit profile'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _S.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Edit Profile',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── MEDICAL IDENTITY ─────────────────────────────
  Widget _buildMedicalIdentity() {
    return Column(
      children: [
        // Blood Group — with left blue border
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _S.surfLowest,
            borderRadius: BorderRadius.circular(12),
            border: const Border(left: BorderSide(color: _S.secondary, width: 4)),
            boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 4), blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BLOOD GROUP',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _S.onSurfaceVariant, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(user.bloodGroup,
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800,
                      color: _S.primaryContainer, letterSpacing: -0.5)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Allergies
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _S.surfLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 4), blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ALLERGIES',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _S.onSurfaceVariant, letterSpacing: 1.5)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['PENICILLIN', 'LATEX'].map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _S.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(a,
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                          color: _S.onErrorContainer)),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Chronic Conditions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _S.surfLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 4), blurRadius: 20)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CHRONIC CONDITIONS',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _S.onSurfaceVariant, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Text(user.conditions.join(', '),
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // ── CAREGIVERS ────────────────────────────────────
  Widget _buildCaregivers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caregivers',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700,
                          color: _S.primaryContainer, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('Authorized individuals for clinical updates and emergency contact.',
                      style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _snack('Add caregiver'),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, size: 18, color: _S.secondary),
                  const SizedBox(width: 4),
                  Text('Add\nCaregiver',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                          color: _S.secondary, height: 1.2)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Primary Caregiver
        _caregiverTile(
          name: user.emergencyContactName,
          relation: user.emergencyContactRelation,
          badgeLabel: 'PRIMARY',
          badgeBg: _S.secondaryContainer,
          badgeText: _S.onSecondaryContainer,
          avatarBg: _S.primaryFixed,
          avatarIconColor: _S.primaryContainer,
        ),
        const SizedBox(height: 12),

        // Emergency Contact
        _caregiverTile(
          name: 'Rahul Sharma',
          relation: 'Brother',
          badgeLabel: 'EMERGENCY',
          badgeBg: _S.errorContainer,
          badgeText: _S.onErrorContainer,
          avatarBg: _S.surfVariant,
          avatarIconColor: _S.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _caregiverTile({
    required String name,
    required String relation,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeText,
    required Color avatarBg,
    required Color avatarIconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: avatarBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person, color: avatarIconColor, size: 24),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                        color: _S.primaryContainer)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(badgeLabel,
                          style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                              color: badgeText)),
                    ),
                    const SizedBox(width: 8),
                    Text(relation,
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500,
                            color: _S.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              _actionButton(Icons.call, () => _snack('Calling $name...')),
              const SizedBox(width: 8),
              _actionButton(Icons.chat_bubble_outline, () => _snack('Messaging $name...')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _S.surfLowest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _S.outlineVariant.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 20, color: _S.secondary),
      ),
    );
  }

  // ── ACCOUNT SETTINGS ─────────────────────────────
  Widget _buildAccountSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700,
                color: _S.primaryContainer)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: _S.surfLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 4), blurRadius: 20)],
          ),
          child: Column(
            children: [
              // Manage Hardware
              _settingsItem(
                icon: Icons.devices_other_outlined,
                label: 'Manage Hardware',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HardwareScreen()));
                },
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.inventory_2_outlined,
                label: 'Pill Inventory',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PillInventoryScreen()));
                },
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.notifications_outlined,
                label: 'Notification Settings',
                onTap: () => _snack('Notification settings'),
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.group_outlined,
                label: 'My Care Team',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CareTeamScreen()));
                },
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.security_outlined,
                label: 'Privacy Policy',
                onTap: () => _snack('Privacy Policy'),
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.help_outline,
                label: 'Support & Help',
                onTap: () => _snack('Support & Help'),
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                },
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.emergency_outlined,
                label: 'Emergency SOS',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencySosScreen()));
                },
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              _settingsItem(
                icon: Icons.badge_outlined,
                label: 'Medical ID Setup',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalIdBasicHealthScreen()));
                },
              ),
              Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0),

              // Log Out
              InkWell(
                onTap: () => _confirmLogout(),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 24, color: _S.error),
                      const SizedBox(width: 16),
                      Text('Log Out',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600,
                              color: _S.error)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 24, color: _S.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600,
                      color: _S.primaryContainer)),
            ),
            const Icon(Icons.chevron_right, size: 20, color: _S.outline),
          ],
        ),
      ),
    );
  }

  // ── PRESERVED BACKEND ────────────────────────────
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLg)),
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Sign out from all devices?',
            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () { Navigator.pop(ctx); _snack('Logged out successfully'); },
            child: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: _S.primaryContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }
}
