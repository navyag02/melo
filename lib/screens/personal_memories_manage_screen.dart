import 'package:flutter/material.dart';
import '../models/personal_memory_model.dart';
import '../services/personal_memory_service.dart';
import '../services/patient_service.dart';
import '../utils/app_routes.dart';
import '../services/language_service.dart';
import '../utils/app_strings.dart';

/// PersonalMemoriesManageScreen — caregiver screen for managing
/// personal memories (photos + questions) for a patient.
///
/// Follows the same visual style as the patient selector and reminders
/// screens: warm yellow background, green app bar, white cards.
class PersonalMemoriesManageScreen extends StatefulWidget {
  const PersonalMemoriesManageScreen({super.key});

  @override
  State<PersonalMemoriesManageScreen> createState() =>
      _PersonalMemoriesManageScreenState();
}

class _PersonalMemoriesManageScreenState
    extends State<PersonalMemoriesManageScreen> {
  final PersonalMemoryService _memoryService = PersonalMemoryService();
  final PatientService _patientService = PatientService();

  List<PersonalMemoryModel> _memories = [];
  String? _patientId;
  String? _patientName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _patientId = await _patientService.getSelectedPatientId();
    _patientName = await _patientService.getSelectedPatientName();

    if (_patientId != null) {
      try {
        final memories =
            await _memoryService.getMemoriesForPatient(_patientId!);
        setState(() {
          _memories = memories;
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading memories: $e');
        setState(() {
          _memories = [];
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading memories: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMemory(PersonalMemoryModel memory) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Memory?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        content: const Text(
          'This will permanently delete this memory and its photo. Are you sure?',
          style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && memory.memoryId != null) {
      try {
        await _memoryService.deleteMemory(memory.memoryId!, memory.imageUrl);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Memory deleted'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting memory: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: wrapped in ListenableBuilder so this screen rebuilds with
    // translated text when the language changes.
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text(
          AppStrings.t('personal_memories_manage_title'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: _patientId != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  AppRoutes.personalMemoryForm,
                );
                _loadData(); // Refresh after returning from form
              },
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_photo_alternate, size: 28),
              label: Text(
                AppStrings.t('add_memory_button'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _patientId == null
                ? _buildNoPatientState()
                : _memories.isEmpty
                    ? _buildEmptyState()
                    : _buildMemoryList(),
      ),
      ),
    );
  }

  Widget _buildNoPatientState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E0E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off,
                size: 64,
                color: Color(0xFF757575),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.t('no_patient_selected'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please select a patient first to manage their memories.',
              style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.patientSelector);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppStrings.t('select_patient_button'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_album,
                size: 64,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.t('no_memories_yet'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add personal photos and questions for ${_patientName ?? "the patient"} to enjoy.',
              style: const TextStyle(fontSize: 18, color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.personalMemoryForm,
                  );
                  _loadData();
                },
                icon: const Icon(Icons.add_photo_alternate, size: 28),
                label: Text(
                  AppStrings.t('add_first_memory_button'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Patient header
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF4CAF50), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Memories for: ${_patientName ?? "Patient"}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                Text(
                  '${_memories.length} ${_memories.length == 1 ? "memory" : "memories"}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Memory list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _memories.length,
            itemBuilder: (context, index) {
              final memory = _memories[index];
              return _buildMemoryCard(memory);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryCard(PersonalMemoryModel memory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Image.network(
              memory.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                );
              },
            ),
          ),

          // Question and actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer: ${memory.answer}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${memory.answerOptions.length} options',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.personalMemoryForm,
                          arguments: memory,
                        );
                        _loadData();
                      },
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Color(0xFF4CAF50),
                      ),
                      label: Text(
                        AppStrings.t('edit_button'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    TextButton.icon(
                      onPressed: () => _deleteMemory(memory),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      label: Text(
                        AppStrings.t('delete_button'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
