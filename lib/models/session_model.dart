/// SessionModel represents a game session played by a patient
/// This model tracks gameplay data for analytics and progress tracking
class SessionModel {
  final String? sessionId; // Unique identifier for the session
  final String patientId; // ID of the patient who played
  final String gameType; // Type of game played (e.g., 'memory_match', 'word_puzzle')
  final int score; // Score achieved in the session
  final double accuracy; // Accuracy percentage (0.0 to 1.0)
  final DateTime timestamp; // When the session was played
  final int durationSeconds; // How long the session lasted in seconds
  final int? level; // Optional: difficulty level reached
  final Map<String, dynamic>? additionalData; // Optional: game-specific data

  SessionModel({
    this.sessionId,
    required this.patientId,
    required this.gameType,
    required this.score,
    required this.accuracy,
    required this.timestamp,
    required this.durationSeconds,
    this.level,
    this.additionalData,
  });

  /// Create a SessionModel from a Firestore document map
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'] as String?,
      patientId: map['patientId'] as String,
      gameType: map['gameType'] as String,
      score: map['score'] as int,
      accuracy: (map['accuracy'] as num).toDouble(),
      timestamp: map['timestamp'] is DateTime 
          ? map['timestamp'] as DateTime
          : DateTime.parse(map['timestamp'] as String),
      durationSeconds: map['durationSeconds'] as int,
      level: map['level'] as int?,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert SessionModel to a Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'patientId': patientId,
      'gameType': gameType,
      'score': score,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': durationSeconds,
      'level': level,
      'additionalData': additionalData,
    };
  }

  /// Create a copy of this SessionModel with some fields updated
  SessionModel copyWith({
    String? sessionId,
    String? patientId,
    String? gameType,
    int? score,
    double? accuracy,
    DateTime? timestamp,
    int? durationSeconds,
    int? level,
    Map<String, dynamic>? additionalData,
  }) {
    return SessionModel(
      sessionId: sessionId ?? this.sessionId,
      patientId: patientId ?? this.patientId,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      level: level ?? this.level,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Get formatted accuracy as percentage string
  String get accuracyPercentage => '${(accuracy * 100).toStringAsFixed(1)}%';

  /// Get formatted duration as minutes and seconds
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
