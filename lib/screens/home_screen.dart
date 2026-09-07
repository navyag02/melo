import 'package:flutter/material.dart';
import '../utils/app_routes.dart';

/// HomeScreen is the main menu for patients
/// Features large, high-contrast buttons for easy navigation
/// This is designed specifically for elderly users with cognitive challenges
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'What would you like to do today?',
                style: TextStyle(
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
                      title: 'Play Games',
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
                      title: 'Reminders',
                      icon: Icons.alarm,
                      color: const Color(0xFFFF9800), // Orange
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.reminders);
                      },
                    ),
                    const SizedBox(height: 30),
                    
                    // Settings button (placeholder for now)
                    _buildLargeButton(
                      context,
                      title: 'Settings',
                      icon: Icons.settings,
                      color: const Color(0xFF9E9E9E), // Gray
                      onTap: () {
                        _showComingSoonMessage(context);
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
                child: const Text(
                  'Caregiver Login',
                  style: TextStyle(
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

  /// Show a "coming soon" message for features not yet implemented
  void _showComingSoonMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This feature is coming soon!',
          style: TextStyle(fontSize: 20),
        ),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
