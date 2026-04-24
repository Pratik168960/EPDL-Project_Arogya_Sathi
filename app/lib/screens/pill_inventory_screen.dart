import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════
//  Design Tokens
// ═══════════════════════════════════════════════
class _S {
  static const Color surface           = Color(0xFFF7FAFD);
  static const Color surfContainerLow  = Color(0xFFF1F4F7);
  static const Color surfContainerHigh = Color(0xFFE5E8EB);
  static const Color surfLowest        = Color(0xFFFFFFFF);
  static const Color primaryContainer  = Color(0xFF0F1C2C);
  static const Color secondary         = Color(0xFF006399);
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outlineVariant    = Color(0xFFC4C6CC);
  static const Color outline           = Color(0xFF74777D);
  static const Color warning           = Color(0xFFF59E0B);
  static const Color emerald           = Color(0xFF10B981);
  static const Color tertiaryContainer = Color(0xFF281804);
  static const Color tertiaryFixed     = Color(0xFFFEDDBA);
}

// ═══════════════════════════════════════════════
//  PILL INVENTORY — 23-SLOT CIRCULAR DISC
// ═══════════════════════════════════════════════
class PillInventoryScreen extends StatefulWidget {
  const PillInventoryScreen({super.key});

  @override
  State<PillInventoryScreen> createState() => _PillInventoryScreenState();
}

