import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../services/alarm_schedule_service.dart';
import '../services/auth_service.dart';
import '../services/hardware_sync_service.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════
//  ALARM SCREEN — Full-screen medication alert
//  *** ALL FIREBASE IoT + HISTORY LOGIC PRESERVED ***
// ═══════════════════════════════════════════════
class AlarmScreen extends StatelessWidget {
  final String payload;

  const AlarmScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    // *** PAYLOAD PARSING — PRESERVED EXACTLY ***
    final parts  = payload.split('|');
    final name   = parts.isNotEmpty ? parts[0] : 'Your Medicine';
    final dosage = parts.length > 1  ? parts[1] : '';
    final payloadId = parts.length > 2 ? int.tryParse(parts[2]) : null;

    final now        = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, Color(0xFF0D3B6E)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Hospital cross icon ──
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.medication_rounded, size: 36, color: AppColors.tealLight),
                  ),
                  const SizedBox(height: 8),
                  Text('TIME FOR YOUR DOSE',
                      style: GoogleFonts.outfit(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.tealLight, letterSpacing: 2.5,
                      )),
                  const SizedBox(height: 24),

                  // ── Giant time display ──
                  Text(timeString,
                      style: GoogleFonts.outfit(
                        fontSize: 80, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: -3, height: 0.9,
                      )),
                  const Spacer(flex: 1),

                  // ── Medicine card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(kRadiusLg),
                      boxShadow: const [
                        BoxShadow(color: Color(0x300C1E35), blurRadius: 40, offset: Offset(0, 16)),
                      ],
                    ),
                    child: Column(children: [
                      // Medicine icon row
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.tealPale,
                            borderRadius: BorderRadius.circular(kRadiusSm),
                          ),
                          child: const Icon(Icons.medication_outlined, color: AppColors.teal, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Prescribed Medication',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(name,
                              style: GoogleFonts.outfit(
                                fontSize: 24, fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary, letterSpacing: -0.3,
                              )),
                        ]),
                      ]),
                      const SizedBox(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        _infoChip(Icons.scale_outlined,    dosage,        AppColors.tealPale,  AppColors.teal),
                        _infoChip(Icons.schedule_outlined, timeString,    AppColors.blueLight, AppColors.bluePrimary),
                        _infoChip(Icons.circle_outlined,   '1 Tablet',    AppColors.successBg, AppColors.success),
                      ]),
                    ]),
                  ),

                  const Spacer(flex: 2),

                  // ── Confirm button (LARGE for elderly) ──
                  SizedBox(
                    width: double.infinity,
                    height: 68,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
                        shadowColor: Colors.transparent,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 28),
                      label: Text('  I TOOK IT',
                          style: GoogleFonts.outfit(
                            fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          )),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();

                        // *** 1. CANCEL ALL ALARMS — PRESERVED ***
                        NotificationService.cancelAll();

                        // *** 2. IoT HARDWARE TRIGGER — PRESERVED EXACTLY ***
                        try {
                          await FirebaseFirestore.instance
                              .collection('hardware_control')
                              .doc('esp32_dispenser_01')
                              .set({
                                'dispense_now': true,
                                'medicine_dispensed': name,
                                'timestamp': FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                          debugPrint('Hardware trigger sent to Firebase!');
                        } catch (e) {
                          debugPrint('Error sending to hardware: $e');
                        }

                        // *** 3. PERMANENT HISTORY LOG — PRESERVED EXACTLY ***
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(AuthService.currentUserId!)
                              .collection('history')
                              .add({
                                'name': name,
                                'dosage': dosage,
                                'taken_at': FieldValue.serverTimestamp(),
                                'status': 'Taken On Time',
                              });
                          debugPrint('History saved successfully!');
                        } catch (e) {
                          debugPrint('Error saving history: $e');
                        }
                        // *** 3b. ROTATE ALARM SCHEDULE — delete fired, create next ***
                        try {
                          if (payloadId != null) {
                            await AlarmScheduleService.onAlarmFired(payloadId);
                          }
                          debugPrint('Alarm schedule rotated to next occurrence!');
                        } catch (e) {
                          debugPrint('Error rotating alarm schedule: $e');
                        }
                        
                        // *** 4. UPDATE DASHBOARD IS_TAKEN STATUS BY ALARM ID ***
                        try {
                          if (payloadId != null) {
                            final querySnapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(AuthService.currentUserId!)
                                .collection('medications')
                                .where('alarm_id', isEqualTo: payloadId)
                                .get();
                              
                            for (var doc in querySnapshot.docs) {
                              await doc.reference.update({'isTaken': true});
                            }
                          }
                          debugPrint('Dashboard UI updated with checkmark!');
                        } catch (e) {
                          debugPrint('Error updating dashboard: $e');
                        }

                        // *** 5. SYNC HARDWARE POINTER → advance to next alarm ***
                        await HardwareSyncService.markCurrentDone();

                        // *** 6. POP BACK — PRESERVED ***
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Snooze option
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.snooze_outlined, size: 18, color: Colors.white38),
                    label: Text('Snooze 10 minutes',
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color bg, Color fg) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(kRadiusSm)),
        child: Icon(icon, color: fg, size: 18),
      ),
      const SizedBox(height: 5),
      Text(label,
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    ]);
  }
}

