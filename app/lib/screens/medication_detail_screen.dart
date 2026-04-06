import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const MedicationDetailScreen({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data['name'] ?? 'Medication';
    final String dosage = data['dosage'] ?? 'Prescription Dose';
    final String indication = data['indication'] ?? 'General Management'; // Dummy for detail
    
    // Evaluate if it's currently taken or pending to influence the UI if needed
    final bool isTaken = data['isTaken'] ?? false;
    final String timeRaw = data['time']?.toString() ?? '--:-- AM';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCards(name, dosage, indication),
                    const SizedBox(height: 32),
                    _buildDailySchedule(timeRaw, isTaken),
                    const SizedBox(height: 32),
                    _buildAdherencePulse(),
                    const SizedBox(height: 32),
                    _buildClinicalGuidelines(),
                    const SizedBox(height: 60), // padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F1C2C)),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Medication Detail',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF006399),
              letterSpacing: -0.5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0F1C2C)),
            onPressed: () {
              // Future Edit logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCards(String name, String dosage, String indication) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Medication Hero Card ──
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x0A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -28, top: -28, bottom: -28,
                  child: Container(width: 4, color: const Color(0xFF006399)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE PRESCRIPTION',
                      style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C).withOpacity(0.6), letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: GoogleFonts.manrope(fontSize: 40, fontWeight: FontWeight.w800, color: const Color(0xFF0F1C2C), letterSpacing: -1.5, height: 1.1),
                    ),
                    Text(
                      dosage,
                      style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF006399)),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Primary Indication',
                      style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF44474C)),
                    ),
                    Text(
                      indication,
                      style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F1C2C)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── IoT Dispenser Status Card ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1C2C),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x1A0F1C2C), offset: Offset(0, 8), blurRadius: 24)],
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
                        Text('Dispenser Status', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF006399), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text('SYSTEM ONLINE', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.5)),
                          ],
                        )
                      ],
                    ),
                    const Icon(Icons.sensors, color: Color(0xFF006399)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('18', style: GoogleFonts.manrope(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0)),
                    const SizedBox(width: 8),
                    Text('Capsules Remaining', style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6,
                    child: Container(decoration: BoxDecoration(color: const Color(0xFF006399), borderRadius: BorderRadius.circular(3))),
                  ),
                ),
                const SizedBox(height: 12),
                Text('REFILL ESTIMATED IN 6 DAYS', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.5)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDailySchedule(String timeRaw, bool isTaken) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daily Schedule', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F1C2C))),
            Text('TODAY', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C).withOpacity(0.6), letterSpacing: 2.0)),
          ],
        ),
        const SizedBox(height: 16),
        _buildScheduleItem('08:00', 'AM', 'Morning Dose', isTaken ? 'Taken at 07:55 AM' : 'Pending', isTaken ? Icons.check_circle : Icons.schedule, isTaken ? const Color(0xFF006399) : const Color(0xFF44474C).withOpacity(0.4), isTaken ? const Color(0xFFF1F4F7) : Colors.white, isTaken ? null : const Color(0xFF006399)),
        const SizedBox(height: 12),
        _buildScheduleItem(timeRaw.split(' ')[0], timeRaw.contains(' ') ? timeRaw.split(' ')[1] : 'PM', 'Scheduled Dose', 'Pending dispense', Icons.schedule, const Color(0xFF44474C).withOpacity(0.4), Colors.white, const Color(0xFF006399).withOpacity(0.2)),
        const SizedBox(height: 12),
        _buildScheduleItem('19:00', 'PM', 'Evening Dose', 'Scheduled', Icons.calendar_today, const Color(0xFF44474C).withOpacity(0.4), const Color(0xFFF1F4F7), null),
      ],
    );
  }

  Widget _buildScheduleItem(String time, String period, String title, String subtitle, IconData icon, Color iconColor, Color bgColor, Color? borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: borderColor != null ? Border(left: BorderSide(color: borderColor, width: 4)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text(time, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
                    Text(period, style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C).withOpacity(0.4))),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: const Color(0xFFE0E3E6).withOpacity(0.5), margin: const EdgeInsets.symmetric(horizontal: 20)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
                  Text(subtitle, style: GoogleFonts.publicSans(fontSize: 12, fontWeight: FontWeight.w600, color: iconColor == const Color(0xFF006399) ? iconColor : const Color(0xFF44474C).withOpacity(0.6))),
                ],
              ),
            ],
          ),
          Icon(icon, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildAdherencePulse() {
    final heights = [0.85, 0.95, 1.0, 0.60, 0.90, 0.95, 1.0];
    final isError = [false, false, false, true, false, false, false];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Adherence Pulse', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F1C2C))),
        const SizedBox(height: 16),
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('96%', style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF0F1C2C))),
                  const SizedBox(width: 4),
                  Text('7-DAY AVG', style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF44474C).withOpacity(0.6), letterSpacing: 1.0)),
                ],
              ),
              const Expanded(child: SizedBox()),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  return Container(
                    width: 32,
                    height: 80 * heights[index],
                    decoration: BoxDecoration(
                      color: isError[index] ? const Color(0xFFBA1A1A).withOpacity(0.6) : const Color(0xFF006399).withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicalGuidelines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clinical Guidelines', style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F1C2C))),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: [
            _buildGuidelineCard(Icons.restaurant, 'With Meals', 'Take during or immediately after food to reduce GI effects.', const Color(0xFF006399)),
            _buildGuidelineCard(Icons.no_drinks, 'Avoid Alcohol', 'Risk of lactic acidosis increases significantly with intake.', const Color(0xFFBA1A1A)),
            _buildGuidelineCard(Icons.water_drop, 'Hydration', 'Maintain steady fluid intake throughout the day.', const Color(0xFF006399)),
            _buildGuidelineCard(Icons.info, 'Consistency', 'Take at the same time daily for maximum efficacy.', const Color(0xFF44474C)),
          ],
        ),
      ],
    );
  }

  Widget _buildGuidelineCard(IconData icon, String title, String desc, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F1C2C))),
          const SizedBox(height: 8),
        Expanded(child: Text(desc, style: GoogleFonts.publicSans(fontSize: 12, color: const Color(0xFF44474C).withOpacity(0.7), height: 1.4))),
        ],
      ),
    );
  }
}
