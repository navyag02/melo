import 'package:flutter/material.dart';
import '../utils/app_routes.dart';

/// GameSelectionScreen shows available games for patients to play
/// Features large, colorful cards with game names and descriptions
/// Designed for easy selection by elderly users
class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Consistent warm background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Select a Game',
          style: TextStyle(
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
              const Text(
                'Choose a game to play:',
                style: TextStyle(
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
                      title: 'Memory Match',
                      description: 'Find matching pairs of cards',
                      icon: Icons.style,
                      color: const Color(0xFFE91E63), // Pink
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.memoryMatchGame);
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Word Puzzle Game
                    _buildGameCard(
                      context,
                      title: 'Word Puzzle',
                      description: 'Arrange letters to form words',
                      icon: Icons.text_fields,
                      color: const Color(0xFF9C27B0), // Purple
                      onTap: () {
                        _showComingSoonMessage(context, 'Word Puzzle');
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Picture Quiz Game
                    _buildGameCard(
                      context,
                      title: 'Picture Quiz',
                      description: 'Identify objects in pictures',
                      icon: Icons.image,
                      color: const Color(0xFFFF5722), // Deep Orange
                      onTap: () {
                        _showComingSoonMessage(context, 'Picture Quiz');
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Number Sequence Game
                    _buildGameCard(
                      context,
                      title: 'Number Sequence',
                      description: 'Complete the number pattern',
                      icon: Icons.format_list_numbered,
                      color: const Color(0xFF009688), // Teal
                      onTap: () {
                        _showComingSoonMessage(context, 'Number Sequence');
                      },
                    ),
                  ],
                ),
              ),
            ],
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
