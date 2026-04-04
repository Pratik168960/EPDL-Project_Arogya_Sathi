import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import 'hardware_screen.dart';

// ═══════════════════════════════════════════════
//  PROFILE SCREEN
// ═══════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsOn = true;
  bool _biometricOn     = true;
  bool _smsAlertsOn     = true;
  String _language      = 'English';

  final UserProfile user = DummyData.user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildStatStrip(),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              children: [
                // Personal Information
                NavySectionLabel(label: 'PERSONAL INFORMATION'),
                _infoCard([
                  ProfileInfoRow(icon: Icons.phone_outlined,     label: 'Phone',   value: user.phone,   onTap: () => _snack('Edit phone')),
                  ProfileInfoRow(icon: Icons.email_outlined,     label: 'Email',   value: user.email,   onTap: () => _snack('Edit email')),
                  ProfileInfoRow(icon: Icons.location_on_outlined,label: 'Address', value: user.address, onTap: () => _snack('Update address')),
                ]),
                const SizedBox(height: 20),

                // Health Information
                NavySectionLabel(label: 'HEALTH INFORMATION'),
                _infoCard([
                  ProfileInfoRow(
                    icon: Icons.bloodtype_outlined,
                    label: 'Blood Group',
                    value: user.bloodGroup,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(user.bloodGroup,
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger)),
                    ),
                  ),
                  ProfileInfoRow(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Conditions',
                    value: user.conditions.join(' · '),
                  ),
                  ProfileInfoRow(
                    icon: Icons.person_pin_outlined,
                    label: 'Age & Gender',
                    value: '${user.age} years · ${user.gender}',
                  ),
                ]),
                const SizedBox(height: 20),

                // Past Medication History
                NavySectionLabel(label: 'PAST MEDICATION HISTORY'),
                _infoCard([
                  _medHistoryRow(
                    name: 'Amoxicillin',
                    note: 'Completed · Oct 2023',
                    tagLabel: 'Add Note',
                    tagColor: AppColors.teal,
                    tagBg: AppColors.tealPale,
                  ),
                  _medHistoryRow(
                    name: 'Lisinopril',
                    note: 'Discontinued · Aug 2022',
                    tagLabel: 'Blood Pressure',
                    tagColor: AppColors.danger,
                    tagBg: AppColors.dangerBg,
                  ),
                ]),
                const SizedBox(height: 20),

                // Emergency Contact
                NavySectionLabel(label: 'EMERGENCY CONTACT'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(kRadius),
                    boxShadow: const [
                      BoxShadow(color: Color(0x050C1E35), blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(kRadius)),
                      child: const Icon(Icons.emergency_share_outlined, color: AppColors.danger, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(user.emergencyContactName,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('${user.emergencyContactRelation} · ${user.emergencyContactPhone}',
                            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.call_outlined, size: 16),
                      label: Text('Call', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
                      onPressed: () => _snack('Calling ${user.emergencyContactName}...'),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                // Medical Reports & Documents
                NavySectionLabel(label: 'MEDICAL REPORTS'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(kRadius),
                    boxShadow: const [
                      BoxShadow(color: Color(0x050C1E35), blurRadius: 16, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(children: [
                    _docRow(Icons.biotech_outlined,     'Blood_Test_Dec.pdf',   'Dec 2024',   AppColors.danger),
                    const SizedBox(height: 8),
                    _docRow(Icons.medical_information_outlined,   'Chest_XRay.jpg',       'Nov 2024',   AppColors.teal),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _snack('Upload new document'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(kRadiusSm)),
                            child: const Icon(Icons.upload_outlined, size: 17, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Text('Upload New',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 32),

                // Settings
                NavySectionLabel(label: 'SETTINGS'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(kRadius),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(children: [
                    // Manage Hardware
                    InkWell(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadius)),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HardwareScreen()),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(kRadiusSm)),
                            child: const Icon(Icons.devices_other_outlined, size: 17, color: AppColors.teal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Manage Hardware',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text('Bluetooth devices & settings',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                            ]),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.border),
                        ]),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 16),

                    // Language
                    InkWell(
                      onTap: () {
                        setState(() => _language = _language == 'English' ? 'हिंदी' : 'English');
                        _snack('Language changed to $_language');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(kRadiusSm)),
                            child: const Icon(Icons.language_outlined, size: 17, color: AppColors.bluePrimary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Language',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text(_language,
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                            ]),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.border),
                        ]),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 16),

                    // Notifications
                    _settingToggleRow(
                      icon: Icons.notifications_outlined,
                      iconBg: AppColors.warningBg,
                      iconColor: AppColors.warning,
                      label: 'Pill Reminders',
                      sub: 'Push & SMS Notifications',
                      value: _notificationsOn,
                      onChanged: (v) => setState(() => _notificationsOn = v),
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 16),

                    // Biometric
                    _settingToggleRow(
                      icon: Icons.fingerprint_outlined,
                      iconBg: AppColors.tealPale,
                      iconColor: AppColors.teal,
                      label: 'Biometric Lock',
                      sub: 'Fingerprint / Face ID',
                      value: _biometricOn,
                      onChanged: (v) => setState(() => _biometricOn = v),
                    ),
                    const Divider(height: 1, color: AppColors.divider, indent: 16),

                    // SMS alerts
                    _settingToggleRow(
                      icon: Icons.sms_outlined,
                      iconBg: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF7C3AED),
                      label: 'SMS Alerts',
                      sub: 'Send to emergency contacts',
                      value: _smsAlertsOn,
                      onChanged: (v) => setState(() => _smsAlertsOn = v),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withOpacity(0.35), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.logout_outlined, size: 18),
                    label: Text('LOGOUT FROM ALL DEVICES',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    onPressed: () => _confirmLogout(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(children: [
            // Avatar
            Stack(alignment: Alignment.bottomRight, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 3),
                ),
                child: Center(
                  child: Text('RS',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.navy, width: 2),
                ),
                child: const Icon(Icons.edit_outlined, size: 12, color: AppColors.navy),
              ),
            ]),
            const SizedBox(height: 12),
            Text(user.name,
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${user.age} Years · ${user.gender} · Blood Group ${user.bloodGroup}',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, alignment: WrapAlignment.center,
              children: user.conditions.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Text(c, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white60)),
              )).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  // ── STAT STRIP ───────────────────────────────
  Widget _buildStatStrip() {
    return Container(
      color: AppColors.white,
      child: Row(children: [
        _statPill('4',  'MEDICINES', AppColors.teal),
        Container(width: 1, height: 36, color: AppColors.divider),
        _statPill('11', 'RECORDS',   AppColors.success),
        Container(width: 1, height: 36, color: AppColors.divider),
        _statPill('2',  'UPCOMING',  AppColors.warning),
      ]),
    );
  }

  Widget _statPill(String val, String label, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(val,   style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1)),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.outfit(fontSize: 9,  fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────
  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x050C1E35), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: rows.map((r) {
          final isLast = rows.last == r;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: r,
          );
        }).toList(),
      ),
    );
  }

  Widget _medHistoryRow({
    required String name,
    required String note,
    required String tagLabel,
    required Color tagColor,
    required Color tagBg,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(kRadiusSm)),
          child: const Icon(Icons.medication_outlined, size: 17, color: AppColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(note, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(20)),
          child: Text(tagLabel, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: tagColor)),
        ),
      ]),
    );
  }

  Widget _docRow(IconData icon, String name, String date, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(kRadiusSm)),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(date, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
        const Icon(Icons.download_outlined, size: 18, color: AppColors.textMuted),
      ]),
    );
  }

  Widget _settingToggleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(kRadiusSm)),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(sub,   style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
        Switch.adaptive(
          value: value,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          activeColor: Colors.white,
          activeTrackColor: AppColors.teal,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.border,
        ),
      ]),
    );
  }

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
      backgroundColor: AppColors.navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }
}
