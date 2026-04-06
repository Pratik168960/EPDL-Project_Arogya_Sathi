import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
}

// ═══════════════════════════════════════════════
//  MEDICAL ID: EMERGENCY CONTACTS (Step 3/3)
// ═══════════════════════════════════════════════
class MedicalIdContactsScreen extends StatefulWidget {
  const MedicalIdContactsScreen({super.key});

  @override
  State<MedicalIdContactsScreen> createState() => _MedicalIdContactsScreenState();
}

class _MedicalIdContactsScreenState extends State<MedicalIdContactsScreen> {
  final _primaryNameCtrl  = TextEditingController(text: 'Sarah Jenkins');
  final _primaryPhoneCtrl = TextEditingController(text: '+1 (555) 000-0000');
  String _primaryRelation = 'Spouse';

  final _secondaryNameCtrl  = TextEditingController(text: 'Michael Jenkins');
  final _secondaryPhoneCtrl = TextEditingController(text: '+1 (555) 123-4567');
  String _secondaryRelation = 'Sibling';

  bool _showOnLockScreen = true;

  final _relations = ['Spouse', 'Parent', 'Sibling', 'Child', 'Friend', 'Other'];

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
              child: SingleChildScrollView(
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
            onTap: () {
              HapticFeedback.selectionClick();
              _snack('Medical ID saved successfully!');
              // Pop all the way back to Profile
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _S.primaryContainer,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: _S.primaryContainer.withOpacity(0.3),
                    offset: const Offset(0, 4), blurRadius: 12)],
              ),
              child: Text('Save &\nContinue',
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: _S.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
