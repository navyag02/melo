import 'package:flutter/material.dart';
import 'dart:math';
import '../services/firestore_service.dart';
import '../services/patient_service.dart';
import '../services/difficulty_engine.dart';
import '../models/session_model.dart';

/// AttentionFocusScreen — "Spot the odd one out" game targeting the
/// Attention & Concentration domain named in the problem statement.
///
/// A grid shows the same NER-themed icon repeated, except one tile is a
/// slightly different shade. The patient taps the odd one out. Played
/// over 5 rounds per session; accuracy = correct taps / 5.
///
/// TODO: Replace the single-icon-with-shade-difference approach with
/// verified, culturally-approved illustrations (e.g. subtly different
/// weaving patterns) before final submission — this version is a
/// placeholder visual mechanic to keep build time low.
class AttentionFocusScreen extends StatefulWidget {
  const AttentionFocusScreen({super.key});

  @override
  State<AttentionFocusScreen> createState() => _AttentionFocusScreenState();
}

class _AttentionFocusScreenState extends State<AttentionFocusScreen> {
  // Icons themed around NER daily/cultural objects — reused across rounds,
  // one is picked at random for the base tile of each round.
  static const List<IconData> _themeIcons = [
    Icons.eco, // tea leaf / bamboo (placeholder)
    Icons.local_florist, // regional flora
    Icons.grass,
    Icons.spa,
  ];

  final FirestoreService _firestoreService = FirestoreService();
  final PatientService _patientService = PatientService();

  String? _patientId;
  DifficultyLevel _currentDifficulty = DifficultyLevel.medium;
  DifficultyLevel _previousDifficulty = DifficultyLevel.medium;

  static const int _totalRounds = 5;
  int _roundIndex = 0;
  int _correctCount = 0;
  int _oddTileIndex = 0;
  int _gridSize = 6;
  late IconData _roundIcon;

  bool _isLoading = true;
  bool _sessionComplete = false;
  late DateTime _startTime;
  late DateTime _roundStartTime;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  int _tileCountForDifficulty(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 6;
      case DifficultyLevel.medium:
        return 9;
      case DifficultyLevel.hard:
        return 12;
    }
  }

  Future<void> _initializeSession() async {
    _patientId = await _patientService.getSelectedPatientId();
    _patientId ??= 'unknown_patient';

    final recentSessions = await _firestoreService.getRecentSessionsForGame(
      _patientId!,
      'attention_focus_ner',
      limit: 3,
    );

    final nextDifficulty = DifficultyEngine.calculateNextDifficulty(
      recentSessions: recentSessions,
      currentDifficulty: _currentDifficulty,
    );

    setState(() {
      _previousDifficulty = _currentDifficulty;
      _currentDifficulty = nextDifficulty;
      _gridSize = _tileCountForDifficulty(_currentDifficulty);
      _roundIndex = 0;
      _correctCount = 0;
      _isLoading = false;
      _sessionComplete = false;
      _startTime = DateTime.now();
    });
    _setupRound();
  }

  void _setupRound() {
    setState(() {
      _roundIcon = _themeIcons[Random().nextInt(_themeIcons.length)];
      _oddTileIndex = Random().nextInt(_gridSize);
      _roundStartTime = DateTime.now();
    });
  }

  void _handleTileTap(int index) {
    final isCorrect = index == _oddTileIndex;
    if (isCorrect) _correctCount++;

    if (_roundIndex + 1 >= _totalRounds) {
      _finishSession();
    } else {
      setState(() {
        _roundIndex++;
      });
      _setupRound();
    }
  }

  Future<void> _finishSession() async {
    final accuracy = _correctCount / _totalRounds;
    final durationSeconds = DateTime.now().difference(_startTime).inSeconds;

    setState(() {
      _sessionComplete = true;
    });

    try {
      final session = SessionModel(
        patientId: _patientId ?? 'unknown_patient',
        gameType: 'attention_focus_ner',
        score: (accuracy * 100).round(),
        accuracy: accuracy,
        timestamp: DateTime.now(),
        durationSeconds: durationSeconds,
        difficultyLevel: DifficultyEngine.difficultyToString(_currentDifficulty),
      );
      await _firestoreService.createSession(session);
      print('Attention focus session saved - accuracy: ${session.accuracyPercentage}');
    } catch (e) {
      print('Error saving attention focus session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Spot the Difference',
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
            : _sessionComplete
                ? _buildCompleteScreen()
                : _buildRoundScreen(),
      ),
    );
  }

  Widget _buildRoundScreen() {
    final crossAxisCount = _gridSize <= 6 ? 3 : (_gridSize <= 9 ? 3 : 4);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Round ${_roundIndex + 1} of $_totalRounds',
            style: const TextStyle(fontSize: 18, color: Color(0xFF666666)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the one that looks slightly different:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            // Same buffer fix as Daily Routine — gives shadows room
            // without disabling the grid's clip (which caused overlap).
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _gridSize,
                itemBuilder: (context, index) {
                  final isOddTile = index == _oddTileIndex;
                // The "odd" tile uses a visibly different shade of the same
                // base color — subtlety controlled by difficulty via a
                // fixed offset for now (kept simple for build time).
                final baseColor = const Color(0xFF4CAF50);
                final tileColor = isOddTile
                    ? baseColor.withOpacity(0.55)
                    : baseColor;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 4)],
                  ),
                  // Same ripple-clip fix as the Daily Routine game — keeps
                  // the tap ripple contained to the rounded card shape.
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Material(
                      color: Colors.transparent,
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _handleTileTap(index),
                        child: Center(
                          child: Icon(_roundIcon, size: 44, color: tileColor),
                        ),
                      ),
                    ),
                  ),
                );
              },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteScreen() {
    final message = DifficultyEngine.getDifficultyChangeMessage(
      oldDifficulty: _previousDifficulty,
      newDifficulty: _currentDifficulty,
    );
    final accuracy = _correctCount / _totalRounds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 64, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Session Complete!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 16),
          Text(
            'You got $_correctCount out of $_totalRounds correct (${(accuracy * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 20, color: Color(0xFF666666)),
            textAlign: TextAlign.center,
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
              onPressed: _initializeSession,
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
