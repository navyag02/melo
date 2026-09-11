/// PersonalMemoryModel represents a personal memory (photo + question)
/// created by a caregiver for a patient's reminiscence game.
///
/// Architecture note: structured so an AI question-generation service
/// can be added later — see [questionType] and the service layer.
class PersonalMemoryModel {
  final String? memoryId;
  final String caregiverId;
  final String patientId;
  final String imageUrl; // Firebase Storage download URL
  final String question; // e.g. "Whose wedding was this?"
  final String answer; // The correct answer
  final List<String> answerOptions; // Multiple-choice options (includes correct answer)
  final String questionType; // 'multiple_choice' or 'open_ended' (for future AI)
  final String? hint; // Optional hint for the patient
  final String? conversationPrompt; // e.g. "Do you remember anything else about this day?"
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalMemoryModel({
    this.memoryId,
    required this.caregiverId,
    required this.patientId,
    required this.imageUrl,
    required this.question,
    required this.answer,
    required this.answerOptions,
    this.questionType = 'multiple_choice',
    this.hint,
    this.conversationPrompt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a PersonalMemoryModel from a Firestore document map
  factory PersonalMemoryModel.fromMap(Map<String, dynamic> map, String id) {
    return PersonalMemoryModel(
      memoryId: id,
      caregiverId: map['caregiverId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      question: map['question'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      answerOptions: List<String>.from(map['answerOptions'] ?? []),
      questionType: map['questionType'] as String? ?? 'multiple_choice',
      hint: map['hint'] as String?,
      conversationPrompt: map['conversationPrompt'] as String?,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt'] as DateTime
          : DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Convert PersonalMemoryModel to a Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'patientId': patientId,
      'imageUrl': imageUrl,
      'question': question,
      'answer': answer,
      'answerOptions': answerOptions,
      'questionType': questionType,
      'hint': hint,
      'conversationPrompt': conversationPrompt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with some fields updated
  PersonalMemoryModel copyWith({
    String? memoryId,
    String? caregiverId,
    String? patientId,
    String? imageUrl,
    String? question,
    String? answer,
    List<String>? answerOptions,
    String? questionType,
    String? hint,
    String? conversationPrompt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalMemoryModel(
      memoryId: memoryId ?? this.memoryId,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      imageUrl: imageUrl ?? this.imageUrl,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      answerOptions: answerOptions ?? this.answerOptions,
      questionType: questionType ?? this.questionType,
      hint: hint ?? this.hint,
      conversationPrompt: conversationPrompt ?? this.conversationPrompt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
