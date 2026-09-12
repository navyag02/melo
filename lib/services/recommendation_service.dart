import 'dart:math';
import 'tflite_loader.dart';
import '../models/session_model.dart';

/// RecommendationService — on-device AI recommendation for "what game
/// should this patient play next."
///
/// This is SEPARATE from DifficultyEngine: DifficultyEngine decides how
/// hard a chosen game should be; this decides WHICH game to choose.
///
/// The model was trained offline on synthetic data that distills the same
/// domain intuition already used elsewhere in the app (low accuracy or a
/// game not played in a while = needs reinforcement). As real session data
/// accumulates across patients, the model bundled here can be retrained
/// on real data and swapped in — see the training script for details.
///
/// IMPORTANT: the feature order/meaning here MUST exactly match
/// train_recommendation_model.py. If you change one, change the other.
class RecommendationService {
  static const List<String> _games = [
    'memory_matching_ner',
    'daily_routine_recall_ner',
    'attention_focus_ner',
    'trip_itinerary_recall_ner',
  ];

  static const Map<String, String> _gameLabels = {
    'memory_matching_ner': 'Memory Match',
    'daily_routine_recall_ner': 'Daily Routine Recall',
    'attention_focus_ner': 'Spot the Difference',
    'trip_itinerary_recall_ner': 'Trip Itinerary Recall',
  };

  final TFLiteLoader _loader = TFLiteLoader();
  bool _modelReady = false;
  bool _loadFailed = false;

  /// Load the bundled TFLite model. Call this once (e.g. in initState of
  /// the dashboard) before calling recommend(). Safe to call multiple
  /// times — it's a no-op after the first attempt. On web, this always
  /// resolves to false (see tflite_loader_stub.dart), so recommend()
  /// transparently uses the rule-based fallback there.
  Future<void> loadModel() async {
    if (_modelReady || _loadFailed) return;
    final success = await _loader.load('assets/models/recommendation_model.tflite');
    if (success) {
      _modelReady = true;
    } else {
      _loadFailed = true;
    }
  }

  /// Returns a GameRecommendation for the patient's next game, using the
  /// on-device model. Falls back to a simple rule if the model isn't
  /// available.
  GameRecommendation recommend(List<SessionModel> allSessions) {
    if (!_modelReady) {
      return _fallbackRecommendation(allSessions);
    }

    try {
      final features = _extractFeatures(allSessions);
      final probabilities = _loader.runInference(features, _games.length);

      if (probabilities == null) {
        return _fallbackRecommendation(allSessions);
      }

      int bestIndex = 0;
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > probabilities[bestIndex]) bestIndex = i;
      }

      final gameType = _games[bestIndex];
      final confidence = probabilities[bestIndex];
      final reason = _explainRecommendation(gameType, allSessions);

