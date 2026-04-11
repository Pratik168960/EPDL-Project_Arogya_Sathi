import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdherenceHistoryScreen extends StatefulWidget {
  const AdherenceHistoryScreen({super.key});

  @override
  State<AdherenceHistoryScreen> createState() => _AdherenceHistoryScreenState();
}

class _AdherenceHistoryScreenState extends State<AdherenceHistoryScreen> {
  final int activeDayIndex = 3; // Thursday 24

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 32),
                    _buildMonthlySummary(),
                    const SizedBox(height: 40),
                    _buildDetailedChart(),
                    const SizedBox(height: 40),
                    _buildHistoryLog(),
                    const SizedBox(height: 100), // Nav bar padding
                  ],
                ),
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

  Widget _buildDateSelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dates = [21, 22, 23, 24, 25, 26, 27];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final isActive = index == activeDayIndex;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 56,
            height: 72,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF0F1C2C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isActive ? const Border(left: BorderSide(color: Color(0xFF006399), width: 2)) : const Border(left: BorderSide(color: Color(0x33006399), width: 2)),
              boxShadow: [
                if (!isActive) const BoxShadow(color: Color(0x050F1C2C), offset: Offset(0, 4), blurRadius: 12),
                if (isActive) const BoxShadow(color: Color(0x1A0F1C2C), offset: Offset(0, 8), blurRadius: 16),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  days[index],
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF44474C),
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  dates[index].toString(),
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF0F1C2C),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthlySummary() {
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
                  Text('October Summary', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
                  const SizedBox(height: 4),
                  Text('Clinical performance overview', style: GoogleFonts.publicSans(fontSize: 14, color: const Color(0xFF44474C))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x1A006399),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Color(0xFF006399), size: 16),
                    const SizedBox(width: 4),
                    Text('PRO MODE', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006399), letterSpacing: 1.0)),
                  ],
                ),
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
                          Text('94', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F1C2C), height: 1.0)),
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
                      Text('ACTIVE STREAK', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C), letterSpacing: 1.5)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('12', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F1C2C), height: 1.0)),
                          const SizedBox(width: 4),
                          Text('Days', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF44474C))),
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

  Widget _buildDetailedChart() {
    final heights = [0.6, 0.75, 0.4, 0.9, 0.95, 1.0, 0.5, 0.85, 0.9, 1.0, 0.95, 0.3, 0.88, 0.92, 1.0, 1.0, 0.94, 0.98, 0.2, 1.0, 1.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30-Day Velocity', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
            Text('VIEW REPORT', style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF006399), letterSpacing: 1.0)),
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
                height: 140 * heights[index],
                decoration: BoxDecoration(
                  color: isLast ? const Color(0xFF0F1C2C) : (isLow ? const Color(0x33006399) : const Color(0xFF006399)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('OCT 04', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C))),
            Text('TODAY', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C))),
          ],
        )
      ],
    );
  }

  Widget _buildHistoryLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Records', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
        const SizedBox(height: 16),
        _buildActiveRecordEntry('Oct 24, Thursday', '3/3 Doses Taken', true, [
          {'name': 'Metformin', 'desc': '500mg • Morning', 'time': '08:05 AM', 'color': const Color(0xFFE0C1A0)},
          {'name': 'Atorvastatin', 'desc': '20mg • Evening', 'time': '08:45 PM', 'color': const Color(0xFF006399)},
        ]),
        const SizedBox(height: 12),
        _buildCollapsedEntry('Oct 23, Wednesday', '2/3 Doses Taken', const Color(0xFFBA1A1A)),
        const SizedBox(height: 12),
        _buildCollapsedEntry('Oct 22, Tuesday', '3/3 Doses Taken', const Color(0xFF006399)),
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
                              Text(med['name'], style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
                              Text(med['desc'], style: GoogleFonts.publicSans(fontSize: 10, color: const Color(0xFF44474C))),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TAKEN', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006399), letterSpacing: 1.5)),
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

