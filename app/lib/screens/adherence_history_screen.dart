import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class AdherenceHistoryScreen extends StatefulWidget {
  const AdherenceHistoryScreen({super.key});

  @override
  State<AdherenceHistoryScreen> createState() => _AdherenceHistoryScreenState();
}

class _AdherenceHistoryScreenState extends State<AdherenceHistoryScreen> {
  final int activeDayIndex = 3;

  @override
  Widget build(BuildContext context) {
    if (AuthService.currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(AuthService.currentUserId)
                    .collection('history')
                    .orderBy('taken_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Calculate stats
                  int total = docs.length;
                  int taken = docs.where((doc) {
                    final status = (doc.data() as Map<String, dynamic>)['status']?.toString().toLowerCase() ?? '';
                    return status.contains('taken') || status == 'dispensed';
                  }).length;
                  
                  int adherence = total > 0 ? ((taken / total) * 100).round() : 100;
                  
                  // Group by Date for History Log
                  Map<String, List<Map<String, dynamic>>> groupedHistory = {};
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = data['taken_at'] as Timestamp?;
                    if (ts == null) continue;
                    
                    final date = ts.toDate();
                    final dateKey = DateFormat('MMM dd, EEEE').format(date);
                    
                    if (!groupedHistory.containsKey(dateKey)) {
                      groupedHistory[dateKey] = [];
                    }
                    groupedHistory[dateKey]!.add({
                      'name': data['name'] ?? 'Unknown',
                      'desc': 'Scheduled',
                      'time': DateFormat('hh:mm a').format(date),
                      'status': data['status'] ?? 'Unknown',
                      'color': (data['status']?.toString().toLowerCase().contains('taken') == true || data['status'] == 'dispensed') ? const Color(0xFF006399) : const Color(0xFFBA1A1A),
                    });
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMonthlySummary(adherence, taken),
                        const SizedBox(height: 40),
                        _buildDetailedChart(adherence),
                        const SizedBox(height: 40),
                        _buildHistoryLog(groupedHistory),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            'Adherence History',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F1C2C),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(int adherence, int streak) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${DateFormat('MMMM').format(DateTime.now())} Summary', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
                  const SizedBox(height: 4),
                  Text('Clinical performance overview', style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF44474C))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(left: BorderSide(color: Color(0xFF006399), width: 4)),
                    boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OVERALL ADHERENCE', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C), letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$adherence', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F1C2C), height: 1.0)),
                          const SizedBox(width: 4),
                          Text('%', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF006399))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(left: BorderSide(color: Color(0xFF0F1C2C), width: 4)),
                    boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL TAKEN', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C), letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$streak', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F1C2C), height: 1.0)),
                          const SizedBox(width: 4),
                          Text('Doses', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF44474C))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDetailedChart(int adherence) {
    // Generate dynamic chart data based on adherence!
    final double baseHeight = adherence / 100.0;
    final heights = List.generate(21, (index) {
      if (baseHeight == 0) return 0.2;
      return baseHeight * (0.8 + (index % 3) * 0.1); 
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30-Day Velocity', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 192,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(heights.length, (index) {
              final isLast = index == heights.length - 1;
              final isLow = heights[index] < 0.6;
              return Container(
                width: 8,
                height: 140 * heights[index].clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: isLast ? const Color(0xFF0F1C2C) : (isLow ? const Color(0x33006399) : const Color(0xFF006399)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryLog(Map<String, List<Map<String, dynamic>>> groupedHistory) {
    if (groupedHistory.isEmpty) {
      return Text('No medication records found.', style: GoogleFonts.manrope(fontSize: 16, color: const Color(0xFF44474C)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Records', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
        const SizedBox(height: 16),
        ...groupedHistory.entries.map((entry) {
          final dateStr = entry.key;
          final meds = entry.value;
          final takenCount = meds.where((m) => m['status'] == 'Taken' || m['status'] == 'dispensed').length;
          final statusString = '$takenCount/${meds.length} Doses Taken';
          
          final isPerfect = takenCount == meds.length;
          final isMissed = takenCount == 0 && meds.isNotEmpty;
          
          if (isMissed) {
             return Column(
               children: [
                 _buildCollapsedEntry(dateStr, statusString, const Color(0xFFBA1A1A)),
                 const SizedBox(height: 12),
               ],
             );
          } else if (isPerfect) {
             return Column(
               children: [
                 _buildActiveRecordEntry(dateStr, statusString, true, meds),
                 const SizedBox(height: 12),
               ],
             );
          } else {
             return Column(
               children: [
                 _buildActiveRecordEntry(dateStr, statusString, true, meds),
                 const SizedBox(height: 12),
               ],
             );
          }
        }),
      ],
    );
  }

  Widget _buildActiveRecordEntry(String date, String status, bool isOpen, List<Map<String, dynamic>> meds) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x050F1C2C), offset: Offset(0, 4), blurRadius: 16)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F1C2C))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF006399), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(status, style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF006399))),
                      ],
                    ),
                  ],
                ),
                const Icon(Icons.expand_less, color: Color(0xFF44474C)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: meds.map((med) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE5E8EB)))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(width: 4, height: 32, decoration: BoxDecoration(color: med['color'], borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(med['name'].toString().toUpperCase(), style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
                              Text(med['desc'], style: GoogleFonts.publicSans(fontSize: 10, color: const Color(0xFF44474C))),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text((med['status'].toString().toUpperCase() == 'DISPENSED' ? 'TAKEN' : med['status'].toString().toUpperCase()), style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: med['color'], letterSpacing: 1.5)),
                          Text(med['time'], style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F1C2C))),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedEntry(String date, String status, Color statusColor) {
    final bool isError = statusColor == const Color(0xFFBA1A1A);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F7).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isError ? const Border(left: BorderSide(color: Color(0x4DBA1A1A), width: 4)) : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF44474C))),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(status, style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: isError ? statusColor : const Color(0xFF44474C))),
                ],
              ),
            ],
          ),
          const Icon(Icons.expand_more, color: Color(0x8044474C)),
        ],
      ),
    );
  }
}
