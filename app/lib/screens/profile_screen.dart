import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;
  String _language = 'English';

  final UserProfile user = DummyData.user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick stats
                _buildQuickStats(),
                const SizedBox(height: 18),

                // Personal Info
                _buildSection('Personal Information', [
                  _ProfileRow(emoji: '📞', label: 'Phone', value: user.phone, onTap: () => _snack('✏️ Edit phone number')),
                  _ProfileRow(emoji: '📧', label: 'Email', value: user.email, onTap: () => _snack('✉️ Edit email')),
                  _ProfileRow(emoji: '📍', label: 'Address', value: user.address, onTap: () => _snack('📍 Update address')),
                ]),
                const SizedBox(height: 14),

                // Health Info
                _buildSection('Health Information', [
                  _ProfileRow(emoji: '🩸', label: 'Blood Group', value: user.bloodGroup),
                  _ProfileRow(emoji: '🏥', label: 'Conditions', value: user.conditions.join(', ')),
                ]),
                const SizedBox(height: 14),

                // Emergency Contact
                _buildEmergencyContact(),
                const SizedBox(height: 14),

                // Past Medication History
                _buildSection('Past Medication History', [
                  _ProfileRow(
                    emoji: '💊', label: 'Amoxicillin',
                    value: 'Completed · Oct 2023',
                    trailing: _miniTag('Add Note', AppColors.blueLight, AppColors.bluePrimary),
                  ),
                  _ProfileRow(
                    emoji: '💊', label: 'Lisinopril',
                    value: 'Discontinued · Aug 2022',
                    trailing: _miniTag('Blood Pressure', AppColors.redLight, AppColors.redAlert),
                  ),
                ]),
                const SizedBox(height: 14),

                // Settings
                _buildSettingsSection(),
                const SizedBox(height: 18),

                // Logout
                _buildLogoutButton(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GradientHeader(
      colors: const [AppColors.blueDark, Color(0xFF1A2F6F)],
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 3),
                ),
                child: const Center(child: Text('🧑‍💼', style: TextStyle(fontSize: 42))),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: () async {
                    _snack('⏳ Uploading to Firebase...');
                    try {
                      // Upload User Profile
                      await FirebaseFirestore.instance.collection('users').doc('user_123').set({
                        'name': user.name,
                        'age': user.age,
                        'gender': user.gender,
                        'bloodGroup': user.bloodGroup,
                        'phone': user.phone,
                        'email': user.email,
                        'address': user.address,
                        'conditions': user.conditions,
                        'emergencyContactName': user.emergencyContactName,
                        'emergencyContactPhone': user.emergencyContactPhone,
                        'emergencyContactRelation': user.emergencyContactRelation,
                      });
                      _snack('✅ Successfully uploaded to Firebase!');
                    } catch (e) {
                      _snack('❌ Error: $e');
                    }
                  },
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.greenPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 14), 
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user.name,
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('${user.age} Years · ${user.gender} · Blood: ${user.bloodGroup}',
              style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: user.conditions.map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(c,
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _quickStat('4', 'Medicines', AppColors.bluePrimary),
        const SizedBox(width: 10),
        _quickStat('11', 'Records', AppColors.greenPrimary),
        const SizedBox(width: 10),
        _quickStat('2', 'Upcoming', AppColors.orange),
      ],
    );
  }

  Widget _quickStat(String val, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(kRadius), boxShadow: cardShadow),
        child: Column(
          children: [
            Text(val, style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(kRadius), boxShadow: cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Add this to prevent unbounded height issues
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(title.toUpperCase(),
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...List.generate(rows.length, (i) => Column(
            mainAxisSize: MainAxisSize.min, // Add this
            children: [
              rows[i],
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppColors.border, indent: 16),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact() {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(kRadius), boxShadow: cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('EMERGENCY CONTACT',
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8)),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('🆘', style: TextStyle(fontSize: 22)))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.emergencyContactName,
                          style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800)),
                      Text('${user.emergencyContactRelation} · ${user.emergencyContactPhone}',
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _snack('📞 Calling ${user.emergencyContactName}...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.greenPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Call', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(kRadius), boxShadow: cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('SETTINGS',
                style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.8)),
          ),
          const Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Text('🌐', style: TextStyle(fontSize: 22)),
            title: Text('Language', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(_language, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            onTap: () {
              setState(() => _language = _language == 'English' ? 'हिंदी' : 'English');
              _snack('🌐 Language changed to $_language');
            },
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16),
          ListTile(
            leading: const Text('🔔', style: TextStyle(fontSize: 22)),
            title: Text('Notifications', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Push & SMS ${_notificationsEnabled ? "enabled" : "disabled"}',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
            trailing: PillToggle(
              initialValue: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
          ),
          const Divider(height: 1, color: AppColors.border, indent: 16),
          ListTile(
            leading: const Text('🔒', style: TextStyle(fontSize: 22)),
            title: Text('Privacy & Security', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text('Biometric Lock ${_biometricEnabled ? "ON" : "OFF"}',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
            trailing: PillToggle(
              initialValue: _biometricEnabled,
              onChanged: (v) => setState(() => _biometricEnabled = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _snack('👋 Logged out from all devices'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.redAlert,
          side: const BorderSide(color: AppColors.redAlert, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
        ),
        child: Text('Logout from All Devices',
            style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.redAlert)),
      ),
    );
  }

  Widget _miniTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  void _snack(String msg) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700)), duration: const Duration(seconds: 2)),
    );
  }
}

// ─── Profile Row ──────────────────────────────────
class _ProfileRow extends StatelessWidget {
  final String emoji, label, value;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileRow({required this.emoji, required this.label, required this.value, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
      subtitle: Text(value, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted) : null),
    );
  }
}