class _PillInventoryScreenState extends State<PillInventoryScreen>
    with SingleTickerProviderStateMixin {
  static const int maxSlots = 23;
  int? _selectedSlotIndex;
  bool _warningDismissed = false;
  late AnimationController _pulseCtrl;

  CollectionReference<Map<String, dynamic>> get _inventoryRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('inventory');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _inventoryRef.orderBy('slot_index').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: _S.secondary),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Build a map: slot_index -> doc data
                  final Map<int, _SlotData> slotMap = {};
                  final lowStockSlots = <Map<String, dynamic>>[];

                  for (final doc in docs) {
                    final data = doc.data();
                    final idx = (data['slot_index'] ?? -1) as int;
                    if (idx < 0 || idx >= maxSlots) continue;
                    final stock = (data['current_stock'] ?? 0) as num;
                    final maxCap = (data['max_capacity'] ?? 30) as num;
                    final pct =
                        maxCap > 0 ? (stock / maxCap * 100).round() : 0;
                    slotMap[idx] = _SlotData(
                      name: data['medication_name'] as String? ?? 'Unknown',
                      stock: stock.toInt(),
                      maxCapacity: maxCap.toInt(),
                      percent: pct.clamp(0, 100),
                      docId: doc.id,
                    );
                    if (pct <= 10) {
                      lowStockSlots.add({
                        'name': data['medication_name'] ?? 'Unknown',
                        'slot_index': idx,
                      });
                    }
                  }

                  final int filledCount = slotMap.length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        _buildStatsRow(filledCount, lowStockSlots.length),
                        const SizedBox(height: 24),

                        // ── CIRCULAR DISC ──
                        Center(
                          child: _buildDisc(slotMap),
                        ),
                        const SizedBox(height: 24),

                        // ── SELECTED SLOT DETAIL ──
                        if (_selectedSlotIndex != null)
                          _buildSelectedSlotDetail(
                              _selectedSlotIndex!, slotMap),
                        const SizedBox(height: 20),

                        // Dynamic warning banner
                        if (!_warningDismissed &&
                            lowStockSlots.isNotEmpty) ...[
                          _buildWarningBanner(lowStockSlots),
                          const SizedBox(height: 20),
                        ],

                        // Dispenser health
                        _buildDispenserHealth(),
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

  // ── APP BAR ──────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child:
                  Icon(Icons.arrow_back, color: _S.secondary, size: 24),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Pill Inventory',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _S.primaryContainer,
                      letterSpacing: -0.3)),
            ),
          ),
          // Online badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _S.surfContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _S.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('ONLINE',
                    style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _S.onSurfaceVariant,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ────────────────────────────────────
  Widget _buildStatsRow(int filled, int lowStock) {
    return Row(
      children: [
        _statCard('$filled', 'Assigned', _S.secondary),
        const SizedBox(width: 12),
        _statCard('${maxSlots - filled}', 'Empty', _S.outline),
        const SizedBox(width: 12),
        _statCard('$lowStock', 'Low Stock', _S.warning),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _S.surfLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0F1C2C),
                offset: Offset(0, 4),
                blurRadius: 16),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _S.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  CIRCULAR DISC — 23 slots arranged radially
  // ═══════════════════════════════════════════════
  Widget _buildDisc(Map<int, _SlotData> slotMap) {
    final double discSize =
        MediaQuery.of(context).size.width - 48; // - horizontal padding
    final double clamped = discSize.clamp(280.0, 400.0);

    return SizedBox(
      width: clamped,
      height: clamped,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background disc with slot arcs
          CustomPaint(
            size: Size(clamped, clamped),
            painter: _DiscPainter(
              slotMap: slotMap,
              selectedIndex: _selectedSlotIndex,
              maxSlots: maxSlots,
            ),
          ),

          // Touch targets for each slot
          ...List.generate(maxSlots, (i) {
            final angle =
                (2 * pi * i / maxSlots) - (pi / 2); // start from top
            final radius = clamped / 2 * 0.72;
            final dx = clamped / 2 + radius * cos(angle);
            final dy = clamped / 2 + radius * sin(angle);
            final isSelected = _selectedSlotIndex == i;
            final hasData = slotMap.containsKey(i);
            final isLow = hasData && slotMap[i]!.percent <= 10;

            return Positioned(
              left: dx - 16,
              top: dy - 16,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedSlotIndex = _selectedSlotIndex == i ? null : i;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (hasData
                            ? (isLow ? _S.warning : _S.emerald)
                            : _S.secondary)
                        : (hasData
                            ? (isLow
                                ? _S.warning.withValues(alpha: 0.15)
                                : _S.emerald.withValues(alpha: 0.15))
                            : _S.surfContainerHigh),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (hasData
                              ? (isLow ? _S.warning : _S.emerald)
                              : _S.outlineVariant),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: (hasData
                                        ? (isLow ? _S.warning : _S.emerald)
                                        : _S.secondary)
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : (hasData
                              ? (isLow ? _S.warning : _S.emerald)
                              : _S.outline),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Center hub
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = 1.0 + _pulseCtrl.value * 0.03;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: clamped * 0.3,
              height: clamped * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F1C2C), Color(0xFF1A2D42)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: _S.primaryContainer.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined,
                      size: 24,
                      color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(height: 4),
                  Text('${slotMap.length}/$maxSlots',
                      style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('SLOTS',
                      style: GoogleFonts.outfit(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SELECTED SLOT DETAIL CARD ────────────────────
  Widget _buildSelectedSlotDetail(
      int index, Map<int, _SlotData> slotMap) {
    final data = slotMap[index];

    if (data == null) {
      // Empty slot
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _S.surfLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _S.outlineVariant.withValues(alpha: 0.4), width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0F1C2C),
                offset: Offset(0, 8),
                blurRadius: 24),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline,
                size: 36,
                color: _S.secondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('Slot ${index + 1} — Empty',
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _S.primaryContainer)),
            const SizedBox(height: 4),
            Text('No medication assigned to this slot.',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: _S.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _S.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.medication, size: 18),
                label: Text('Assign Medicine',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                onPressed: () => _showAssignSlotDialog(index),
              ),
            ),
          ],
        ),
      );
    }

    // Filled slot
    final isLow = data.percent <= 10;
    final accent = isLow ? _S.warning : _S.emerald;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F1C2C),
              offset: Offset(0, 8),
              blurRadius: 24),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SLOT ${index + 1}',
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _S.onSurfaceVariant,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(data.name,
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _S.primaryContainer)),
                ],
              ),
              if (isLow)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _S.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('REFILL SOON',
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _S.warning,
                          letterSpacing: 0.5)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('${data.stock}',
                  style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: isLow ? _S.warning : _S.primaryContainer)),
              const SizedBox(width: 6),
              Text('/ ${data.maxCapacity} pills',
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _S.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _S.surfContainerHigh,
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (data.percent / 100).clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('INVENTORY LEVEL',
                  style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _S.onSurfaceVariant,
                      letterSpacing: 1.2)),
              Text('${data.percent}% FULL',
                  style: GoogleFonts.outfit(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _S.secondary,
                    side: const BorderSide(color: _S.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () =>
                      _showAssignSlotDialog(index, docId: data.docId),
                  child: Text('Reassign',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _S.warning,
                    side: const BorderSide(color: _S.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    await _inventoryRef.doc(data.docId).delete();
                    if (mounted) {
                      setState(() => _selectedSlotIndex = null);
                      _snack('Slot cleared');
                    }
                  },
                  child: Text('Clear Slot',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ASSIGN SLOT DIALOG ───────────────────────────
  void _showAssignSlotDialog(int slotIndex, {String? docId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _S.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _S.surfContainerHigh,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Assign Medicine to Slot ${slotIndex + 1}',
                  style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _S.primaryContainer)),
              const SizedBox(height: 8),
              Text(
                  'Choose a medicine from your reminders to link it to this physical hardware slot.',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: _S.onSurfaceVariant)),
              const SizedBox(height: 20),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(AuthService.currentUserId!)
                    .collection('medications')
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _S.secondary));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                          'No medicines found. Please add medicines in the Reminders tab first.',
                          style: GoogleFonts.outfit(color: _S.warning)),
                    );
                  }

                  return SizedBox(
                    height: 250,
                    child: ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: _S.surfContainerHigh),
                      itemBuilder: (context, idx) {
                        final med =
                            docs[idx].data() as Map<String, dynamic>;
                        final medName = med['name'] ?? 'Unknown';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _S.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.medication,
                                color: _S.secondary, size: 20),
                          ),
                          title: Text(medName,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${med['dosage'] ?? ''} · ${med['frequency'] ?? ''}',
                              style: GoogleFonts.outfit(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right,
                              color: _S.outline),
                          onTap: () async {
                            Navigator.pop(ctx);
                            _assignMedicineToSlot(
                                slotIndex, medName, docId);
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _assignMedicineToSlot(
      int slotIndex, String medicationName, String? docId) async {
    try {
      if (docId == null) {
        await _inventoryRef.add({
          'medication_name': medicationName,
          'current_stock': 30,
          'max_capacity': 30,
          'slot_index': slotIndex,
          'refill_threshold': 5,
          'last_dispensed': FieldValue.serverTimestamp(),
        });
      } else {
        await _inventoryRef.doc(docId).update({
          'medication_name': medicationName,
          'current_stock': 30,
        });
      }
      if (mounted) _snack('Slot ${slotIndex + 1} assigned!');
    } catch (e) {
      if (mounted) _snack('Error: $e');
    }
  }

  // ── WARNING BANNER ───────────────────────────────
  Widget _buildWarningBanner(List<Map<String, dynamic>> lowStockSlots) {
    final names = lowStockSlots
        .map((s) => 'Slot ${(s['slot_index'] as int) + 1} (${s['name']})')
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _S.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A0F1C2C),
              offset: Offset(0, 8),
              blurRadius: 24),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _S.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_rounded,
                size: 28, color: _S.warning),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$names running low.',
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _S.tertiaryFixed,
                        letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Text('Please refill soon to avoid missed doses.',
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _S.tertiaryFixed.withValues(alpha: 0.8),
                        height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _warningDismissed = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _S.warning,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('DISMISS',
                  style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _S.primaryContainer,
                      letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  // ── DISPENSER HEALTH ─────────────────────────────
  Widget _buildDispenserHealth() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dispenser Health',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _S.primaryContainer,
                  letterSpacing: -0.5)),
          const SizedBox(height: 20),
          _healthRow('JAM SENSORS', 'CLEAR', _S.emerald),
          const SizedBox(height: 10),
          _healthRow('WIFI STRENGTH', 'EXCELLENT', _S.primaryContainer),
          const SizedBox(height: 10),
          _healthRow('CALIBRATION', 'OPTIMAL', _S.primaryContainer),
        ],
      ),
    );
  }

  Widget _healthRow(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _S.onSurfaceVariant,
                  letterSpacing: 1.0)),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: _S.secondary,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

