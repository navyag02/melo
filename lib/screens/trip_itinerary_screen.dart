import 'package:flutter/material.dart';
import 'dart:math';
import '../services/firestore_service.dart';
import '../services/patient_service.dart';
import '../services/difficulty_engine.dart';
import '../models/session_model.dart';
import '../utils/app_routes.dart';

/// TripItineraryScreen - A cognitive game targeting sequential/working memory
/// 
/// Patients memorize a trip itinerary for a North Eastern state, then answer
/// multiple-choice questions about the sequence. Features NER cultural theming
/// and integrates with the adaptive difficulty engine.
/// 
/// Cultural Note: The itineraries feature real, well-known stops in NER states:
/// - Assam: Kaziranga, Tea Gardens, Kamakhya Temple, Brahmaputra Cruise, Majuli, Sivasagar, Guwahati Market
/// - Meghalaya: Living Root Bridges, Dawki, Mawlynnong, Elephant Falls, Shillong Peak, Nohkalikai Falls, Police Bazar
/// - Nagaland: Kohima War Cemetery, Khonoma Village, Touphema Village, Dzukou Valley, Kisama Heritage Village, Naga Market, Japfu Peak
/// 
/// TODO: Verify stop order, spellings, and cultural framing with someone from the region before demo day
class TripItineraryScreen extends StatefulWidget {
  const TripItineraryScreen({super.key});

  @override
  State<TripItineraryScreen> createState() => _TripItineraryScreenState();
}

class _TripItineraryScreenState extends State<TripItineraryScreen> {
  // Game state
  String _selectedState = 'Assam';
  List<TripStop> _itinerary = [];
  bool _showingItinerary = true;
  int _revealCountdown = 0;
  int _currentQuestionIndex = 0;
  List<Question> _questions = [];
  int _correctAnswers = 0;
  bool _gameCompleted = false;
  bool _stateSelectionEnabled = true;
  
  // Difficulty state
  DifficultyLevel currentDifficulty = DifficultyLevel.medium;
  DifficultyLevel nextDifficulty = DifficultyLevel.medium;
  String difficultyChangeMessage = '';
  
  // Firebase
  final FirestoreService _firestoreService = FirestoreService();
  final PatientService _patientService = PatientService();

