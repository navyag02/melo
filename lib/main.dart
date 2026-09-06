import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_selection_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/memory_match_game_screen.dart';
import 'utils/app_routes.dart';

/// Main entry point for the Melo application
/// Initializes Firebase and sets up the app with navigation
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // Note: You need to add your Firebase configuration files:
  // - android/app/google-services.json
  // - ios/Runner/GoogleService-Info.plist
  // Get these from Firebase Console after creating your project
  // TODO: Uncomment Firebase initialization when config files are added
  // await Firebase.initializeApp();
  
  runApp(const MeloApp());
}

/// MeloApp is the root widget of the application
/// Sets up the theme, navigation routes, and overall app structure
class MeloApp extends StatelessWidget {
  const MeloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melo - Memory & Cognitive Assistance',
      debugShowCheckedModeBanner: false,
      
      // App theme optimized for elderly users
      theme: ThemeData(
        // Use a warm, calming color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Green as primary color
          brightness: Brightness.light,
        ),
        
        // Larger text sizes for elderly users
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 20),
          bodyMedium: TextStyle(fontSize: 18),
          bodySmall: TextStyle(fontSize: 16),
          labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        
        // Enable Material 3 design
        useMaterial3: true,
        
        // Default elevated button style for large touch targets
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60), // Large touch targets
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      
      // Navigation routes configuration
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.gameSelection: (context) => const GameSelectionScreen(),
        AppRoutes.caregiverDashboard: (context) => const CaregiverDashboardScreen(),
        AppRoutes.memoryMatchGame: (context) => const MemoryMatchGameScreen(),
      },
    );
  }
}
