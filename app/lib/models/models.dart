import 'package:flutter/material.dart';

// ─── Medication Model ──────────────────────────────
enum MedStatus { taken, upcoming, missed, skipped }

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final TimeOfDay time;
  final String mealInstruction; // "Before Breakfast", "After Lunch", etc.
  final MedStatus status;
  final Color color;
  final int pillCount;
  bool reminderEnabled;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.mealInstruction,
    this.status = MedStatus.upcoming,
    this.color = const Color(0xFF1A6FC4),
    this.pillCount = 1,
    this.reminderEnabled = true,
  });
}

// ─── Appointment Model ─────────────────────────────
enum AppointmentStatus { upcoming, completed, cancelled }

class Appointment {
  final String id;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime dateTime;
  final int durationMinutes;
  final AppointmentStatus status;
  final Color accentColor;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.dateTime,
    this.durationMinutes = 30,
    this.status = AppointmentStatus.upcoming,
    this.accentColor = const Color(0xFF1A6FC4),
  });
}

// ─── Health Record Model ───────────────────────────
enum RecordCategory { bloodTest, prescription, xray, vaccination, other }

class HealthRecord {
  final String id;
  final String name;
  final RecordCategory category;
  final DateTime uploadedDate;
  final double fileSizeMb;
  final String fileType;

  HealthRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.uploadedDate,
    required this.fileSizeMb,
    this.fileType = 'PDF',
  });

  String get categoryLabel {
    switch (category) {
      case RecordCategory.bloodTest: return 'Blood Test';
      case RecordCategory.prescription: return 'Prescription';
      case RecordCategory.xray: return 'Radiology';
      case RecordCategory.vaccination: return 'Vaccination';
      case RecordCategory.other: return 'Other';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case RecordCategory.bloodTest: return '🩸';
      case RecordCategory.prescription: return '📜';
      case RecordCategory.xray: return '🫁';
      case RecordCategory.vaccination: return '💉';
      case RecordCategory.other: return '📄';
    }
  }

  Color get categoryColor {
    switch (category) {
      case RecordCategory.bloodTest: return const Color(0xFFE53E3E);
      case RecordCategory.prescription: return const Color(0xFF1A6FC4);
      case RecordCategory.xray: return const Color(0xFF2EAE82);
      case RecordCategory.vaccination: return const Color(0xFFF6820D);
      case RecordCategory.other: return const Color(0xFF7C5CBF);
    }
  }
}

// ─── User Profile Model ────────────────────────────
class UserProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final List<String> conditions;
  final String phone;
  final String email;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    this.conditions = const [],
    required this.phone,
    required this.email,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
  });
}

// ─── Dummy Data ────────────────────────────────────
class DummyData {
  static final UserProfile user = UserProfile(
    id: 'user_001',
    name: 'Rahul Sharma',
    age: 32,
    gender: 'Male',
    bloodGroup: 'A+',
    conditions: ['Type 2 Diabetes', 'Hypertension'],
    phone: '+91 98765 43210',
    email: 'rahul.sharma@gmail.com',
    address: 'Pune, Maharashtra, India',
    emergencyContactName: 'Sneha Sharma',
    emergencyContactPhone: '+91 98100 11223',
    emergencyContactRelation: 'Spouse',
  );

  static final List<Medication> medications = [
    Medication(
      id: 'med_001',
      name: 'Metformin',
      dosage: '500mg',
      frequency: 'Twice daily',
      time: const TimeOfDay(hour: 8, minute: 0),
      mealInstruction: 'After Breakfast',
      status: MedStatus.taken,
      color: const Color(0xFF2EAE82),
    ),
    Medication(
      id: 'med_002',
      name: 'Atorvastatin',
      dosage: '10mg',
      frequency: 'Once daily',
      time: const TimeOfDay(hour: 13, minute: 0),
      mealInstruction: 'With Lunch',
      status: MedStatus.upcoming,
      color: const Color(0xFF1A6FC4),
    ),
    Medication(
      id: 'med_003',
      name: 'Vitamin D3',
      dosage: '1000 IU',
      frequency: 'Once daily',
      time: const TimeOfDay(hour: 9, minute: 0),
      mealInstruction: 'Morning',
      status: MedStatus.missed,
      color: const Color(0xFFF6820D),
      reminderEnabled: false,
    ),
    Medication(
      id: 'med_004',
      name: 'Amlodipine',
      dosage: '5mg',
      frequency: 'Once daily',
      time: const TimeOfDay(hour: 21, minute: 0),
      mealInstruction: 'After Dinner',
      status: MedStatus.upcoming,
      color: const Color(0xFF7C5CBF),
    ),
  ];

  static final List<Appointment> appointments = [
    Appointment(
      id: 'appt_001',
      doctorName: 'Dr. Priya Menon',
      specialty: 'Endocrinologist',
      hospital: 'Apollo Clinic, Pune',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 10)),
      durationMinutes: 30,
      accentColor: const Color(0xFF1A6FC4),
    ),
    Appointment(
      id: 'appt_002',
      doctorName: 'Dr. Arvind Shah',
      specialty: 'General Physician',
      hospital: 'Fortis Hospital, Pune',
      dateTime: DateTime.now().add(const Duration(days: 7, hours: 16)),
      durationMinutes: 20,
      accentColor: const Color(0xFF2EAE82),
    ),
    Appointment(
      id: 'appt_003',
      doctorName: 'Dr. Kavita Nair',
      specialty: 'Ophthalmologist',
      hospital: 'Eye Care Centre, Pune',
      dateTime: DateTime.now().subtract(const Duration(days: 14)),
      durationMinutes: 45,
      status: AppointmentStatus.completed,
      accentColor: const Color(0xFF7C5CBF),
    ),
  ];

  static final List<HealthRecord> records = [
    HealthRecord(
      id: 'rec_001',
      name: 'Blood_Report_Mar2025.pdf',
      category: RecordCategory.bloodTest,
      uploadedDate: DateTime(2025, 3, 12),
      fileSizeMb: 2.3,
    ),
    HealthRecord(
      id: 'rec_002',
      name: 'Dr_Menon_Prescription.pdf',
      category: RecordCategory.prescription,
      uploadedDate: DateTime(2025, 3, 10),
      fileSizeMb: 0.8,
    ),
    HealthRecord(
      id: 'rec_003',
      name: 'Chest_XRay_2024.jpg',
      category: RecordCategory.xray,
      uploadedDate: DateTime(2024, 11, 5),
      fileSizeMb: 4.1,
      fileType: 'JPG',
    ),
    HealthRecord(
      id: 'rec_004',
      name: 'CovidVaccine_Cert.pdf',
      category: RecordCategory.vaccination,
      uploadedDate: DateTime(2023, 8, 20),
      fileSizeMb: 1.2,
    ),
    HealthRecord(
      id: 'rec_005',
      name: 'HbA1c_Test_Jan2025.pdf',
      category: RecordCategory.bloodTest,
      uploadedDate: DateTime(2025, 1, 15),
      fileSizeMb: 1.8,
    ),
  ];

  static const String dailyHealthTip =
      'Eating fiber-rich foods like dal, sabzi, and whole grains helps regulate blood sugar and keeps your gut healthy. Aim for 25–30g of fiber daily for best results.';

  static const Map<String, int> vitalStats = {
    'heartRate': 72,
    'systolic': 120,
    'diastolic': 80,
    'spo2': 98,
  };

  static const int weeklyAdherencePercent = 75;
  static const int waterGlassesGoal = 8;
  static const int waterGlassesDone = 5;
}
