import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'medical_id_conditions_screen.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens
// ═══════════════════════════════════════════════
class _S {
  static const Color surface           = Color(0xFFF7FAFD);
  static const Color surfContainerLow  = Color(0xFFF1F4F7);
  static const Color surfContainerHigh = Color(0xFFE5E8EB);
  static const Color surfContainerHighest = Color(0xFFE0E3E6);
  static const Color surfLowest        = Color(0xFFFFFFFF);
  static const Color primaryContainer  = Color(0xFF0F1C2C);
  static const Color onPrimaryContainer = Color(0xFF778598);
  static const Color secondary         = Color(0xFF006399);
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outline           = Color(0xFF74777D);
  static const Color onPrimary         = Color(0xFFFFFFFF);
  static const Color emerald           = Color(0xFF10B981);
}

// ═══════════════════════════════════════════════
//  MEDICAL ID: BASIC HEALTH (Step 1 of 3)
//  Phase 3: Firebase Firestore Integration
// ═══════════════════════════════════════════════
class MedicalIdBasicHealthScreen extends StatefulWidget {
  const MedicalIdBasicHealthScreen({super.key});

  @override
  State<MedicalIdBasicHealthScreen> createState() => _MedicalIdBasicHealthScreenState();
}

class _MedicalIdBasicHealthScreenState extends State<MedicalIdBasicHealthScreen> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String? _bloodType;
  bool _organDonor = true;
  bool _isSaving = false;
  bool _isLoaded = false;

  final _bloodTypes = [
    'A Positive (A+)', 'A Negative (A-)',
    'B Positive (B+)', 'B Negative (B-)',
    'AB Positive (AB+)', 'AB Negative (AB-)',
    'O Positive (O+)', 'O Negative (O-)',
    'Unknown / Not Sure',
  ];

  // ── Firestore Reference ──────────────────────
  DocumentReference<Map<String, dynamic>> get _medicalIdDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('medical_id')
          .doc('basic_health');

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ── Load existing data from Firestore ────────────
  Future<void> _loadExistingData() async {
    try {
      final doc = await _medicalIdDoc.get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _heightCtrl.text = data['height'] ?? '';
          _weightCtrl.text = data['weight'] ?? '';
          _bloodType = data['blood_type'];
          _organDonor = data['organ_donor'] ?? true;
          _isLoaded = true;
        });
      } else {
        if (mounted) setState(() => _isLoaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoaded = true);
      debugPrint('Error loading medical ID: $e');
    }
  }

  // ── Save data to Firestore ───────────────────────
  Future<void> _saveAndContinue() async {
    HapticFeedback.selectionClick();
    setState(() => _isSaving = true);

    try {
      await _medicalIdDoc.set({
        'height': _heightCtrl.text.trim(),
        'weight': _weightCtrl.text.trim(),
        'blood_type': _bloodType,
        'organ_donor': _organDonor,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Basic health info saved!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: _S.emerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));

        Navigator.push(context, MaterialPageRoute(
            builder: (_) => const MedicalIdConditionsScreen()));
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
            Container(height: 1, color: _S.surfContainerHighest.withValues(alpha: 0.5)),
            Expanded(
              child: !_isLoaded
                  ? const Center(child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _S.secondary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressHeader(),
                          const SizedBox(height: 32),
                          _buildWhyCard(),
                          const SizedBox(height: 20),
                          _buildSecurityBadges(),
                          const SizedBox(height: 40),
                          _buildPhysicalAttributes(),
                          const SizedBox(height: 40),
                          _buildMedicalSpecs(),
                          const SizedBox(height: 48),
                          _buildBottomImage(),
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
                  child: Icon(Icons.arrow_back, color: _S.primaryContainer, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Text('Medical ID Setup',
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: -0.3)),
            ],
          ),
          GestureDetector(
            onTap: _isSaving ? null : _saveAndContinue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isSaving ? _S.surfContainerHigh : _S.primaryContainer,
                borderRadius: BorderRadius.circular(6),
                boxShadow: _isSaving ? null : [BoxShadow(color: _S.primaryContainer.withValues(alpha: 0.3),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP 1 OF 3',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                        color: _S.secondary, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('Basic Health',
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800,
                        color: _S.primaryContainer, letterSpacing: -0.8)),
              ],
            ),
            // Progress dots
            Row(
              children: [
                Container(width: 32, height: 6, decoration: BoxDecoration(
                    color: _S.secondary, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Container(width: 32, height: 6, decoration: BoxDecoration(
                    color: _S.surfContainerHighest, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 4),
                Container(width: 32, height: 6, decoration: BoxDecoration(
                    color: _S.surfContainerHighest, borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── WHY THIS MATTERS CARD ────────────────────────
  Widget _buildWhyCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _S.secondary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Why this matters',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
                  color: _S.primaryContainer)),
          const SizedBox(height: 8),
          Text(
            'In an emergency, medical professionals need your basic physical profile to provide safe and effective treatment. This data is stored securely on your device.',
            style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── SECURITY BADGES ──────────────────────────────
  Widget _buildSecurityBadges() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, size: 20, color: _S.secondary),
              const SizedBox(width: 12),
              Text('SECURE ENCRYPTION',
                  style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                      color: _S.secondary, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: _S.onSurfaceVariant),
              const SizedBox(width: 12),
              Text('Only accessible via lock screen in emergencies.',
                  style: GoogleFonts.outfit(fontSize: 12, color: _S.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  // ── PHYSICAL ATTRIBUTES ──────────────────────────
  Widget _buildPhysicalAttributes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('PHYSICAL ATTRIBUTES'),
        const SizedBox(height: 24),
        // Height
        _inputLabel('HEIGHT'),
        const SizedBox(height: 12),
        _buildTextField(_heightCtrl, "e.g., 5' 10\"", 'INCHES'),
        const SizedBox(height: 24),
        // Weight
        _inputLabel('WEIGHT'),
        const SizedBox(height: 12),
        _buildTextField(_weightCtrl, 'e.g., 165', 'LBS'),
      ],
    );
  }

  // ── MEDICAL SPECIFICATIONS ───────────────────────
  Widget _buildMedicalSpecs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('MEDICAL SPECIFICATIONS'),
        const SizedBox(height: 24),

        // Blood Type
        _inputLabel('BLOOD TYPE'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _S.surfContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonFormField<String>(
            value: _bloodType,
            hint: Text('Select Blood Type',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500,
                    color: _S.onSurfaceVariant)),
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: _S.primaryContainer),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: _S.onSurfaceVariant),
            dropdownColor: _S.surfLowest,
            items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _bloodType = v),
          ),
        ),
        const SizedBox(height: 28),

        // Organ Donor Toggle
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _S.surfContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: _S.surfContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, size: 20, color: _S.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Organ Donor Status',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                            color: _S.primaryContainer)),
                    const SizedBox(height: 2),
                    Text('Are you a registered organ donor?',
                        style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _organDonor,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _organDonor = v);
                },
                activeThumbColor: Colors.white,
                activeTrackColor: _S.secondary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: _S.surfContainerHighest,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── BOTTOM CLINICAL IMAGE ────────────────────────
  Widget _buildBottomImage() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: _S.surfContainerHigh,
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x990F1C2C), Color(0x000F1C2C)],
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x990F1C2C), Color(0x000F1C2C)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: Text(
                  'Building a comprehensive profile saves lives.',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                      color: _S.onPrimary, height: 1.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SHARED HELPERS ───────────────────────────────
  Widget _sectionHeader(String label) {
    return Row(
      children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                color: _S.primaryContainer, letterSpacing: 1.2)),
        const SizedBox(width: 16),
        Expanded(child: Container(height: 1, color: _S.surfContainerHighest)),
      ],
    );
  }

  Widget _inputLabel(String label) {
    return Text(label,
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
            color: _S.onSurfaceVariant, letterSpacing: 1.5));
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, String suffix) {
    return Container(
      decoration: BoxDecoration(
        color: _S.surfContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: _S.primaryContainer),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(fontSize: 14, color: _S.onSurfaceVariant.withValues(alpha: 0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          suffixText: suffix,
          suffixStyle: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
              color: _S.outline, letterSpacing: 1.0),
        ),
      ),
    );
  }
}

