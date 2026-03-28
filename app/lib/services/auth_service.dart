import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Listen to Auth State (Logs in/out automatically)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 2. Get Current User ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // 3. Sign Up
  static Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // 4. Log In
  static Future<UserCredential?> logIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // 5. Log Out
  static Future<void> logOut() async {
    await _auth.signOut();
  }
}