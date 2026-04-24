import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens (exact from HTML)
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
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outline           = Color(0xFF74777D);
  static const Color error             = Color(0xFFBA1A1A);
  static const Color onError           = Color(0xFFFFFFFF);
}

// ═══════════════════════════════════════════════
//  EMERGENCY SOS SCREEN
// ═══════════════════════════════════════════════
class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _countdownController;
  int _seconds = 5;
  bool _cancelled = false;
  bool _alertWritten = false;

  String get _uid => AuthService.currentUserId ?? '';

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

  CollectionReference<Map<String, dynamic>> get _alertsRef =>
      FirebaseFirestore.instance
          .collection('users').doc(_uid)
          .collection('alerts');

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        final newSeconds = 5 - (_countdownController.value * 5).floor();
        if (newSeconds != _seconds && newSeconds >= 0) {
          setState(() => _seconds = newSeconds);
          HapticFeedback.heavyImpact();
        }
      })..addStatusListener((status) async {
        if (status == AnimationStatus.completed && !_cancelled && !_alertWritten) {
          _alertWritten = true;
          // 1. Write to patient's own alerts
          await _alertsRef.add({
            'type': 'SOS_TRIGGERED',
            'message': 'Emergency SOS was triggered!',
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'active',
          });
          // 2. Notify all linked caregivers 
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
          final caregiverUids = List<String>.from(userDoc.data()?['linked_caregivers'] ?? []);
          final patientName = userDoc.data()?['name'] ?? userDoc.data()?['email']?.toString().split('@').first ?? 'Patient';
          for (final cgUid in caregiverUids) {
            await FirebaseFirestore.instance
                .collection('users').doc(cgUid)
                .collection('alerts')
                .add({
              'type': 'SOS_ALERT',
              'message': '🚨 $patientName triggered an Emergency SOS!',
              'medicine': '',
              'patient_uid': _uid,
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
            });
          }
        }
      });
    _countdownController.forward();
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  void _cancelSos() {
    _countdownController.stop();
    setState(() => _cancelled = true);
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

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
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  children: [
                    _buildSosButton(),
                    const SizedBox(height: 32),
                    _buildStatusText(),
                    const SizedBox(height: 48),
                    _buildMedicalIdSnapshot(),
                    const SizedBox(height: 32),
                    _buildEmergencyContacts(),
                    const SizedBox(height: 48),
                    _buildQuickActions(),
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
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, color: _S.secondary, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Text('Emergency SOS',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: -0.3)),
            ],
          ),
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: _S.error, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('LIVE PROTOCOL',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                      color: _S.onSurfaceVariant, letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  // ── SOS COUNTDOWN BUTTON ─────────────────────────
  Widget _buildSosButton() {
    return AnimatedBuilder(
      animation: _countdownController,
      builder: (context, child) {
        final progress = _countdownController.value;
        return SizedBox(
          width: 220, height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              CustomPaint(
                size: const Size(220, 220),
                painter: _RingPainter(
                  progress: progress,
                  bgColor: _S.surfContainerHighest,
                  fgColor: _S.error,
                ),
              ),
              // Central button
              Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  color: _S.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _S.error.withValues(alpha: 0.3),
                      offset: const Offset(0, 12),
                      blurRadius: 48,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$_seconds',
                        style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800,
                            color: _S.onError)),
                    Text('SECONDS',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                            color: _S.onError.withValues(alpha: 0.8), letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── STATUS TEXT ───────────────────────────────────
  Widget _buildStatusText() {
    return Column(
      children: [
        Text('Protocol Initiated',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700,
                color: _S.primaryContainer)),
        const SizedBox(height: 8),
        SizedBox(
          width: 280,
          child: Text(
            'Sending alert to emergency services and 3 caregivers...',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, color: _S.onSurfaceVariant, height: 1.5),
          ),
        ),
      ],
    );
  }

  // ── MEDICAL ID SNAPSHOT — Firestore ─────────────
  Widget _buildMedicalIdSnapshot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MEDICAL ID SNAPSHOT',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                color: _S.onPrimaryContainer, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
          future: Future.wait([_basicHealthDoc.get(), _conditionsDoc.get()]),
          builder: (context, snap) {
            final basicData = snap.data?[0].data();
            final condData  = snap.data?[1].data();
            final bloodType  = basicData?['blood_type'] as String? ?? '—';
            final allergies  = (condData?['allergies']  as List?)?.cast<String>() ?? [];
            final conditions = (condData?['conditions'] as List?)?.cast<String>() ?? [];

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _S.surfLowest,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: _S.secondary, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blood Type
                  Text('BLOOD TYPE',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _S.onSurfaceVariant, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(bloodType,
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700,
                          color: _S.error)),
                  const SizedBox(height: 20),

                  // Allergies
                  Text('ALLERGIES',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _S.onSurfaceVariant, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  allergies.isEmpty
                      ? Text('None recorded',
                          style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant))
                      : Wrap(
                          spacing: 8, runSpacing: 6,
                          children: allergies.map((a) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _S.surfContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(a,
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500,
                                    color: _S.primaryContainer)),
                          )).toList(),
                        ),
                  const SizedBox(height: 20),

                  // Chronic Conditions
                  Text('CHRONIC CONDITIONS',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _S.onSurfaceVariant, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(
                    conditions.isEmpty ? 'None recorded' : conditions.join(', '),
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,
                        color: _S.primaryContainer),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── EMERGENCY CONTACTS — Firestore StreamBuilder ─
  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('EMERGENCY CONTACTS',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700,
                color: _S.onPrimaryContainer, letterSpacing: 1.5)),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _caregiversRef.orderBy('created_at').limit(3).snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _S.surfContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('No emergency contacts added.',
                    style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant)),
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
                  child: _contactTile(
                    name: name,
                    subtitle: '${isPrimary ? 'Primary Caregiver' : 'Emergency'} • $relation',
                    statusLabel: isPrimary ? 'NOTIFIED' : 'IN QUEUE',
                    statusBg: isPrimary
                        ? _S.secondary.withValues(alpha: 0.1)
                        : _S.onSurfaceVariant.withValues(alpha: 0.1),
                    statusText: isPrimary ? _S.secondary : _S.onSurfaceVariant,
                    trailingIcon: isPrimary ? Icons.check_circle : Icons.schedule,
                    trailingColor: isPrimary ? _S.secondary : _S.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _contactTile({
    required String name,
    required String subtitle,
    required String statusLabel,
    required Color statusBg,
    required Color statusText,
    required IconData trailingIcon,
    required Color trailingColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Avatar with first-letter initial
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _S.surfContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                    color: _S.secondary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700,
                        color: _S.primaryContainer)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.outfit(fontSize: 11, color: _S.onSurfaceVariant)),
              ],
            ),
          ),
          // Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statusLabel,
                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                        color: statusText, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 20, color: trailingColor),
            ],
          ),
        ],
      ),
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      children: [
        // Call Emergency Services
        GestureDetector(
          onTap: () async {
            HapticFeedback.heavyImpact();
            final url = Uri.parse('tel:108');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Could not open phone dialer', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  backgroundColor: _S.error,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            }
          },
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: _S.secondary,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: _S.secondary.withValues(alpha: 0.25), offset: const Offset(0, 8), blurRadius: 24),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.call, size: 20, color: Colors.white),
                const SizedBox(width: 12),
                Text('Call Emergency Services',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Call Primary Caregiver
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _caregiversRef.orderBy('created_at').limit(1).get(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) return const SizedBox.shrink();
            final data = docs.first.data();
            final name = data['name'] as String? ?? 'Caregiver';
            final phone = data['phone'] as String? ?? '';
            if (phone.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () async {
                HapticFeedback.heavyImpact();
                final url = Uri.parse('tel:$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: _S.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_in_talk, size: 20, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Call $name',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Cancel SOS
        GestureDetector(
          onTap: _cancelSos,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: _S.surfContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close, size: 20, color: _S.primaryContainer),
                const SizedBox(width: 12),
                Text('Cancel SOS',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700,
                        color: _S.primaryContainer)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
//  Countdown Ring Painter
// ═══════════════════════════════════════════════
class _RingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  _RingPainter({required this.progress, required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    canvas.drawCircle(center, radius,
        Paint()..color = bgColor..style = PaintingStyle.stroke..strokeWidth = 6);

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = fgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

