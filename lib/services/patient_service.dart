import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// PatientService handles patient management operations
/// This service manages creating patients, fetching patients for caregivers,
/// and storing the currently selected patient locally using shared_preferences
class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Shared preferences keys for local storage
  static const String _selectedPatientIdKey = 'selected_patient_id';
  static const String _selectedPatientNameKey = 'selected_patient_name';

  /// Get the currently selected patient ID from local storage
  /// This allows game screens to know which patient's sessions to save
  Future<String?> getSelectedPatientId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedPatientIdKey);
    } catch (e) {
      print('Error getting selected patient ID: $e');
      return null;
    }
  }

  /// Get the currently selected patient name from local storage
  /// Used for displaying the patient name in the UI
  Future<String?> getSelectedPatientName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedPatientNameKey);
    } catch (e) {
      print('Error getting selected patient name: $e');
      return null;
    }
  }

  /// Set the currently selected patient ID and name in local storage
  /// This is called when a caregiver selects a patient from the patient selector
  Future<void> setSelectedPatient(String patientId, String patientName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedPatientIdKey, patientId);
      await prefs.setString(_selectedPatientNameKey, patientName);
      print('Selected patient saved: $patientName ($patientId)');
    } catch (e) {
      print('Error setting selected patient: $e');
    }
  }

  /// Clear the currently selected patient from local storage
  /// This is called when a caregiver logs out or switches patients
  Future<void> clearSelectedPatient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedPatientIdKey);
      await prefs.remove(_selectedPatientNameKey);
      print('Selected patient cleared');
    } catch (e) {
      print('Error clearing selected patient: $e');
    }
  }

  /// Create a new patient in Firestore
  /// This creates a patient document linked to the currently logged-in caregiver
  /// 
  /// Parameters:
  /// - name: Patient's full name
  /// - preferredLanguage: Patient's preferred language (e.g., 'Assamese', 'English')
  /// 
  /// Returns: The created patient model with the generated patientId
  Future<UserModel> createPatient({
    required String name,
    required String preferredLanguage,
  }) async {
    try {
      // Get the currently logged-in caregiver's ID
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No caregiver logged in');
      }

      // Create a new patient document in Firestore
      // Firestore will automatically generate a unique document ID
      DocumentReference patientRef = await _firestore.collection('users').add({
        'name': name,
        'preferredLanguage': preferredLanguage,
        'caregiverId': currentUser.uid, // Link to the caregiver
        'createdAt': FieldValue.serverTimestamp(),
        'profileImageUrl': null, // Optional, not implemented yet
      });

      // Create a UserModel from the created document
      UserModel patient = UserModel(
        patientId: patientRef.id,
        name: name,
        preferredLanguage: preferredLanguage,
        caregiverId: currentUser.uid,
        createdAt: DateTime.now(),
        profileImageUrl: null,
      );

      print('Patient created successfully: ${patient.name} (${patient.patientId})');
      return patient;
    } catch (e) {
      print('Error creating patient: $e');
      rethrow;
    }
  }

  /// Get all patients for the currently logged-in caregiver
  /// This is used to populate the patient selector screen
  /// 
  /// Returns: List of patients managed by the current caregiver
  Future<List<UserModel>> getPatientsForCaregiver() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No caregiver logged in');
      }

      // Query Firestore for patients where caregiverId matches the current user
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('caregiverId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true) // Most recent first
          .get();

      // Convert the query results to UserModel objects
      List<UserModel> patients = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel(
          patientId: doc.id,
          name: data['name'] as String,
          preferredLanguage: data['preferredLanguage'] as String,
          caregiverId: data['caregiverId'] as String,
          createdAt: data['createdAt'] is DateTime 
              ? data['createdAt'] as DateTime
              : DateTime.now(),
          profileImageUrl: data['profileImageUrl'] as String?,
        );
      }).toList();

      print('Found ${patients.length} patients for caregiver');
      return patients;
    } catch (e) {
      print('Error getting patients for caregiver: $e');
      rethrow;
    }
  }

  /// Check if the current caregiver has any patients
  /// This is used to determine whether to show the "Add Patient" screen
  /// or the patient selector screen
  /// 
  /// Returns: true if the caregiver has at least one patient, false otherwise
  Future<bool> hasPatients() async {
    try {
      List<UserModel> patients = await getPatientsForCaregiver();
      return patients.isNotEmpty;
    } catch (e) {
      print('Error checking if caregiver has patients: $e');
      return false;
    }
  }

  /// Get a specific patient by their ID
  /// This is used to fetch patient details when needed
  /// 
  /// Parameters:
  /// - patientId: The unique ID of the patient
  /// 
  /// Returns: The patient model if found, null otherwise
  Future<UserModel?> getPatientById(String patientId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(patientId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return UserModel(
          patientId: doc.id,
          name: data['name'] as String,
          preferredLanguage: data['preferredLanguage'] as String,
          caregiverId: data['caregiverId'] as String,
          createdAt: data['createdAt'] is DateTime 
              ? data['createdAt'] as DateTime
              : DateTime.now(),
          profileImageUrl: data['profileImageUrl'] as String?,
        );
      }
      return null;
    } catch (e) {
      print('Error getting patient by ID: $e');
      return null;
    }
  }
}