  // NER State itineraries (real, well-known stops)
  // TODO: Verify cultural accuracy and sequencing with regional experts
  final Map<String, List<TripStop>> _stateItineraries = {
    'Assam': [
      TripStop(name: 'Kaziranga National Park', icon: Icons.forest),
      TripStop(name: 'Tea Garden, Jorhat', icon: Icons.emoji_food_beverage),
      TripStop(name: 'Kamakhya Temple, Guwahati', icon: Icons.temple_hindu),
      TripStop(name: 'Brahmaputra River Cruise', icon: Icons.directions_boat),
      TripStop(name: 'Majuli Island', icon: Icons.landscape),
      TripStop(name: 'Sivasagar (Ahom monuments)', icon: Icons.account_balance),
      TripStop(name: 'Guwahati local market', icon: Icons.storefront),
    ],
    'Meghalaya': [
      TripStop(name: 'Living Root Bridges, Nongriat', icon: Icons.park),
      TripStop(name: 'Dawki (Umngot River)', icon: Icons.water),
      TripStop(name: 'Mawlynnong (cleanest village)', icon: Icons.eco),
      TripStop(name: 'Elephant Falls', icon: Icons.waterfall_chart),
      TripStop(name: 'Shillong Peak', icon: Icons.terrain),
      TripStop(name: 'Nohkalikai Falls', icon: Icons.water_drop),
      TripStop(name: 'Police Bazar, Shillong', icon: Icons.storefront),
    ],
    'Nagaland': [
      TripStop(name: 'Kohima War Cemetery', icon: Icons.account_balance),
      TripStop(name: 'Khonoma Village', icon: Icons.holiday_village),
      TripStop(name: 'Touphema Village', icon: Icons.cabin),
      TripStop(name: 'Dzukou Valley', icon: Icons.terrain),
      TripStop(name: 'Kisama Heritage Village', icon: Icons.museum),
      TripStop(name: 'Naga Market, Kohima', icon: Icons.storefront),
      TripStop(name: 'Japfu Peak viewpoint', icon: Icons.landscape),
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeGame(startCountdown: false);
  }

  /// Initialize the game with adaptive difficulty
  Future<void> _initializeGame({bool startCountdown = true}) async {
    // STEP 1: Calculate appropriate difficulty using the AI engine
    String? patientId = await _patientService.getSelectedPatientId();
    if (patientId != null) {
      List<SessionModel> recentSessions = await _firestoreService.getRecentSessionsForGame(
        patientId,
        'trip_itinerary_recall_ner',
        limit: 3,
      );
      nextDifficulty = DifficultyEngine.calculateNextDifficulty(
        recentSessions: recentSessions,
        currentDifficulty: currentDifficulty,
      );
    }
    
    // STEP 2: Use the nextDifficulty as the current difficulty for this round
    currentDifficulty = nextDifficulty;
    
    // STEP 3: Get game parameters based on difficulty
    final params = _getDifficultyParameters(currentDifficulty);
    
    // STEP 4: Generate itinerary for selected state
    _itinerary = _stateItineraries[_selectedState]!.take(params.numberOfStops).toList();
    
    // STEP 5: Generate questions based on difficulty
    _questions = _generateQuestions(_itinerary, params.numberOfQuestions);
    
    // STEP 6: Generate difficulty change message
    difficultyChangeMessage = DifficultyEngine.getDifficultyChangeMessage(
      oldDifficulty: currentDifficulty,
      newDifficulty: nextDifficulty,
    );
    
    print('Trip Itinerary Game: Starting with ${_displayDifficultyName(currentDifficulty)}');
    print('Trip Itinerary Game: ${params.numberOfStops} stops, ${params.revealTime}s reveal, ${params.numberOfQuestions} questions');
    
    // STEP 7: Start reveal countdown
    _startRevealCountdown(params.revealTime);
    
    setState(() {});
  }

  /// Get game parameters based on difficulty level
  DifficultyParameters _getDifficultyParameters(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return DifficultyParameters(
          numberOfStops: 3,
          revealTime: 20,
          numberOfQuestions: 2,
        );
      case DifficultyLevel.medium:
        return DifficultyParameters(
          numberOfStops: 5,
          revealTime: 15,
          numberOfQuestions: 3,
        );
      case DifficultyLevel.hard:
        return DifficultyParameters(
          numberOfStops: 7,
          revealTime: 10,
          numberOfQuestions: 4,
        );
    }
  }

