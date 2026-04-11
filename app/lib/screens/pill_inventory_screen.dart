import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens
// ═══════════════════════════════════════════════
class _S {
  static const Color surface           = Color(0xFFF7FAFD);
  static const Color surfContainerLow  = Color(0xFFF1F4F7);
  static const Color surfContainerHigh = Color(0xFFE5E8EB);
  static const Color surfContainerHighest = Color(0xFFE0E3E6);
  static const Color surfContainer     = Color(0xFFEBEEF1);
  static const Color surfLowest        = Color(0xFFFFFFFF);
  static const Color primaryContainer  = Color(0xFF0F1C2C);
  static const Color onPrimaryContainer = Color(0xFF778598);
  static const Color secondary         = Color(0xFF006399);
  static const Color onSecondary       = Color(0xFFFFFFFF);
  static const Color onSurface         = Color(0xFF181C1E);
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outlineVariant    = Color(0xFFC4C6CC);
  static const Color outline           = Color(0xFF74777D);
  static const Color warning           = Color(0xFFF59E0B);
  static const Color emerald           = Color(0xFF10B981);
  static const Color tertiaryContainer = Color(0xFF281804);
  static const Color tertiaryFixed     = Color(0xFFFEDDBA);
}

// ═══════════════════════════════════════════════
//  PILL INVENTORY / HARDWARE INVENTORY SCREEN
//  Phase 2: Firebase Firestore Integration
// ═══════════════════════════════════════════════
class PillInventoryScreen extends StatefulWidget {
  const PillInventoryScreen({super.key});

  @override
  State<PillInventoryScreen> createState() => _PillInventoryScreenState();
}

class _PillInventoryScreenState extends State<PillInventoryScreen> {
  bool _warningDismissed = false;

  // ── Firestore References ─────────────────────
  static const int _maxSlots = 4;
  static const String _slotLabels = 'ABCDEFGH';

  CollectionReference<Map<String, dynamic>> get _inventoryRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('inventory');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── STREAM-DRIVEN CONTENT ──────────
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _inventoryRef.orderBy('slot_index').snapshots(),
                          builder: (context, snapshot) {
                            // Loading state
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildLoadingState();
                            }

                            // Error state
                            if (snapshot.hasError) {
                              return _buildErrorState(snapshot.error.toString());
                            }

                            final docs = snapshot.data?.docs ?? [];

                            // Derive dynamic data
                            final int totalInstalled = docs.length;
                            final lowStockSlots = <Map<String, dynamic>>[];

