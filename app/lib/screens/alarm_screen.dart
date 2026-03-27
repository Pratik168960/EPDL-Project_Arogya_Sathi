
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class AlarmScreen extends StatelessWidget {
  final String payload;

  const AlarmScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    // Extract medicine name and dosage from payload
    final parts = payload.split('|');
    final name = parts.isNotEmpty ? parts[0] : 'Your Medicine';
    final dosage = parts.length > 1 ? parts[1] : '';

    // Get current time formatted like "05:12"
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      body: Container(
        // ── Calming Medical Gradient Background ──
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00B4D8), // Vibrant cyan/teal
              Color(0xFF0077B6), // Deep medical blue
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // ── Medical Icon ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 30),
              
              // ── The Giant Time ──
              Text(timeString, 
                style: GoogleFonts.nunito(
                  fontSize: 90, 
                  fontWeight: FontWeight.w900, 
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1.0,
                )
              ),
              const SizedBox(height: 10),
              
              Text('TIME FOR YOUR DOSE', 
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 2)
              ),
              
              const SizedBox(height: 40),
              
              // ── The Medicine Details ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    Text(name, 
                      style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0077B6)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(dosage, 
                      style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // ── Single Giant "STOP" Button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 80, // Massive touch target for elderly
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B4D8), // Matching medical teal
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40), // Pill shape
                        side: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle, size: 36),
                    label: Text('  I TOOK IT', 
                      style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1)
                    ),
                    onPressed: () async {
                      // 1. Defuse the alarms!
                      NotificationService.cancelAll();
                      
                      // 2. The IoT Hardware Trigger!
                      try {
                        await FirebaseFirestore.instance
                            .collection('hardware_control')
                            .doc('esp32_dispenser_01')
                            .set({
                              'dispense_now': true,
                              'medicine_dispensed': name,
                              'timestamp': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            
                        print("Hardware trigger sent to Firebase!");
                      } catch (e) {
                        print("Error sending to hardware: $e");
                      }

                      // 3. THE PERMANENT HISTORY LOG!
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc('user_123')
                            .collection('history') 
                            .add({
                              'name': name,
                              'dosage': dosage,
                              'taken_at': FieldValue.serverTimestamp(),
                              'status': 'Taken On Time',
                            });
                        print("History saved successfully!");
                      } catch (e) {
                        print("Error saving history: $e");
                      }

                      // 4. Return to the Home Screen
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}