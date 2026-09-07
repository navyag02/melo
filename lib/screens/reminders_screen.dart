import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';
import '../services/patient_service.dart';

/// RemindersScreen shows a patient's reminders (e.g. medicine, hydration)
/// and lets a caregiver add a new one. Kept to a single reminder type
/// for the first version, matching the same elderly-friendly visual style
/// as the rest of the patient-facing screens.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  final PatientService _patientService = PatientService();

  List<ReminderModel> _reminders = [];
  bool _isLoading = true;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);

    final patientId = await _patientService.getSelectedPatientId();
    _patientId = patientId;

    if (patientId == null) {
      setState(() {
        _reminders = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final reminders = await _reminderService.getRemindersForPatient(patientId);
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reminders: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load reminders: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Reminder', style: TextStyle(fontSize: 22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Reminder (e.g. Take medicine)',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Time: ', style: TextStyle(fontSize: 18)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedTime = picked);
                      }
                    },
                    child: Text(
                      selectedTime.format(context),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || _patientId == null) return;

                final timeString =
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

                final reminder = ReminderModel(
                  patientId: _patientId!,
                  title: titleController.text.trim(),
                  time: timeString,
                );

                await _reminderService.addReminder(reminder);
                if (mounted) Navigator.pop(context);
                _loadReminders();
              },
              child: const Text('Add', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const Text(
          'Reminders',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _reminders.isEmpty
                          ? const Center(
                              child: Text(
                                'No reminders yet.\nTap below to add one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20, color: Color(0xFF666666)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _reminders.length,
                              itemBuilder: (context, index) {
                                final reminder = _reminders[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: const Icon(Icons.alarm,
                                        color: Color(0xFFFF9800), size: 32),
                                    title: Text(
                                      reminder.title,
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      reminder.time,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    trailing: Switch(
                                      value: reminder.isActive,
                                      activeColor: const Color(0xFF4CAF50),
                                      onChanged: (_) async {
                                        await _reminderService.toggleReminder(reminder);
                                        _loadReminders();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _showAddReminderDialog,
                        icon: const Icon(Icons.add, size: 28),
                        label: const Text('Add Reminder', style: TextStyle(fontSize: 20)),
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
      ),
    );
  }
}
