import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════
//  Design Tokens
// ═══════════════════════════════════════════════
class _C {
  static const Color surface   = Color(0xFFF7FAFD);
  static const Color navy      = Color(0xFF0F1C2C);
  static const Color teal      = Color(0xFF00897B);
  static const Color tealLight = Color(0xFFE0F2F1);
  static const Color onSurface = Color(0xFF181C1E);
  static const Color onSurfVar = Color(0xFF44474C);
  static const Color outline   = Color(0xFFC4C6CC);
  static const Color white     = Color(0xFFFFFFFF);
  static const Color danger    = Color(0xFFBA1A1A);
  static const Color dangerBg  = Color(0xFFFFEBEE);
  static const Color success   = Color(0xFF2E7D32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color warning   = Color(0xFFE65100);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color infoBg    = Color(0xFFE3F2FD);
  static const Color info      = Color(0xFF1565C0);
}

/// ═══════════════════════════════════════════════
///  CAREGIVER ALERTS SCREEN
///  Real-time feed of events from linked patients:
///    - Medication taken (history)
///    - Missed doses
///    - SOS alerts
///    - Dispenser failures
/// ═══════════════════════════════════════════════
class CaregiverAlertsScreen extends StatefulWidget {
  const CaregiverAlertsScreen({super.key});

  @override
  State<CaregiverAlertsScreen> createState() => _CaregiverAlertsScreenState();
}

class _CaregiverAlertsScreenState extends State<CaregiverAlertsScreen> {
  List<String> _patientUids = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uids = await AuthService.getLinkedPatients();
    setState(() {
      _patientUids = uids;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: _C.navy,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text('Alerts & Activity',
                style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                )),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF0F1C2C), Color(0xFF1A3A5C)],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _C.teal)),
            )
          else if (_patientUids.isEmpty)
            SliverFillRemaining(child: _emptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _patientUids.map((uid) => _patientAlertSection(uid)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _C.tealLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.notifications_none_rounded,
                color: _C.teal, size: 36),
            ),
            const SizedBox(height: 20),
            Text('No alerts yet',
              style: GoogleFonts.outfit(
                fontSize: 18, fontWeight: FontWeight.w700, color: _C.onSurface)),
            const SizedBox(height: 8),
            Text('Link a patient to see their activity here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: _C.onSurfVar)),
          ],
        ),
      ),
    );
  }

  /// Stream alerts + history for one patient
  Widget _patientAlertSection(String patientUid) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getPatientProfile(patientUid),
      builder: (context, profileSnap) {
        final name = profileSnap.data?['email']?.toString().split('@').first ?? 'Patient';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient header
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 8),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _C.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(name[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(name,
                    style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _C.onSurface)),
                ],
              ),
            ),

            // Medication history stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(patientUid)
                  .collection('history')
                  .orderBy('taken_at', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 42, bottom: 16),
                    child: Text('No recent activity',
                      style: GoogleFonts.outfit(fontSize: 12, color: _C.outline)),
                  );
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _alertTile(d);
                  }).toList(),
                );
              },
            ),

            // SOS alerts stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users').doc(patientUid)
                  .collection('alerts')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _sosTile(d);
                  }).toList(),
                );
              },
            ),

            const Divider(height: 32),
          ],
        );
      },
    );
  }

  Widget _alertTile(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'Unknown';
    final name = data['name'] ?? 'Medicine';
    final ts = data['taken_at'] as Timestamp?;
    final timeStr = ts != null
        ? '${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';
    final dateStr = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}'
        : '';

    final isTaken = status.toLowerCase().contains('taken');

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 42),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTaken ? _C.successBg : _C.warningBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isTaken ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: isTaken ? _C.success : _C.warning, size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _C.onSurface)),
                Text('$status • $timeStr $dateStr',
                  style: GoogleFonts.outfit(fontSize: 11, color: _C.onSurfVar)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sosTile(Map<String, dynamic> data) {
    final type = data['type'] ?? 'SOS';
    final msg = data['message'] ?? 'Emergency alert triggered';
    final ts = data['timestamp'] as Timestamp?;
    final timeStr = ts != null
        ? '${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 42),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: _C.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🚨 $type',
                  style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.w800, color: _C.danger)),
                Text('$msg • $timeStr',
                  style: GoogleFonts.outfit(fontSize: 11, color: _C.onSurfVar)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
