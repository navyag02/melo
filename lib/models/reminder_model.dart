/// ReminderModel represents a single reminder (medicine, activity, etc.)
/// for a patient. Kept intentionally simple for the first version —
/// one type of reminder, no repeat-schedule complexity yet.
class ReminderModel {
  final String? reminderId;
  final String patientId;
  final String title; // e.g. "Take medicine"
  final String time; // stored as "HH:mm", e.g. "09:00"
  final bool isActive;

  ReminderModel({
    this.reminderId,
    required this.patientId,
    required this.title,
    required this.time,
    this.isActive = true,
  });

  factory ReminderModel.fromMap(Map<String, dynamic> map, String id) {
    return ReminderModel(
      reminderId: id,
      patientId: map['patientId'] as String,
      title: map['title'] as String,
      time: map['time'] as String,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'title': title,
      'time': time,
      'isActive': isActive,
    };
  }

  /// Parse the stored "HH:mm" string into hour/minute ints for scheduling.
  int get hour => int.parse(time.split(':')[0]);
  int get minute => int.parse(time.split(':')[1]);
}
