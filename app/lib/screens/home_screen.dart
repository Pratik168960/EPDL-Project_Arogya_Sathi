import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

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
  int _waterCount = DummyData.waterGlassesDone;
  final int _waterGoal = DummyData.waterGlassesGoal;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ── SOS DIALOG ──────────────────────────────
  void _showSOSDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('🚨 SOS sent — calling 108 & alerting contacts',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.danger,
                        duration: const Duration(seconds: 4),
                      ));
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

  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20, bottom: 100),
              children: [
                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      QuickActionItem(icon: Icons.calendar_today_outlined, label: 'Book Appt.', bgColor: AppColors.tealPale,   iconColor: AppColors.teal,    onTap: () => _snack('Opening appointment booking...')),
                      QuickActionItem(icon: Icons.note_add_outlined,        label: 'Add Record', bgColor: AppColors.successBg,  iconColor: AppColors.success, onTap: widget.onNavigateToRecords ?? () {}),
                      QuickActionItem(icon: Icons.medication_outlined,      label: 'Medicines',  bgColor: AppColors.warningBg,  iconColor: AppColors.warning, onTap: widget.onNavigateToReminders ?? () {}),
                      QuickActionItem(icon: Icons.emergency_share_outlined, label: 'Emergency',  bgColor: AppColors.dangerBg,   iconColor: AppColors.danger,  onTap: _showSOSDialog),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Health Summary ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(title: 'Health Summary', actionLabel: 'Details', onAction: () {}),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10, crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                    children: const [
                      VitalCard(icon: Icons.medication_outlined,   value: '2',   unit: ' doses', label: 'Meds Today',      subLabel: '1 taken · 1 pending',  accent: AppColors.teal,    accentBg: AppColors.tealPale),
                      VitalCard(icon: Icons.favorite_border,        value: '72',  unit: ' bpm',   label: 'Heart Rate',      subLabel: 'Normal range',          accent: AppColors.success, accentBg: AppColors.successBg),
                      VitalCard(icon: Icons.opacity_outlined,       value: '120', unit: '/80',    label: 'Blood Pressure',  subLabel: 'Checked today',         accent: AppColors.warning, accentBg: AppColors.warningBg),
                      VitalCard(icon: Icons.air_outlined,           value: '98',  unit: '%',      label: 'SpO₂',            subLabel: 'Excellent',             accent: AppColors.bluePrimary, accentBg: AppColors.blueLight),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Live Medications (Firebase) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: "Today's Medications",
                    actionLabel: 'View All',
                    onAction: widget.onNavigateToReminders,
                  ),
                ),
                _buildLiveMedications(),
                const SizedBox(height: 24),

                // ── Upcoming Appointments ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(title: 'Upcoming Appointments', actionLabel: 'All'),
                ),
                _buildAppointments(),
                const SizedBox(height: 24),

                // ── Hydration ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: 'Hydration',
                    actionLabel: '$_waterCount / $_waterGoal glasses',
                  ),
                ),
                _buildHydrationCard(),
                const SizedBox(height: 24),

                // ── Clinical Insight ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(title: 'Clinical Insight'),
                ),
                _buildInsightCard(),
                const SizedBox(height: 24),

                // ── SOS Bar ──
                _buildSOSBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(
            children: [
              // Greeting row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _greeting.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: Colors.white38, letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DummyData.user.name,
                      style: GoogleFonts.outfit(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: -0.3,
                      ),
                    ),
                  ]),
                  GestureDetector(
                    onTap: widget.onNavigateToProfile,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                      ),
                      child: Center(
                        child: Text('RS',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Next dose banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(kRadius),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.3), borderRadius: BorderRadius.circular(kRadiusSm)),
                      child: const Icon(Icons.alarm_outlined, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('NEXT DOSE IN',
                            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.tealLight, letterSpacing: 1.2)),
                        Text('45 min',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                        Text('Atorvastatin · 10mg',
                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54)),
                      ]),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tealLight,
                        foregroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
                      ),
                      onPressed: () => _snack('✓ Dose marked as taken'),
                      child: Text('Take Now', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LIVE MEDICATIONS (Firebase + Dismissible) ──
  // *** ALL FIREBASE LOGIC PRESERVED EXACTLY ***
  Widget _buildLiveMedications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc('user_123')
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
                  }
                  // *** FIREBASE DELETE — PRESERVED ***
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc('user_123')
                      .collection('medications')
                      .doc(doc.id)
                      .delete();
                },
                child: _medRow(data),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _medRow(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: AppColors.cardShadow,
        border: const Border(left: BorderSide(color: AppColors.teal, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Time
            SizedBox(
              width: 46,
              child: Text(
                data['time'] ?? '',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal),
              ),
            ),
            Container(width: 1, height: 28, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 12)),
            // Info
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['name']   ?? '',
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(data['dosage'] ?? '',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ),
            StatusBadge(
              label: 'Upcoming',
              background: AppColors.tealPale,
              textColor: AppColors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyMedState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: [
        Icon(Icons.medication_outlined, size: 32, color: AppColors.textMuted),
        const SizedBox(height: 8),
        Text('No medications scheduled',
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text('Add medicines in Reminders tab',
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted.withOpacity(0.7))),
      ]),
    );
  }

  // ── APPOINTMENTS ────────────────────────────
  Widget _buildAppointments() {
    final upcoming = DummyData.appointments
        .where((a) => a.status == AppointmentStatus.upcoming)
        .take(2)
        .toList();

    return Column(
      children: upcoming.map((appt) {
        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          child: _apptCard(appt),
        );
      }).toList(),
    );
  }

  Widget _apptCard(Appointment appt) {
    final day   = DateFormat('dd').format(appt.dateTime);
    final month = DateFormat('MMM').format(appt.dateTime);
    final time  = DateFormat('h:mm a').format(appt.dateTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.border.withOpacity(0.4), width: 0.5),
      ),
      child: Row(children: [
        // Date pill
        Container(
          width: 48, padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.tealPale,
            borderRadius: BorderRadius.circular(kRadiusSm),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(day,   style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.teal, height: 1)),
            Text(month, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal.withOpacity(0.7))),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appt.doctorName,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text('${appt.specialty} · ${appt.hospital}',
                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.schedule_outlined, size: 11, color: AppColors.teal),
                const SizedBox(width: 4),
                Text('$time · ${appt.durationMinutes} min',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.teal)),
              ]),
            ),
          ]),
        ),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.border),
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
          border: Border.all(color: AppColors.teal.withOpacity(0.12)),
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
                DummyData.dailyHealthTip,
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
            border: Border.all(color: AppColors.danger.withOpacity(0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: AppColors.danger, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.danger.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)],
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
