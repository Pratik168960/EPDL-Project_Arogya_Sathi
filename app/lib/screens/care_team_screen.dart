import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'emergency_sos_screen.dart';

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
  static const Color error             = Color(0xFFBA1A1A);
  static const Color errorContainer    = Color(0xFFFFDAD6);
}

// ═══════════════════════════════════════════════
//  MY CARE TEAM SCREEN
//  Phase 2: Firebase Firestore Integration
// ═══════════════════════════════════════════════
class CareTeamScreen extends StatefulWidget {
  const CareTeamScreen({super.key});

  @override
  State<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends State<CareTeamScreen> {
  bool _isSending = false;

  // ── Firestore References ─────────────────────
  CollectionReference<Map<String, dynamic>> get _caregiversRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('caregivers');

  CollectionReference<Map<String, dynamic>> get _alertsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('alerts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle
                    Text('People who receive alerts about your schedule.',
                        style: GoogleFonts.outfit(fontSize: 15, color: _S.onSurfaceVariant, height: 1.4)),
                    const SizedBox(height: 24),

                    // Add Caregiver Button
                    _buildAddButton(),
                    const SizedBox(height: 32),

                    // Active Contacts — STREAM-DRIVEN
                    _buildSectionLabel('ACTIVE CONTACTS'),
                    const SizedBox(height: 20),

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _caregiversRef.orderBy('created_at', descending: false).snapshots(),
                      builder: (context, snapshot) {
                        // Loading
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingState();
                        }

                        // Error
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // Empty state
                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        // Build contact cards from Firestore
                        return _buildContactsList(docs);
                      },
                    ),

                    const SizedBox(height: 48),

