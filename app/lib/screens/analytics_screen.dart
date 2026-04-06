import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
}

// ═══════════════════════════════════════════════
//  ANALYTICS SCREEN
// ═══════════════════════════════════════════════
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTab = 0; // 0 = Weekly, 1 = Monthly

  // Bar chart data: heights as fractions (0..1)
  final List<_BarData> _weeklyBars = [
    _BarData('MON', 0.90, true),
    _BarData('TUE', 0.85, true),
    _BarData('WED', 0.30, false), // Missed
    _BarData('THU', 0.95, true),
    _BarData('FRI', 0.80, true),
    _BarData('SAT', 0.20, false), // Missed
    _BarData('SUN', 1.00, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                child: Column(
                  children: [
                    _buildSegmentedToggle(),
                    const SizedBox(height: 40),
                    _buildProgressRing(),
                    const SizedBox(height: 28),
                    _buildStreakBanner(),
                    const SizedBox(height: 48),
                    _buildActivityLogs(),
                    const SizedBox(height: 40),
                    _buildHealthInsights(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────
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
                child: const Icon(Icons.menu, color: _S.secondary, size: 24),
              ),
              const SizedBox(width: 16),
              Text('Analytics',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: -0.3)),
            ],
          ),
          Text('ArogyaSathi',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                  color: _S.primaryContainer, letterSpacing: -0.5)),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _S.surfContainerHighest,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 18, color: _S.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── SEGMENTED TOGGLE ─────────────────────────────
  Widget _buildSegmentedToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _segmentButton('Weekly', 0),
          _segmentButton('Monthly', 1),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, int index) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _S.surfLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [BoxShadow(color: _S.primaryContainer.withOpacity(0.06),
                    offset: const Offset(0, 2), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isActive ? _S.secondary : _S.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }

  // ── PROGRESS RING ────────────────────────────────
  Widget _buildProgressRing() {
    return SizedBox(
      width: 220, height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _AdherenceRingPainter(
              progress: 0.92,
              bgColor: _S.surfContainer,
              fgColor: _S.secondary,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('92%',
                  style: GoogleFonts.outfit(fontSize: 44, fontWeight: FontWeight.w800,
                      color: _S.primaryContainer, letterSpacing: -1.5)),
              const SizedBox(height: 2),
              Text('ADHERENCE',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                      color: _S.onSurfaceVariant, letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  // ── STREAK BANNER ────────────────────────────────
  Widget _buildStreakBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: _S.surfContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('Great job! You are on a 14-day streak.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500,
              color: _S.onSurface, height: 1.4)),
    );
  }

  // ── ACTIVITY LOGS (BAR CHART) ────────────────────
  Widget _buildActivityLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Activity Logs',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700,
                    color: _S.primaryContainer)),
            Text('PAST 7 DAYS',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600,
                    color: _S.onSurfaceVariant, letterSpacing: 1.2)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: _S.surfContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _weeklyBars.map((bar) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: bar.height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bar.taken ? _S.secondary : _S.outlineVariant,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(3)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(bar.label,
                                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                                    color: _S.onSurfaceVariant, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(_S.secondary, 'Taken'),
                  const SizedBox(width: 24),
                  _legendDot(_S.outlineVariant, 'Missed'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600,
                color: _S.onSurface)),
      ],
    );
  }

  // ── HEALTH INSIGHTS ──────────────────────────────
  Widget _buildHealthInsights() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _S.secondary, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HEALTH INSIGHTS',
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: 1.5)),
              const Icon(Icons.trending_up, size: 16, color: _S.secondary),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500,
                  color: _S.onSurface, height: 1.4),
              children: [
                const TextSpan(text: 'Your blood pressure medication compliance has improved by '),
                TextSpan(text: '15%', style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _S.secondary)),
                const TextSpan(text: ' this month.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Sparkline
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(color: _S.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Bar Data Model
// ═══════════════════════════════════════════════
class _BarData {
  final String label;
  final double height;
  final bool taken;
  _BarData(this.label, this.height, this.taken);
}

// ═══════════════════════════════════════════════
//  Adherence Ring Painter
// ═══════════════════════════════════════════════
class _AdherenceRingPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;

  _AdherenceRingPainter({required this.progress, required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background ring
    canvas.drawCircle(center, radius,
        Paint()..color = bgColor..style = PaintingStyle.stroke..strokeWidth = 12);

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = fgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AdherenceRingPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════
//  Sparkline Painter
// ═══════════════════════════════════════════════
class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.9),
      Offset(size.width * 0.14, size.height * 0.8),
      Offset(size.width * 0.28, size.height * 0.84),
      Offset(size.width * 0.42, size.height * 0.6),
      Offset(size.width * 0.56, size.height * 0.7),
      Offset(size.width * 0.70, size.height * 0.4),
      Offset(size.width * 0.84, size.height * 0.2),
      Offset(size.width * 0.92, size.height * 0.3),
      Offset(size.width, size.height * 0.1),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Line
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true);

    // Fill gradient
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.15), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
