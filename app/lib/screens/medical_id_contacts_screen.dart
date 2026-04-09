import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens
// ═══════════════════════════════════════════════
class _S {
  static const Color surface           = Color(0xFFF7FAFD);
  static const Color surfContainerLow  = Color(0xFFF1F4F7);
  static const Color surfContainerHigh = Color(0xFFE5E8EB);
  static const Color surfContainerHighest = Color(0xFFE0E3E6);
  static const Color surfContainer     = Color(0xFFEBEEF1);
  static const Color surfLowest        = Color(0xFFFFFFFF);
  static const Color primaryContainer  = Color(0xFF0F1C2C);
  static const Color onPrimaryContainer = Color(0xFF778598);
  static const Color secondary         = Color(0xFF006399);
  static const Color onSecondary       = Color(0xFFFFFFFF);
  static const Color onSurface         = Color(0xFF181C1E);
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outlineVariant    = Color(0xFFC4C6CC);
  static const Color emerald           = Color(0xFF10B981);
}

// ═══════════════════════════════════════════════
//  MEDICAL ID: EMERGENCY CONTACTS (Step 3/3)
//  Phase 3: Firebase Firestore Integration
// ═══════════════════════════════════════════════
class MedicalIdContactsScreen extends StatefulWidget {
  const MedicalIdContactsScreen({super.key});

  @override
  State<MedicalIdContactsScreen> createState() => _MedicalIdContactsScreenState();
}

class _MedicalIdContactsScreenState extends State<MedicalIdContactsScreen> {
  final _primaryNameCtrl  = TextEditingController();
  final _primaryPhoneCtrl = TextEditingController();
  String _primaryRelation = 'Spouse';

  final _secondaryNameCtrl  = TextEditingController();
  final _secondaryPhoneCtrl = TextEditingController();
  String _secondaryRelation = 'Sibling';

  bool _showOnLockScreen = true;
  bool _isSaving = false;
  bool _isLoaded = false;

  final _relations = ['Spouse', 'Parent', 'Sibling', 'Child', 'Friend', 'Other'];

