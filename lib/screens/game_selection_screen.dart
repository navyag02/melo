import 'package:flutter/material.dart';
import '../utils/app_routes.dart';
import '../services/language_service.dart';
import '../utils/app_strings.dart';

/// GameSelectionScreen shows available games for patients to play
/// Features large, colorful cards with game names and descriptions
/// Designed for easy selection by elderly users
class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIX: wrapped in ListenableBuilder so this screen's translated text
    // rebuilds when the language changes.
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Consistent warm background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text(
          AppStrings.t('select_a_game'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header text
              Text(
                AppStrings.t('choose_game_to_play'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Game cards
              Expanded(
                child: ListView(
                  children: [
                    // Memory Match Game
                    _buildGameCard(
                      context,
                      title: AppStrings.t('memory_match_title'),
                      description: AppStrings.t('memory_match_desc'),
                      icon: Icons.style,
                      color: const Color(0xFFE91E63), // Pink
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.memoryMatchGame);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Trip Itinerary Recall Game
                    _buildGameCard(
                      context,
                      title: AppStrings.t('trip_itinerary_title'),
                      description: AppStrings.t('trip_itinerary_desc'),
                      icon: Icons.luggage,
                      color: const Color(0xFF3F51B5), // Indigo
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.tripItinerary);
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Daily Routine Recall Game
                    _buildGameCard(
                      context,
                      title: AppStrings.t('daily_routine_title'),
                      description: AppStrings.t('daily_routine_desc'),
                      icon: Icons.checklist,
                      color: const Color(0xFF9C27B0), // Purple
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.dailyRoutineRecall);
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Attention & Concentration Game
                    _buildGameCard(
                      context,
                      title: AppStrings.t('spot_difference_title'),
                      description: AppStrings.t('spot_difference_desc'),
                      icon: Icons.visibility,
                      color: const Color(0xFFFF5722), // Deep Orange
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.attentionFocus);
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    
                    // Personal Memories Game
                    _buildGameCard(
                      context,
                      title: AppStrings.t('personal_memories_title'),
                      description: AppStrings.t('personal_memories_desc'),
                      icon: Icons.photo_album,
                      color: const Color(0xFF795548), // Brown — warm, personal
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.personalMemoriesPlay);
                      },
                    ),
                    const SizedBox(height: 20),
                    

                    // Number Sequence Game
                    _buildGameCard(
                      context,
                      title: AppStrings.t('number_sequence_title'),
                      description: AppStrings.t('number_sequence_desc'),
                      icon: Icons.format_list_numbered,
                      color: const Color(0xFF009688), // Teal
                      onTap: () {
                        _showComingSoonMessage(context, AppStrings.t('number_sequence_title'));
                      },
                    ),
                    
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Build a large game card with elderly-friendly design
  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Row(
            children: [
              // Game icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              
              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 28,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a "coming soon" message for games not yet implemented
  void _showComingSoonMessage(BuildContext context, String gameName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$gameName is coming soon!',
          style: const TextStyle(fontSize: 20),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
