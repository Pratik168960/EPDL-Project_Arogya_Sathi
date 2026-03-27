import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _waterCount = DummyData.waterGlassesDone;
  final int _waterGoal = DummyData.waterGlassesGoal;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌤️ Good Morning';
    if (hour < 17) return '☀️ Good Afternoon';
    return '🌙 Good Evening';
  }

  void _showSOSDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusXl)),
        title: Row(
          children: [
            const Text('🆘', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text('Emergency SOS',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.redAlert,
                )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will immediately:',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            _sosBullet('📞 Call emergency services (108)'),
            _sosBullet('📍 Send your location to Sneha Sharma'),
            _sosBullet('💬 Send SOS SMS to your contacts'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                )),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redAlert),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚨 SOS Sent! Calling 108 & alerting contacts...',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.redAlert,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: Text('CALL NOW',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _sosBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text,
          style: GoogleFonts.nunito(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Body ──
            SliverPadding(
              padding: const EdgeInsets.all(18),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Actions
                  const SectionHeader(title: 'Quick Actions'),
                  _buildQuickActions(),
                  const SizedBox(height: 22),

                  // Health Summary
                  const SectionHeader(title: 'Health Summary', actionLabel: 'Details →'),
                  _buildHealthStats(),
                  const SizedBox(height: 22),

                  // Today's Medications
                  SectionHeader(
                    title: "Today's Medications",
                    actionLabel: 'View All',
                    onAction: widget.onNavigateToReminders,
                  ),
                  _buildMedications(),
                  const SizedBox(height: 22),

                  // Water Tracker
                  SectionHeader(
                    title: '💧 Water Intake',
                    actionLabel: '$_waterCount / $_waterGoal glasses',
                  ),
                  _buildWaterTracker(),
                  const SizedBox(height: 22),

                  // Appointments
                  const SectionHeader(title: 'Upcoming Appointments', actionLabel: 'All →'),
                  _buildAppointments(),
                  const SizedBox(height: 22),

                  // Health Tip
                  const SectionHeader(title: 'Daily Health Tip'),
                  _buildHealthTip(),
                  const SizedBox(height: 22),
                ]),
              ),
            ),

            // ── SOS Button ──
            // ── SOS Button ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 40), // Adjusted padding
              sliver: SliverToBoxAdapter(child: _buildSOSButton()),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────
  Widget _buildHeader() {
    return GradientHeader(
      colors: const [AppColors.blueDark, AppColors.bluePrimary, AppColors.blueMid],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13, fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text('${DummyData.user.name} 👋',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 22, fontWeight: FontWeight.w900,
                      )),
                ],
              ),
              GestureDetector(
                onTap: widget.onNavigateToProfile,
                child: Stack(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                      ),
                      child: const Center(child: Text('🧑‍💼', style: TextStyle(fontSize: 24))),
                    ),
                    Positioned(
                      top: 0, right: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.redAlert,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Next medicine banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⏱ NEXT MEDICINE IN',
                          style: GoogleFonts.nunito(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11, fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          )),
                      const SizedBox(height: 4),
                      Text('45 Mins',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 28, fontWeight: FontWeight.w900,
                            height: 1,
                          )),
                      Text('Atorvastatin • 10mg',
                          style: GoogleFonts.nunito(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12, fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Atorvastatin marked as taken!',
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                        backgroundColor: AppColors.greenPrimary,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.greenPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Take Now',
                        style: GoogleFonts.nunito(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800,
                        )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuickActionItem(
          emoji: '📅',
          label: 'Book\nAppt.',
          bgColor: AppColors.blueLight,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('📅 Booking appointment...', style: GoogleFonts.nunito(fontWeight: FontWeight.w700))),
          ),
        ),
        QuickActionItem(
          emoji: '📋',
          label: 'Add\nRecord',
          bgColor: AppColors.greenLight,
          onTap: widget.onNavigateToRecords ?? () {},
        ),
        QuickActionItem(
          emoji: '💊',
          label: 'Medicines',
          bgColor: AppColors.purpleLight,
          onTap: widget.onNavigateToReminders ?? () {},
        ),
        QuickActionItem(
          emoji: '🆘',
          label: 'Emergency',
          bgColor: AppColors.redLight,
          onTap: () => _showSOSDialog(context),
        ),
      ],
    );
  }

  // ── HEALTH STATS ─────────────────────────────────
  Widget _buildHealthStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: const [
        StatMiniCard(
          emoji: '💊', value: '2', label: 'Meds Today',
          subLabel: '1 taken • 1 pending', accentColor: AppColors.bluePrimary,
        ),
        StatMiniCard(
          emoji: '🫀', value: '72', unit: 'bpm', label: 'Heart Rate',
          subLabel: 'Normal range', accentColor: AppColors.greenPrimary,
        ),
        StatMiniCard(
          emoji: '🩸', value: '120', unit: '/80', label: 'Blood Pressure',
          subLabel: 'Checked today', accentColor: AppColors.orange,
        ),
        StatMiniCard(
          emoji: '🔬', value: '98', unit: '%', label: 'SpO₂',
          subLabel: 'Excellent', accentColor: AppColors.greenPrimary,
        ),
      ],
    );
  }

  // ── MEDICATIONS ──────────────────────────────────
  // ── MEDICATIONS (LIVE FROM FIREBASE) ──────────────────
  // ── MEDICATIONS (LIVE FROM FIREBASE) ──────────────────
  Widget _buildMedications() {
    return StreamBuilder<QuerySnapshot>(
      // Listen to the specific user's medications
      stream: FirebaseFirestore.instance.collection('users').doc('user_123').collection('medications').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Text('Error loading medications', style: TextStyle(color: AppColors.redAlert));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('No medications scheduled today! 🎉', 
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          );
        }

        // Build the beautiful custom card for each Firebase document
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Row(
                children: [
                  // ── TIME ──
                  SizedBox(
                    width: 55,
                    child: Text(
                      data['time'] ?? '--:--',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.bluePrimary),
                    ),
                  ),
                  
                  // ── VERTICAL LINE ──
                  Container(
                    height: 40,
                    width: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bluePrimary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  
                  // ── MEDICATION INFO ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Unknown Med',
                          style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data['dosage'] ?? ''}',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  
                  // ── STATUS BADGE ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.blueLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Upcoming',
                      style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.bluePrimary),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  // ── WATER TRACKER ────────────────────────────────
  Widget _buildWaterTracker() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Hydration',
                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800)),
              Text('$_waterCount of $_waterGoal glasses',
                  style: GoogleFonts.nunito(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.bluePrimary,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8,
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
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Goal: $_waterGoal glasses (2 Litres) per day',
              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ── APPOINTMENTS ─────────────────────────────────
  Widget _buildAppointments() {
    final upcoming = DummyData.appointments
        .where((a) => a.status == AppointmentStatus.upcoming)
        .take(2)
        .toList();

    return Column(
      children: upcoming.map((appt) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _AppointmentCard(appointment: appt),
      )).toList(),
    );
  }

  // ── HEALTH TIP ───────────────────────────────────
  Widget _buildHealthTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.greenLight, Color(0xFFD0F0E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.greenPrimary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🥗', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌿 TIP OF THE DAY',
                    style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: AppColors.greenDark, letterSpacing: 0.8,
                    )),
                const SizedBox(height: 6),
                Text(DummyData.dailyHealthTip,
                    style: GoogleFonts.nunito(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A4A3A), height: 1.5,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SOS BUTTON ───────────────────────────────────
  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () => _showSOSDialog(context),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.02),
        duration: const Duration(milliseconds: 1200),
        builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC0392B), AppColors.redAlert],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(kRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.redAlert.withOpacity(0.5),
                blurRadius: 24, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🆘', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text('EMERGENCY SOS — CALL 108',
                  style: GoogleFonts.nunito(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w900, letterSpacing: 1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Medication Card ───────────────────────────────
class _MedCard extends StatelessWidget {
  final Medication medication;
  const _MedCard({required this.medication});

  @override
  Widget build(BuildContext context) {
    Widget badge;
    switch (medication.status) {
      case MedStatus.taken:
        badge = const StatusBadge(
          label: '✓ Taken',
          background: AppColors.greenLight,
          textColor: AppColors.greenDark,
        );
        break;
      case MedStatus.upcoming:
        badge = const StatusBadge(
          label: 'Upcoming',
          background: AppColors.blueLight,
          textColor: AppColors.bluePrimary,
        );
        break;
      case MedStatus.missed:
        badge = const StatusBadge(
          label: 'Missed',
          background: AppColors.redLight,
          textColor: AppColors.redAlert,
        );
        break;
      case MedStatus.skipped:
        badge = const StatusBadge(
          label: 'Skipped',
          background: AppColors.orangeLight,
          textColor: AppColors.orange,
        );
        break;
    }

    final timeStr = medication.time.format(context);

    return Opacity(
      opacity: medication.status == MedStatus.missed ? 0.7 : 1.0,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () {
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💊 ${medication.name} details',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Row(
          children: [
            // Time column
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  Text(timeStr.split(' ')[0],
                      style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: AppColors.bluePrimary,
                      )),
                  Text(timeStr.split(' ').length > 1 ? timeStr.split(' ')[1] : '',
                      style: GoogleFonts.nunito(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      )),
                ],
              ),
            ),

            // Divider
            Container(width: 1, height: 40, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 8)),

            // Color indicator
            Container(width: 3, height: 40, decoration: BoxDecoration(color: medication.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(medication.name,
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800)),
                  Text('${medication.dosage} · ${medication.mealInstruction}',
                      style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            badge,
          ],
        ),
      ),
    );
  }
}

// ─── Appointment Card ──────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd');
    final monthFormat = DateFormat('MMM');
    final timeFormat = DateFormat('h:mm a');

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 ${appointment.doctorName} appointment details',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              appointment.accentColor.withOpacity(0.85),
              appointment.accentColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: [
            BoxShadow(
              color: appointment.accentColor.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(dateFormat.format(appointment.dateTime),
                      style: GoogleFonts.nunito(
                        fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, height: 1,
                      )),
                  Text(monthFormat.format(appointment.dateTime).toUpperCase(),
                      style: GoogleFonts.nunito(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.8),
                      )),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.doctorName,
                      style: GoogleFonts.nunito(
                        fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white,
                      )),
                  Text('${appointment.specialty} • ${appointment.hospital}',
                      style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.75),
                      )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      '⏰ ${timeFormat.format(appointment.dateTime)} · ${appointment.durationMinutes} min',
                      style: GoogleFonts.nunito(
                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
