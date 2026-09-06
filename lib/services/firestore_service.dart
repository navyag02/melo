import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';

/// FirestoreService handles all Cloud Firestore database operations
/// This service manages data for users (patients) and game sessions
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _sessionsCollection = 
      FirebaseFirestore.instance.collection('sessions');

  /// Create a new patient user in Firestore
  /// Returns the document ID of the created user
  Future<String> createPatientUser(UserModel user) async {
    try {
      DocumentReference docRef = await _usersCollection.add(user.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating patient user: $e');
      rethrow;
    }
  }

  /// Get a patient user by their ID
  /// Returns the UserModel if found, null otherwise
  Future<UserModel?> getPatientUser(String userId) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting patient user: $e');
      rethrow;
    }
  }

  /// Update an existing patient user
  Future<void> updatePatientUser(String userId, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(userId).update(data);
    } catch (e) {
      print('Error updating patient user: $e');
      rethrow;
    }
  }

  /// Get all patients associated with a caregiver
  /// This will be useful when we implement caregiver-patient relationships
  Future<List<UserModel>> getPatientsForCaregiver(String caregiverId) async {
    try {
      QuerySnapshot querySnapshot = await _usersCollection
          .where('caregiverId', isEqualTo: caregiverId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting patients for caregiver: $e');
      rethrow;
    }
  }

  /// Create a new game session in Firestore
  /// Returns the document ID of the created session
  Future<String> createSession(SessionModel session) async {
    try {
      DocumentReference docRef = await _sessionsCollection.add(session.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating session: $e');
      rethrow;
    }
  }

  /// Get all sessions for a specific patient
  /// Useful for tracking patient progress over time
  Future<List<SessionModel>> getSessionsForPatient(String patientId) async {
    try {
      QuerySnapshot querySnapshot = await _sessionsCollection
          .where('patientId', isEqualTo: patientId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting sessions for patient: $e');
      rethrow;
    }
  }

  /// Get recent sessions for a specific patient and game type
  /// Useful for showing recent performance in specific games
  Future<List<SessionModel>> getRecentSessionsForGame(
      String patientId, String gameType, {int limit = 10}) async {
    try {
      QuerySnapshot querySnapshot = await _sessionsCollection
          .where('patientId', isEqualTo: patientId)
          .where('gameType', isEqualTo: gameType)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting recent sessions: $e');
      rethrow;
    }
  }

  /// Get all sessions (for caregiver dashboard analytics)
  Future<List<SessionModel>> getAllSessions() async {
    try {
      QuerySnapshot querySnapshot = await _sessionsCollection
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => SessionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all sessions: $e');
      rethrow;
    }
  }
}
