import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'emergency_sos_screen.dart';
import 'medical_id_basic_health_screen.dart';
import 'analytics_screen.dart';
import 'care_team_screen.dart';
import 'pill_inventory_screen.dart';
import '../services/hardware_sync_service.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens
// ═══════════════════════════════════════════════
class _S {
  static const Color surface           = Color(0xFFF7FAFD);
  static const Color surfContainerLow  = Color(0xFFF1F4F7);
  static const Color surfContainerHigh = Color(0xFFE5E8EB);
  static const Color surfContainerHighest = Color(0xFFE0E3E6);
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
//  PROFILE SCREEN
//  Phase 4: Firebase Auth + Firestore Integration
// ═══════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  // ── Live Firebase Auth user ───────────────────
  User? get _authUser => FirebaseAuth.instance.currentUser;

  String get _uid => AuthService.currentUserId ?? '';

  // 1. The missing settings key
  final GlobalKey _settingsKey = GlobalKey();

  // 2. Edit Profile — updates Firebase Auth displayName + Firestore
  void _showEditProfileDialog() async {
    // Pre-load existing data from Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    final data = doc.data() ?? {};

    final nameCtrl = TextEditingController(text: _authUser?.displayName ?? data['name'] ?? '');
    final phoneCtrl = TextEditingController(text: data['phone'] ?? '');
    final ageCtrl = TextEditingController(text: data['age']?.toString() ?? '');
    String gender = data['gender'] ?? 'Prefer not to say';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _S.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: _S.primaryContainer)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _profileField(nameCtrl, 'Full Name', Icons.person_outline),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: GoogleFonts.outfit(color: _S.primaryContainer),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: GoogleFonts.outfit(color: _S.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    prefixText: '+91 ',
                    prefixStyle: GoogleFonts.outfit(color: _S.primaryContainer, fontWeight: FontWeight.w600),
                    counterText: '',
                    filled: true,
                    fillColor: _S.surfContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                _profileField(ageCtrl, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number, maxLength: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: gender,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _S.primaryContainer),
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: GoogleFonts.outfit(color: _S.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.wc_outlined, size: 20),
                    filled: true,
                    fillColor: _S.surfContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  items: ['Male', 'Female', 'Other', 'Prefer not to say']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => gender = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: _S.onSurfaceVariant)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _S.secondary),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isEmpty) return;
                final phone = phoneCtrl.text.trim();
                if (phone.isNotEmpty && phone.length != 10) {
                  _snack('Phone must be exactly 10 digits');
                  return;
                }
                try {
                  await _authUser?.updateDisplayName(newName);
                  await FirebaseFirestore.instance.collection('users').doc(_uid).update({
                    'name': newName,
                    'phone': phone.isNotEmpty ? '+91$phone' : '',
                    'age': int.tryParse(ageCtrl.text.trim()) ?? 0,
                    'gender': gender,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() {});
                    _snack('Profile updated!');
                  }
                } catch (e) {
                  if (mounted) _snack('Error: $e');
                }
              },
              child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType, int? maxLength}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: GoogleFonts.outfit(color: _S.primaryContainer),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: _S.onSurfaceVariant),
        prefixIcon: Icon(icon, size: 20),
        counterText: '',
        filled: true,
        fillColor: _S.surfContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  // 3. Notification Settings — real toggles persisted to Firestore
  void _showNotificationSettingsDialog() {
    bool medReminders = true;
    bool missedDose = true;
    bool sosAlerts = true;
    bool caregiverUpdates = true;

    // Load current prefs from Firestore
    FirebaseFirestore.instance.collection('users').doc(_uid).get().then((doc) {
      final prefs = doc.data()?['notification_prefs'] as Map<String, dynamic>? ?? {};
      medReminders = prefs['med_reminders'] ?? true;
      missedDose = prefs['missed_dose'] ?? true;
      sosAlerts = prefs['sos_alerts'] ?? true;
      caregiverUpdates = prefs['caregiver_updates'] ?? true;
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _S.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Notification Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: _S.primaryContainer)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _notifToggle('Medicine Reminders', 'Alarm alerts for medications', medReminders, (v) {
                setDialogState(() => medReminders = v);
              }),
              _notifToggle('Missed Dose Alerts', 'Alerts when a dose is missed', missedDose, (v) {
                setDialogState(() => missedDose = v);
              }),
              _notifToggle('SOS Alerts', 'Emergency SOS notifications', sosAlerts, (v) {
                setDialogState(() => sosAlerts = v);
              }),
              _notifToggle('Caregiver Updates', 'Updates from linked caregivers', caregiverUpdates, (v) {
                setDialogState(() => caregiverUpdates = v);
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: _S.onSurfaceVariant)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _S.secondary),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(_uid).update({
                  'notification_prefs': {
                    'med_reminders': medReminders,
                    'missed_dose': missedDose,
                    'sos_alerts': sosAlerts,
                    'caregiver_updates': caregiverUpdates,
                  }
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _snack('Notification settings saved!');
                }
              },
              child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _S.primaryContainer)),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 10, color: _S.onSurfaceVariant)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _S.secondary,
          ),
        ],
      ),
    );
  }

  // 4. The missing Info Sheet function (handles Privacy Policy & Support)
  void _showInfoSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ── Firestore references ─────────────────────
  DocumentReference<Map<String, dynamic>> get _basicHealthDoc =>
      FirebaseFirestore.instance
          .collection('users').doc(_uid)
          .collection('medical_id').doc('basic_health');

  DocumentReference<Map<String, dynamic>> get _conditionsDoc =>
      FirebaseFirestore.instance
          .collection('users').doc(_uid)
          .collection('medical_id').doc('conditions');

  CollectionReference<Map<String, dynamic>> get _caregiversRef =>
      FirebaseFirestore.instance
          .collection('users').doc(_uid)
          .collection('caregivers');

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
                  // ── Profile Summary — from Firebase Auth ──
                  _buildProfileSummary(),
                  const SizedBox(height: 32),

                  // ── Medical Identity — from Firestore ──────
                  _buildMedicalIdentity(),
                  const SizedBox(height: 32),

                  // ── Caregivers — StreamBuilder ─────────────
                  _buildCaregivers(),
                  const SizedBox(height: 32),

                  // ── Share Code — for patient-caregiver linking ──
                  _buildShareCode(),
                  const SizedBox(height: 32),

                  // ── Account Settings ───────────────────────
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
            onTap: () {
              HapticFeedback.selectionClick();
              // Scroll down to Account Settings section
              Scrollable.ensureVisible(
                _settingsKey.currentContext!,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            },
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

  // ── PROFILE SUMMARY — Firebase Auth ──────────────
  Widget _buildProfileSummary() {
    final user = _authUser;
    // Derive display name: prefer displayName, fall back to email prefix
    final rawName = (user?.displayName?.isNotEmpty == true)
        ? user!.displayName!
        : (user?.email ?? 'User').split('@').first;
    final displayName = rawName
        .split(RegExp(r'[._\s]+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    // Initials from display name
    final initials = displayName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final email = user?.email ?? '';

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
                child: Text(initials,
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
              Text(displayName,
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800,
                      color: _S.primaryContainer, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(email,
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500,
                      color: _S.onSurfaceVariant)),
              const SizedBox(height: 16),
              // Edit Profile Button
              GestureDetector(
                onTap: () => _showEditProfileDialog(),
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

  // ── MEDICAL IDENTITY — Firestore FutureBuilders ──
  Widget _buildMedicalIdentity() {
    return Column(
      children: [
        // Blood Type card
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _basicHealthDoc.get(),
          builder: (context, snap) {
            final bloodType = snap.data?.data()?['blood_type'] as String?;
            final display = (bloodType != null && bloodType.isNotEmpty) ? bloodType : '—';
            return Container(
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
                  Text(display,
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800,
                          color: _S.primaryContainer, letterSpacing: -0.5)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Allergies card
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _conditionsDoc.get(),
          builder: (context, snap) {
            final data = snap.data?.data();
            final allergies = (data?['allergies'] as List?)?.cast<String>() ?? [];
            return Container(
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
                  allergies.isEmpty
                      ? Text('None recorded',
                          style: GoogleFonts.outfit(fontSize: 14, color: _S.onSurfaceVariant))
                      : Wrap(
                          spacing: 8, runSpacing: 8,
                          children: allergies.map((a) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _S.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(a.toUpperCase(),
                                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: _S.onErrorContainer)),
                          )).toList(),
                        ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Chronic Conditions card
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _conditionsDoc.get(),
          builder: (context, snap) {
            final data = snap.data?.data();
            final conditions = (data?['conditions'] as List?)?.cast<String>() ?? [];
            final display = conditions.isEmpty ? 'None recorded' : conditions.join(', ');
            return Container(
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
                  Text(display,
                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
                          color: _S.primaryContainer, height: 1.3)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── CAREGIVERS — StreamBuilder ────────────────────
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
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CareTeamScreen()));
              },
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, size: 18, color: _S.secondary),
                  const SizedBox(width: 4),
                  Text('Manage',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                          color: _S.secondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _caregiversRef.orderBy('created_at').limit(3).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2, color: _S.secondary),
              ));
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareTeamScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _S.surfContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _S.outlineVariant.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_add_outlined, size: 32, color: _S.outlineVariant),
                      const SizedBox(height: 10),
                      Text('No caregivers added yet',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600,
                              color: _S.primaryContainer)),
                      const SizedBox(height: 4),
                      Text('Tap to add your care team',
                          style: GoogleFonts.outfit(fontSize: 12, color: _S.onSurfaceVariant)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: List.generate(docs.length, (i) {
                final data = docs[i].data();
                final name = data['name'] as String? ?? 'Unknown';
                final relation = data['relation'] as String? ?? '';
                final isPrimary = i == 0;
                return Padding(
                  padding: EdgeInsets.only(bottom: i < docs.length - 1 ? 12 : 0),
                  child: _caregiverTile(
                    name: name,
                    relation: relation,
                    badgeLabel: isPrimary ? 'PRIMARY' : 'CONTACT',
                    badgeBg: isPrimary ? _S.secondaryContainer : _S.errorContainer,
                    badgeText: isPrimary ? _S.onSecondaryContainer : _S.onErrorContainer,
                    avatarBg: isPrimary ? _S.primaryFixed : _S.surfVariant,
                    avatarIconColor: isPrimary ? _S.primaryContainer : _S.onSurfaceVariant,
                  ),
                );
              }),
            );
          },
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
          // Avatar with initial
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: avatarBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: avatarIconColor),
              ),
            ),
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
                    if (relation.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(relation,
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500,
                              color: _S.onSurfaceVariant)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              _actionButton(Icons.call, () async {
                final uri = Uri.parse('tel:+911234567890');
                if (await canLaunchUrl(uri)) {
                  launchUrl(uri);
                } else {
                  _snack('Could not open phone dialer');
                }
              }),
              const SizedBox(width: 8),
              _actionButton(Icons.chat_bubble_outline, () async {
                final uri = Uri.parse('sms:+911234567890');
                if (await canLaunchUrl(uri)) {
                  launchUrl(uri);
                } else {
                  _snack('Could not open messaging app');
                }
              }),
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
          border: Border.all(color: _S.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 20, color: _S.secondary),
      ),
    );
  }

  // ── SHARE CODE — for caregiver linking ─────────────
  Widget _buildShareCode() {
    return FutureBuilder<String?>(
      future: AuthService.getShareCode(),
      builder: (context, snapshot) {
        // Don't show for caregivers
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final code = snapshot.data ?? '------';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Code',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700,
                    color: _S.primaryContainer)),
            const SizedBox(height: 8),
            Text('Give this code to your caregiver so they can link to your account.',
                style: GoogleFonts.outfit(fontSize: 12, color: _S.onSurfaceVariant)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: _S.surfLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _S.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 4), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  // The code display
                  Text(code,
                    style: GoogleFonts.outfit(
                      fontSize: 36, fontWeight: FontWeight.w900,
                      letterSpacing: 10, color: _S.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Copy button
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          _snack('Code copied!');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text('Copy', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _S.secondary,
                          side: BorderSide(color: _S.outlineVariant.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Regenerate button
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await AuthService.regenerateShareCode();
                            setState(() {}); // Rebuild to show new code
                            _snack('New code generated!');
                          } catch (e) {
                            _snack('Error: $e');
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text('New Code', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _S.outline,
                          side: BorderSide(color: _S.outlineVariant.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── ACCOUNT SETTINGS ─────────────────────────────
  Widget _buildAccountSettings() {
    return Column(
      key: _settingsKey,
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
              _settingsItem(
                icon: Icons.inventory_2_outlined,
                label: 'Pill Inventory',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PillInventoryScreen()));
                },
              ),
              _divider(),
              _settingsItem(
                icon: Icons.notifications_outlined,
                label: 'Notification Settings',
                onTap: () => _showNotificationSettingsDialog(),
              ),
              _divider(),
              _settingsItem(
                icon: Icons.group_outlined,
                label: 'My Care Team',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CareTeamScreen()));
                },
              ),
              _divider(),
              _settingsItem(
                icon: Icons.security_outlined,
                label: 'Privacy Policy',
                onTap: () => _showInfoSheet('Privacy Policy', 'ArogyaSathi respects your privacy.\n\n• Your health data is stored securely in Firebase with encryption at rest.\n• Data is only shared with linked caregivers that YOU approve.\n• You can revoke caregiver access at any time.\n• We never sell your data to third parties.\n• All communication is encrypted via TLS/SSL.\n• You can delete your account and all data from Settings.\n\nFor questions: support@arogyasathi.com'),
              ),
              _divider(),
              _settingsItem(
                icon: Icons.help_outline,
                label: 'Support & Help',
                onTap: () => _showInfoSheet('Support & Help', '📧 Email: support@arogyasathi.com\n\n📞 Helpline: 1800-XXX-XXXX\n(Mon-Fri, 9 AM - 6 PM IST)\n\n💡 Quick Tips:\n• Add medicines via the + button on Reminders tab\n• Link caregivers via Profile → Share Code\n• Set up Medical ID for emergencies\n• Use the SOS button for emergencies\n\n🔧 Troubleshooting:\n• If alarms don\'t ring, check notification permissions\n• If dispenser fails, check WiFi on the ESP32\n• Clear app cache from Phone Settings if issues persist'),
              ),
              _divider(),
              _settingsItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                },
              ),
              _divider(),
              _settingsItem(
                icon: Icons.emergency_outlined,
                label: 'Emergency SOS',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencySosScreen()));
                },
              ),
              _divider(),
              _settingsItem(
                icon: Icons.badge_outlined,
                label: 'Medical ID Setup',
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalIdBasicHealthScreen()));
                },
              ),
              _divider(),
              // Log Out
              InkWell(
                onTap: _confirmLogout,
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

  Divider _divider() => const Divider(height: 1, color: _S.surfContainer, indent: 0, endIndent: 0);

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

  // ── LOGOUT DIALOG ─────────────────────────────────
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLg)),
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('Sign out from all devices?',
            style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              HardwareSyncService.stopListening();
              await AuthService.logOut();
            },
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
