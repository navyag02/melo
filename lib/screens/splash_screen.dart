import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_routes.dart';

/// SplashScreen is the first screen users see when opening the app
/// It checks if a caregiver is logged in and redirects accordingly
/// This screen is mainly for caregivers - patients will be directed to home directly
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRedirect();
  }

  /// Check authentication status and redirect to appropriate screen
  /// If logged in as caregiver -> Caregiver Dashboard
  /// If not logged in -> Login screen
  /// We'll add patient flow later
  Future<void> _checkAuthAndRedirect() async {
    // Wait for 2 seconds to show splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Check if user is logged in
    final User? user = _auth.currentUser;
    
    if (user != null) {
      // User is logged in - redirect to caregiver dashboard
      Navigator.pushReplacementNamed(context, AppRoutes.caregiverDashboard);
    } else {
      // No user logged in - redirect to login screen
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50), // Green color - calming and positive
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo placeholder
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Melo',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // App tagline
            const Text(
              'Memory & Cognitive Assistance',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 60),
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