  // ── Firestore Reference ──────────────────────
  DocumentReference<Map<String, dynamic>> get _contactsDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('medical_id')
          .doc('emergency_contacts');

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _primaryNameCtrl.dispose();
    _primaryPhoneCtrl.dispose();
    _secondaryNameCtrl.dispose();
    _secondaryPhoneCtrl.dispose();
    super.dispose();
  }

  // ── Load existing data ───────────────────────────
  Future<void> _loadExistingData() async {
    try {
      final doc = await _contactsDoc.get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          // Primary
          _primaryNameCtrl.text  = data['primary_name'] ?? '';
          _primaryPhoneCtrl.text = data['primary_phone'] ?? '';
          _primaryRelation = data['primary_relation'] ?? 'Spouse';
          if (!_relations.contains(_primaryRelation)) _primaryRelation = 'Other';

          // Secondary
          _secondaryNameCtrl.text  = data['secondary_name'] ?? '';
          _secondaryPhoneCtrl.text = data['secondary_phone'] ?? '';
          _secondaryRelation = data['secondary_relation'] ?? 'Sibling';
          if (!_relations.contains(_secondaryRelation)) _secondaryRelation = 'Other';

          _showOnLockScreen = data['show_on_lock_screen'] ?? true;
          _isLoaded = true;
        });
      } else {
        if (mounted) setState(() => _isLoaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoaded = true);
      debugPrint('Error loading contacts: $e');
    }
  }

  // ── Save & Finish ────────────────────────────────
  Future<void> _saveAndFinish() async {
    HapticFeedback.selectionClick();
    setState(() => _isSaving = true);

    try {
      // Save to medical_id/emergency_contacts
      await _contactsDoc.set({
        'primary_name': _primaryNameCtrl.text.trim(),
        'primary_phone': _primaryPhoneCtrl.text.trim(),
        'primary_relation': _primaryRelation,
        'secondary_name': _secondaryNameCtrl.text.trim(),
        'secondary_phone': _secondaryPhoneCtrl.text.trim(),
        'secondary_relation': _secondaryRelation,
        'show_on_lock_screen': _showOnLockScreen,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also sync primary contact to the caregivers collection
      // so it appears in the Care Team screen
      final uid = AuthService.currentUserId!;
      final primaryName = _primaryNameCtrl.text.trim();
      if (primaryName.isNotEmpty) {
        final caregiversRef = FirebaseFirestore.instance
            .collection('users').doc(uid).collection('caregivers');

        // Check if this contact already exists (by name)
        final existing = await caregiversRef
            .where('name', isEqualTo: primaryName)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await caregiversRef.add({
            'name': primaryName,
            'phone': _primaryPhoneCtrl.text.trim(),
            'relation': _primaryRelation,
            'alert_missed_dose': true,
            'alert_hw_offline': false,
            'alert_monthly': true,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text('✅ Medical ID complete! Profile saved.',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          backgroundColor: _S.emerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ));

        // Pop all the way back to Profile
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Container(height: 1, color: _S.surfContainerHighest.withOpacity(0.5)),
            Expanded(
              child: !_isLoaded
                  ? const Center(child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _S.secondary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressHeader(),
                          const SizedBox(height: 32),
                          _buildHeadline(),
                          const SizedBox(height: 32),
                          _buildContactSection(
                            title: 'PRIMARY CONTACT',
                            accentColor: _S.secondary,
                            borderLeft: true,
                            nameCtrl: _primaryNameCtrl,
                            phoneCtrl: _primaryPhoneCtrl,
                            relation: _primaryRelation,
                            onRelationChanged: (v) => setState(() => _primaryRelation = v!),
                          ),
                          const SizedBox(height: 32),
                          _buildContactSection(
                            title: 'SECONDARY CONTACT',
                            accentColor: _S.outlineVariant,
                            borderLeft: false,
                            nameCtrl: _secondaryNameCtrl,
                            phoneCtrl: _secondaryPhoneCtrl,
                            relation: _secondaryRelation,
                            onRelationChanged: (v) => setState(() => _secondaryRelation = v!),
                          ),
                          const SizedBox(height: 32),
                          _buildLockScreenToggle(),
                          const SizedBox(height: 32),
                          _buildSummaryInsight(),
                        ],
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, color: _S.secondary, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Text('Medical ID\nSetup',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, height: 1.2, letterSpacing: -0.2)),
            ],
          ),
          GestureDetector(
            onTap: _isSaving ? null : _saveAndFinish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isSaving ? _S.surfContainerHigh : _S.primaryContainer,
                borderRadius: BorderRadius.circular(6),
                boxShadow: _isSaving ? null : [BoxShadow(color: _S.primaryContainer.withOpacity(0.3),
                    offset: const Offset(0, 4), blurRadius: 12)],
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save &\nContinue',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Colors.white, height: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  // ── PROGRESS HEADER ──────────────────────────────
  Widget _buildProgressHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STEP 3 OF 3',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                    color: _S.onSurfaceVariant, letterSpacing: 1.2)),
            Text('Finalizing Profile',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _S.secondary)),
          ],
        ),
        const SizedBox(height: 12),
        // Full progress bar
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _S.surfContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _S.secondary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  // ── HEADLINE ─────────────────────────────────────
  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Emergency\nContacts',
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800,
                color: _S.primaryContainer, letterSpacing: -0.8, height: 1.1)),
        const SizedBox(height: 12),
        Text(
          'Add trusted individuals who should be contacted in the event of a medical emergency.',
          style: GoogleFonts.outfit(fontSize: 15, color: _S.onSurfaceVariant, height: 1.5),
        ),
      ],
    );
  }

  // ── CONTACT FORM SECTION ─────────────────────────
  Widget _buildContactSection({
    required String title,
    required Color accentColor,
    required bool borderLeft,
    required TextEditingController nameCtrl,
    required TextEditingController phoneCtrl,
    required String relation,
    required ValueChanged<String?> onRelationChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(width: 4, height: 24, decoration: BoxDecoration(
                color: accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Text(title,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _S.primaryContainer, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 16),

        // Form card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _S.surfContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: borderLeft
                ? const Border(left: BorderSide(color: _S.secondary, width: 4))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              _fieldLabel('FULL NAME'),
              const SizedBox(height: 8),
              _textInput(nameCtrl, 'Enter full name'),
              const SizedBox(height: 20),

              // Relationship
              _fieldLabel('RELATIONSHIP'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _S.surfLowest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonFormField<String>(
                  value: relation,
                  style: GoogleFonts.outfit(fontSize: 14, color: _S.onSurface),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down, color: _S.onSurfaceVariant),
                  dropdownColor: _S.surfLowest,
                  items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: onRelationChanged,
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number
              _fieldLabel('PHONE NUMBER'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _S.surfLowest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.outfit(fontSize: 14, color: _S.onSurface,
                      fontFeatures: [const FontFeature.tabularFigures()]),
                  decoration: InputDecoration(
                    hintText: '+1 (555) 000-0000',
                    hintStyle: GoogleFonts.outfit(fontSize: 14, color: _S.onSurfaceVariant.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.call, size: 18, color: _S.onSurfaceVariant),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── LOCK SCREEN TOGGLE ───────────────────────────
  Widget _buildLockScreenToggle() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _S.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _S.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_open, size: 22, color: _S.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Show on Lock Screen',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  'Allows paramedics to view these contacts without unlocking your device.',
                  style: GoogleFonts.outfit(fontSize: 12, color: _S.onPrimaryContainer, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: _showOnLockScreen,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _showOnLockScreen = v);
            },
            activeColor: Colors.white,
            activeTrackColor: _S.secondary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF334155),
          ),
        ],
      ),
    );
  }

  // ── SUMMARY INSIGHT ──────────────────────────────
  Widget _buildSummaryInsight() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _S.surfContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'By saving these contacts, you agree to allow medical professionals to access this information in emergency situations through the universal Medical ID shortcut.',
              style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant,
                  fontWeight: FontWeight.w500, height: 1.5),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user, size: 28, color: _S.secondary),
          ),
        ],
      ),
    );
  }

  // ── SHARED HELPERS ───────────────────────────────
  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
              color: _S.onSurfaceVariant, letterSpacing: 1.5)),
    );
  }

  Widget _textInput(TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.outfit(fontSize: 14, color: _S.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 14, color: _S.onSurfaceVariant.withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
