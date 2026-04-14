import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ═══════════════════════════════════════════════════════════
///  AUTH SERVICE
///  Handles Firebase Auth + Role Management + Caregiver Linking
///
///  Roles: "patient" | "caregiver"
///  Linking: Patients generate a 6-char share code.
///           Caregivers enter the code to link.
/// ═══════════════════════════════════════════════════════════
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Auth State ─────────────────────────────────
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static String? get currentUserId => _auth.currentUser?.uid;

  // ── Sign Up ───────────────────────────────────
  static Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── Log In ────────────────────────────────────
  static Future<UserCredential?> logIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── Log Out ───────────────────────────────────
  static Future<void> logOut() async {
    await _auth.signOut();
  }

  // ═══════════════════════════════════════════════
  //  ROLE MANAGEMENT
  // ═══════════════════════════════════════════════

  /// Get the current user's role. Returns null if not set yet.
  static Future<String?> getUserRole() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['role'] as String?;
  }

  /// Set the user's role (called once from RoleSelectionScreen).
  /// Also generates a share code for patients.
  static Future<void> setUserRole(String role) async {
    final uid = currentUserId;
    if (uid == null) return;

    final data = <String, dynamic>{
      'role': role,
      'email': _auth.currentUser?.email ?? '',
      'created_at': FieldValue.serverTimestamp(),
    };

    // Patients get a share code for caregiver linking
    if (role == 'patient') {
      data['share_code'] = _generateShareCode();
    }

    // Caregivers start with an empty linked_patients list
    if (role == 'caregiver') {
      data['linked_patients'] = [];
    }

    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════
  //  SHARE CODE — Patient Side
  // ═══════════════════════════════════════════════

  /// Generate a random 6-character alphanumeric code.
  static String _generateShareCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I/O/0/1 ambiguity
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Get the current patient's share code.
  static Future<String?> getShareCode() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['share_code'] as String?;
  }

  /// Regenerate the patient's share code.
  static Future<String> regenerateShareCode() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final newCode = _generateShareCode();
    await _db.collection('users').doc(uid).update({'share_code': newCode});
    return newCode;
  }

  // ═══════════════════════════════════════════════
  //  LINKING — Caregiver Side
  // ═══════════════════════════════════════════════

  /// Caregiver enters a share code to link to a patient.
  /// Returns the patient's display name/email on success.
  static Future<String> linkToPatient(String code) async {
    final caregiverUid = currentUserId;
    if (caregiverUid == null) throw Exception('Not authenticated');

    // Find the patient with this share code
    final query = await _db
        .collection('users')
        .where('share_code', isEqualTo: code.toUpperCase().trim())
        .where('role', isEqualTo: 'patient')
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid code. No patient found with this share code.');
    }

    final patientDoc = query.docs.first;
    final patientUid = patientDoc.id;
    final patientEmail = patientDoc.data()['email'] ?? 'Unknown';

    // Prevent self-linking
    if (patientUid == caregiverUid) {
      throw Exception('You cannot link to yourself.');
    }

    // Add patient to caregiver's linked_patients
    await _db.collection('users').doc(caregiverUid).update({
      'linked_patients': FieldValue.arrayUnion([patientUid]),
    });

    // Add caregiver to patient's linked_caregivers
    await _db.collection('users').doc(patientUid).update({
      'linked_caregivers': FieldValue.arrayUnion([caregiverUid]),
    });

    return patientEmail;
  }

  /// Unlink a patient from this caregiver.
  static Future<void> unlinkPatient(String patientUid) async {
    final caregiverUid = currentUserId;
    if (caregiverUid == null) return;

    await _db.collection('users').doc(caregiverUid).update({
      'linked_patients': FieldValue.arrayRemove([patientUid]),
    });

    await _db.collection('users').doc(patientUid).update({
      'linked_caregivers': FieldValue.arrayRemove([caregiverUid]),
    });
  }

  /// Get list of linked patient UIDs for the current caregiver.
  static Future<List<String>> getLinkedPatients() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || !data.containsKey('linked_patients')) return [];

    return List<String>.from(data['linked_patients']);
  }

  /// Get patient profile info by UID.
  static Future<Map<String, dynamic>?> getPatientProfile(String patientUid) async {
    final doc = await _db.collection('users').doc(patientUid).get();
    return doc.data();
  }
}