import 'package:flutter/material.dart';
import 'dart:math';
import '../services/firestore_service.dart';
import '../models/session_model.dart';
import '../services/difficulty_engine.dart';
import '../services/patient_service.dart';

/// MemoryMatchGameScreen - A cultural memory matching game themed around
/// North Eastern Region (NER) of India
/// 
/// This game helps elderly patients with cognitive exercises while celebrating
/// the rich cultural heritage of India's North Eastern Region.
/// 
/// Cultural Note: The card themes represent significant cultural elements from NER:
/// - Bihu dance/Gamosa (Assam)
/// - Hornbill (Nagaland - state bird, Hornbill Festival)
/// - Bamboo handicrafts (across NER)
/// - Tea gardens (Assam)
/// - Living root bridges (Meghalaya)
/// - Traditional textiles/handloom (across NER)
class MemoryMatchGameScreen extends StatefulWidget {
  const MemoryMatchGameScreen({super.key});

  @override
  State<MemoryMatchGameScreen> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGameScreen>
    with SingleTickerProviderStateMixin {
  // Game state
  List<CardModel> cards = [];
  List<CardModel> flippedCards = [];
  bool isCheckingMatch = false;
  int moves = 0;
  int matchesFound = 0;
  int totalPairs = 6; // Will be set by adaptive difficulty engine
  Stopwatch stopwatch = Stopwatch();
  bool gameCompleted = false;

  // Adaptive difficulty state
  DifficultyLevel currentDifficulty = DifficultyLevel.medium;
  DifficultyLevel nextDifficulty = DifficultyLevel.medium;
  String difficultyChangeMessage = '';

  // Firebase
  final FirestoreService _firestoreService = FirestoreService();
  final PatientService _patientService = PatientService();

  // FIX: the real patient ID, loaded from local storage (set when a
  // caregiver selects a patient). Sessions and difficulty lookups now use
  // this instead of the old hardcoded 'placeholder_patient_id'.
  String? _patientId;

  // Cultural card themes - NER themed icons with regional language labels
  // TODO: Replace with verified, culturally-approved illustrations before final submission
  // TODO: Verify translations with native speakers before demo day
  final List<CulturalCardTheme> culturalThemes = [
    CulturalCardTheme(
      id: 'bihu',
      name: 'Bihu Dance',
      regionalName: 'বিহু নৃত্য', // Assamese - TODO: verify translation
      icon: Icons.music_note, // used only if imagePath is null
      imagePath: 'assets/images/bihu.jpeg', // TODO: add this file
      color: Colors.red,
      description: 'Traditional Assamese dance',
    ),
    CulturalCardTheme(
      id: 'hornbill',
      name: 'Hornbill',
      regionalName: 'হৰ্নিল', // Assamese approximation - TODO: verify translation
      icon: Icons.flutter_dash,
      imagePath: 'assets/images/hornbill.jpeg', // TODO: add this file
      color: Colors.green,
      description: 'State bird of Nagaland',
    ),
    CulturalCardTheme(
      id: 'bamboo',
      name: 'Bamboo Craft',
      regionalName: 'বাঁহ শিল্প', // Assamese - TODO: verify translation
      icon: Icons.grass,
      imagePath: 'assets/images/bamboo.jpeg', // TODO: add this file
      color: Colors.lightGreen,
      description: 'Traditional bamboo handicrafts',
    ),
    CulturalCardTheme(
      id: 'tea',
      name: 'Tea Garden',
      regionalName: 'চাহ বাগিছা', // Assamese - TODO: verify translation
      icon: Icons.local_florist,
      imagePath: 'assets/images/tea.jpeg', // TODO: add this file
      color: Colors.brown,
      description: 'Assam tea gardens',
    ),
    CulturalCardTheme(
      id: 'root_bridge',
      name: 'Root Bridge',
      regionalName: 'শিপা সেতু', // Assamese approximation - TODO: verify translation
      icon: Icons.water,
      imagePath: 'assets/images/bridge.jpeg', // TODO: add this file
      color: Colors.amber,
      description: 'Living root bridges of Meghalaya',
    ),
    CulturalCardTheme(
      id: 'textile',
      name: 'Traditional Textile',
      regionalName: 'আদৰৰ কাপোৰ', // Assamese - TODO: verify translation
      icon: Icons.checkroom,
      imagePath: 'assets/images/textile.jpeg', // TODO: add this file
      color: Colors.purple,
      description: 'NER handloom textiles',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with default difficulty for first round
    currentDifficulty = DifficultyLevel.medium;
    nextDifficulty = DifficultyLevel.medium;
    _initializeGame();
  }

  /// Initialize the game with adaptive difficulty
  /// This is where our AI adaptive difficulty engine comes into play
  Future<void> _initializeGame() async {
    // STEP 0 (FIX): Load the actual selected patient ID from local storage.
    // This was previously skipped, so every session saved under a fake
    // placeholder ID and the difficulty engine could never see real history.
    _patientId = await _patientService.getSelectedPatientId();
    if (_patientId == null) {
      // No patient selected yet — this shouldn't normally happen since the
      // caregiver flow selects a patient before reaching this screen, but
      // we fall back safely instead of crashing.
      print('Warning: No patient selected. Using fallback ID for this session.');
      _patientId = 'unknown_patient';
    }

    // STEP 1: Calculate appropriate difficulty using the AI engine
    List<SessionModel> recentSessions = await _getRecentSessions();
    nextDifficulty = DifficultyEngine.calculateNextDifficulty(
      recentSessions: recentSessions,
      currentDifficulty: currentDifficulty,
    );
    
    // STEP 2: Use the nextDifficulty as the current difficulty for this round
    currentDifficulty = nextDifficulty;
    
    // STEP 3: Get the number of pairs for the calculated difficulty
    totalPairs = DifficultyEngine.getPairsForDifficulty(currentDifficulty);
    
    // STEP 4: Generate initial difficulty message (will be updated after round completes)
    difficultyChangeMessage = 'Current difficulty: ${DifficultyEngine.getDifficultyName(currentDifficulty)}';
    
    print('Adaptive Difficulty Engine: Starting game with ${DifficultyEngine.getDifficultyName(currentDifficulty)}');
    print('Adaptive Difficulty Engine: Total pairs: $totalPairs');
    print('Adaptive Difficulty Engine: Recent sessions analyzed: ${recentSessions.length}');
    
    // STEP 5: Create cards based on the calculated difficulty
    _createCardsForDifficulty();
    
    // STEP 6: Reset game state
    setState(() {
      moves = 0;
      matchesFound = 0;
      flippedCards = [];
      isCheckingMatch = false;
      gameCompleted = false;
      stopwatch.reset();
      stopwatch.start();
    });
  }

  /// Create cards based on the current difficulty level
  void _createCardsForDifficulty() {
    List<CardModel> gameCards = [];
    
    // Determine how many cultural themes to use based on difficulty
    int themesToUse = totalPairs;
    
    // If we need more themes than available, cycle through them
    for (int i = 0; i < themesToUse; i++) {
      // Use themes cyclically if we need more than available
      CulturalCardTheme theme = culturalThemes[i % culturalThemes.length];
      
      // Add two cards for each theme (the pair)
      gameCards.add(CardModel(theme: theme, id: '${theme.id}_${i}_1'));
      gameCards.add(CardModel(theme: theme, id: '${theme.id}_${i}_2'));
    }

    // Shuffle the cards
    gameCards.shuffle(Random());

    setState(() {
      cards = gameCards;
    });
  }

  /// Fetch recent sessions from Firestore for adaptive difficulty
  Future<List<SessionModel>> _getRecentSessions() async {
    try {
      // FIX: use the real patient ID loaded in _initializeGame instead of
      // a hardcoded placeholder.
      final patientId = _patientId ?? 'unknown_patient';
      return await _firestoreService.getRecentSessionsForGame(
        patientId,
        'memory_matching_ner',
        limit: 3,
      );
    } catch (e) {
      print('Error fetching recent sessions: $e');
      return [];
    }
  }

  /// Handle card tap - flip card and check for matches
  void _handleCardTap(CardModel card) {
    // Don't allow interaction if game is checking match or completed
    if (isCheckingMatch || gameCompleted) return;
    
    // Don't allow flipping already matched or flipped cards
    if (card.isMatched || card.isFlipped) return;

    // Don't allow more than 2 cards flipped at once
    if (flippedCards.length >= 2) return;

    // Flip the card
    setState(() {
      card.isFlipped = true;
      flippedCards.add(card);
    });

    // Check for match when 2 cards are flipped
    if (flippedCards.length == 2) {
      moves++;
      _checkForMatch();
    }
  }

  /// Check if the two flipped cards match
  void _checkForMatch() {
    setState(() {
      isCheckingMatch = true;
    });

    CardModel card1 = flippedCards[0];
    CardModel card2 = flippedCards[1];

    if (card1.theme.id == card2.theme.id) {
      // Match found!
      setState(() {
        card1.isMatched = true;
        card2.isMatched = true;
        matchesFound++;
        flippedCards = [];
        isCheckingMatch = false;
      });

      // Check if game is complete
      if (matchesFound == totalPairs) {
        _handleGameComplete();
      }
    } else {
      // No match - flip back after delay
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          card1.isFlipped = false;
          card2.isFlipped = false;
          flippedCards = [];
          isCheckingMatch = false;
        });
      });
    }
  }

  /// Handle game completion - save to Firestore and show results
  void _handleGameComplete() {
    stopwatch.stop();
    
    // STEP 1: Calculate the next difficulty based on this session's performance
    // This is where the AI adaptive logic happens after each round
    double accuracy = matchesFound / max(moves, 1);
    
    // Create a temporary session model for difficulty calculation
    SessionModel tempSession = SessionModel(
      patientId: _patientId ?? 'unknown_patient',
      gameType: 'memory_matching_ner',
      score: matchesFound * 100,
      accuracy: accuracy,
      timestamp: DateTime.now(),
      durationSeconds: stopwatch.elapsed.inSeconds,
      difficultyLevel: DifficultyEngine.difficultyToString(currentDifficulty),
    );
    
    // TODO: Uncomment when Firebase is configured to get actual recent sessions
    // For now, use simple logic based on current session only
    // List<SessionModel> recentSessions = await _getRecentSessions();
    // recentSessions.insert(0, tempSession); // Add current session to beginning
    
    // Calculate next difficulty using the AI engine
    // For demo purposes, use simple threshold logic
    if (accuracy >= DifficultyEngine.increaseThreshold) {
      nextDifficulty = DifficultyLevel.hard;
    } else if (accuracy <= DifficultyEngine.decreaseThreshold) {
      nextDifficulty = DifficultyLevel.easy;
    } else {
      nextDifficulty = currentDifficulty;
    }
    
    // Generate the difficulty change message
    difficultyChangeMessage = DifficultyEngine.getDifficultyChangeMessage(
      oldDifficulty: currentDifficulty,
      newDifficulty: nextDifficulty,
    );
    
    print('Adaptive Difficulty Engine: Session completed with ${(accuracy * 100).toStringAsFixed(1)}% accuracy');
    print('Adaptive Difficulty Engine: Current difficulty: ${DifficultyEngine.getDifficultyName(currentDifficulty)}');
    print('Adaptive Difficulty Engine: Next difficulty: ${DifficultyEngine.getDifficultyName(nextDifficulty)}');
    print('Adaptive Difficulty Engine: Message: $difficultyChangeMessage');
    
    setState(() {
      gameCompleted = true;
    });

    // Save session to Firestore
    _saveGameSession(accuracy);
  }

  /// Save the game session to Firestore
  Future<void> _saveGameSession(double accuracy) async {
    try {
      // Calculate accuracy (matches found / total moves)
      // Minimum possible moves = totalPairs (perfect game)
      
      // Create session model with adaptive difficulty information
      SessionModel session = SessionModel(
        patientId: _patientId ?? 'unknown_patient', // FIX: real patient ID
        gameType: 'memory_matching_ner',
        score: matchesFound * 100, // Simple scoring: 100 points per match
        accuracy: accuracy,
        timestamp: DateTime.now(),
        durationSeconds: stopwatch.elapsed.inSeconds,
        difficultyLevel: DifficultyEngine.difficultyToString(currentDifficulty),
        additionalData: {
          'totalPairs': totalPairs,
          'moves': moves,
          'culturalThemes': culturalThemes.map((t) => t.id).toList(),
          'adaptiveDifficulty': {
            'currentLevel': DifficultyEngine.difficultyToString(currentDifficulty),
            'nextLevel': DifficultyEngine.difficultyToString(nextDifficulty),
            'changeMessage': difficultyChangeMessage,
          },
        },
      );

      // Save to Firestore
      await _firestoreService.createSession(session);
      
      print('Game session saved successfully - Score: ${matchesFound * 100}, Moves: $moves, Time: ${stopwatch.elapsed.inSeconds}s');
      print('Adaptive Difficulty: ${DifficultyEngine.difficultyToString(currentDifficulty)} -> ${DifficultyEngine.difficultyToString(nextDifficulty)}');
    } catch (e) {
      print('Error saving game session: $e');
      // Continue even if save fails - don't block user experience
      // Show a message to the user that there was a save issue
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

  @override
  void dispose() {
    stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Consistent warm background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Memory Match - NER Culture',
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
            if (!gameCompleted && moves > 0) {
              _showExitConfirmation();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Restart button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
            onPressed: () {
              _showRestartConfirmation();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: gameCompleted
            ? _buildRoundCompleteScreen()
            : _buildGameScreen(),
      ),
    );
  }

  /// Build the main game screen
  Widget _buildGameScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Game stats header
          _buildGameStats(),
          const SizedBox(height: 20),
          
          // Game grid
          Expanded(
            child: _buildCardGrid(),
          ),
          
          // Cultural info button
          _buildCulturalInfoButton(),
        ],
      ),
    );
  }

  /// Build the game statistics header
  Widget _buildGameStats() {
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
        children: [
          // Difficulty indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology, color: Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 8),
              Text(
                'Difficulty: ${DifficultyEngine.getDifficultyName(currentDifficulty)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Game stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Moves', '$moves/$totalPairs', Icons.touch_app),
              _buildStatItem('Matches', '$matchesFound/$totalPairs', Icons.check_circle),
              _buildStatItem('Time', _formatTime(stopwatch.elapsed), Icons.timer),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: const Color(0xFF4CAF50)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// Build the card grid
  Widget _buildCardGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns for 12 cards (4 rows)
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8, // Slightly taller cards
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _buildCard(cards[index]);
      },
    );
  }

  /// Build individual card, with a real 3D flip animation between the
  /// back (hidden) and front (revealed) faces.
  ///
  /// FIX (flip replay bug): matched cards used to replay their flip
  /// animation every time GridView.builder recreated them after
  /// scrolling out of and back into view. Matched cards are now rendered
  /// statically in their final revealed state — only cards currently
  /// mid-flip (tapped, not yet resolved as matched/unmatched) animate.
  Widget _buildCard(CardModel card) {
    // Matched cards: no animation wrapper at all, so scrolling them back
    // into view can never replay a flip.
    if (card.isMatched) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 4),
          ],
        ),
        child: _buildCardFront(card),
      );
    }

    return GestureDetector(
      onTap: () => _handleCardTap(card),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: card.isFlipped ? 1 : 0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          final angle = value * pi; // 0 -> 180 degrees
          final showFront = value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 4,
                  ),
                ],
              ),
              // Mirror the front face's content back so it doesn't render
              // reversed once we've rotated past 90 degrees.
              child: showFront
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildCardFront(card),
                    )
                  : _buildCardBack(),
            ),
          );
        },
      ),
    );
  }

  /// Build the front of the card (when flipped)
  Widget _buildCardFront(CardModel card) {
    final borderColor = card.isMatched ? Colors.green : Colors.grey;
    final borderWidth = card.isMatched ? 3.0 : 1.0;
    final radius = BorderRadius.circular(12);

    // When a real image is available, it fills the entire card with the
    // name/regional name overlaid at the bottom — not just a small icon
    // in the middle.
    if (card.theme.imagePath != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11), // slightly inset so the border shows cleanly
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                card.theme.imagePath!,
                fit: BoxFit.cover,
              ),
              // Bottom label strip so the name stays readable over any image
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.theme.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        card.theme.regionalName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback layout (no image set yet) — original icon + text design.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            card.theme.icon,
            size: 48,
            color: card.theme.color,
          ),
          const SizedBox(height: 8),
          Text(
            card.theme.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            card.theme.regionalName,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build the back of the card (when face down)
  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.help_outline,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Build cultural info button
  Widget _buildCulturalInfoButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        onPressed: _showCulturalInfo,
        icon: const Icon(Icons.info_outline, size: 28),
        label: const Text(
          'Learn About NER Culture',
          style: TextStyle(fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Build the round complete screen
  Widget _buildRoundCompleteScreen() {
    double accuracy = matchesFound / max(moves, 1);
    int score = matchesFound * 100;

    // FIX: wrapped in SingleChildScrollView — the Column's natural height
    // (icon + text + score card + AI message + buttons) was taller than
    // the screen on smaller devices, causing a RenderFlex overflow.
    // Scrolling lets all content stay reachable instead of clipping.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon — small bounce-in celebration on appearance
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
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
          ),
          const SizedBox(height: 32),
          
          // Congratulations text
          const Text(
            'Round Complete!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
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
                _buildResultRow('Score', '$score', Icons.star, Colors.amber),
                const SizedBox(height: 16),
                _buildResultRow('Moves', '$moves', Icons.touch_app, Colors.blue),
                const SizedBox(height: 16),
                _buildResultRow('Time', _formatTime(stopwatch.elapsed), Icons.timer, Colors.green),
                const SizedBox(height: 16),
                // FIX: patients no longer see a raw accuracy percentage —
                // that number can feel discouraging. They see encouraging,
                // effort-based feedback instead. The real accuracy is
                // still saved to Firestore for the difficulty engine and
                // the caregiver dashboard, which does show exact numbers.
                _buildResultRow(
                  'How you did',
                  _encouragingLabel(accuracy),
                  Icons.favorite,
                  Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Adaptive difficulty message (AI transparency)
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
                    'Play Again (${DifficultyEngine.getPairsForDifficulty(nextDifficulty)} pairs)',
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
                    'Back to Menu',
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

  /// Show cultural information dialog
  void _showCulturalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'NER Cultural Themes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: culturalThemes.map((theme) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(theme.icon, color: theme.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          theme.regionalName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF666666),
                          ),
                        ),
                        Text(
                          theme.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
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

  /// Show restart confirmation dialog
  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Restart Game?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your current progress will be lost. Are you sure you want to restart?',
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
              _initializeGame();
            },
            child: const Text(
              'Restart',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Format duration as MM:SS
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// Encouraging, non-numeric feedback shown to the patient instead of a
  /// raw accuracy percentage — a low number displayed plainly can feel
  /// discouraging to someone managing memory decline. Exact accuracy is
  /// still saved to Firestore for the difficulty engine and the
  /// caregiver dashboard.
  String _encouragingLabel(double accuracy) {
    if (accuracy >= 0.8) return 'Wonderful!';
    if (accuracy >= 0.5) return 'Well Done!';
    return 'Good Try!';
  }
}

/// Model for a cultural card theme
class CulturalCardTheme {
  final String id;
  final String name;
  final String regionalName;
  final IconData icon;
  final String? imagePath; // e.g. 'assets/images/bihu.png' — null falls back to icon
  final Color color;
  final String description;

  CulturalCardTheme({
    required this.id,
    required this.name,
    required this.regionalName,
    required this.icon,
    this.imagePath,
    required this.color,
    required this.description,
  });
}

/// Model for a game card
class CardModel {
  final CulturalCardTheme theme;
  final String id;
  bool isFlipped;
  bool isMatched;

  CardModel({
    required this.theme,
    required this.id,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
