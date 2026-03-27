import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // We use this to format the timestamps nicely
import '../theme/app_theme.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Medication History', 
          style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)
        ),
      ),
      // ── StreamBuilder constantly listens to Firebase for new logs ──
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc('user_123')
            .collection('history')
            .orderBy('taken_at', descending: true) // Shows newest first!
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.bluePrimary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No history yet.\nTake a pill to see it here!', 
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 18, color: AppColors.textMuted, fontWeight: FontWeight.w600)
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;
              final name = log['name'] ?? 'Unknown';
              final dosage = log['dosage'] ?? '';
              final status = log['status'] ?? 'Taken';
              
              // Safely handle the Firebase timestamp
              String timeString = "Just now";
              if (log['taken_at'] != null) {
                final DateTime date = (log['taken_at'] as Timestamp).toDate();
                timeString = DateFormat('MMM d, h:mm a').format(date); // e.g., "Mar 27, 5:45 PM"
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.bluePrimary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    // Green Checkmark Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 16),
                    
                    // Medicine Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          Text(dosage, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    
                    // Timestamp
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(status, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.green)),
                        const SizedBox(height: 4),
                        Text(timeString, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}