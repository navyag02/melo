import 'package:flutter/material.dart';
import '../services/patient_service.dart';
import '../models/user_model.dart';
import '../utils/app_routes.dart';

/// PatientSelectorScreen allows caregivers to select which patient to work with
/// This screen is shown when a caregiver has one or more patients
/// Selecting a patient stores their ID locally for game sessions
class PatientSelectorScreen extends StatefulWidget {
  const PatientSelectorScreen({super.key});

  @override
  State<PatientSelectorScreen> createState() => _PatientSelectorScreenState();
}

class _PatientSelectorScreenState extends State<PatientSelectorScreen> {
  final PatientService _patientService = PatientService();
  
  List<UserModel> _patients = [];
  bool _isLoading = true;
  String? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  /// Load patients for the current caregiver
  Future<void> _loadPatients() async {
    try {
      List<UserModel> patients = await _patientService.getPatientsForCaregiver();
      
      // Check if there's a previously selected patient
      String? selectedId = await _patientService.getSelectedPatientId();
      
      setState(() {
        _patients = patients;
        _isLoading = false;
        _selectedPatientId = selectedId;
      });
    } catch (e) {
      print('Error loading patients: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patients: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle patient selection
  Future<void> _selectPatient(UserModel patient) async {
    try {
      // Store the selected patient ID and name locally
      await _patientService.setSelectedPatient(
        patient.patientId!,
        patient.name,
      );
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${patient.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate to caregiver dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.caregiverDashboard);
      }
    } catch (e) {
      print('Error selecting patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting patient: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Select Patient',
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
            Navigator.pop(context);
          },
        ),
        actions: [
          // Add new patient button
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 32),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.addPatient);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _patients.isEmpty
                ? _buildEmptyState()
                : _buildPatientList(),
      ),
    );
  }

  /// Build empty state when no patients exist
  Widget _buildEmptyState() {
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
                color: const Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 64,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Patients Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add your first patient to get started',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addPatient);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add First Patient',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the patient list
  Widget _buildPatientList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header text
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Text(
              'Your Patients',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
          
          // Patient list
          Expanded(
            child: ListView.builder(
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                UserModel patient = _patients[index];
                bool isSelected = _selectedPatientId == patient.patientId;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? const BorderSide(color: Color(0xFF4CAF50), width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: () => _selectPatient(patient),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Patient avatar placeholder
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE0E0E0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: isSelected ? Colors.white : const Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Patient info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.language,
                                      size: 18,
                                      color: Color(0xFF666666),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      patient.preferredLanguage,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Selection indicator
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4CAF50),
                              size: 32,
                            )
                          else
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFF999999),
                              size: 24,
                            ),
                        ],
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
}
