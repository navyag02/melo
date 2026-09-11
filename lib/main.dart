import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/add_patient_screen.dart';
import 'screens/patient_selector_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_selection_screen.dart';
import 'screens/caregiver_dashboard_screen.dart';
import 'screens/memory_match_game_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/daily_routine_recall_screen.dart';
import 'screens/attention_focus_screen.dart';
import 'screens/personal_memories_manage_screen.dart';
import 'screens/personal_memory_form_screen.dart';
import 'screens/personal_memories_play_screen.dart';
import 'utils/app_routes.dart';
import 'firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_options.dart';

/// Main entry point for the Melo application
/// Initializes Firebase, Supabase, and sets up the app with navigation
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase for Personal Memories image storage
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Green as primary color
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(
          const TextTheme(
            displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            titleSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            // Body/label sizes raised to a consistent 20 baseline for
            // elderly-friendly readability, as requested.
            bodyLarge: TextStyle(fontSize: 20),
            bodyMedium: TextStyle(fontSize: 20),
            bodySmall: TextStyle(fontSize: 20),
            labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            labelMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            labelSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        useMaterial3: true,
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
        AppRoutes.signup: (context) => const SignupScreen(),
        // FIX: these two routes were missing before — navigating to them
        // would crash the app with a "route not found" error.
        AppRoutes.addPatient: (context) => const AddPatientScreen(),
        AppRoutes.patientSelector: (context) => const PatientSelectorScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.gameSelection: (context) => const GameSelectionScreen(),
        AppRoutes.caregiverDashboard: (context) => const CaregiverDashboardScreen(),
        AppRoutes.memoryMatchGame: (context) => const MemoryMatchGameScreen(),
        AppRoutes.reminders: (context) => const RemindersScreen(),
        AppRoutes.dailyRoutineRecall: (context) => const DailyRoutineRecallScreen(),
        AppRoutes.attentionFocus: (context) => const AttentionFocusScreen(),
        AppRoutes.personalMemoriesManage: (context) => const PersonalMemoriesManageScreen(),
        AppRoutes.personalMemoryForm: (context) => const PersonalMemoryFormScreen(),
        AppRoutes.personalMemoriesPlay: (context) => const PersonalMemoriesPlayScreen(),
      },
    );
  }
}
