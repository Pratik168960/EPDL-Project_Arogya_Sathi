import 'dart:async';
import '../services/notification_service.dart';
import '../services/fcm_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/alarm_schedule_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/medication_detail_screen.dart';
import '../screens/book_appointment_screen.dart';
import '../screens/adherence_history_screen.dart';
import '../widgets/add_medicine_sheet.dart';

// ═══════════════════════════════════════════════
//  HOME / DASHBOARD SCREEN
// ═══════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToReminders;
  final VoidCallback? onNavigateToRecords;
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({
    super.key,
    this.onNavigateToReminders,
    this.onNavigateToRecords,
    this.onNavigateToProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _waterCount = 5;
  final int _waterGoal = 8;

  Timer? _missedDoseTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Check for missed doses now and every 5 minutes
    FCMService.checkMissedDoses();
    _missedDoseTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => FCMService.checkMissedDoses(),
    );
  }

  @override
  void dispose() {
    _missedDoseTimer?.cancel();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName?.isNotEmpty == true) return user!.displayName!;
    final raw = (user?.email ?? 'User').split('@').first;
    return raw
        .split(RegExp(r'[._\s]+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ── SOS DIALOG ──────────────────────────────
  void _showSOSDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLg)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(kRadiusSm)),
                  child: const Icon(Icons.emergency_outlined, color: AppColors.danger, size: 22),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Emergency SOS',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.danger)),
                  Text('Immediate assistance',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(kRadiusSm)),
                child: Column(children: [
                  _sosAction(Icons.call_outlined,        'Call emergency services (108)'),
                  const Divider(height: 16, color: AppColors.divider),
                  _sosAction(Icons.location_on_outlined, 'Send location to Sneha Sharma'),
                  const Divider(height: 16, color: AppColors.divider),
                  _sosAction(Icons.sms_outlined,         'Send SOS SMS to contacts'),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final url = Uri.parse('tel:108');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        if (mounted) _snack('Could not open phone dialer.');
                      }
                    },
                    child: Text('CALL 108', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sosAction(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 10),
      Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: Container(
          color: const Color(0xFF0F1C2C),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.onNavigateToProfile != null) {
                      widget.onNavigateToProfile!();
                    }
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE0E3E6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuDbTNIq-ipFd7SYWHS-LgQfO9xSx2O3OL4SQKdEMN6MSQx3qLTSnVU5Vyi64zHUVtWNqdTCaFRpMoiYHrGEvE42O1kNr-JPWzyvVYq9_zNW93HnQMgyhXpYzFR7HfhgrzXMdgLD8WTw-UgmJwvFr8FDKdhcvOauMQtLn_Reep8iEcxC5GIlaMtzxe5ul4Cus9TdQT76m60IFWMskQy7TzOfiryhYgkOeQFVbhtlNk0xkEbIbaQhoyIg_ubHxHMe4bYzHObv-b-wEw",
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.blueGrey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _displayName,
                            style: GoogleFonts.manrope(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              letterSpacing: -0.5, color: const Color(0xFFF7FAFD),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PATIENT ID: AS-9942',
                            style: GoogleFonts.publicSans(
                              fontSize: 10, fontWeight: FontWeight.normal,
                              letterSpacing: 2.0, color: const Color(0xFFF7FAFD).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showRecentNotifications(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.0),
                    ),
                    child: const Icon(Icons.notifications_active, color: Color(0xFFF7FAFD), size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 92), // Equals ~16px above NavBar mirroring right-edge margin
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => const AddMedicineSheet(),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF006399),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x4D006399), offset: Offset(0, 8), blurRadius: 24)],
            ),
            child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 30),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Hero Banner
          Container(
            color: const Color(0xFF0F1C2C),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0x33006399),
                border: Border.all(color: const Color(0x4D006399)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF006399),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.alarm, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Dose: 8:00 AM',
                          style: GoogleFonts.manrope(
                            fontSize: 20, fontWeight: FontWeight.bold,
                            letterSpacing: -0.5, color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Metformin 500mg • 1 Capsule',
                          style: GoogleFonts.publicSans(
                            fontSize: 14, color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.4), size: 24),
                ],
              ),
            ),
          ),
          
          // Overlapping Main Content (-mt-6 equivalent)
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _quickActionButton(Icons.event_available, 'BOOK APPT', const Color(0xFF006399), () {
                        HapticFeedback.selectionClick();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BookAppointmentScreen()));
                      }),
                      _quickActionButton(Icons.note_add, 'ADD RECORD', const Color(0xFF006399), widget.onNavigateToRecords ?? () {}),
                      _quickActionButton(Icons.medication, 'MEDICINES', const Color(0xFF006399), widget.onNavigateToReminders ?? () {}),
                      _quickActionButton(Icons.emergency, 'EMERGENCY', const Color(0xFFBA1A1A), _showSOSDialog),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Today's Medications Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "TODAY'S MEDICATIONS",
                        style: GoogleFonts.manrope(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F1C2C), letterSpacing: 2.8,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onNavigateToReminders,
                        child: Text(
                          'VIEW ALL',
                          style: GoogleFonts.publicSans(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: const Color(0xFF006399), letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Dynamic Med List
                  _buildLiveMedications(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
            ),
            child: Center(
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: color == const Color(0xFFBA1A1A) ? color : const Color(0xFF44474C),
              letterSpacing: 1.0, 
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthBox(String label, String value, String unit, bool activeBorder) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F7),
        borderRadius: BorderRadius.circular(12),
        border: activeBorder ? const Border(left: BorderSide(color: Color(0xFF006399), width: 4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: const Color(0xFF44474C), letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F1C2C),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F1C2C).withValues(alpha: 0.5),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  // ── LIVE MEDICATIONS (Firebase + Dismissible) ──
  // *** ALL FIREBASE LOGIC PRESERVED EXACTLY ***
  Widget _buildLiveMedications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('medications')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _emptyMedState(),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.white, size: 22),
                      const SizedBox(height: 2),
                      Text('Remove', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
                onDismissed: (direction) async {
                  // *** NOTIFICATION CANCEL — PRESERVED ***
                  if (data.containsKey('alarm_id')) {
                    await NotificationService.cancelSpecificAlarm(data['alarm_id']);
                    await AlarmScheduleService.deleteAlarm(data['alarm_id']);
                  }
                  // *** FIREBASE DELETE — PRESERVED ***
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(AuthService.currentUserId!)
                      .collection('medications')
                      .doc(doc.id)
                      .delete();
                },
                child: _medRow(data, doc.id),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _medRow(Map<String, dynamic> data, String docId) {
    String timeRaw = data['time']?.toString() ?? '--:-- AM';
    String mainTime = timeRaw;
    String period = '';
    final parts = timeRaw.split(' ');
    if (parts.length > 1) {
      mainTime = parts[0];
      period = parts[1];
    } else {
      final ampmMatches = RegExp(r'[a-zA-Z]+').allMatches(timeRaw);
      if(ampmMatches.isNotEmpty) {
          period = ampmMatches.first.group(0) ?? '';
          mainTime = timeRaw.replaceAll(period, '').trim();
      }
    }
    
    // Evaluate taken state based on firestore data
    bool isTaken = data['isTaken'] ?? false;
    bool isReminderOn = data['isReminderOn'] ?? true;

    return GestureDetector(
      onTap: () {
        // Toggle the physical 'Taken' status, which rules the checkmark and strikethrough
        FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('medications')
          .doc(docId)
          .update({'isTaken': !isTaken});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
        decoration: BoxDecoration(
          color: isTaken ? const Color(0xFFFFFFFF).withValues(alpha: 0.6) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: isTaken ? null : const Border(left: BorderSide(color: Color(0xFF006399), width: 3)),
          boxShadow: const [BoxShadow(color: Color(0x080F1C2C), offset: Offset(0, 8), blurRadius: 24)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      Text(
                        mainTime,
                        style: GoogleFonts.manrope(
                          fontSize: 13, fontWeight: FontWeight.bold,
                          color: const Color(0xFF44474C),
                        ),
                      ),
                      Text(
                        period.toUpperCase(),
                        style: GoogleFonts.publicSans(
                          fontSize: 10, color: Colors.blueGrey.shade400,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data['name'] ?? ''} ${data['dosage'] ?? ''}'.trim(),
                      style: GoogleFonts.manrope(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F1C2C),
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      data['meal'] ?? data['frequency'] ?? 'Medication',
                      style: GoogleFonts.publicSans(
                        fontSize: 12, color: const Color(0xFF44474C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Color(0xFFC4C6CC), size: 24),
                  onPressed: () {
                    // Navigate to detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicationDetailScreen(data: data, docId: docId),
                      ),
                    );
                  },
                ),
                if (isTaken)
                  const Icon(Icons.check_circle, color: Color(0xFF006399), size: 28)
                else
                  Switch.adaptive(
                    value: isReminderOn,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF006399),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    onChanged: (val) {
                      FirebaseFirestore.instance
                        .collection('users')
                        .doc(AuthService.currentUserId!)
                        .collection('medications')
                        .doc(docId)
                        .update({'isReminderOn': val});
                        
                      if (!val && data.containsKey('alarm_id')) {
                        NotificationService.cancelSpecificAlarm(data['alarm_id']);
                        AlarmScheduleService.deactivateAlarm(data['alarm_id']);
                      } else if (val && data.containsKey('alarm_id')) {
                        AlarmScheduleService.activateAlarm(data['alarm_id']);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyMedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
      ),
      child: Column(children: [
        const Icon(Icons.medical_services_outlined, size: 28, color: Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text('No medications scheduled',
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text('Add medicines in Reminders tab',
            style: GoogleFonts.publicSans(fontSize: 11, color: const Color(0xFF94A3B8))),
      ]),
    );
  }

  // ── APPOINTMENTS — Firestore ──────────────────
  Widget _buildAppointments() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('appointments')
          .orderBy('date_time')
          .limit(2)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kRadius),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(children: [
                const Icon(Icons.event_outlined, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Text('No upcoming appointments',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
              ]),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final doctorName = data['doctor_name'] as String? ?? 'Doctor';
            final specialty = data['specialty'] as String? ?? '';
            final hospital = data['hospital'] as String? ?? '';
            final durationMin = data['duration_minutes'] as int? ?? 30;
            DateTime dateTime;
            final dtField = data['date_time'];
            if (dtField is Timestamp) {
              dateTime = dtField.toDate();
            } else {
              dateTime = DateTime.now();
            }

            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: _apptCardFromData(
                doctorName: doctorName,
                specialty: specialty,
                hospital: hospital,
                dateTime: dateTime,
                durationMinutes: durationMin,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _apptCardFromData({
    required String doctorName,
    required String specialty,
    required String hospital,
    required DateTime dateTime,
    required int durationMinutes,
  }) {
    final day   = DateFormat('dd').format(dateTime);
    final month = DateFormat('MMM').format(dateTime);
    final time  = DateFormat('h:mm a').format(dateTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x050C1E35), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date pill
        Container(
          width: 56, padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(day,   style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy, height: 1)),
            Text(month, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doctorName,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('$specialty · $hospital',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text('$time · $durationMinutes min',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.navy)),
          ]),
        ),
      ]),
    );
  }

  // ── HYDRATION ────────────────────────────────
  Widget _buildHydrationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Daily Goal: 2 Litres',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            Text('${((_waterCount / _waterGoal) * 100).round()}% complete',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _waterCount / _waterGoal,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.teal),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_waterGoal, (i) => WaterCup(
              filled: i < _waterCount,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _waterCount = (i < _waterCount) ? i : i + 1;
                });
              },
            )),
          ),
        ]),
      ),
    );
  }

  // ── CLINICAL INSIGHT ─────────────────────────
  Widget _buildInsightCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: AppColors.cardShadow,
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.12)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(kRadiusSm)),
            child: const Icon(Icons.lightbulb_outline, color: AppColors.teal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('TIP OF THE DAY',
                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.teal, letterSpacing: 1.2)),
              ]),
              const SizedBox(height: 6),
              Text(
                'Eating fiber-rich foods like dal, sabzi, and whole grains helps regulate blood sugar and keeps your gut healthy. Aim for 25–30g of fiber daily for best results.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary, height: 1.55),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── SOS BAR ──────────────────────────────────
  Widget _buildSOSBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showSOSDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: AppColors.danger, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)],
              ),
            ),
            const SizedBox(width: 10),
            Text('EMERGENCY SOS',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
            Text(' — CALL 108',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger)),
          ]),
        ),
      ),
    );
  }

  void _showRecentNotifications() {
    final uid = AuthService.currentUserId ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.navy, size: 24),
                  const SizedBox(width: 12),
                  Text('Recent Activity', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users').doc(uid).collection('history')
                    .orderBy('taken_at', descending: true)
                    .limit(15)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return Center(child: Text('No recent activity', style: GoogleFonts.outfit(color: Colors.grey)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: snap.data!.docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                      final name = d['name'] ?? 'Medicine';
                      final status = d['status'] ?? 'Unknown';
                      final isTaken = status == 'Taken';
                      return ListTile(
                        leading: Icon(
                          isTaken ? Icons.check_circle : Icons.warning_rounded,
                          color: isTaken ? const Color(0xFF2E7D32) : const Color(0xFFBA1A1A),
                        ),
                        title: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(status, style: GoogleFonts.outfit(fontSize: 12, color: isTaken ? const Color(0xFF2E7D32) : const Color(0xFFBA1A1A))),
                        trailing: Text(
                          d['scheduled_time'] ?? '',
                          style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.navy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }
}

