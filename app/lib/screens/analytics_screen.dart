import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  static const Color warning           = Color(0xFFF59E0B);
  static const Color emerald           = Color(0xFF10B981);
}

// ═══════════════════════════════════════════════
//  ANALYTICS SCREEN
//  Phase 2: Firebase Firestore Integration
// ═══════════════════════════════════════════════
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedTab = 0; // 0 = Weekly, 1 = Monthly

  // ── Firestore Reference ──────────────────────
  CollectionReference<Map<String, dynamic>> get _historyRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(AuthService.currentUserId!)
          .collection('history');

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

                    // ── STREAM-DRIVEN ANALYTICS ──────────
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _historyRef.orderBy('taken_at', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        // Loading
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingState();
                        }

                        // Error
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }

                        final docs = snapshot.data?.docs ?? [];

                        // ── CALCULATE STATS ─────────────
                        final now = DateTime.now();
                        final int rangeDays = _selectedTab == 0 ? 7 : 30;
                        final cutoff = now.subtract(Duration(days: rangeDays));

                        // Filter to selected range
                        final rangeDocs = docs.where((doc) {
                          final data = doc.data();
                          final takenAt = data['taken_at'];
                          if (takenAt == null || takenAt is! Timestamp) return false;
                          return takenAt.toDate().isAfter(cutoff);
                        }).toList();

                        final int totalLogs = rangeDocs.length;
                        int takenCount = 0;
                        int missedCount = 0;

                        // For the bar chart
                        final Map<int, _DayStats> chartDays = {};
                        for (int i = rangeDays - 1; i >= 0; i--) {
                          final day = now.subtract(Duration(days: i));
                          chartDays[_dayKey(day)] = _DayStats();
                        }

                        // Current streak tracking
                        int currentStreak = 0;
                        bool streakBroken = false;

                        // Process range docs only
                        for (final doc in rangeDocs) {
                          final data = doc.data();
                          final status = (data['status'] ?? '') as String;
                          final takenAt = data['taken_at'];

                          final isTaken = status.toLowerCase().contains('taken');
                          if (isTaken) {
                            takenCount++;
                          } else {
                            missedCount++;
                          }

                          // Populate chart
                          if (takenAt != null && takenAt is Timestamp) {
                            final date = takenAt.toDate();
                            final key = _dayKey(date);
                            if (chartDays.containsKey(key)) {
                              if (isTaken) {
                                chartDays[key]!.taken++;
                              } else {
                                chartDays[key]!.missed++;
                              }
                            }
                          }
                        }

                        // Calculate streak (consecutive days with at least 1 taken)
                        for (int i = 0; i <= 30 && !streakBroken; i++) {
                          final day = now.subtract(Duration(days: i));
                          final key = _dayKey(day);
                          // Check if that day had any taken logs
                          bool hadTaken = false;
                          for (final doc in docs) {
                            final data = doc.data();
                            final takenAt = data['taken_at'];
                            if (takenAt != null && takenAt is Timestamp) {
                              final d = takenAt.toDate();
                              if (_dayKey(d) == key &&
                                  (data['status'] ?? '').toString().toLowerCase().contains('taken')) {
                                hadTaken = true;
                                break;
                              }
                            }
                          }
                          if (hadTaken) {
                            currentStreak++;
                          } else if (i > 0) {
                            // Don't break on today if no logs yet
                            streakBroken = true;
                          }
                        }

                        // Adherence percentage
                        final double adherencePercent = totalLogs > 0
                            ? (takenCount / totalLogs * 100)
                            : 0.0;
                        final int adherenceRounded = adherencePercent.round();
                        final bool isGoodAdherence = adherenceRounded >= 80;

                        // Build bar chart data
                        final List<_BarData> barData = [];
                        // Show last 7 bars regardless of range
                        final int barCount = _selectedTab == 0 ? 7 : 7;
                        final int step = _selectedTab == 0 ? 1 : (rangeDays / 7).ceil();
                        for (int i = barCount - 1; i >= 0; i--) {
                          final dayOffset = i * step;
                          final day = now.subtract(Duration(days: dayOffset));
                          final key = _dayKey(day);
                          // Aggregate stats for the step window
                          int stepTaken = 0, stepMissed = 0;
                          for (int s = 0; s < step; s++) {
                            final k = _dayKey(now.subtract(Duration(days: dayOffset + s)));
                            if (chartDays.containsKey(k)) {
                              stepTaken += chartDays[k]!.taken;
                              stepMissed += chartDays[k]!.missed;
                            }
                          }
                          final total = stepTaken + stepMissed;
                          final label = _selectedTab == 0
                              ? DateFormat('E').format(day).toUpperCase().substring(0, 3)
                              : 'W${barCount - i}';
                          if (total > 0) {
                            final ratio = stepTaken / total;
                            barData.add(_BarData(label, ratio.clamp(0.05, 1.0), stepMissed == 0));
                          } else {
                            barData.add(_BarData(label, 0.05, true));
                          }
                        }

                        // Empty state
                        if (totalLogs == 0) {
                          return _buildEmptyState();
                        }

                        return Column(
                          children: [
                            _buildProgressRing(adherenceRounded, isGoodAdherence),
                            const SizedBox(height: 28),
                            _buildStreakBanner(currentStreak, isGoodAdherence, adherenceRounded),
                            const SizedBox(height: 16),
                            _buildStatsRow(totalLogs, takenCount, missedCount),
                            const SizedBox(height: 48),
                            _buildActivityLogs(barData),
                            const SizedBox(height: 40),
                            _buildHealthInsights(adherenceRounded, isGoodAdherence),
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
      ),
    );
  }

  // ── Helper: day key for grouping ─────────────────
  int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  // ── LOADING STATE ────────────────────────────────
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(
          children: [
            const SizedBox(width: 32, height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _S.secondary)),
            const SizedBox(height: 16),
            Text('Calculating analytics...',
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
            Icon(Icons.error_outline, size: 36, color: _S.warning),
            const SizedBox(height: 12),
            Text('Failed to load analytics',
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

  // ── EMPTY STATE ──────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          _buildProgressRing(0, false),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: _S.surfContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.analytics_outlined, size: 40, color: _S.outlineVariant),
                const SizedBox(height: 16),
                Text('No medication history yet',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700,
                        color: _S.primaryContainer)),
                const SizedBox(height: 6),
                Text('Take your first medication to start\ntracking your adherence.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 13, color: _S.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: _S.secondary, size: 24),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Analytics',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700,
                      color: _S.primaryContainer, letterSpacing: -0.3)),
            ),
          ),
          const SizedBox(width: 40), // Balance the back arrow
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
                ? [BoxShadow(color: _S.primaryContainer.withValues(alpha: 0.06),
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

  // ── PROGRESS RING (dynamic) ──────────────────────
  Widget _buildProgressRing(int percent, bool isGood) {
    final double progress = (percent / 100).clamp(0.0, 1.0);
    final Color ringColor = isGood ? _S.secondary : _S.warning;

    return SizedBox(
      width: 220, height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _AdherenceRingPainter(
              progress: progress,
              bgColor: _S.surfContainer,
              fgColor: ringColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$percent%',
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

  // ── STREAK BANNER (dynamic) ──────────────────────
  Widget _buildStreakBanner(int streak, bool isGood, int percent) {
    final String message;
    final Color bgColor;

    if (isGood) {
      message = streak > 1
          ? '🎉 Great job! You are on a $streak-day streak.'
          : '🎉 Great job! Your adherence is $percent%.';
      bgColor = _S.surfContainerLow;
    } else {
      message = percent > 0
          ? '⚠️ Your adherence is $percent%. Try to stay consistent.'
          : 'Start taking your medications to build a streak!';
      bgColor = _S.warning.withValues(alpha: 0.08);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isGood ? null : Border.all(color: _S.warning.withValues(alpha: 0.2)),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500,
              color: _S.onSurface, height: 1.4)),
    );
  }

  // ── STATS ROW (Total / Taken / Missed) ───────────
  Widget _buildStatsRow(int total, int taken, int missed) {
    return Row(
      children: [
        _statCard('Total Logs', '$total', _S.primaryContainer),
        const SizedBox(width: 12),
        _statCard('Taken', '$taken', _S.emerald),
        const SizedBox(width: 12),
        _statCard('Missed', '$missed', missed > 0 ? _S.warning : _S.onSurfaceVariant),
      ],
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _S.surfLowest,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 4), blurRadius: 12)],
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800,
                    color: valueColor)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700,
                    color: _S.onSurfaceVariant, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  // ── ACTIVITY LOGS BAR CHART (dynamic) ────────────
  Widget _buildActivityLogs(List<_BarData> bars) {
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
                  children: bars.map((bar) {
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

  // ── HEALTH INSIGHTS (dynamic) ────────────────────
  Widget _buildHealthInsights(int adherencePercent, bool isGood) {
    final String insightText;
    final IconData trendIcon;
    final Color trendColor;

    if (isGood) {
      insightText = 'Your medication adherence is at $adherencePercent%. '
          'Keep up the excellent work — consistent adherence is key to better health outcomes.';
      trendIcon = Icons.trending_up;
      trendColor = _S.emerald;
    } else {
      insightText = 'Your medication adherence is at $adherencePercent%. '
          'Try setting reminders and keeping medications visible to improve your consistency.';
      trendIcon = Icons.trending_down;
      trendColor = _S.warning;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _S.surfLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: isGood ? _S.secondary : _S.warning, width: 4)),
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
              Icon(trendIcon, size: 16, color: trendColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(insightText,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500,
                  color: _S.onSurface, height: 1.4)),
          const SizedBox(height: 20),
          // Sparkline
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(color: isGood ? _S.secondary : _S.warning),
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
//  Day Stats (for 7-day grouping)
// ═══════════════════════════════════════════════
class _DayStats {
  int taken = 0;
  int missed = 0;
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
  bool shouldRepaint(_AdherenceRingPainter old) => old.progress != progress || old.fgColor != fgColor;
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
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

