import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

/// ═══════════════════════════════════════════════
///  SEED DATA UTILITY
///  Populates Firestore with realistic demo data
///  for all collections used in the app.
///  Run once, then remove from profile settings.
/// ═══════════════════════════════════════════════
class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  final List<_SeedStep> _steps = [];
  bool _isSeeding = false;
  bool _isDone = false;

  String get _uid => AuthService.currentUserId!;
  DocumentReference _userDoc() =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  void _log(String icon, String msg) {
    setState(() => _steps.add(_SeedStep(icon, msg)));
  }

  Future<void> _seedAll() async {
    setState(() {
      _isSeeding = true;
      _steps.clear();
    });

    try {
      await _seedMedications();
      await _seedHistory();
      await _seedInventory();
      await _seedCaregivers();
      await _seedMedicalId();
      await _seedAppointments();

      _log('✅', 'ALL SEED DATA COMPLETE!');
      setState(() => _isDone = true);
    } catch (e) {
      _log('❌', 'Error: $e');
    } finally {
      setState(() => _isSeeding = false);
    }
  }

  // ── 1. MEDICATIONS ──────────────────────────────
  Future<void> _seedMedications() async {
    _log('💊', 'Seeding medications...');
    final ref = _userDoc().collection('medications');

    final meds = [
      {
        'name': 'Metformin',
        'dosage': '500mg',
        'frequency': 'Twice daily',
        'time': '08:00',
        'meal': 'After Breakfast',
        'color': 0xFF2EAE82,
        'reminder': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Atorvastatin',
        'dosage': '10mg',
        'frequency': 'Once daily',
        'time': '13:00',
        'meal': 'With Lunch',
        'color': 0xFF1A6FC4,
        'reminder': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Amlodipine',
        'dosage': '5mg',
        'frequency': 'Once daily',
        'time': '21:00',
        'meal': 'After Dinner',
        'color': 0xFF7C5CBF,
        'reminder': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Vitamin D3',
        'dosage': '1000 IU',
        'frequency': 'Once daily',
        'time': '09:00',
        'meal': 'Morning',
        'color': 0xFFF6820D,
        'reminder': false,
        'created_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final med in meds) {
      await ref.add(med);
    }
    _log('✅', '${meds.length} medications added');
  }

  // ── 2. HISTORY (Adherence Logs) ─────────────────
  Future<void> _seedHistory() async {
    _log('📊', 'Seeding adherence history...');
    final ref = _userDoc().collection('history');
    final now = DateTime.now();

    final logs = <Map<String, dynamic>>[];
    final medNames = ['Metformin', 'Atorvastatin', 'Amlodipine', 'Vitamin D3'];
    final dosages  = ['500mg', '10mg', '5mg', '1000 IU'];

    // Generate 14 days of history
    for (int day = 0; day < 14; day++) {
      final date = now.subtract(Duration(days: day));
      for (int i = 0; i < medNames.length; i++) {
        // ~85% taken, ~10% missed, ~5% skipped
        String status;
        if (day == 0 && i == 3) {
          status = 'missed'; // Today's Vitamin D3 missed
        } else if (day == 2 && i == 1) {
          status = 'missed';
        } else if (day == 5 && i == 0) {
          status = 'skipped';
        } else {
          status = 'taken';
        }

        logs.add({
          'name': medNames[i],
          'dosage': dosages[i],
          'status': status,
          'taken_at': Timestamp.fromDate(
            DateTime(date.year, date.month, date.day, 8 + (i * 4), 0),
          ),
        });
      }
    }

    // Batch write (max 500 per batch)
    final batch = FirebaseFirestore.instance.batch();
    for (final log in logs) {
      batch.set(ref.doc(), log);
    }
    await batch.commit();
    _log('✅', '${logs.length} adherence logs added (14 days × 4 meds)');
  }

  // ── 3. INVENTORY ────────────────────────────────
  Future<void> _seedInventory() async {
    _log('🏥', 'Seeding pill inventory...');
    final ref = _userDoc().collection('inventory');

    final slots = [
      {
        'medication_name': 'Metformin 500mg',
        'current_stock': 42,
        'max_capacity': 60,
        'slot_number': 1,
        'refill_threshold': 10,
        'last_dispensed': FieldValue.serverTimestamp(),
      },
      {
        'medication_name': 'Atorvastatin 10mg',
        'current_stock': 5,
        'max_capacity': 30,
        'slot_number': 2,
        'refill_threshold': 5,
        'last_dispensed': FieldValue.serverTimestamp(),
      },
      {
        'medication_name': 'Amlodipine 5mg',
        'current_stock': 28,
        'max_capacity': 30,
        'slot_number': 3,
        'refill_threshold': 5,
        'last_dispensed': FieldValue.serverTimestamp(),
      },
      {
        'medication_name': 'Vitamin D3 1000 IU',
        'current_stock': 2,
        'max_capacity': 30,
        'slot_number': 4,
        'refill_threshold': 5,
        'last_dispensed': FieldValue.serverTimestamp(),
      },
    ];

    for (final slot in slots) {
      await ref.add(slot);
    }
    _log('✅', '${slots.length} inventory slots added (2 low-stock alerts)');
  }

  // ── 4. CAREGIVERS ───────────────────────────────
  Future<void> _seedCaregivers() async {
    _log('👥', 'Seeding care team...');
    final ref = _userDoc().collection('caregivers');

    final contacts = [
      {
        'name': 'Sneha Sharma',
        'phone': '+91 98100 11223',
        'relation': 'Spouse',
        'alert_missed_dose': true,
        'alert_hw_offline': true,
        'alert_monthly': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Dr. Priya Menon',
        'phone': '+91 98765 00001',
        'relation': 'Doctor',
        'alert_missed_dose': false,
        'alert_hw_offline': false,
        'alert_monthly': true,
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Rahul Sharma',
        'phone': '+91 91234 56789',
        'relation': 'Brother',
        'alert_missed_dose': true,
        'alert_hw_offline': false,
        'alert_monthly': false,
        'created_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final c in contacts) {
      await ref.add(c);
    }
    _log('✅', '${contacts.length} caregivers added');
  }

  // ── 5. MEDICAL ID ───────────────────────────────
  Future<void> _seedMedicalId() async {
    _log('🪪', 'Seeding Medical ID...');
    final ref = _userDoc().collection('medical_id');

    await ref.doc('basic_health').set({
      'height': '175',
      'weight': '78',
      'blood_type': 'A+',
      'organ_donor': true,
      'updated_at': FieldValue.serverTimestamp(),
    });

    await ref.doc('conditions').set({
      'allergies': ['Penicillin', 'Latex'],
      'conditions': ['Type 2 Diabetes', 'Hypertension'],
      'updated_at': FieldValue.serverTimestamp(),
    });

    await ref.doc('emergency_contacts').set({
      'primary_name': 'Sneha Sharma',
      'primary_phone': '+91 98100 11223',
      'primary_relation': 'Spouse',
      'secondary_name': 'Rahul Sharma',
      'secondary_phone': '+91 91234 56789',
      'secondary_relation': 'Brother',
      'show_on_lock_screen': true,
      'updated_at': FieldValue.serverTimestamp(),
    });

    _log('✅', 'Medical ID complete (basic health + conditions + contacts)');
  }

  // ── 6. APPOINTMENTS ─────────────────────────────
  Future<void> _seedAppointments() async {
    _log('📅', 'Seeding appointments...');
    final ref = _userDoc().collection('appointments');
    final now = DateTime.now();

    final appts = [
      {
        'doctor_name': 'Dr. Priya Menon',
        'specialty': 'Endocrinologist',
        'hospital': 'Apollo Clinic, Pune',
        'date_time': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 3, 10, 30),
        ),
        'duration_minutes': 30,
        'status': 'upcoming',
        'created_at': FieldValue.serverTimestamp(),
      },
      {
        'doctor_name': 'Dr. Arvind Shah',
        'specialty': 'General Physician',
        'hospital': 'Fortis Hospital, Pune',
        'date_time': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 8, 16, 0),
        ),
        'duration_minutes': 20,
        'status': 'upcoming',
        'created_at': FieldValue.serverTimestamp(),
      },
    ];

    for (final a in appts) {
      await ref.add(a);
    }
    _log('✅', '${appts.length} appointments added');
  }

  // ═══════════════════════════════════════════════
  //  UI
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1C2C),
        foregroundColor: Colors.white,
        title: Text('Seed Demo Data',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF0F1C2C),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Populate Firestore',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(
                  'This will add realistic demo data to your account:\n'
                  '• 4 medications with reminders\n'
                  '• 14 days of adherence history (56 logs)\n'
                  '• 4 inventory slots (2 low-stock)\n'
                  '• 3 caregivers\n'
                  '• Complete Medical ID\n'
                  '• 2 upcoming appointments',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70, height: 1.6),
                ),
              ],
            ),
          ),

          // Log output
          Expanded(
            child: _steps.isEmpty
                ? Center(
                    child: Text('Tap the button below to seed data',
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF44474C))),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _steps.length,
                    itemBuilder: (_, i) {
                      final step = _steps[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(step.message,
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500,
                                      color: const Color(0xFF0F1C2C), height: 1.4)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Seed button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isSeeding || _isDone) ? null : _seedAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDone
                        ? const Color(0xFF10B981)
                        : const Color(0xFF006399),
                    disabledBackgroundColor: _isDone
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE5E8EB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSeeding
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          _isDone ? '✓  Data Seeded Successfully' : 'Seed All Demo Data',
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedStep {
  final String icon;
  final String message;
  _SeedStep(this.icon, this.message);
}
