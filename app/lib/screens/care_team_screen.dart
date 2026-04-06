import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
// ═══════════════════════════════════════════════
class CareTeamScreen extends StatefulWidget {
  const CareTeamScreen({super.key});

  @override
  State<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends State<CareTeamScreen> {
  bool _missedDoseAlerts = true;
  bool _hardwareOffline  = false;
  bool _monthlyReports   = true;

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

                    // Active Contacts
                    _buildSectionLabel('ACTIVE CONTACTS'),
                    const SizedBox(height: 20),

                    // Primary Contact Card
                    _buildPrimaryContactCard(),
                    const SizedBox(height: 20),

                    // Secondary + Invite Row
                    _buildSecondaryRow(),
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
          boxShadow: [BoxShadow(color: _S.secondary.withOpacity(0.15),
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

  // ── PRIMARY CONTACT CARD ─────────────────────────
  Widget _buildPrimaryContactCard() {
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
            child: Container(width: 4, color: _S.secondary.withOpacity(0.8))),

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
                      child: const Icon(Icons.person, size: 28, color: _S.onSurfaceVariant),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sarah Jenkins',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                                  color: _S.primaryContainer)),
                          const SizedBox(height: 6),
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _S.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('PRIMARY EMERGENCY CONTACT',
                                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800,
                                    color: _S.secondary, letterSpacing: 0.3)),
                          ),
                          const SizedBox(height: 8),
                          // Phone
                          Row(
                            children: [
                              const Icon(Icons.call, size: 14, color: _S.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Text('+1 (555) 012-3456',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500,
                                      color: _S.onSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Edit
                          GestureDetector(
                            onTap: () => _snack('Edit contact'),
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

                // Alert Toggles
                _alertToggle(
                  title: 'Receive Missed Dose Alerts',
                  subtitle: 'Immediate notification if a medication window is missed.',
                  value: _missedDoseAlerts,
                  onChanged: (v) => setState(() => _missedDoseAlerts = v),
                ),
                const SizedBox(height: 18),
                _alertToggle(
                  title: 'Hardware Offline Alerts',
                  subtitle: 'Notified if the smart dispenser loses connectivity.',
                  value: _hardwareOffline,
                  onChanged: (v) => setState(() => _hardwareOffline = v),
                ),
                const SizedBox(height: 18),
                _alertToggle(
                  title: 'Monthly Reports',
                  subtitle: 'Detailed adherence summary sent via email every 30 days.',
                  value: _monthlyReports,
                  onChanged: (v) => setState(() => _monthlyReports = v),
                ),
              ],
            ),
          ),
        ],
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
          onChanged: (v) {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
          activeColor: Colors.white,
          activeTrackColor: _S.secondary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: _S.surfContainerHighest,
        ),
      ],
    );
  }

  // ── SECONDARY ROW ────────────────────────────────
  Widget _buildSecondaryRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dr. Michael Chen card
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _S.surfContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _S.surfContainerHigh,
                      ),
                      child: const Icon(Icons.person, size: 22, color: _S.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dr. Michael Chen',
                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: _S.primaryContainer)),
                          Text('PHYSICIAN',
                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500,
                                  color: _S.onSurfaceVariant, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _snack('View details'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _S.surfLowest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('View Details',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                            color: _S.secondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Invite New card
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _S.surfContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _S.outlineVariant.withOpacity(0.3),
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
        ),
      ],
    );
  }

  // ── EMERGENCY PROTOCOLS ──────────────────────────
  Widget _buildEmergencySection() {
    return Column(
      children: [
        // Top divider
        Container(height: 2, color: _S.errorContainer.withOpacity(0.3)),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _S.errorContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _S.error.withOpacity(0.1)),
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

              // SOS Trigger Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const EmergencySosScreen()));
                },
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
                        const Icon(Icons.warning, size: 20, color: _S.error),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text('TRIGGER SOS ALERT NOW',
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
