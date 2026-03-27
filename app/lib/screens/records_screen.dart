import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  RecordCategory? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HealthRecord> get _filtered {
    return DummyData.records.where((r) {
      final matchSearch = _query.isEmpty || r.name.toLowerCase().contains(_query.toLowerCase());
      final matchCat = _selectedCategory == null || r.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();
  }

  final List<_FolderItem> _folders = [
    const _FolderItem(emoji: '🩸', name: 'Blood Tests', count: 4, category: RecordCategory.bloodTest, bg: AppColors.redLight),
    const _FolderItem(emoji: '📜', name: 'Prescriptions', count: 7, category: RecordCategory.prescription, bg: AppColors.blueLight),
    const _FolderItem(emoji: '🫁', name: 'X-Rays & Scans', count: 2, category: RecordCategory.xray, bg: AppColors.greenLight),
    const _FolderItem(emoji: '💉', name: 'Vaccination', count: 3, category: RecordCategory.vaccination, bg: AppColors.orangeLight),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(18),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SectionHeader(title: 'Folders'),
                _buildFolderGrid(),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'Recent Files',
                  actionLabel: 'View All',
                  onAction: () => setState(() => _selectedCategory = null),
                ),
                ..._filtered.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FileRow(record: r),
                )),
                const SizedBox(height: 10),
                _buildUploadButton(),
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
      colors: const [AppColors.greenDark, AppColors.greenPrimary],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Records 🗂️',
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('Your secure digital health locker',
              style: GoogleFonts.nunito(color: Colors.white.withOpacity(0.75), fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                const Text('🔍', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      hintStyle: GoogleFonts.nunito(color: Colors.white.withOpacity(0.6), fontSize: 14),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: _folders.map((f) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedCategory = _selectedCategory == f.category ? null : f.category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedCategory == f.category ? f.bg.withOpacity(0.8) : AppColors.card,
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(
              color: _selectedCategory == f.category
                  ? DummyData.records.firstWhere((r) => r.category == f.category, orElse: () => DummyData.records.first).categoryColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(f.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(f.name,
                  style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('${f.count} files',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildUploadButton() {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📤 Upload dialog opening...',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.bluePrimary,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: AppColors.border, width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Text('⬆️', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text('Upload New Record',
                style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _FolderItem {
  final String emoji, name;
  final int count;
  final RecordCategory category;
  final Color bg;
  const _FolderItem({required this.emoji, required this.name, required this.count, required this.category, required this.bg});
}

// ─── File Row ─────────────────────────────────────
class _FileRow extends StatelessWidget {
  final HealthRecord record;
  const _FileRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📄 Opening ${record.name}...', style: GoogleFonts.nunito(fontWeight: FontWeight.w700))),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: record.categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(record.categoryEmoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.name,
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${record.categoryLabel} · ${dateFormat.format(record.uploadedDate)} · ${record.fileSizeMb} MB',
                    style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