      return GameRecommendation(
        gameType: gameType,
        gameLabel: _gameLabels[gameType]!,
        confidence: confidence,
        reason: reason,
        isFallback: false,
      );
    } catch (e) {
      print('RecommendationService: inference failed, using fallback: $e');
      return _fallbackRecommendation(allSessions);
    }
  }

  /// Feature extraction — MUST mirror generate_synthetic_dataset() in
  /// train_recommendation_model.py exactly (same order, same scaling).
  List<double> _extractFeatures(List<SessionModel> allSessions) {
    final features = <double>[];
    final now = DateTime.now();

    for (final game in _games) {
      final gameSessions = allSessions
          .where((s) => s.gameType == game)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // newest first

      double recentAccuracy;
      double staleness;
      double difficultyEncoded;

      if (gameSessions.isEmpty) {
        recentAccuracy = 0.6; // neutral default, matches training
        staleness = 1.0; // never played = maximally stale
        difficultyEncoded = 0.5; // medium default
      } else {
        final recent = gameSessions.take(3).toList();
        recentAccuracy =
            recent.map((s) => s.accuracy).reduce((a, b) => a + b) / recent.length;

        final daysSinceLastPlayed =
            now.difference(gameSessions.first.timestamp).inDays;
        staleness = (daysSinceLastPlayed / 14.0).clamp(0.0, 1.0);

        difficultyEncoded = _difficultyToDouble(gameSessions.first.difficultyLevel);
      }

      features.addAll([recentAccuracy, staleness, difficultyEncoded]);
    }

    // Global features
    final sortedAll = List<SessionModel>.from(allSessions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    double overallTrend = 0.0;
    if (sortedAll.length >= 2) {
      final recentFive = sortedAll.take(5).toList().reversed.toList();
      overallTrend = _calculateTrend(recentFive.map((s) => s.accuracy).toList());
    }

    final totalSessionsNorm = (allSessions.length / 20.0).clamp(0.0, 1.0);

    double avgDurationNorm = 0.5;
    if (allSessions.isNotEmpty) {
      final avgDuration = allSessions
              .map((s) => s.durationSeconds)
              .reduce((a, b) => a + b) /
          allSessions.length;
      avgDurationNorm = (avgDuration / 180.0).clamp(0.0, 1.0);
    }

    features.addAll([overallTrend, totalSessionsNorm, avgDurationNorm]);

    return features;
  }

  double _difficultyToDouble(String? difficulty) {
    switch (difficulty) {
      case 'easy':
        return 0.0;
      case 'hard':
        return 1.0;
      case 'medium':
      default:
        return 0.5;
    }
  }

  /// Simple linear-regression-style slope over a list of accuracy values,
  /// normalized to roughly -1..1. Positive = improving, negative = declining.
  double _calculateTrend(List<double> accuracies) {
    final n = accuracies.length;
    if (n < 2) return 0.0;

    final xMean = (n - 1) / 2.0;
    final yMean = accuracies.reduce((a, b) => a + b) / n;

    double numerator = 0.0;
    double denominator = 0.0;
    for (int i = 0; i < n; i++) {
      numerator += (i - xMean) * (accuracies[i] - yMean);
      denominator += pow(i - xMean, 2);
    }

    if (denominator == 0.0) return 0.0;
    final slope = numerator / denominator;
    // Scale slope to a roughly -1..1 range for a typical few-session window.
    return (slope * n).clamp(-1.0, 1.0);
  }

  /// Explainability layer — surfaces the most likely reason for a caregiver,
  /// so the recommendation isn't a black box. Keeps with the app's existing
  /// transparent, explainable design philosophy.
  String _explainRecommendation(String gameType, List<SessionModel> allSessions) {
    final gameSessions = allSessions.where((s) => s.gameType == gameType).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (gameSessions.isEmpty) {
      return 'The patient hasn\'t tried ${_gameLabels[gameType]} yet.';
    }

    final recent = gameSessions.take(3).toList();
    final avgAccuracy =
        recent.map((s) => s.accuracy).reduce((a, b) => a + b) / recent.length;
    final daysSince = DateTime.now().difference(gameSessions.first.timestamp).inDays;

    if (avgAccuracy < 0.5) {
      return 'Recent accuracy in ${_gameLabels[gameType]} is lower than other games.';
    } else if (daysSince > 7) {
      return 'It\'s been $daysSince days since the patient played ${_gameLabels[gameType]}.';
    } else {
      return 'This game best matches the patient\'s current needs.';
    }
  }

  /// Fallback when the ML model isn't available: recommend whichever game
  /// has the lowest recent accuracy (or hasn't been played, or is stalest).
  /// Same transparent logic style as DifficultyEngine.
  GameRecommendation _fallbackRecommendation(List<SessionModel> allSessions) {
    if (allSessions.isEmpty) {
      return GameRecommendation(
        gameType: _games.first,
        gameLabel: _gameLabels[_games.first]!,
        confidence: 0.0,
        reason: 'No sessions yet — starting with Memory Match.',
        isFallback: true,
      );
    }

    String worstGame = _games.first;
    double worstScore = -1.0;

    for (final game in _games) {
      final gameSessions = allSessions.where((s) => s.gameType == game).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      double score;
      if (gameSessions.isEmpty) {
        score = 1.0; // never played = high priority
      } else {
        final recent = gameSessions.take(3).toList();
        final avgAccuracy =
            recent.map((s) => s.accuracy).reduce((a, b) => a + b) / recent.length;
        final daysSince =
            DateTime.now().difference(gameSessions.first.timestamp).inDays;
        score = (1.0 - avgAccuracy) * 0.6 + (daysSince / 14.0).clamp(0.0, 1.0) * 0.4;
      }

      if (score > worstScore) {
        worstScore = score;
        worstGame = game;
      }
    }

    return GameRecommendation(
      gameType: worstGame,
      gameLabel: _gameLabels[worstGame]!,
      confidence: 0.0,
      reason: _explainRecommendation(worstGame, allSessions),
      isFallback: true,
    );
  }

  void dispose() {
    _loader.dispose();
  }
}

/// Result of a recommendation — includes the game, a confidence score,
/// a plain-language reason (for caregiver trust), and whether this came
/// from the ML model or the rule-based fallback.
class GameRecommendation {
  final String gameType;
  final String gameLabel;
  final double confidence;
  final String reason;
  final bool isFallback;

  GameRecommendation({
    required this.gameType,
    required this.gameLabel,
    required this.confidence,
    required this.reason,
    required this.isFallback,
  });
}