// ═══════════════════════════════════════════════
//  Slot Data Model
// ═══════════════════════════════════════════════
class _SlotData {
  final String name;
  final int stock;
  final int maxCapacity;
  final int percent;
  final String docId;

  _SlotData({
    required this.name,
    required this.stock,
    required this.maxCapacity,
    required this.percent,
    required this.docId,
  });
}

// ═══════════════════════════════════════════════
//  Custom Painter — 23-Slot Circular Disc
// ═══════════════════════════════════════════════
class _DiscPainter extends CustomPainter {
  final Map<int, _SlotData> slotMap;
  final int? selectedIndex;
  final int maxSlots;

  _DiscPainter({
    required this.slotMap,
    required this.selectedIndex,
    required this.maxSlots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.42;
    final slotAngle = 2 * pi / maxSlots;
    final gapAngle = 0.02; // small gap between slots

    // Draw outer ring border
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = const Color(0xFFE0E3E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw inner ring border
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = const Color(0xFFE0E3E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    for (int i = 0; i < maxSlots; i++) {
      final startAngle = -pi / 2 + slotAngle * i + gapAngle / 2;
      final sweepAngle = slotAngle - gapAngle;

      final hasData = slotMap.containsKey(i);
      final isLow = hasData && slotMap[i]!.percent <= 10;
      final isSelected = selectedIndex == i;

      // Slot fill color
      Color fillColor;
      if (isSelected) {
        fillColor = hasData
            ? (isLow
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE0F2F1))
            : const Color(0xFFE3F2FD);
      } else if (hasData) {
        final pct = slotMap[i]!.percent;
        if (isLow) {
          fillColor = const Color(0xFFFFF8E1).withValues(alpha: 0.8);
        } else if (pct > 50) {
          fillColor = const Color(0xFFE8F5E9).withValues(alpha: 0.8);
        } else {
          fillColor = const Color(0xFFF1F8E9).withValues(alpha: 0.8);
        }
      } else {
        fillColor = const Color(0xFFF7FAFD);
      }

      // Draw arc segment
      final path = Path()
        ..moveTo(
          center.dx + innerRadius * cos(startAngle),
          center.dy + innerRadius * sin(startAngle),
        )
        ..lineTo(
          center.dx + outerRadius * cos(startAngle),
          center.dy + outerRadius * sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          sweepAngle,
          false,
        )
        ..lineTo(
          center.dx + innerRadius * cos(startAngle + sweepAngle),
          center.dy + innerRadius * sin(startAngle + sweepAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle + sweepAngle,
          -sweepAngle,
          false,
        )
        ..close();

      // Fill
      canvas.drawPath(
          path,
          Paint()
            ..color = fillColor
            ..style = PaintingStyle.fill);

      // Stock fill indicator (arc within the slot proportional to stock %)
      if (hasData) {
        final pct = slotMap[i]!.percent / 100.0;
        final fillSweep = sweepAngle * pct;
        final stockPath = Path()
          ..moveTo(
            center.dx + innerRadius * cos(startAngle),
            center.dy + innerRadius * sin(startAngle),
          )
          ..lineTo(
            center.dx + outerRadius * cos(startAngle),
            center.dy + outerRadius * sin(startAngle),
          )
          ..arcTo(
            Rect.fromCircle(center: center, radius: outerRadius),
            startAngle,
            fillSweep,
            false,
          )
          ..lineTo(
            center.dx + innerRadius * cos(startAngle + fillSweep),
            center.dy + innerRadius * sin(startAngle + fillSweep),
          )
          ..arcTo(
            Rect.fromCircle(center: center, radius: innerRadius),
            startAngle + fillSweep,
            -fillSweep,
            false,
          )
          ..close();

        canvas.drawPath(
            stockPath,
            Paint()
              ..color = isLow
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                  : const Color(0xFF10B981).withValues(alpha: 0.25)
              ..style = PaintingStyle.fill);
      }

      // Border
      canvas.drawPath(
          path,
          Paint()
            ..color = isSelected
                ? (hasData
                    ? (isLow
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF10B981))
                    : const Color(0xFF006399))
                : const Color(0xFFD0D3D8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 2.5 : 1);

      // Radial divider lines
      canvas.drawLine(
        Offset(
          center.dx + innerRadius * cos(startAngle - gapAngle / 2),
          center.dy + innerRadius * sin(startAngle - gapAngle / 2),
        ),
        Offset(
          center.dx + outerRadius * cos(startAngle - gapAngle / 2),
          center.dy + outerRadius * sin(startAngle - gapAngle / 2),
        ),
        Paint()
          ..color = const Color(0xFFD0D3D8)
          ..strokeWidth = 0.8,
      );
    }

    // Center circle fill
    canvas.drawCircle(
      center,
      innerRadius - 1,
      Paint()
        ..color = const Color(0xFF0F1C2C)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_DiscPainter old) =>
      old.selectedIndex != selectedIndex ||
      old.slotMap.length != slotMap.length;
}
