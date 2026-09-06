/// UserModel represents a patient user in the system
/// This model stores patient information for the Melo app
class UserModel {
  final String? patientId; // Unique identifier for the patient
  final String name; // Patient's full name
  final String preferredLanguage; // Language preference (e.g., 'Assamese', 'Bengali', 'English')
  final String? caregiverId; // ID of the caregiver managing this patient
  final DateTime createdAt; // When the patient profile was created
  final String? profileImageUrl; // Optional profile picture URL

  UserModel({
    this.patientId,
    required this.name,
    required this.preferredLanguage,
    this.caregiverId,
    required this.createdAt,
    this.profileImageUrl,
  });

  /// Create a UserModel from a Firestore document map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      patientId: map['patientId'] as String?,
      name: map['name'] as String,
      preferredLanguage: map['preferredLanguage'] as String,
      caregiverId: map['caregiverId'] as String?,
      createdAt: map['createdAt'] is DateTime 
          ? map['createdAt'] as DateTime
          : DateTime.parse(map['createdAt'] as String),
      profileImageUrl: map['profileImageUrl'] as String?,
    );
  }

  /// Convert UserModel to a Firestore document map
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'preferredLanguage': preferredLanguage,
      'caregiverId': caregiverId,
      'createdAt': createdAt.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }

  /// Create a copy of this UserModel with some fields updated
  UserModel copyWith({
    String? patientId,
    String? name,
    String? preferredLanguage,
    String? caregiverId,
    DateTime? createdAt,
    String? profileImageUrl,
  }) {
    return UserModel(
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      caregiverId: caregiverId ?? this.caregiverId,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
