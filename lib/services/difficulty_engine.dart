import '../models/session_model.dart';

/// DifficultyEngine - AI Adaptive Difficulty System
/// 
/// This is our "AI adaptive difficulty engine" for the hackathon demo.
/// It uses rule-based logic to adjust game difficulty based on patient performance.
/// 
/// The logic is transparent and explainable - important for healthcare credibility.
/// No black box ML models, just clear, rule-based adaptive learning.
/// Difficulty level enum for Firestore storage
  enum DifficultyLevel {
    easy,    // 4 pairs
    medium,  // 6 pairs (default)
    hard,    // 8 pairs
  }
  
class DifficultyEngine {
  
  /// Difficulty levels with their corresponding card pair counts
  static const int easyPairs = 4;      // 8 cards total
  static const int mediumPairs = 6;    // 12 cards total (default)
  static const int hardPairs = 8;      // 16 cards total
  
  /// Accuracy thresholds for difficulty adjustment
  static const double increaseThreshold = 0.80;  // 80% accuracy to increase difficulty
  static const double decreaseThreshold = 0.40;  // 40% accuracy to decrease difficulty
  
  
  
  /// Calculate the appropriate difficulty level based on recent performance
  /// 
  /// This is the core "AI" logic - transparent rule-based decision making:
  /// 
  /// STEP 1: Analyze recent performance (last 2-3 sessions)
  /// STEP 2: Check if patient is consistently performing well (accuracy >= 80%)
  /// STEP 3: Check if patient is struggling (accuracy <= 40%)
  /// STEP 4: Adjust difficulty accordingly or maintain current level
  /// 
  /// Parameters:
  /// - recentSessions: List of recent sessions (2-3 most recent)
  /// - currentDifficulty: Current difficulty level (default to medium if first session)
  /// 
  /// Returns: Recommended difficulty level for next round
  static DifficultyLevel calculateNextDifficulty({
    required List<SessionModel> recentSessions,
    DifficultyLevel currentDifficulty = DifficultyLevel.medium,
  }) {
    // RULE 1: If this is the patient's first session, start with medium difficulty
    if (recentSessions.isEmpty) {
      print('Difficulty Engine: First session - starting with medium difficulty (6 pairs)');
      return DifficultyLevel.medium;
    }
    
    // RULE 2: If we have at least 2 sessions, analyze performance trend
    if (recentSessions.length >= 2) {
      // Get the 2 most recent sessions
      SessionModel mostRecent = recentSessions[0];
      SessionModel secondMostRecent = recentSessions[1];
      
      double recentAccuracy1 = mostRecent.accuracy;
      double recentAccuracy2 = secondMostRecent.accuracy;
      
      print('Difficulty Engine: Analyzing recent performance:');
      print('  - Most recent session accuracy: ${(recentAccuracy1 * 100).toStringAsFixed(1)}%');
      print('  - Second recent session accuracy: ${(recentAccuracy2 * 100).toStringAsFixed(1)}%');
      
      // RULE 3: If both recent sessions show high performance (>= 80%), increase difficulty
      if (recentAccuracy1 >= increaseThreshold && recentAccuracy2 >= increaseThreshold) {
        print('Difficulty Engine: Patient performing well - INCREASING difficulty to hard (8 pairs)');
        return DifficultyLevel.hard;
      }
      
      // RULE 4: If both recent sessions show low performance (<= 40%), decrease difficulty
      if (recentAccuracy1 <= decreaseThreshold && recentAccuracy2 <= decreaseThreshold) {
        print('Difficulty Engine: Patient struggling - DECREASING difficulty to easy (4 pairs)');
        return DifficultyLevel.easy;
      }
      
      // RULE 5: If performance is mixed or moderate, maintain current difficulty
      print('Difficulty Engine: Performance is mixed - MAINTAINING current difficulty');
      return currentDifficulty;
    }
    
    // RULE 6: If we only have 1 session, maintain current difficulty
    print('Difficulty Engine: Only 1 session available - maintaining current difficulty');
    return currentDifficulty;
  }
  
  /// Convert difficulty level to number of card pairs
  static int getPairsForDifficulty(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return easyPairs;
      case DifficultyLevel.medium:
        return mediumPairs;
      case DifficultyLevel.hard:
        return hardPairs;
    }
  }
  
  /// Convert difficulty level to string for Firestore storage
  static String difficultyToString(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 'easy';
      case DifficultyLevel.medium:
        return 'medium';
      case DifficultyLevel.hard:
        return 'hard';
    }
  }
  
  /// Convert string from Firestore to difficulty level
  static DifficultyLevel stringToDifficulty(String levelString) {
    switch (levelString.toLowerCase()) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'medium':
        return DifficultyLevel.medium;
      case 'hard':
        return DifficultyLevel.hard;
      default:
        return DifficultyLevel.medium; // Default to medium
    }
  }
  
  /// Get user-friendly message for difficulty change
  /// This makes the AI logic visible and explainable to users/caregivers
  static String getDifficultyChangeMessage({
    required DifficultyLevel oldDifficulty,
    required DifficultyLevel newDifficulty,
  }) {
    if (newDifficulty == oldDifficulty) {
      return 'Same difficulty level for next round - keep up the good work!';
    }
    
    if (oldDifficulty == DifficultyLevel.medium && newDifficulty == DifficultyLevel.hard) {
      return 'Great job! Next round will be a bit harder (8 pairs).';
    }
    
    if (oldDifficulty == DifficultyLevel.medium && newDifficulty == DifficultyLevel.easy) {
      return 'Let\'s try an easier round next time (4 pairs).';
    }
    
    if (oldDifficulty == DifficultyLevel.easy && newDifficulty == DifficultyLevel.medium) {
      return 'Good progress! Moving to medium difficulty (6 pairs).';
    }
    
    if (oldDifficulty == DifficultyLevel.hard && newDifficulty == DifficultyLevel.medium) {
      return 'Let\'s try medium difficulty next round (6 pairs).';
    }
    
    if (oldDifficulty == DifficultyLevel.easy && newDifficulty == DifficultyLevel.hard) {
      return 'Excellent progress! Jumping to hard difficulty (8 pairs).';
    }
    
    if (oldDifficulty == DifficultyLevel.hard && newDifficulty == DifficultyLevel.easy) {
      return 'Let\'s start with easier rounds (4 pairs).';
    }
    
    return 'Difficulty adjusted for next round.';
  }
  
  /// Get descriptive name for difficulty level
  static String getDifficultyName(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 'Easy (4 pairs)';
      case DifficultyLevel.medium:
        return 'Medium (6 pairs)';
      case DifficultyLevel.hard:
        return 'Hard (8 pairs)';
    }
  }
}
