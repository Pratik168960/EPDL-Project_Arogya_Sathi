import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> with TickerProviderStateMixin {
  late List<Medication> _meds;
  int _waterCount = DummyData.waterGlassesDone;
  late AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _meds = List.from(DummyData.medications);
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  int get _takenCount => _meds.where((m) => m.status == MedStatus.taken).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAddButton(),
                const SizedBox(height: 20),
                const SectionHeader(title: "Today's Schedule"),
                ..._meds.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ScheduleItem(
                    medication: m,
                    onToggle: (val) {
                      setState(() => m.reminderEnabled = val);
                      HapticFeedback.selectionClick();
                    },
                  ),
                )),
                const SizedBox(height: 22),
                SectionHeader(title: '💧 Water Goal', actionLabel: '$_waterCount / 8 glasses'),
                _buildWaterProgress(),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GradientHeader(
      colors: const [Color(0xFF5B3BB5), AppColors.purple],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medicine Reminders 💊',
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Row(
            children: [
              // Adherence Ring
              AnimatedBuilder(
                animation: _ringCtrl,
                builder: (ctx, _) {
                  return CustomPaint(
                    size: const Size(90, 90),
                    painter: _RingPainter(progress: _ringCtrl.value * 0.75),
                  );
                },
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${DummyData.weeklyAdherencePercent}%',
                      style: GoogleFonts.nunito(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
                  Text('Weekly Adherence',
                      style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('15 of 20 doses taken',
                      style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Today: $_takenCount / ${_meds.length} taken',
                      style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _showAddMedSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.purple,
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: [
            BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('➕', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('Add New Medicine',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  void _showAddMedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMedSheet(),
    );
  }

  Widget _buildWaterProgress() {
    return AppCard(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _waterCount / 8,
              minHeight: 10,
              backgroundColor: AppColors.blueLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.bluePrimary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_waterCount glasses consumed',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              Text('${8 - _waterCount} remaining',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.bluePrimary)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(8, (i) => WaterCup(
              filled: i < _waterCount,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _waterCount = i < _waterCount ? i : i + 1);
              },
            )),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Item ────────────────────────────────
class _ScheduleItem extends StatelessWidget {
  final Medication medication;
  final ValueChanged<bool> onToggle;

  const _ScheduleItem({required this.medication, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final timeStr = medication.time.format(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(timeStr,
                style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          ),
          Container(width: 4, height: 44, decoration: BoxDecoration(color: medication.color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medication.name,
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('${medication.dosage} · ${medication.mealInstruction} · ${medication.pillCount} Tablet',
                    style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
          ),
          PillToggle(
            initialValue: medication.reminderEnabled,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

// ─── Add Medicine Sheet ────────────────────────────
class _AddMedSheet extends StatefulWidget {
  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  String _frequency = 'Once daily';
  final TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final String _meal = 'After Breakfast';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Add New Medicine',
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Medicine Name', prefixIcon: Text('💊', style: TextStyle(fontSize: 20))),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _doseCtrl,
              decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg)', prefixIcon: Text('⚖️', style: TextStyle(fontSize: 20))),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14),
              items: ['Once daily', 'Twice daily', 'Thrice daily', 'As needed'].map((f) =>
                  DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Medicine added successfully!',
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                  );
                },
                child: const Text('Save Medicine'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.42;

    // Background ring
    canvas.drawCircle(Offset(cx, cy), radius,
        Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 8);

    // Progress arc
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );

    // Center text
    final tp = TextPainter(
      text: TextSpan(
        text: '${(progress / 0.75 * 75).round()}%',
        style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
