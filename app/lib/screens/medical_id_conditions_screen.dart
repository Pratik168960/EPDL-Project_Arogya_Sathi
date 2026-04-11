import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'medical_id_contacts_screen.dart';

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
  static const Color secondary         = Color(0xFF006399);
  static const Color onSecondary       = Color(0xFFFFFFFF);
  static const Color onSurface         = Color(0xFF181C1E);
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outlineVariant    = Color(0xFFC4C6CC);
  static const Color error             = Color(0xFFBA1A1A);
  static const Color emerald           = Color(0xFF10B981);
}

// ═══════════════════════════════════════════════
//  MEDICAL ID: CONDITIONS & ALLERGIES (Step 2/3)
//  Phase 3: Firebase Firestore Integration
// ═══════════════════════════════════════════════
class MedicalIdConditionsScreen extends StatefulWidget {
  const MedicalIdConditionsScreen({super.key});

  @override
  State<MedicalIdConditionsScreen> createState() => _MedicalIdConditionsScreenState();
}

class _MedicalIdConditionsScreenState extends State<MedicalIdConditionsScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isLoaded = false;

  final List<String> _commonAllergens = ['Penicillin', 'Latex', 'Peanuts', 'Shellfish', 'Aspirin', 'Sulfa Drugs'];
  final List<String> _chronicConditions = ['Type 2 Diabetes', 'Hypertension', 'Asthma', 'Epilepsy', 'Heart Disease'];

  final Set<String> _selectedAllergies  = {};
  final Set<String> _selectedConditions = {};

  int get _totalSelected => _selectedAllergies.length + _selectedConditions.length;

  // ── Firestore Reference ──────────────────────
  DocumentReference<Map<String, dynamic>> get _conditionsDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('medical_id')
          .doc('conditions');

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Load existing data ───────────────────────────
  Future<void> _loadExistingData() async {
    try {
      final doc = await _conditionsDoc.get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          final allergies = data['allergies'];
          if (allergies is List) {
            _selectedAllergies.addAll(allergies.cast<String>());
          }
          final conditions = data['conditions'];
          if (conditions is List) {
            _selectedConditions.addAll(conditions.cast<String>());
          }
          _isLoaded = true;
        });
      } else {
        if (mounted) setState(() => _isLoaded = true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoaded = true);
      debugPrint('Error loading conditions: $e');
    }
  }

  // ── Save & Continue ──────────────────────────────
  Future<void> _saveAndContinue() async {
    HapticFeedback.selectionClick();
    setState(() => _isSaving = true);

    try {
      await _conditionsDoc.set({
        'allergies': _selectedAllergies.toList(),
        'conditions': _selectedConditions.toList(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Conditions & allergies saved!',
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
            builder: (_) => const MedicalIdContactsScreen()));
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

  void _toggleAllergen(String item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedAllergies.contains(item)) {
        _selectedAllergies.remove(item);
      } else {
        _selectedAllergies.add(item);
      }
    });
  }

  void _toggleCondition(String item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedConditions.contains(item)) {
        _selectedConditions.remove(item);
      } else {
        _selectedConditions.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: !_isLoaded
                  ? const Center(child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: _S.secondary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressHeader(),
                          const SizedBox(height: 32),
                          _buildSearchSection(),
                          const SizedBox(height: 28),
                          _buildChipSection('Common Allergens', _commonAllergens, _selectedAllergies, _toggleAllergen),
                          const SizedBox(height: 24),
                          _buildChipSection('Chronic Conditions', _chronicConditions, _selectedConditions, _toggleCondition),
                          const SizedBox(height: 28),
                          _buildWhyCard(),
                          const SizedBox(height: 28),
                          _buildReviewCard(),
                        ],
                      ),
                    ),
            ),
            _buildBottomBar(),
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
            onTap: _isSaving ? null : _saveAndContinue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _isSaving ? _S.surfContainerHigh : _S.secondary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save &\nContinue',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                          color: _S.onSecondary, height: 1.2)),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SETUP PROGRESS',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _S.onSurfaceVariant, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text('Conditions &\nAllergies',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800,
                          color: _S.primaryContainer, letterSpacing: -0.5, height: 1.1)),
                ],
              ),
            ),
            Text('Step 2\nof 3',
                textAlign: TextAlign.end,
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
                    color: _S.secondary, height: 1.2)),
          ],
        ),
        const SizedBox(height: 16),
        // Progress Bar
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _S.surfContainer,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 2 / 3,
            child: Container(
              decoration: BoxDecoration(
                color: _S.secondary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── SEARCH SECTION ───────────────────────────────
  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search Database',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                color: _S.primaryContainer)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _S.surfContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.outfit(fontSize: 14, color: _S.primaryContainer),
            decoration: InputDecoration(
              hintText: 'Search conditions, allergens, or medications...',
              hintStyle: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant.withValues(alpha: 0.6)),
              prefixIcon: const Icon(Icons.search, color: _S.onSurfaceVariant, size: 22),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── CHIP SELECTION SECTION ───────────────────────
  Widget _buildChipSection(String title, List<String> items, Set<String> selected, Function(String) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                color: _S.primaryContainer)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selected.contains(item);
            return GestureDetector(
              onTap: () => onToggle(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _S.secondary : _S.surfLowest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? _S.secondary : _S.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(item,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500,
                        color: isSelected ? _S.onSecondary : _S.onSurface)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── WHY THIS MATTERS CARD ────────────────────────
  Widget _buildWhyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, size: 20, color: _S.secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why this matters',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                        color: _S.primaryContainer)),
                const SizedBox(height: 6),
                Text(
                  'Accurate medical records allow emergency responders to provide faster, safer treatment by avoiding contraindications.',
                  style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── REVIEW ENTRIES CARD ──────────────────────────
  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 32)],
        border: Border.all(color: _S.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Review Entries',
                  style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800,
                      color: _S.primaryContainer)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _S.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$_totalSelected SELECTED',
                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                        color: _S.secondary, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Active Allergies
          if (_selectedAllergies.isNotEmpty) ...[
            Text('ACTIVE ALLERGIES',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                    color: _S.onSurfaceVariant, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            ..._selectedAllergies.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _reviewEntry(a, _S.error, () {
                setState(() => _selectedAllergies.remove(a));
                HapticFeedback.selectionClick();
              }),
            )),
            const SizedBox(height: 16),
          ],

          // Chronic Conditions
          if (_selectedConditions.isNotEmpty) ...[
            Text('CHRONIC CONDITIONS',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                    color: _S.onSurfaceVariant, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            ..._selectedConditions.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _reviewEntry(c, _S.secondary, () {
                setState(() => _selectedConditions.remove(c));
                HapticFeedback.selectionClick();
              }),
            )),
          ],

          if (_totalSelected == 0) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No items selected yet',
                    style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant)),
              ),
            ),
          ],

          // Footer
          const SizedBox(height: 20),
          Container(height: 1, color: _S.surfContainerHigh),
          const SizedBox(height: 20),
          Text(
            'All entries are encrypted and only accessible to verified medical personnel during emergencies.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 11, color: _S.onSurfaceVariant,
                fontStyle: FontStyle.italic, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _reviewEntry(String label, Color accentColor, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 24, decoration: BoxDecoration(
              color: accentColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600,
                    color: _S.primaryContainer)),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 20, color: _S.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM ACTION BAR ────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _S.surfLowest,
        boxShadow: [BoxShadow(color: Color(0x0D000000), offset: Offset(0, -4), blurRadius: 16)],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _S.surfContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text('Back',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                          color: _S.primaryContainer)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _isSaving ? null : _saveAndContinue,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _isSaving ? _S.surfContainerHigh : _S.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Continue',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                              color: _S.onSecondary)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

