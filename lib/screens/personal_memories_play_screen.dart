import 'dart:math';
import 'package:flutter/material.dart';
import '../models/personal_memory_model.dart';
import '../models/session_model.dart';
import '../services/personal_memory_service.dart';
import '../services/patient_service.dart';
import '../services/firestore_service.dart';
import '../widgets/elderly_friendly_button.dart';

class PersonalMemoriesPlayScreen extends StatefulWidget {
  const PersonalMemoriesPlayScreen({super.key});

  @override
  State<PersonalMemoriesPlayScreen> createState() => _PersonalMemoriesPlayScreenState();
}

class _PersonalMemoriesPlayScreenState extends State<PersonalMemoriesPlayScreen> {
  // State 1: Welcome, State 2: Memory Display, State 3: Feedback, State 4: Completion
  int _currentState = 1;
  
  final PersonalMemoryService _memoryService = PersonalMemoryService();
  final PatientService _patientService = PatientService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = true;
  String? _patientId;
  String? _patientName;
  List<PersonalMemoryModel> _memories = [];
  
  int _currentIndex = 0;
  List<String> _currentOptions = [];
  
  // Session tracking
  int _correctAnswers = 0;
  final DateTime _startTime = DateTime.now();
  
  // Feedback state
  String _selectedAnswer = '';
  bool _wasCorrect = false;
  bool _wasIdk = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final patientId = await _patientService.getSelectedPatientId();
      if (patientId != null) {
        _patientId = patientId;
        _patientName = await _patientService.getSelectedPatientName();
        _memories = await _memoryService.getMemoriesForPatient(patientId);
        _memories.shuffle();
      }
    } catch (e) {
      debugPrint("Error loading memories: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupCurrentMemory() {
    final memory = _memories[_currentIndex];
    // answerOptions already includes the correct answer because of how we save it in the form
    _currentOptions = List.from(memory.answerOptions);
    // Ensure the correct answer is in there just in case
    if (!_currentOptions.contains(memory.answer)) {
      _currentOptions.add(memory.answer);
    }
    _currentOptions.shuffle();
  }

  void _startGame() {
    setState(() {
      if (_memories.isNotEmpty) {
        _setupCurrentMemory();
        _currentState = 2;
      }
    });
  }

  void _handleAnswer(String answer) {
    final bool isIdk = (answer == "I don't remember");
    final bool isCorrect = !isIdk && (answer == _memories[_currentIndex].answer);
    
    if (isCorrect) {
      _correctAnswers++;
    }
    
    setState(() {
      _selectedAnswer = answer;
      _wasCorrect = isCorrect;
      _wasIdk = isIdk;
      _currentState = 3;
    });
  }
  
  void _nextMemory() async {
    if (_currentIndex < _memories.length - 1) {
      setState(() {
        _currentIndex++;
        _setupCurrentMemory();
        _currentState = 2;
      });
    } else {
      await _saveSession();
      if (mounted) {
        setState(() {
          _currentState = 4;
        });
      }
    }
  }
  
  Future<void> _saveSession() async {
    if (_patientId == null || _memories.isEmpty) return;
    
    try {
      final double accuracy = _correctAnswers / _memories.length;
      final int score = (accuracy * 100).round();
      final int durationSeconds = DateTime.now().difference(_startTime).inSeconds;
      
      final session = SessionModel(
        patientId: _patientId!,
        gameType: 'personal_memories',
        score: score,
        accuracy: accuracy,
        timestamp: DateTime.now(),
        durationSeconds: durationSeconds,
        difficultyLevel: 'normal', // Personal memories don't have adaptive difficulty
      );
      
      await _firestoreService.createSession(session);
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
        title: const Text(
          "Personal Memories",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 32),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : SafeArea(child: _buildCurrentState()),
    );
  }

  Widget _buildCurrentState() {
    if (_currentState == 1) return _buildWelcomeState();
    if (_currentState == 2) return _buildMemoryState();
    if (_currentState == 3) return _buildFeedbackState();
    return _buildCompletionState();
  }

  Widget _buildWelcomeState() {
    if (_memories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_album, size: 64, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 32),
              const Text(
                "Personal Memories",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                "No memories added yet. Ask your caregiver to add some personal photos!",
                style: TextStyle(
                  fontSize: 22,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElderlyFriendlyButton(
                text: "Go Back",
                icon: Icons.arrow_back,
                backgroundColor: const Color(0xFF4CAF50),
                textColor: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_album, size: 64, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 32),
            const Text(
              "Personal Memories",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Let's look at some memories together",
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            if (_patientName != null && _patientName!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "Playing for: $_patientName",
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 48),
            ElderlyFriendlyButton(
              text: "Let's Begin",
              icon: Icons.play_arrow,
              backgroundColor: const Color(0xFF4CAF50),
              textColor: Colors.white,
              onPressed: _startGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryState() {
    final memory = _memories[_currentIndex];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                memory.imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  constraints: const BoxConstraints(minHeight: 280),
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    constraints: const BoxConstraints(minHeight: 280),
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            memory.question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ..._currentOptions.map((option) => _buildOptionButton(option, false)),
          _buildOptionButton("I don't remember", true),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String text, bool isIdk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF333333),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: isIdk ? const Color(0xFF9E9E9E) : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
        ),
        onPressed: () => _handleAnswer(text),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: isIdk ? FontWeight.normal : FontWeight.w600,
            fontStyle: isIdk ? FontStyle.italic : FontStyle.normal,
            color: const Color(0xFF333333),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFeedbackState() {
    final memory = _memories[_currentIndex];
    final random = Random();
    
    String feedbackText = "";
    if (_wasIdk) {
      final options = ["That's perfectly okay! 🤗", "Let's look at this together 💝", "No problem at all! 😊"];
      feedbackText = options[random.nextInt(options.length)];
    } else if (_wasCorrect) {
      final options = ["That's right! 🌟", "Wonderful memory! 💝", "You remembered! 🎉"];
      feedbackText = options[random.nextInt(options.length)];
    } else {
      final options = ["That's okay! 💛", "Let's look at another memory 😊", "No worries at all! 🤗"];
      feedbackText = options[random.nextInt(options.length)];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                memory.imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  constraints: const BoxConstraints(minHeight: 280),
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            feedbackText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              "The answer is: ${memory.answer}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (memory.conversationPrompt != null && memory.conversationPrompt!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF9800)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      memory.conversationPrompt!,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          ElderlyFriendlyButton(
            text: "Next Memory →",
            backgroundColor: const Color(0xFF4CAF50),
            textColor: Colors.white,
            onPressed: _nextMemory,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, size: 64, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 32),
            const Text(
              "Thank you for sharing these memories today! 💝",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Every memory is precious 🌟",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElderlyFriendlyButton(
              text: "Done",
              icon: Icons.check,
              backgroundColor: const Color(0xFF4CAF50),
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
