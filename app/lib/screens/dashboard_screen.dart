import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Clean white/light gray background
      body: Stack(
        children: [
          // Main Scrollable Content
          ListView(
            padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav and FAB
            children: [
              _buildHeader(),
              _buildFeaturedCard(),
              _buildQuickActions(),
              _buildHealthSummary(),
              _buildMedicationsSection(),
            ],
          ),
          
          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color(0xFF006399), // Navy/Teal block
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // 1 & 2. Status Bar integration is handled by SafeArea natively. Header:
  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0F1C2C), // Dark Navy Blue
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Generic placeholder
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rahul Sharma',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PATIENT ID: AS-9942',
                    style: GoogleFonts.publicSans(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Stack(
            children: [
              const Icon(Icons.notifications_none, color: Colors.white, size: 28),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // 3. Featured Dose Card
  Widget _buildFeaturedCard() {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF102841), // Deep Navy Blue
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF006399).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF006399),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.alarm, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Dose: 8:00 AM',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Metformin 500mg • 1 Capsule',
                    style: GoogleFonts.publicSans(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  // 4. Quick Action Row
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionItem(Icons.calendar_today, 'BOOK APPT', const Color(0xFF006399)),
          _actionItem(Icons.note_add_outlined, 'ADD RECORD', const Color(0xFF006399)),
          _actionItem(Icons.medication_outlined, 'MEDICINES', const Color(0xFF006399)), // Pill capsule
          _actionItem(Icons.emergency, 'EMERGENCY', Colors.red), // Red asterisk
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: GoogleFonts.publicSans(
            color: color == Colors.red ? Colors.red : const Color(0xFF4A5568),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 5. HEALTH SUMMARY
  Widget _buildHealthSummary() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEALTH SUMMARY',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: const Color(0xFF0F1C2C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _healthCard(
                  title: 'MEDS TODAY',
                  value: '3/4',
                  unit: 'Taken',
                  showAccentLine: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _healthCard(
                  title: 'HEART RATE',
                  value: '72',
                  unit: 'bpm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _healthCard(
                  title: 'BLOOD PRESSURE',
                  value: '120/80',
                  unit: '',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _healthCard(
                  title: 'SPO2',
                  value: '98',
                  unit: '%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthCard({required String title, required String value, required String unit, bool showAccentLine = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Light grayish-blue
        borderRadius: BorderRadius.circular(12),
        border: showAccentLine ? const Border(left: BorderSide(color: Color(0xFF006399), width: 4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.publicSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A5568),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F1C2C),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }

  // 6. TODAY'S MEDICATIONS
  Widget _buildMedicationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY\'S MEDICATIONS',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: const Color(0xFF0F1C2C),
                ),
              ),
              Text(
                'VIEW ALL',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF006399),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _medicationCard(
            time: '08:00',
            ampm: 'AM',
            name: 'Metformin 500mg',
            description: 'Diabetes Management',
            isTaken: false,
          ),
          _medicationCard(
            time: '12:30',
            ampm: 'PM',
            name: 'Atorvastatin 20mg',
            description: 'Cholesterol Control',
            isTaken: false,
          ),
          _medicationCard(
            time: '07:00',
            ampm: 'AM',
            name: 'Lisinopril 10mg',
            description: 'Blood Pressure',
            isTaken: true,
          ),
        ],
      ),
    );
  }

  Widget _medicationCard({
    required String time,
    required String ampm,
    required String name,
    required String description,
    required bool isTaken,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isTaken ? Colors.white.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: isTaken ? null : const Border(left: BorderSide(color: Color(0xFF006399), width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isTaken ? Colors.grey : const Color(0xFF4A5568),
                      ),
                    ),
                    Text(
                      ampm,
                      style: GoogleFonts.publicSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                      color: isTaken ? Colors.grey : const Color(0xFF0F1C2C),
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isTaken)
            const Icon(Icons.check_circle, color: Color(0xFF006399), size: 28)
          else
            Switch.adaptive(
              value: true, // Rendered in 'on' state as requested
              activeColor: const Color(0xFF006399),
              onChanged: (val) {},
            ),
        ],
      ),
    );
  }

  // 8. Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Slight blur effect base
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, 'HOME', 0),
          _navItem(Icons.medication_outlined, 'MEDS', 1),
          _navItem(Icons.description_outlined, 'HEALTH', 2),
          _navItem(Icons.person_outline, 'PROFILE', 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _bottomNavIndex == index;
    Color color = isSelected ? const Color(0xFF006399) : Colors.grey.shade400;

    return GestureDetector(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
