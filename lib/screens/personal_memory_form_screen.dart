import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/personal_memory_model.dart';
import '../services/personal_memory_service.dart';
import '../services/patient_service.dart';
import '../services/auth_service.dart';

/// PersonalMemoryFormScreen — Add or Edit a personal memory.
///
/// Accepts an optional [PersonalMemoryModel] via route arguments for editing.
/// If null, creates a new memory.
class PersonalMemoryFormScreen extends StatefulWidget {
  const PersonalMemoryFormScreen({super.key});

  @override
  State<PersonalMemoryFormScreen> createState() =>
      _PersonalMemoryFormScreenState();
}

class _PersonalMemoryFormScreenState extends State<PersonalMemoryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();

  final List<TextEditingController> _optionControllers = [];

  // Web-compatible image handling
  Uint8List? _imageBytes;
  String? _fileName;
  String? _existingImageUrl;
  bool _isLoading = false;
  PersonalMemoryModel? _editingMemory;

  final PersonalMemoryService _memoryService = PersonalMemoryService();
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Default: 2 empty incorrect option fields
    _optionControllers.add(TextEditingController());
    _optionControllers.add(TextEditingController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load editing memory from route arguments (only once)
    if (_editingMemory == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PersonalMemoryModel) {
        _editingMemory = args;
        _prefillForm(args);
      }
    }
  }

  void _prefillForm(PersonalMemoryModel memory) {
    _questionController.text = memory.question;
    _answerController.text = memory.answer;
    _promptController.text = memory.conversationPrompt ?? '';
    _hintController.text = memory.hint ?? '';
    _existingImageUrl = memory.imageUrl;

    // Pre-fill incorrect options (all options except the correct answer)
    _optionControllers.clear();
    for (var option in memory.answerOptions) {
      if (option != memory.answer) {
        _optionControllers.add(TextEditingController(text: option));
      }
    }
    if (_optionControllers.isEmpty) {
      _optionControllers.add(TextEditingController());
    }
    setState(() {});
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _promptController.dispose();
    _hintController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        // Read as bytes to support Web, Android, and iOS natively
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _fileName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: Color(0xFF4CAF50), size: 28),
                title: const Text('Take a Photo',
                    style: TextStyle(fontSize: 18, color: Color(0xFF333333))),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: Color(0xFF4CAF50), size: 28),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontSize: 18, color: Color(0xFF333333))),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _addOption() {
    if (_optionControllers.length < 5) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 incorrect options allowed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 1) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveMemory() async {
    debugPrint('DEBUG: _saveMemory called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('DEBUG: Form validation failed');
      return;
    }

    if (_imageBytes == null && _existingImageUrl == null) {
      debugPrint('DEBUG: No image selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('DEBUG: Loading state set to true');

    try {
      debugPrint('DEBUG: Getting caregiver ID...');
      final String caregiverId = _authService.currentUser?.uid ?? '';
      debugPrint('DEBUG: Caregiver ID: $caregiverId');

      debugPrint('DEBUG: Getting patient ID...');
      final String? patientId = await _patientService.getSelectedPatientId();
      debugPrint('DEBUG: Patient ID: $patientId');

      if (caregiverId.isEmpty || patientId == null || patientId.isEmpty) {
        throw Exception('Caregiver or Patient ID not found. caregiverId=$caregiverId, patientId=$patientId');
      }

      // Upload photo if a new file was selected
      String imageUrl = _existingImageUrl ?? '';
      bool isNewUpload = false;
      if (_imageBytes != null && _fileName != null) {
        debugPrint('DEBUG: Starting image upload... bytes=${_imageBytes!.length}, fileName=$_fileName');
        imageUrl = await _memoryService.uploadPhoto(patientId, _imageBytes!, _fileName!);
        isNewUpload = true;
        debugPrint('DEBUG: Image upload complete. URL: ${imageUrl.substring(0, imageUrl.length > 60 ? 60 : imageUrl.length)}...');
      } else {
        debugPrint('DEBUG: Using existing image URL: $imageUrl');
      }

      // Build answer options: correct answer + incorrect options
      debugPrint('DEBUG: Building answer options...');
      List<String> answerOptions = [_answerController.text.trim()];
      for (var controller in _optionControllers) {
        final text = controller.text.trim();
        if (text.isNotEmpty) {
          answerOptions.add(text);
        }
      }
      debugPrint('DEBUG: Answer options: $answerOptions');

      final now = DateTime.now();

      debugPrint('DEBUG: Creating PersonalMemoryModel...');
      final memory = PersonalMemoryModel(
        memoryId: _editingMemory?.memoryId,
        caregiverId: caregiverId,
        patientId: patientId,
        imageUrl: imageUrl,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        answerOptions: answerOptions,
        questionType: 'multiple_choice',
        conversationPrompt: _promptController.text.trim().isEmpty
            ? null
            : _promptController.text.trim(),
        hint: _hintController.text.trim().isEmpty
            ? null
            : _hintController.text.trim(),
        createdAt: _editingMemory?.createdAt ?? now,
        updatedAt: now,
      );
      debugPrint('DEBUG: PersonalMemoryModel created');

      try {
        if (_editingMemory == null) {
          debugPrint('DEBUG: Saving NEW memory to Firestore...');
          await _memoryService.addMemory(memory);
          debugPrint('DEBUG: Memory saved to Firestore!');
        } else {
          debugPrint('DEBUG: Updating EXISTING memory in Firestore...');
          await _memoryService.updateMemory(memory);
          debugPrint('DEBUG: Memory updated in Firestore!');
        }
      } catch (firestoreError) {
        debugPrint('ERROR: Personal Memory Firestore save failed: $firestoreError');
        // Clean up the uploaded image from Supabase if Firestore fails
        if (isNewUpload && imageUrl.isNotEmpty) {
          debugPrint('DEBUG: Cleaning up orphaned Supabase image...');
          await _memoryService.deletePhoto(imageUrl);
        }
        rethrow;
      }

      debugPrint('DEBUG: Save complete! Showing success message...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingMemory == null
                ? 'Memory added successfully!'
                : 'Memory updated successfully!'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: _saveMemory failed: $e');
      debugPrint('ERROR: stackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving memory: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint('DEBUG: _saveMemory finally block — resetting loading state');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 18, color: Color(0xFF666666)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _editingMemory != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        centerTitle: true,
        title: Text(
          isEditing ? 'Edit Memory' : 'Add Memory',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Saving memory...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo section
                      _buildPhotoSection(),
                      const SizedBox(height: 24),

                      // Memory details card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Memory Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _questionController,
                                decoration: _buildInputDecoration(
                                    'Question (e.g. Whose wedding was this?)'),
                                style: const TextStyle(
                                    fontSize: 18, color: Color(0xFF333333)),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Please enter a question'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _answerController,
                                decoration: _buildInputDecoration(
                                    'Correct Answer (e.g. My sister\'s wedding)'),
                                style: const TextStyle(
                                    fontSize: 18, color: Color(0xFF333333)),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Please enter the answer'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _promptController,
                                decoration: _buildInputDecoration(
                                    'Conversation Prompt (Optional)'),
                                style: const TextStyle(
                                    fontSize: 18, color: Color(0xFF333333)),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'e.g. "Do you remember anything else about this day?"',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF999999)),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _hintController,
                                decoration:
                                    _buildInputDecoration('Hint (Optional)'),
                                style: const TextStyle(
                                    fontSize: 18, color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Incorrect options card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Other Answer Choices',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '"I don\'t remember" is added automatically',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF999999),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_optionControllers.length < 5)
                                    IconButton(
                                      icon: const Icon(Icons.add_circle,
                                          color: Color(0xFF4CAF50), size: 32),
                                      onPressed: _addOption,
                                      tooltip: 'Add option',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List.generate(_optionControllers.length,
                                  (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller:
                                              _optionControllers[index],
                                          decoration: _buildInputDecoration(
                                              'Option ${index + 1}'),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF333333)),
                                          validator: (val) => val == null ||
                                                  val.trim().isEmpty
                                              ? 'Please enter an option'
                                              : null,
                                        ),
                                      ),
                                      if (_optionControllers.length > 1)
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.redAccent,
                                              size: 28),
                                          onPressed: () =>
                                              _removeOption(index),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _saveMemory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEditing ? 'Save Changes' : 'Add Memory',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_imageBytes != null) {
      return _buildPhotoPreview(
          Image.memory(_imageBytes!, fit: BoxFit.contain, width: double.infinity));
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return _buildPhotoPreview(Image.network(
        _existingImageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            constraints: const BoxConstraints(minHeight: 200),
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            constraints: const BoxConstraints(minHeight: 200),
            color: Colors.grey[200],
            child: const Center(
              child:
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
        },
      ));
    } else {
      return GestureDetector(
        onTap: _showImagePickerOptions,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CAF50),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 48, color: Color(0xFF4CAF50)),
              SizedBox(height: 12),
              Text(
                'Tap to add a photo',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Camera or Gallery',
                style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPhotoPreview(Widget imageWidget) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: imageWidget,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _showImagePickerOptions,
          icon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
          label: const Text(
            'Change Photo',
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
