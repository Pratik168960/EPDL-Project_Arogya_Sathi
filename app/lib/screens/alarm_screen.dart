import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class AlarmScreen extends StatelessWidget {
  final String payload;

  const AlarmScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    // Extract medicine name from payload
    final parts = payload.split('|');
    final name = parts.isNotEmpty ? parts[0] : 'Alarm';

    // Get current time formatted like "05:12"
    final now = DateTime.now();
    final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C22), // Dark background from your image
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // ── The Giant Time ──
            Text(timeString, 
              style: GoogleFonts.nunito(
                fontSize: 100, 
                fontWeight: FontWeight.w900, 
                color: Colors.white,
                letterSpacing: -2,
              )
            ),
            const SizedBox(height: 20),
            
            // ── The Medicine Name ──
            Text(name, 
              style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)
            ),
            
            const Spacer(),
            
            // ── Snooze & Stop Buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A3D55), // Purplish Snooze color
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        NotificationService.cancelAll();
                        Navigator.pop(context);
                        // Later, we can add logic to reschedule for 5 mins here!
                      },
                      child: Text('Snooze', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F4254), // Dark Grey Stop color
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        NotificationService.cancelAll();
                        Navigator.pop(context);
                      },
                      child: Text('Stop', style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}