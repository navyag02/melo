import 'package:flutter/material.dart';
import '../utils/app_routes.dart';
import '../services/language_service.dart';
import '../utils/app_strings.dart';

/// HomeScreen is the main menu for patients
/// Features large, high-contrast buttons for easy navigation
/// This is designed specifically for elderly users with cognitive challenges
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: wrapped in ListenableBuilder so this whole screen rebuilds
    // with translated text whenever the language changes.
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFFFFF8E1), // Warm, calming light yellow background
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          title: const Text(
            'Melo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome message
                Text(
                  AppStrings.t('welcome'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.t('what_to_do_today'),
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Main action buttons
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Play Games button
                      _buildLargeButton(
                        context,
                        title: AppStrings.t('play_games'),
                        icon: Icons.games,
                        color: const Color(0xFF2196F3), // Blue
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.gameSelection);
                        },
                      ),
                      const SizedBox(height: 30),

                      // Reminders button
                      _buildLargeButton(
                        context,
                        title: AppStrings.t('reminders'),
                        icon: Icons.alarm,
                        color: const Color(0xFFFF9800), // Orange
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.reminders);
                        },
                      ),
                      const SizedBox(height: 30),

                      // Settings button — now opens the language selector
                      _buildLargeButton(
                        context,
                        title: AppStrings.t('settings'),
                        icon: Icons.settings,
                        color: const Color(0xFF9E9E9E), // Gray
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.languageSelector);
                        },
                      ),
                    ],
                  ),
                ),

                // Caregiver login button at bottom
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  child: Text(
                    AppStrings.t('caregiver_login'),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a large, elderly-friendly button
  Widget _buildLargeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 80, // Large touch target for elderly users
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: Colors.white,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
