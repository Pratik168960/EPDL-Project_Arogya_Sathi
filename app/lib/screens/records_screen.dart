import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

// ═══════════════════════════════════════════════
//  RECORDS SCREEN — History (Firebase) + Health Locker
// ═══════════════════════════════════════════════
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Medical Records',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Your secure health vault',
                              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                        ]),
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.12)),
                          ),
                          child: const Icon(Icons.search_outlined, color: Colors.white54, size: 20),
                        ),
                      ],
                    ),
                  ),

                  // Tab bar
                  TabBar(
                    controller: _tab,
                    indicatorColor: AppColors.tealLight,
                    indicatorWeight: 2,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
                    dividerColor: Colors.white.withOpacity(0.08),
                    tabs: const [
                      Tab(text: 'Medication History'),
                      Tab(text: 'Health Locker'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── TAB CONTENT ──
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildHistoryTab(),
                _buildLockerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc('user_123')
          .collection('history')
          .orderBy('taken_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.history_outlined, color: AppColors.teal, size: 32),
                ),
                const SizedBox(height: 16),
                Text('No history yet',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('Take a pill to see it here!',
                    style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          );
        }

        final logs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final name   = log['name']   ?? 'Unknown';
            final dosage = log['dosage'] ?? '';
            final status = log['status'] ?? 'Taken';

            String timeString = 'Just now';
            if (log['taken_at'] != null) {
              final DateTime date = (log['taken_at'] as Timestamp).toDate();
              timeString = DateFormat('MMM d, h:mm a').format(date);
            }

            return _historyCard(name: name, dosage: dosage, status: status, time: timeString);
          },
        );
      },
    );
  }

  Widget _historyCard({
    required String name,
    required String dosage,
    required String status,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: AppColors.cardShadow,
        border: const Border(left: BorderSide(color: AppColors.success, width: 3)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,   style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(dosage, style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(status,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
          const SizedBox(height: 3),
          Text(time,
              style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }

  Widget _buildLockerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary row ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(kRadius),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(children: [
            _lockerStat('16', 'Total Files'),
            _vLine(),
            _lockerStat('3', 'This Month'),
            _vLine(),
            _lockerStat('2', 'Shared'),
          ]),
        ),
        const SizedBox(height: 20),

        // ── Categories ──
        Text('Categories',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: const [
            _LockerFolder(icon: Icons.biotech_outlined,                  label: 'Blood Tests',   count: 4, color: Color(0xFFC62828), bg: Color(0xFFFFF0F0)),
            _LockerFolder(icon: Icons.description_outlined,    label: 'Prescriptions', count: 7, color: Color(0xFF1565C0), bg: Color(0xFFE8F1FD)),
            
            // *** THE FIX: Swapped radiology_outlined for medical_information_outlined ***
            _LockerFolder(icon: Icons.medical_information_outlined,      label: 'X-Rays & Scans',count: 2, color: Color(0xFF2E7D32), bg: Color(0xFFEDF7EE)),
            
            _LockerFolder(icon: Icons.vaccines_outlined,       label: 'Vaccination',   count: 3, color: Color(0xFFB45309), bg: Color(0xFFFEF3C7)),
          ],
        ),
        const SizedBox(height: 20),

        // ── Recent Files ──
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent Files',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('View All',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal)),
        ]),
        const SizedBox(height: 10),

        ...DummyData.records.take(5).map((r) => _fileRow(r)),

        const SizedBox(height: 14),
        // Upload button
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(color: AppColors.border, width: 1.5, style: BorderStyle.solid),
            ),
            child: Column(children: [
              const Icon(Icons.upload_outlined, color: AppColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text('Upload New Record',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              Text('PDF, JPG, PNG up to 10 MB',
                  style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted.withOpacity(0.7))),
            ]),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _lockerStat(String val, String label) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(val,   style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.teal)),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
      ]),
    );
  }

  Widget _vLine() => Container(width: 1, height: 32, color: AppColors.border);

  Widget _fileRow(HealthRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: r.categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_categoryIcon(r.category), color: r.categoryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${r.categoryLabel} · ${DateFormat('dd MMM yyyy').format(r.uploadedDate)} · ${r.fileSizeMb} MB',
                style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, size: 18, color: AppColors.border),
      ]),
    );
  }

  IconData _categoryIcon(RecordCategory cat) {
    switch (cat) {
      case RecordCategory.bloodTest:    return Icons.biotech_outlined;
      case RecordCategory.prescription: return Icons.description_outlined;
      // *** THE FIX: Swapped radiology_outlined for medical_information_outlined ***
      case RecordCategory.xray:         return Icons.medical_information_outlined;
      case RecordCategory.vaccination:  return Icons.vaccines_outlined;
      case RecordCategory.other:        return Icons.insert_drive_file_outlined;
    }
  }
}

// ── Locker Folder Card ────────────────────────────
class _LockerFolder extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color bg;

  const _LockerFolder({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kRadius),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('$count files',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}