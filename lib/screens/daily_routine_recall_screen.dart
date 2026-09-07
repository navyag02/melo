import 'package:flutter/material.dart';
import 'dart:math';
import '../services/firestore_service.dart';
import '../services/patient_service.dart';
import '../services/difficulty_engine.dart';
import '../models/session_model.dart';

/// DailyRoutineRecallScreen — a cognitive game targeting "daily routine
/// recall", one of the four domains named in the problem statement that
/// wasn't covered by the memory matching game alone.
///
/// The patient sees a shuffled set of daily-activity cards (themed around
/// NER rural/family life) and taps them in what they believe is the
/// correct order of a typical day. Same adaptive-difficulty pattern as
/// the memory game: rule-based, explainable, no black-box model.
class DailyRoutineRecallScreen extends StatefulWidget {
  const DailyRoutineRecallScreen({super.key});

  @override
  State<DailyRoutineRecallScreen> createState() => _DailyRoutineRecallScreenState();
}

/// A single daily-activity step, themed around NER daily/cultural life.
/// TODO: Replace icons with verified, culturally-approved illustrations
/// before final submission — same caution as the memory-matching cards.
class _RoutineStep {
  final String label;
  final IconData icon;
  const _RoutineStep(this.label, this.icon);
}

class _DailyRoutineRecallScreenState extends State<DailyRoutineRecallScreen> {
  // The FULL correct daily sequence (7 steps = "hard"). Easy/medium use a
  // leading subset of this list, so the correct order is always a prefix
  // of this master sequence — keeps checking logic simple.
  // TODO: verify this sequence and the NER framing with someone from the
  // region before demo day.
  static const List<_RoutineStep> _masterSequence = [
    _RoutineStep('Wake up & fold the mekhela chador', Icons.wb_sunny),
    _RoutineStep('Morning tea with family', Icons.emoji_food_beverage),
    _RoutineStep('Feed the poultry', Icons.pets),
    _RoutineStep('Visit the local bazaar', Icons.storefront),
    _RoutineStep('Afternoon rest', Icons.self_improvement),
    _RoutineStep('Evening prayer / naam-prasanga', Icons.self_improvement_outlined),
    _RoutineStep('Dinner with family', Icons.dinner_dining),
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final PatientService _patientService = PatientService();

  String? _patientId;
  DifficultyLevel _currentDifficulty = DifficultyLevel.medium;
  List<_RoutineStep> _correctOrder = [];
  List<_RoutineStep> _shuffledSteps = [];
  List<_RoutineStep> _selectedOrder = [];

  bool _isLoading = true;
  bool _roundComplete = false;
  double _lastAccuracy = 0;
  late DateTime _startTime;
  DifficultyLevel _previousDifficulty = DifficultyLevel.medium;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  /// Map difficulty level -> number of steps for THIS game.
  /// (Kept local to this file — the shared DifficultyEngine's pairs
  /// mapping is specific to the memory-matching game.)
  int _stepsForDifficulty(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 3;
      case DifficultyLevel.medium:
        return 5;
      case DifficultyLevel.hard:
        return 7;
    }
  }

  Future<void> _initializeGame() async {
    _patientId = await _patientService.getSelectedPatientId();
    _patientId ??= 'unknown_patient';

    // Reuse the same rule-based difficulty engine, fed with this game's
    // own session history (separate gameType from memory matching).
    final recentSessions = await _firestoreService.getRecentSessionsForGame(
      _patientId!,
      'daily_routine_recall_ner',
      limit: 3,
    );

    final nextDifficulty = DifficultyEngine.calculateNextDifficulty(
      recentSessions: recentSessions,
      currentDifficulty: _currentDifficulty,
    );

    setState(() {
      _previousDifficulty = _currentDifficulty;
      _currentDifficulty = nextDifficulty;
      final stepCount = _stepsForDifficulty(_currentDifficulty);
      _correctOrder = _masterSequence.sublist(0, stepCount);
      _shuffledSteps = List.of(_correctOrder)..shuffle(Random());
      _selectedOrder = [];
      _isLoading = false;
      _roundComplete = false;
      _startTime = DateTime.now();
    });
  }

  void _handleStepTap(_RoutineStep step) {
    if (_selectedOrder.contains(step)) return; // already picked

    setState(() {
      _selectedOrder.add(step);
    });

    if (_selectedOrder.length == _correctOrder.length) {
      _finishRound();
    }
  }

  void _undoLastStep() {
    if (_selectedOrder.isEmpty) return;
    setState(() {
      _selectedOrder.removeLast();
    });
  }

  Future<void> _finishRound() async {
    // Score = fraction of positions the patient got exactly right.
    int correctPositions = 0;
    for (int i = 0; i < _correctOrder.length; i++) {
      if (_selectedOrder[i] == _correctOrder[i]) correctPositions++;
    }
    final accuracy = correctPositions / _correctOrder.length;
    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;

    setState(() {
      _lastAccuracy = accuracy;
      _roundComplete = true;
    });

    try {
      final session = SessionModel(
        patientId: _patientId ?? 'unknown_patient',
        gameType: 'daily_routine_recall_ner',
        score: (accuracy * 100).round(),
        accuracy: accuracy,
        timestamp: DateTime.now(),
        durationSeconds: durationSeconds,
        difficultyLevel: DifficultyEngine.difficultyToString(_currentDifficulty),
      );
      await _firestoreService.createSession(session);
      print('Daily routine recall session saved - accuracy: ${session.accuracyPercentage}');
    } catch (e) {
      print('Error saving daily routine recall session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Daily Routine Recall',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _roundComplete
                ? _buildRoundCompleteScreen()
                : _buildGameScreen(),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tap the activities in the order you do them during the day:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Selected order so far
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _selectedOrder.isEmpty
                      ? const Center(
                          child: Text('Your order will appear here',
                              style: TextStyle(color: Color(0xFF999999))),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: _selectedOrder
                              .map((s) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: CircleAvatar(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      child: Icon(s.icon, color: Colors.white, size: 20),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                IconButton(
                  icon: const Icon(Icons.undo, color: Color(0xFF999999)),
                  onPressed: _undoLastStep,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shuffled step cards
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _shuffledSteps.length,
              itemBuilder: (context, index) {
                final step = _shuffledSteps[index];
                final alreadyPicked = _selectedOrder.contains(step);

                return InkWell(
                  onTap: alreadyPicked ? null : () => _handleStepTap(step),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alreadyPicked ? const Color(0xFFE0E0E0) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: alreadyPicked
                          ? []
                          : [const BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          step.icon,
                          size: 40,
                          color: alreadyPicked ? const Color(0xFF999999) : const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: alreadyPicked ? const Color(0xFF999999) : const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundCompleteScreen() {
    final message = DifficultyEngine.getDifficultyChangeMessage(
      oldDifficulty: _previousDifficulty,
      newDifficulty: _currentDifficulty,
    );

    // FIX (same lesson as the memory game): wrap in SingleChildScrollView
    // so this doesn't overflow on smaller screens.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Round Complete!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 16),
          Text(
            'Accuracy: ${(_lastAccuracy * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 22, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50)),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _initializeGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Play Again', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Games', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
