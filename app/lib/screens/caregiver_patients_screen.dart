import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════
//  Design Tokens
// ═══════════════════════════════════════════════
class _C {
  static const Color surface      = Color(0xFFF7FAFD);
  static const Color navy         = Color(0xFF0F1C2C);
  static const Color teal         = Color(0xFF00897B);
  static const Color tealLight    = Color(0xFFE0F2F1);
  static const Color blue         = Color(0xFF006399);
  static const Color onSurface    = Color(0xFF181C1E);
  static const Color onSurfVar    = Color(0xFF44474C);
  static const Color outline      = Color(0xFFC4C6CC);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color danger       = Color(0xFFBA1A1A);
  static const Color success      = Color(0xFF2E7D32);
}

/// ═══════════════════════════════════════════════
///  CAREGIVER PATIENTS SCREEN
///  - Link patients via share code
///  - View linked patients
///  - Tap to view/manage their medications
/// ═══════════════════════════════════════════════
class CaregiverPatientsScreen extends StatefulWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  State<CaregiverPatientsScreen> createState() => _CaregiverPatientsScreenState();
}

class _CaregiverPatientsScreenState extends State<CaregiverPatientsScreen> {
  List<String> _patientUids = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    final uids = await AuthService.getLinkedPatients();
    setState(() {
      _patientUids = uids;
      _loading = false;
    });
  }

  void _showLinkDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Link a Patient',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit share code from your patient\'s profile.',
              style: GoogleFonts.outfit(fontSize: 13, color: _C.onSurfVar)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 28, fontWeight: FontWeight.w800,
                letterSpacing: 8, color: _C.navy,
              ),
              decoration: InputDecoration(
                hintText: 'A3X7K9',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 28, fontWeight: FontWeight.w300,
                  letterSpacing: 8, color: _C.outline,
                ),
                counterText: '',
                filled: true,
                fillColor: _C.tealLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
              style: GoogleFonts.outfit(color: _C.onSurfVar)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _linkPatient(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Link', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _linkPatient(String code) async {
    if (code.trim().length != 6) {
      _showSnack('Please enter a valid 6-digit code', isError: true);
      return;
    }
    try {
      final email = await AuthService.linkToPatient(code);
      _showSnack('Linked to $email ✓');
      _loadPatients();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  Future<void> _unlinkPatient(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unlink Patient?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('You will no longer be able to manage this patient\'s medications.',
          style: GoogleFonts.outfit(color: _C.onSurfVar)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: _C.onSurfVar)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.danger, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Unlink', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.unlinkPatient(uid);
      _loadPatients();
      _showSnack('Patient unlinked');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? _C.danger : _C.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: _C.navy,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text('My Patients',
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
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50, right: 20),
                    child: Icon(Icons.people_alt_rounded,
                      size: 80, color: Colors.white.withValues(alpha: 0.06)),
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
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => _patientCard(_patientUids[index]),
                  childCount: _patientUids.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLinkDialog,
        backgroundColor: _C.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.link_rounded),
        label: Text('Link Patient',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
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
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _C.tealLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.person_add_rounded, color: _C.teal, size: 40),
            ),
            const SizedBox(height: 24),
            Text('No patients linked yet',
              style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w700, color: _C.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Ask your patient for their 6-digit share code\nfrom their Profile → Share Code section.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: _C.onSurfVar, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(String patientUid) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getPatientProfile(patientUid),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final email = data?['email'] ?? 'Loading...';
        final name = data?['name'] ?? email.toString().split('@').first;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => _PatientDetailScreen(
                    patientUid: patientUid, patientName: name,
                  ),
                ));
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_C.teal, Color(0xFF26A69A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(
                            fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
                          ),
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
                            style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w700, color: _C.onSurface,
                            )),
                          const SizedBox(height: 2),
                          Text(email,
                            style: GoogleFonts.outfit(fontSize: 12, color: _C.onSurfVar)),
                        ],
                      ),
                    ),
                    // Actions
                    IconButton(
                      onPressed: () => _unlinkPatient(patientUid),
                      icon: const Icon(Icons.link_off_rounded, color: _C.danger, size: 20),
                      tooltip: 'Unlink',
                    ),
                    const Icon(Icons.chevron_right_rounded, color: _C.outline),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PATIENT DETAIL — Caregiver views/manages patient's meds
// ═══════════════════════════════════════════════════════════
class _PatientDetailScreen extends StatelessWidget {
  final String patientUid;
  final String patientName;

  const _PatientDetailScreen({
    required this.patientUid,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final medsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(patientUid)
        .collection('medications');

    final historyRef = FirebaseFirestore.instance
        .collection('users')
        .doc(patientUid)
        .collection('history');

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _C.surface,
        appBar: AppBar(
          backgroundColor: _C.navy,
          foregroundColor: Colors.white,
          title: Text(patientName,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          bottom: TabBar(
            indicatorColor: _C.teal,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(icon: Icon(Icons.medication_outlined), text: 'Medications'),
              Tab(icon: Icon(Icons.history_rounded), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMedicationsList(medsRef),
            _buildHistoryList(historyRef),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMedicationDialog(context, medsRef),
          backgroundColor: _C.teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: Text('Add Medicine',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildMedicationsList(CollectionReference medsRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: medsRef.orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _C.teal));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No medications yet',
              style: GoogleFonts.outfit(fontSize: 16, color: _C.onSurfVar)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: _C.tealLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_rounded,
                      color: _C.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name'] ?? 'Medicine',
                          style: GoogleFonts.outfit(
                            fontSize: 15, fontWeight: FontWeight.w700, color: _C.onSurface)),
                        Text('${d['dosage'] ?? ''} • ${d['time'] ?? ''}',
                          style: GoogleFonts.outfit(fontSize: 12, color: _C.onSurfVar)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: _C.danger, size: 20),
                    onPressed: () => docs[i].reference.delete(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryList(CollectionReference historyRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: historyRef.orderBy('taken_at', descending: true).limit(50).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _C.teal));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No history yet',
              style: GoogleFonts.outfit(fontSize: 16, color: _C.onSurfVar)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final ts = d['taken_at'] as Timestamp?;
            final dateStr = ts != null
                ? '${ts.toDate().day}/${ts.toDate().month} ${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                : '';
            final status = d['status'] ?? 'Unknown';
            final isGood = status.toString().toLowerCase().contains('taken');

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isGood ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isGood ? _C.success : _C.danger, size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d['name'] ?? 'Medicine',
                          style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.w600, color: _C.onSurface)),
                        Text('$status • $dateStr',
                          style: GoogleFonts.outfit(fontSize: 11, color: _C.onSurfVar)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddMedicationDialog(BuildContext context, CollectionReference medsRef) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final timeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Medicine for $patientName',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameCtrl, 'Medicine Name', Icons.medication_outlined),
              const SizedBox(height: 12),
              _dialogField(dosageCtrl, 'Dosage (e.g. 500mg)', Icons.scale_outlined),
              const SizedBox(height: 12),
              _dialogField(timeCtrl, 'Time (e.g. 8:00 AM)', Icons.access_time_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: _C.onSurfVar)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await medsRef.add({
                'name': nameCtrl.text.trim(),
                'dosage': dosageCtrl.text.trim(),
                'time': timeCtrl.text.trim(),
                'frequency': 'Once daily',
                'meal': 'After food',
                'added_by': 'caregiver',
                'created_at': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.teal, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Add', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: _C.outline),
        prefixIcon: Icon(icon, color: _C.teal, size: 20),
        filled: true,
        fillColor: _C.tealLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
