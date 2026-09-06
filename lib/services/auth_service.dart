import 'package:firebase_auth/firebase_auth.dart';

/// AuthService handles all Firebase Authentication operations
/// This service manages caregiver login using email/password authentication
/// Patients don't need login - they use the app directly
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login caregiver with email and password
  /// Returns the User object if successful
  /// Throws an exception if login fails
  Future<User?> loginCaregiver(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  /// Register a new caregiver account
  /// Returns the User object if successful
  /// Throws an exception if registration fails
  Future<User?> registerCaregiver(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  /// Logout the current caregiver
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }

  /// Check if a user is currently logged in
  bool get isLoggedIn => _auth.currentUser != null;
}