                            for (final doc in docs) {
                              final data = doc.data();
                              final stock = (data['current_stock'] ?? 0) as num;
                              final max = (data['max_capacity'] ?? 30) as num;
                              final percent = max > 0 ? (stock / max * 100).round() : 0;
                              if (percent <= 10) {
                                lowStockSlots.add({
                                  'name': data['medication_name'] ?? 'Unknown',
                                  'slot_index': data['slot_index'] ?? 0,
                                });
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(totalInstalled),
                                const SizedBox(height: 20),
                                _buildSlotGrid(docs),
                                const SizedBox(height: 28),
                                // Dynamic warning banner
                                if (!_warningDismissed && lowStockSlots.isNotEmpty) ...[
                                  _buildWarningBanner(lowStockSlots),
                                  const SizedBox(height: 28),
                                ],
                                _buildDispenserHealth(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // FAB — Log Medication Refill
            Positioned(
              left: 24, right: 24, bottom: 16,
              child: _buildRefillButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADING STATE ────────────────────────────────
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _S.secondary),
            ),
            const SizedBox(height: 16),
            Text('Loading inventory...',
                style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ── ERROR STATE ──────────────────────────────────
  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 36, color: _S.warning),
            const SizedBox(height: 12),
            Text('Failed to load inventory',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600,
                    color: _S.primaryContainer)),
            const SizedBox(height: 4),
            Text(error, textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 11, color: _S.onSurfaceVariant)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(Icons.settings_remote, color: _S.secondary, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Hardware\nInventory',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, height: 1.2, letterSpacing: -0.3)),
            ],
          ),
          // Online badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _S.surfContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: _S.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('DISPENSER ONLINE',
                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                        color: _S.onSurfaceVariant, letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION HEADER (dynamic count) ───────────────
  Widget _buildSectionHeader(int totalInstalled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Slots',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800,
                    color: _S.primaryContainer, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Real-time status of physical dispenser units.',
                style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant)),
          ],
        ),
        Text('${totalInstalled > 0 ? totalInstalled : _maxSlots} UNITS',
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                color: _S.secondary, letterSpacing: 0.5)),
      ],
    );
  }

  // ── SLOT GRID (Firestore-driven) ─────────────────
  Widget _buildSlotGrid(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    // Build a list of _maxSlots items — filled or empty
    final List<Widget> slotWidgets = [];
    for (int i = 0; i < _maxSlots; i++) {
      final slotLabel = 'Slot ${_slotLabels[i]}';
      // Find the doc with slot_index == i
      final match = docs.where((d) => (d.data()['slot_index'] ?? -1) == i);

      if (match.isNotEmpty) {
        final data = match.first.data();
        final name = (data['medication_name'] ?? 'Unknown') as String;
        final stock = (data['current_stock'] ?? 0) as num;
        final max = (data['max_capacity'] ?? 30) as num;
        final percent = max > 0 ? (stock / max * 100).round() : 0;
        final isLow = percent <= 10;

        slotWidgets.add(
          _slotCard(
            slot: slotLabel,
            name: name,
            count: stock.toInt(),
            percent: percent.clamp(0, 100),
            accentColor: isLow ? _S.warning : _S.secondary,
            isWarning: isLow,
          ),
        );
      } else {
        slotWidgets.add(_emptySlot(slotLabel));
      }
    }

    // Layout in 2-column grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: slotWidgets[0]),
            const SizedBox(width: 14),
            Expanded(child: slotWidgets[1]),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: slotWidgets[2]),
            const SizedBox(width: 14),
            Expanded(child: slotWidgets[3]),
          ],
        ),
      ],
    );
  }

  Widget _slotCard({
    required String slot,
    required String name,
    required int count,
    required int percent,
    required Color accentColor,
    required bool isWarning,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(slot.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                            color: _S.onSurfaceVariant, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700,
                            color: _S.primaryContainer)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (isWarning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _S.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('REFILL\nSOON',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w700,
                          color: _S.warning, letterSpacing: 0.3, height: 1.2)),
                )
              else
                Icon(Icons.medication, size: 20, color: _S.secondary),
            ],
          ),
          const SizedBox(height: 16),

          // Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$count',
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800,
                      color: isWarning ? _S.warning : _S.primaryContainer)),
              Flexible(
                child: Text('pills remaining',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500,
                        color: _S.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _S.surfContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percent / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('INVENTORY LEVEL',
                  style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                      color: _S.onSurfaceVariant, letterSpacing: 1.2)),
              Text('$percent% FULL',
                  style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                      color: accentColor, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptySlot(String slot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _S.outlineVariant.withValues(alpha: 0.4), width: 2,
            strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 28, color: _S.outline.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(slot.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                  color: _S.onSurfaceVariant, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text('No medication assigned',
              style: GoogleFonts.outfit(fontSize: 11, color: _S.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ── WARNING BANNER (dynamic) ─────────────────────
  Widget _buildWarningBanner(List<Map<String, dynamic>> lowStockSlots) {
    // Build a human-readable summary
    final names = lowStockSlots.map((s) {
      final idx = (s['slot_index'] as int).clamp(0, _slotLabels.length - 1);
      return 'Slot ${_slotLabels[idx]} (${s['name']})';
    }).join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _S.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
      ),
      child: Row(
        children: [
          // Warning icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _S.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_rounded, size: 28, color: _S.warning),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$names running low.',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700,
                        color: _S.tertiaryFixed, letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Text('Please refill soon to avoid missed doses.',
                    style: GoogleFonts.outfit(fontSize: 12,
                        color: _S.tertiaryFixed.withValues(alpha: 0.8), height: 1.3)),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _S.warning,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('DISMISS',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: 1.2)),
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
          Text('Dispenser Health &\nEfficiency',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800,
                  color: _S.primaryContainer, letterSpacing: -0.5, height: 1.2)),
          const SizedBox(height: 24),

          _healthRow('JAM SENSORS', 'CLEAR', _S.emerald),
          const SizedBox(height: 12),
          _healthRow('WIFI STRENGTH', 'EXCELLENT', _S.primaryContainer),
          const SizedBox(height: 12),
          _healthRow('CALIBRATION', 'OPTIMAL', _S.primaryContainer),

          const SizedBox(height: 24),
          // Device preview placeholder
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _S.surfLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings_remote, size: 40, color: _S.secondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 8),
                      Text('Smart Dispenser',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                              color: _S.onSurfaceVariant.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, _S.surfContainerLow.withValues(alpha: 0.4)],
                      ),
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
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                  color: _S.onSurfaceVariant, letterSpacing: 1.0)),
          Text(value,
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }

  // ── REFILL BUTTON ────────────────────────────────
  Widget _buildRefillButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        _snack('Logging medication refill...');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _S.secondary,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [BoxShadow(color: _S.secondary.withValues(alpha: 0.3),
              offset: const Offset(0, 12), blurRadius: 32)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Text('LOG MEDICATION REFILL',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: _S.secondary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }
}