  /// Start the itinerary reveal countdown
  void _startRevealCountdown(int seconds) {
    _revealCountdown = seconds;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _revealCountdown--;
      });
      
      if (_revealCountdown > 0) {
        return true;
      } else {
        // Countdown finished, hide itinerary and start questions
        setState(() {
          _showingItinerary = false;
        });
        return false;
      }
    });
  }

  /// Generate questions about the itinerary sequence
  List<Question> _generateQuestions(List<TripStop> itinerary, int numberOfQuestions) {
    List<Question> questions = [];
    Random random = Random();
    
    for (int i = 0; i < numberOfQuestions && i < itinerary.length - 1; i++) {
      // Pick a random anchor stop (not the last one)
      int anchorIndex = random.nextInt(itinerary.length - 1);
      TripStop anchorStop = itinerary[anchorIndex];
      
      // Generate different question types
      int questionType = random.nextInt(3);
      String questionText = '';
      String correctAnswer = '';
      
      if (questionType == 0 && anchorIndex > 0) {
        // "What came before X?"
        questionText = 'What stop came before ${anchorStop.name}?';
        correctAnswer = itinerary[anchorIndex - 1].name;
      } else if (questionType == 1 && anchorIndex < itinerary.length - 1) {
        // "What came after X?"
        questionText = 'What stop came after ${anchorStop.name}?';
        correctAnswer = itinerary[anchorIndex + 1].name;
      } else {
        // "What was stop number N?"
        int stopNumber = random.nextInt(itinerary.length) + 1;
        questionText = 'What was stop number $stopNumber?';
        correctAnswer = itinerary[stopNumber - 1].name;
      }
      
      // Generate distractors from the same itinerary
      List<String> distractors = itinerary
          .where((stop) => stop.name != correctAnswer)
          .map((stop) => stop.name)
          .toList();
      
      // Shuffle and pick 3 distractors
      distractors.shuffle(random);
      List<String> options = [correctAnswer, ...distractors.take(3)];
      options.shuffle(random);
      
      questions.add(Question(
        question: questionText,
        options: options,
        correctAnswer: correctAnswer,
      ));
    }
    
    return questions;
  }

  /// Handle answer selection
  void _handleAnswer(String selectedAnswer) {
    if (selectedAnswer == _questions[_currentQuestionIndex].correctAnswer) {
      _correctAnswers++;
    }
    
    setState(() {
      _currentQuestionIndex++;
    });
    
    // Check if all questions are answered
    if (_currentQuestionIndex >= _questions.length) {
      _handleGameComplete();
    }
  }

  /// Handle game completion
  void _handleGameComplete() {
    // Calculate next difficulty based on performance
    double accuracy = _correctAnswers / _questions.length;
    
    if (accuracy >= DifficultyEngine.increaseThreshold) {
      nextDifficulty = DifficultyLevel.hard;
    } else if (accuracy <= DifficultyEngine.decreaseThreshold) {
      nextDifficulty = DifficultyLevel.easy;
    } else {
      nextDifficulty = currentDifficulty;
    }
    
    // Generate difficulty change message
    difficultyChangeMessage = DifficultyEngine.getDifficultyChangeMessage(
      oldDifficulty: currentDifficulty,
      newDifficulty: nextDifficulty,
    );
    
    print('Trip Itinerary Game: Session completed with ${(accuracy * 100).toStringAsFixed(1)}% accuracy');
    print('Trip Itinerary Game: $_correctAnswers/${_questions.length} correct');
    
    setState(() {
      _gameCompleted = true;
    });

    // Save session to Firestore
    _saveGameSession(accuracy);
  }

  /// Save the game session to Firestore
  Future<void> _saveGameSession(double accuracy) async {
    try {
      String? patientId = await _patientService.getSelectedPatientId();
      if (patientId == null) {
        patientId = 'placeholder_patient_id';
      }
      
      // Create session model with adaptive difficulty information
      SessionModel session = SessionModel(
        patientId: patientId,
        gameType: 'trip_itinerary_recall_ner',
        score: (_correctAnswers / _questions.length * 100).round(),
        accuracy: accuracy,
        timestamp: DateTime.now(),
        durationSeconds: 0, // Not tracking time for this game
        difficultyLevel: DifficultyEngine.difficultyToString(currentDifficulty),
        additionalData: {
          'state': _selectedState,
          'correctAnswers': _correctAnswers,
          'totalQuestions': _questions.length,
          'itineraryStops': _itinerary.map((stop) => stop.name).toList(),
          'adaptiveDifficulty': {
            'currentLevel': DifficultyEngine.difficultyToString(currentDifficulty),
            'nextLevel': DifficultyEngine.difficultyToString(nextDifficulty),
            'changeMessage': difficultyChangeMessage,
          },
        },
      );

      // Save to Firestore
      await _firestoreService.createSession(session);
      
      print('Trip Itinerary session saved successfully');
    } catch (e) {
      print('Error saving trip itinerary session: $e');
      // Continue even if save fails - don't block user experience
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session data could not be saved. Please check your internet connection.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Get performance message based on correct answers
  String _getPerformanceMessage(int correct, int total) {
    double percentage = correct / total;
    
    if (percentage == 1.0) {
      return 'Perfect recall! You remembered the whole trip perfectly.';
    } else if (percentage >= 0.75) {
      return 'Great memory! You remembered most of the trip.';
    } else if (percentage >= 0.5) {
      return 'Good effort! A few parts of the trip were tricky.';
    } else {
      return 'That was a tough trip to remember — let\'s try an easier one next time.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Consistent warm background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Trip Itinerary Recall',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () {
            // Confirm exit if game is in progress
            if (!_gameCompleted && _currentQuestionIndex > 0) {
              _showExitConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Difficulty indicator
          if (!_gameCompleted)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  _displayDifficultyName(currentDifficulty),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _gameCompleted
            ? _buildCompleteScreen()
            : _showingItinerary
                ? _buildItineraryScreen()
                : _buildQuestionScreen(),
      ),
    );
  }

  /// Display only the difficulty level (e.g. "Medium"), without
  /// gameplay parameters such as "(6 pairs)".
  String _displayDifficultyName(DifficultyLevel level) {
    final name = DifficultyEngine.getDifficultyName(level);
    return name.replaceFirst(RegExp(r'\\s*\\([^)]*\\)\\s*$'), '').trim();
  }

  /// Build the itinerary reveal screen
  Widget _buildItineraryScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // State selection (only shown before countdown starts)
          if (_stateSelectionEnabled)
            _buildStateSelector(),
          
          const SizedBox(height: 24),
          
          // Itinerary header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trip Itinerary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    // Countdown timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_revealCountdown',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$_selectedState Trip',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Itinerary list
          Expanded(
            child: ListView.builder(
              itemCount: _itinerary.length,
              itemBuilder: (context, index) {
                return _buildItineraryItem(_itinerary[index], index + 1);
              },
            ),
          ),
          
          // Progress bar for countdown
          if (_revealCountdown > 0)
            Column(
              children: [
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _revealCountdown / 8.0,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  'Memorize the trip! Itinerary will disappear in $_revealCountdown seconds...',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build state selector
  Widget _buildStateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a State to Visit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStateButton('Assam'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStateButton('Meghalaya'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStateButton('Nagaland'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual state button
  Widget _buildStateButton(String state) {
    bool isSelected = _selectedState == state;
    return SizedBox(
      height: 60, // Fixed height for consistency
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            _selectedState = state;
            _currentQuestionIndex = 0;
            _correctAnswers = 0;
            _questions = [];
            _gameCompleted = false;
            _showingItinerary = true;
            _stateSelectionEnabled = false;
          });

          await _initializeGame(startCountdown: true);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.grey[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: isSelected ? 4 : 0,
        ),
        child: Text(
          state,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Build individual itinerary item
  Widget _buildItineraryItem(TripStop stop, int stopNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Stop number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stopNumber',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Stop icon
            Icon(
              stop.icon,
              size: 32,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(width: 16),
            
            // Stop name
            Expanded(
              child: Text(
                stop.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the question screen
  Widget _buildQuestionScreen() {
    if (_currentQuestionIndex >= _questions.length) {
      return const Center(child: CircularProgressIndicator());
    }
    
    Question currentQuestion = _questions[_currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  'Correct: $_correctAnswers',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Question
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              currentQuestion.question,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Answer options
          Expanded(
            child: ListView.builder(
              itemCount: currentQuestion.options.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 70, // Large touch target for elderly users
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleAnswer(currentQuestion.options[index]),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF333333),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                      ),
                      child: Text(
                        currentQuestion.options[index],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  /// Build the completion screen
  Widget _buildCompleteScreen() {
    String performanceMessage = _getPerformanceMessage(_correctAnswers, _questions.length);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Congratulations text
          const Text(
            'Trip Complete!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 24),
          
          // Performance message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFF4CAF50),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    performanceMessage,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Score card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildResultRow('Correct Answers', '$_correctAnswers/${_questions.length}', Icons.check_circle, Colors.green),
                const SizedBox(height: 16),
                _buildResultRow('State Visited', _selectedState, Icons.location_on, Colors.blue),
                const SizedBox(height: 16),
                _buildResultRow('Difficulty', _displayDifficultyName(currentDifficulty), Icons.tune, Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Adaptive difficulty message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Color(0xFF4CAF50),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Adaptive Difficulty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        difficultyChangeMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Update current difficulty to next difficulty for the new round
                    currentDifficulty = nextDifficulty;
                    _initializeGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Play Again (${_displayDifficultyName(nextDifficulty)})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Games',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build result row for summary screen
  Widget _buildResultRow(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  /// Show exit confirmation dialog
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Exit Game?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 18),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Exit',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model for a trip stop
class TripStop {
  final String name;
  final IconData icon;

  TripStop({required this.name, required this.icon});
}

/// Model for a question
class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

/// Parameters for different difficulty levels
class DifficultyParameters {
  final int numberOfStops;
  final int revealTime;
  final int numberOfQuestions;

  DifficultyParameters({
    required this.numberOfStops,
    required this.revealTime,
    required this.numberOfQuestions,
  });
}
