import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════
//  Stitch Design Tokens
// ═══════════════════════════════════════════════
class _S {
  static const Color surface           = Color(0xFFF7FAFD);
  static const Color surfContainerHigh = Color(0xFFE5E8EB);
  static const Color primaryContainer  = Color(0xFF0F1C2C);
  static const Color secondary         = Color(0xFF006399);
  static const Color onSurfaceVariant  = Color(0xFF44474C);
  static const Color outline           = Color(0xFF74777D);
}

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<DocumentSnapshot> _caregivers = [];
  String? _selectedCaregiverName;
  
  final _specialtyCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchCaregivers();
  }

  Future<void> _fetchCaregivers() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('caregivers')
          .get();

      if (mounted) {
        setState(() {
          _caregivers = snapshot.docs;
          if (_caregivers.isNotEmpty) {
            final firstDoc = _caregivers.first.data() as Map<String, dynamic>;
            _selectedCaregiverName = firstDoc['name'] ?? 'Unknown';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load caregivers: $e')));
      }
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _S.primaryContainer,
              onPrimary: Colors.white,
              onSurface: _S.primaryContainer,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
         return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _S.primaryContainer,
              onPrimary: Colors.white,
              onSurface: _S.primaryContainer,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _bookAppointment() async {
    if (_selectedCaregiverName == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Doctor, Date, and Time.'), backgroundColor: Color(0xFFBA1A1A))
      );
      return;
    }

    final uid = AuthService.currentUserId;
    if (uid == null) return;

    setState(() => _isSubmitting = true);

    try {
      final appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .add({
        'doctor_name': _selectedCaregiverName,
        'specialty': _specialtyCtrl.text.trim().isEmpty ? 'General Visit' : _specialtyCtrl.text.trim(),
        'hospital': _hospitalCtrl.text.trim().isEmpty ? 'Clinic' : _hospitalCtrl.text.trim(),
        'date_time': Timestamp.fromDate(appointmentDateTime),
        'duration_minutes': 30, // Default duration
        'status': 'upcoming',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully! ✓'), backgroundColor: Color(0xFF10B981))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e'), backgroundColor: const Color(0xFFBA1A1A))
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _S.onSurfaceVariant)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: _S.outline),
            filled: true,
            fillColor: _S.surfContainerHigh,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: GoogleFonts.outfit(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _S.surface,
      appBar: AppBar(
        backgroundColor: _S.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _S.primaryContainer),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Book Appointment',
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: _S.primaryContainer, letterSpacing: -0.5),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: _S.secondary))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Doctor selection
                Text('Select Doctor (Caregiver)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _S.onSurfaceVariant)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _S.surfContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCaregiverName,
                      icon: const Icon(Icons.expand_more, color: _S.primaryContainer),
                      items: _caregivers.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name']?.toString() ?? 'Unknown';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.w500, color: _S.primaryContainer)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCaregiverName = val);
                      },
                    ),
                  ),
                ),
                if (_caregivers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('No caregivers found in your care team.', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFBA1A1A))),
                  ),
                const SizedBox(height: 20),

                _buildTextField('Specialty (Optional)', Icons.medical_services_outlined, _specialtyCtrl, hint: 'e.g. Cardiologist'),
                _buildTextField('Hospital / Clinic (Optional)', Icons.local_hospital_outlined, _hospitalCtrl, hint: 'e.g. Apollo Clinic'),

                // Date Time selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appointment Date', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _S.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: _S.surfContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20, color: _S.outline),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                    style: GoogleFonts.outfit(color: _selectedDate == null ? _S.outline : _S.primaryContainer, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _S.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickTime,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: _S.surfContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 20, color: _S.outline),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedTime == null ? 'Select Time' : _selectedTime!.format(context),
                                    style: GoogleFonts.outfit(color: _selectedTime == null ? _S.outline : _S.primaryContainer, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _caregivers.isEmpty ? null : _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _S.secondary,
                      disabledBackgroundColor: _S.surfContainerHigh,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isSubmitting 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Confirm Booking', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}
