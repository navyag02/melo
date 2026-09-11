import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/patient_service.dart';
import '../services/firestore_service.dart';
import '../models/session_model.dart';
import '../utils/app_routes.dart';

/// CaregiverDashboardScreen — the real dashboard, wired to Firestore.
///
/// FIX: this used to be a static placeholder with "Coming Soon" cards.
/// It now:
///   1. Checks whether a patient is selected (redirects to patient
///      selector/add-patient flow if not)
///   2. Fetches that patient's real sessions from Firestore
///   3. Shows a simple session list (date, accuracy, difficulty)
///   4. Shows a plain-language recommendation based on recent accuracy
class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  String? _patientId;
  String? _patientName;
  List<SessionModel> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load the selected patient and their sessions.
  /// If no patient is selected yet, send the caregiver to pick/add one first.
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final patientId = await _patientService.getSelectedPatientId();
    final patientName = await _patientService.getSelectedPatientName();

    if (patientId == null) {
      // No patient selected yet — go to the selector (it will offer
      // "Add Patient" itself if the list is empty).
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.patientSelector);
      }
      return;
    }

    try {
      final sessions = await _firestoreService.getSessionsForPatient(patientId);
      setState(() {
        _patientId = patientId;
        _patientName = patientName;
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard sessions: $e');
      setState(() {
        _patientId = patientId;
        _patientName = patientName;
        _sessions = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load session data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Simple rule-based recommendation from the last 3 sessions' average
  /// accuracy. Same style of transparent, explainable logic as the
  /// difficulty engine — no black-box model.
  String _getRecommendation() {
    if (_sessions.isEmpty) {
      return 'No sessions yet — encourage the patient to play their first game.';
    }

    final recent = _sessions.take(3).toList();
    final avgAccuracy = recent.map((s) => s.accuracy).reduce((a, b) => a + b) / recent.length;

    if (avgAccuracy < 0.5) {
      return 'Recommend: Easier sessions, more frequent practice.';
    } else if (avgAccuracy > 0.8) {
      return 'Recommend: Increase difficulty — patient is progressing well.';
    } else {
      return 'Recommend: Continue current routine.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Caregiver Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Switch patient button
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white, size: 28),
            tooltip: 'Switch Patient',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.patientSelector);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Header card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient: ${_patientName ?? "Unknown"}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Logged in as: ${currentUser?.email ?? "Unknown"}',
                              style: const TextStyle(fontSize: 16, color: Color(0xFF666666)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recommendation card (AI-driven, explainable)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.psychology, color: Color(0xFF4CAF50), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Recommendation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getRecommendation(),
                                  style: const TextStyle(fontSize: 16, color: Color(0xFF388E3C)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- NEW: Game Management for Caregiver ---
                    const Text(
                      'Game Management',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.personalMemoriesManage);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF795548).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.photo_album, color: Color(0xFF795548), size: 32),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manage Personal Memories',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add photos and custom questions for the patient',
                                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Color(0xFF999999)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Accuracy trend chart — real analytics visualization,
                    // not just a raw list. Only shown when there's enough
                    // data to make a trend meaningful.
                    if (_sessions.length >= 2) ...[
                      const Text(
                        'Accuracy Trend',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 12),
                      _buildAccuracyChart(),
                      const SizedBox(height: 24),
                    ],

                    // Session history
                    const Text(
                      'Session History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 12),

                    if (_sessions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No sessions recorded yet.',
                          style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                        ),
                      )
                    else
                      ..._sessions.map((session) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: Icon(
                                _iconForGameType(session.gameType),
                                color: const Color(0xFF4CAF50),
                                size: 28, // standardized list-icon size app-wide
                              ),
                              title: Text(
                                // FIX: now shows which game this session was,
                                // since sessions from multiple games are
                                // mixed together in this list.
                                '${_labelForGameType(session.gameType)} — '
                                '${session.accuracyPercentage} accuracy',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${session.timestamp.day}/${session.timestamp.month}/${session.timestamp.year} · '
                                'Difficulty: ${session.difficultyLevel ?? "unknown"} · '
                                'Duration: ${session.formattedDuration}',
                              ),
                            ),
                          )),

                    const SizedBox(height: 20),

                    // Switch to patient mode
                    SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.home);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Switch to Patient Mode',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Line chart of accuracy over the patient's recent sessions.
  /// Shows the last 10 sessions, oldest to newest (left to right), so a
  /// caregiver can see the trend at a glance instead of reading a list
  /// of numbers.
  Widget _buildAccuracyChart() {
    // _sessions is sorted newest-first (from Firestore orderBy timestamp
    // descending) — reverse a capped slice so the chart reads left-to-right
    // as oldest-to-newest, which is the intuitive reading direction.
    final chartSessions = _sessions.take(10).toList().reversed.toList();

    final spots = <FlSpot>[
      for (int i = 0; i < chartSessions.length; i++)
        FlSpot(i.toDouble(), chartSessions[i].accuracy * 100),
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 25,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF4CAF50),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4CAF50).withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Human-readable name for each game type, since sessions from multiple
  /// games are now mixed together in one list.
  String _labelForGameType(String gameType) {
    switch (gameType) {
      case 'memory_matching_ner':
        return 'Memory Match';
      case 'daily_routine_recall_ner':
        return 'Daily Routine';
      case 'attention_focus_ner':
        return 'Spot the Difference';
      default:
        return gameType;
    }
  }

  /// Icon shown next to each session, matching its game type.
  IconData _iconForGameType(String gameType) {
    switch (gameType) {
      case 'memory_matching_ner':
        return Icons.style;
      case 'daily_routine_recall_ner':
        return Icons.checklist;
      case 'attention_focus_ner':
        return Icons.visibility;
      default:
        return Icons.videogame_asset;
    }
  }

  /// Handle logout process
  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      await _patientService.clearSelectedPatient();

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