                    // Emergency Protocols
                    _buildEmergencySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADING STATE ────────────────────────────────
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _S.secondary),
            ),
            const SizedBox(height: 12),
            Text('Loading contacts...',
                style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ── ERROR STATE ──────────────────────────────────
  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 32, color: _S.error.withValues(alpha: 0.6)),
            const SizedBox(height: 10),
            Text('Failed to load contacts',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600,
                    color: _S.primaryContainer)),
            const SizedBox(height: 4),
            Text(error, textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 11, color: _S.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _S.outlineVariant.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: _S.outlineVariant),
          const SizedBox(height: 16),
          Text('No contacts added yet',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700,
                  color: _S.primaryContainer)),
          const SizedBox(height: 6),
          Text('Tap the button above to add your first\ncarearegiver or emergency contact.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant, height: 1.4)),
        ],
      ),
    );
  }

  // ── CONTACTS LIST (Firestore-driven) ─────────────
  Widget _buildContactsList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final List<Widget> cards = [];

    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data();
      final docId = docs[i].id;
      final name = (data['name'] ?? 'Unknown') as String;
      final phone = (data['phone'] ?? '') as String;
      final relation = (data['relation'] ?? '') as String;
      final isPrimary = i == 0; // First contact is "Primary"

      // Alert toggle states (stored per-doc or default)
      final missedDose = data['alert_missed_dose'] ?? true;
      final hwOffline  = data['alert_hw_offline'] ?? false;
      final monthly    = data['alert_monthly'] ?? true;

      cards.add(_buildContactCard(
        docId: docId,
        name: name,
        phone: phone,
        relation: relation,
        isPrimary: isPrimary,
        missedDose: missedDose as bool,
        hwOffline: hwOffline as bool,
        monthly: monthly as bool,
      ));

      if (i < docs.length - 1) {
        cards.add(const SizedBox(height: 20));
      }
    }

    // Append the "Invite New" card
    cards.add(const SizedBox(height: 20));
    cards.add(_buildInviteCard());

    return Column(children: cards);
  }

  // ── SINGLE CONTACT CARD (reusable, Stitch layout) ─
  Widget _buildContactCard({
    required String docId,
    required String name,
    required String phone,
    required String relation,
    required bool isPrimary,
    required bool missedDose,
    required bool hwOffline,
    required bool monthly,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Left accent strip
          Positioned(left: 0, top: 0, bottom: 0,
            child: Container(width: 4, color: _S.secondary.withValues(alpha: 0.8))),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _S.surfContainer,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700,
                              color: _S.secondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                                  color: _S.primaryContainer)),
                          const SizedBox(height: 6),
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _S.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                                isPrimary
                                    ? 'PRIMARY EMERGENCY CONTACT'
                                    : relation.toUpperCase(),
                                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800,
                                    color: _S.secondary, letterSpacing: 0.3)),
                          ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            // Phone
                            Row(
                              children: [
                                const Icon(Icons.call, size: 14, color: _S.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(phone,
                                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500,
                                          color: _S.onSurfaceVariant)),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Edit
                          GestureDetector(
                            onTap: () => _snack('Edit contact: $name'),
                            child: Text('Edit Contact',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
                                    color: _S.secondary, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Divider
                const SizedBox(height: 24),
                Container(height: 1, color: _S.surfContainer),
                const SizedBox(height: 20),

                // Alert Toggles — wired to Firestore
                _alertToggle(
                  title: 'Receive Missed Dose Alerts',
                  subtitle: 'Immediate notification if a medication window is missed.',
                  value: missedDose,
                  onChanged: (v) => _updateToggle(docId, 'alert_missed_dose', v),
                ),
                const SizedBox(height: 18),
                _alertToggle(
                  title: 'Hardware Offline Alerts',
                  subtitle: 'Notified if the smart dispenser loses connectivity.',
                  value: hwOffline,
                  onChanged: (v) => _updateToggle(docId, 'alert_hw_offline', v),
                ),
                const SizedBox(height: 18),
                _alertToggle(
                  title: 'Monthly Reports',
                  subtitle: 'Detailed adherence summary sent via email every 30 days.',
                  value: monthly,
                  onChanged: (v) => _updateToggle(docId, 'alert_monthly', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Update toggle in Firestore ───────────────────
  Future<void> _updateToggle(String docId, String field, bool value) async {
    HapticFeedback.selectionClick();
    try {
      await _caregiversRef.doc(docId).update({field: value});
    } catch (e) {
      _snack('Failed to update setting');
    }
  }

  // ── INVITE CARD ──────────────────────────────────
  Widget _buildInviteCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _snack('Add new caregiver');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _S.surfContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _S.outlineVariant.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add, size: 24, color: _S.outlineVariant),
            const SizedBox(height: 8),
            Text('Invite New',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _S.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _alertToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _S.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.outfit(fontSize: 11, color: _S.onSurfaceVariant, height: 1.3)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: _S.secondary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _S.surfContainerHighest,
        ),
      ],
    );
  }

  // ── APP BAR ──────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu, color: _S.secondary, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Text('My Care Team',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: -0.5)),
            ],
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _S.secondary, width: 2),
              color: _S.surfContainer,
            ),
            child: const Icon(Icons.person, size: 20, color: _S.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── ADD CAREGIVER BUTTON ─────────────────────────
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _snack('Add new caregiver');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _S.secondary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: _S.secondary.withValues(alpha: 0.15),
              offset: const Offset(0, 8), blurRadius: 24)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(
              child: Text('Add New Caregiver / Emergency Contact',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── SECTION LABEL ────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
              color: _S.onPrimaryContainer, letterSpacing: 1.5)),
    );
  }

  // ── EMERGENCY PROTOCOLS ──────────────────────────
  Widget _buildEmergencySection() {
    return Column(
      children: [
        // Top divider
        Container(height: 2, color: _S.errorContainer.withValues(alpha: 0.3)),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _S.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _S.error.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const Icon(Icons.emergency_outlined, size: 36, color: _S.error),
              const SizedBox(height: 16),
              Text('Emergency Protocols',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800,
                      color: _S.primaryContainer)),
              const SizedBox(height: 8),
              Text(
                'This action will immediately alert all emergency contacts and share your current health profile and location.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 24),

              // SOS Trigger Button — Writes to Firestore
              GestureDetector(
                onTap: _isSending ? null : _triggerSOS,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _S.error, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSending)
                        const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _S.error))
                      else
                        const Icon(Icons.warning, size: 20, color: _S.error),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                            _isSending ? 'SENDING ALERT...' : 'TRIGGER SOS ALERT NOW',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900,
                                color: _S.error, letterSpacing: 1.5)),
                      ),
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

  // ── SOS ACTION — Writes to Firestore ─────────────
  Future<void> _triggerSOS() async {
    HapticFeedback.heavyImpact();
    setState(() => _isSending = true);

    try {
      await _alertsRef.add({
        'type': 'SOS_TRIGGERED',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('🚨 SOS Alert sent to all emergency contacts!',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: _S.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ));

        // Also navigate to SOS screen
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => const EmergencySosScreen()));
      }
    } catch (e) {
      if (mounted) {
        _snack('Failed to send SOS alert: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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

