import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/notification_service.dart';
import '../services/auth_service.dart'; // <-- ADDED THIS IMPORT
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

// ═══════════════════════════════════════════════
//  REMINDERS SCREEN — LIVE FIREBASE STREAM
// ═══════════════════════════════════════════════
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with TickerProviderStateMixin {

  // Local reminder toggle state per med id
  final Map<String, bool> _toggleState = {};

  int _waterCount = DummyData.waterGlassesDone;
  final int _waterGoal = DummyData.waterGlassesGoal;

  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);
    _ringCtrl.forward();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── OPEN ADD MEDICINE SHEET ──
  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMedicineSheet(),
    );
  }

  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── HEADER ──
          Container(
            color: AppColors.navy,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medicine Reminders',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Live Schedule',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                    const SizedBox(height: 16),

                    // Adherence card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(kRadius),
                      ),
                      child: Row(children: [
                        // Animated ring
                        AnimatedBuilder(
                          animation: _ringAnim,
                          builder: (_, __) => SizedBox(
                            width: 60, height: 60,
                            child: CustomPaint(
                              painter: _AdherenceRingPainter(progress: _ringAnim.value * 0.75),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('75%',
                                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
                            Text('Weekly Adherence',
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54, height: 1.4)),
                            Text('Based on recent history',
                                style: GoogleFonts.outfit(fontSize: 10, color: Colors.white30)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          _adherencePill('On Track', AppColors.teal),
                          const SizedBox(height: 6),
                          Text('This week',
                              style: GoogleFonts.outfit(fontSize: 9, color: Colors.white30)),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── SCROLLABLE CONTENT ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              children: [
                // Add button
                GestureDetector(
                  onTap: _openAddSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(kRadius),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Add New Medicine',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                // Today's schedule
                Text("Today's Schedule",
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                
                _buildScheduleList(), // <-- NOW CALLS THE FIREBASE STREAM!
                
                const SizedBox(height: 24),

                // Water goal
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Hydration Goal',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('$_waterCount / $_waterGoal glasses',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal)),
                ]),
                const SizedBox(height: 10),
                _buildWaterSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── THE LIVE FIREBASE SCHEDULE ──
  Widget _buildScheduleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId!).collection('medications').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No medicines scheduled.', style: GoogleFonts.outfit(color: AppColors.textMuted))),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final med = doc.data() as Map<String, dynamic>;
            final isOn = _toggleState[doc.id] ?? true; // Default toggle to ON

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kRadiusSm),
                boxShadow: const [
                  BoxShadow(color: Color(0x050C1E35), blurRadius: 10, offset: Offset(0, 4)),
                ],
                border: Border(left: BorderSide(color: isOn ? AppColors.teal : AppColors.border, width: 4)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(children: [
                  // Time
                  SizedBox(
                    width: 56,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        med['time'] != null ? med['time'].split(' ')[0] : '--:--',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: isOn ? AppColors.teal : AppColors.textMuted, letterSpacing: -0.5),
                      ),
                      Text(
                        med['time'] != null && med['time'].toString().length > 5 ? med['time'].split(' ')[1] : '',
                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 16), // Divider removed for cleanliness
                  // Med info
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(med['name'] ?? 'Unknown',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600,
                              color: isOn ? AppColors.textPrimary : AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text('${med['dosage'] ?? ''}',
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                    ]),
                  ),
                  // Toggle Switch
                  Switch.adaptive(
                    value: isOn,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _toggleState[doc.id] = val);
                      
                      // Cancel the alarm if toggled off!
                      if (val == false && med.containsKey('alarm_id')) {
                         NotificationService.cancelSpecificAlarm(med['alarm_id']);
                      }
                    },
                    activeColor: Colors.white,
                    activeTrackColor: AppColors.teal,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppColors.border,
                  ),
                ]),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildWaterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: const [
          BoxShadow(color: Color(0x050C1E35), blurRadius: 16, offset: Offset(0, 4)),
        ],
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
              setState(() => _waterCount = i < _waterCount ? i : i + 1);
            },
          )),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$_waterCount glasses consumed',
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted)),
          Text('${_waterGoal - _waterCount} remaining',
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teal)),
        ]),
      ]),
    );
  }

  Widget _adherencePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ═══════════════════════════════════════════════
//  ADD MEDICINE BOTTOM SHEET (with Firebase)
// ═══════════════════════════════════════════════
class _AddMedicineSheet extends StatefulWidget {
  const _AddMedicineSheet();

  @override
  State<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<_AddMedicineSheet> {
  final _nameCtrl   = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String _frequency = 'Once daily';
  String _meal      = 'After Breakfast';
  TimeOfDay _time   = const TimeOfDay(hour: 8, minute: 0);
  bool _saving      = false;

  final _freqOptions = ['Once daily', 'Twice daily', 'Thrice daily', 'As needed'];
  final _mealOptions = ['Before Breakfast', 'After Breakfast', 'With Lunch', 'After Lunch', 'Evening', 'After Dinner', 'Bedtime'];

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _dosageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    setState(() => _saving = true);

    final timeStr = '${_time.hourOfPeriod}:${_time.minute.toString().padLeft(2, '0')} ${_time.period.name.toUpperCase()}';

    try {
      final alarmId = DateTime.now().millisecondsSinceEpoch % 100000;

      await NotificationService.scheduleMedicineNotification(
        id: alarmId,
        name: _nameCtrl.text.trim(),
        dosage: '${_dosageCtrl.text.trim()} · $_meal',
        time: _time,
      );

      // *** THE FIX: REMOVED QUOTES AROUND AuthService.currentUserId! ***
      await FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('medications')
          .add({
            'name':      _nameCtrl.text.trim(),
            'dosage':    _dosageCtrl.text.trim(),
            'frequency': _frequency,
            'meal':      _meal,
            'time':      timeStr,
            'alarm_id':  alarmId,
            'created_at': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Medicine added & reminder set ✓',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXl)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.medication_outlined, color: AppColors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Add New Medicine',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 20),

              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  prefixIcon: Icon(Icons.medication_outlined, size: 20, color: AppColors.textMuted),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _dosageCtrl,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Dosage (e.g. 500mg, 1 tablet)',
                  prefixIcon: Icon(Icons.scale_outlined, size: 20, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: _time);
                  if (picked != null) setState(() => _time = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.schedule_outlined, size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _time.format(context),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.border),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _frequency,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat_outlined, size: 20, color: AppColors.textMuted),
                ),
                items: _freqOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                onChanged: (v) => setState(() => _frequency = v!),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _meal,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'When to take',
                  prefixIcon: Icon(Icons.restaurant_outlined, size: 20, color: AppColors.textMuted),
                ),
                items: _mealOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _meal = v!),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save & Set Reminder', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Adherence Ring Painter ────────────────────────
class _AdherenceRingPainter extends CustomPainter {
  final double progress;
  const _AdherenceRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.42;

    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 5,
    );

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = AppColors.tealLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AdherenceRingPainter old) => old.progress != progress;
}