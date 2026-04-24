import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/alarm_schedule_service.dart';
import '../services/notification_service.dart';
import '../services/hardware_sync_service.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════
//  ADD MEDICINE BOTTOM SHEET (with Firebase)
// ═══════════════════════════════════════════════
class AddMedicineSheet extends StatefulWidget {
  const AddMedicineSheet({super.key});

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  final _nameCtrl   = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String _frequency = 'Once daily';
  String _meal      = 'After Breakfast';
  int _selectedSlot = -1;
  TimeOfDay _time   = const TimeOfDay(hour: 8, minute: 0);
  bool _saving      = false;
  
  bool _isSpecificDays = false;
  final List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  final _freqOptions = ['Once daily', 'Twice daily', 'Thrice daily', 'As needed'];
  final _mealOptions = ['Before Breakfast', 'After Breakfast', 'With Lunch', 'After Lunch', 'Evening', 'After Dinner', 'Bedtime'];
  final _slotOptions = {-1: 'No Physical Slot', 0: 'Slot A', 1: 'Slot B', 2: 'Slot C', 3: 'Slot D'};

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
        selectedDays: _selectedDays,
      );

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

      // Sync to dedicated alarm_schedules collection
      await AlarmScheduleService.saveAlarmSchedule(
        medicineName: _nameCtrl.text.trim(),
        dosage: _dosageCtrl.text.trim(),
        frequency: _frequency,
        mealTiming: _meal,
        time: _time,
        alarmId: alarmId,
        selectedDays: _selectedDays,
      );

      // Sync physical hardware slot if selected
      if (_selectedSlot != -1) {
        final inventoryRef = FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId!).collection('inventory');
        final match = await inventoryRef.where('slot_index', isEqualTo: _selectedSlot).limit(1).get();
        if (match.docs.isEmpty) {
          await inventoryRef.add({
            'medication_name': _nameCtrl.text.trim(),
            'current_stock': 30,
            'max_capacity': 30,
            'slot_index': _selectedSlot,
            'refill_threshold': 5,
            'last_dispensed': FieldValue.serverTimestamp(),
          });
        } else {
          await inventoryRef.doc(match.docs.first.id).update({
            'medication_name': _nameCtrl.text.trim(),
            'current_stock': 30,
          });
        }
      }

      // Sync the ESP32 "Next Alarm Pointer"
      await HardwareSyncService.syncNow();

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
      if (!mounted) return;
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
                value: _isSpecificDays ? 'Specific Days' : 'Daily',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Schedule Type',
                  prefixIcon: Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.textMuted),
                ),
                items: ['Daily', 'Specific Days'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  setState(() {
                    _isSpecificDays = v == 'Specific Days';
                    if (!_isSpecificDays) {
                      _selectedDays.clear();
                      _selectedDays.addAll([1, 2, 3, 4, 5, 6, 7]);
                    } else if (_selectedDays.length == 7) {
                      _selectedDays.clear();
                      _selectedDays.add(DateTime.now().weekday);
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              if (_isSpecificDays) ...[
                _buildDayPicker(),
                const SizedBox(height: 12),
              ],

              DropdownButtonFormField<String>(
                initialValue: _frequency,
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
                initialValue: _meal,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'When to take',
                  prefixIcon: Icon(Icons.restaurant_outlined, size: 20, color: AppColors.textMuted),
                ),
                items: _mealOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _meal = v!),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                initialValue: _selectedSlot,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Hardware Slot (Optional)',
                  prefixIcon: Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.textMuted),
                ),
                items: _slotOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _selectedSlot = v!),
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

  Widget _buildDayPicker() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayVal = index + 1; // 1=Mon, 7=Sun
        final isSelected = _selectedDays.contains(dayVal);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                if (_selectedDays.length > 1) _selectedDays.remove(dayVal); // Prevent empty
              } else {
                _selectedDays.add(dayVal);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.teal : AppColors.background,
              border: Border.all(color: isSelected ? AppColors.teal : AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: GoogleFonts.outfit(
                fontSize: 14, 
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }
}
