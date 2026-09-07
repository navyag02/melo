import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/reminder_model.dart';

/// ReminderService handles saving/fetching reminders in Firestore and
/// scheduling on-device notifications for them.
///
/// Kept to ONE reminder type for now (e.g. medicine reminder) — no
/// caregiver edit UI beyond add/toggle. Repeats daily at the set time.
class ReminderService {
  final CollectionReference _remindersCollection =
      FirebaseFirestore.instance.collection('reminders');

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Must be called once (e.g. in main.dart or on first use) before
  /// scheduling any notifications.
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Android 13+ requires explicit notification permission at runtime.
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Add a new reminder for a patient — saves to Firestore and schedules
  /// a daily repeating local notification.
  Future<String> addReminder(ReminderModel reminder) async {
    final docRef = await _remindersCollection.add(reminder.toMap());
    await _scheduleNotification(docRef.id, reminder);
    return docRef.id;
  }

  /// Get all reminders for a patient.
  Future<List<ReminderModel>> getRemindersForPatient(String patientId) async {
    final snapshot = await _remindersCollection
        .where('patientId', isEqualTo: patientId)
        .get();

    return snapshot.docs
        .map((doc) => ReminderModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Toggle a reminder active/inactive — cancels or reschedules the
  /// notification accordingly.
  Future<void> toggleReminder(ReminderModel reminder) async {
    final updated = ReminderModel(
      reminderId: reminder.reminderId,
      patientId: reminder.patientId,
      title: reminder.title,
      time: reminder.time,
      isActive: !reminder.isActive,
    );

    await _remindersCollection.doc(reminder.reminderId).update(updated.toMap());

    if (updated.isActive) {
      await _scheduleNotification(reminder.reminderId!, updated);
    } else {
      await _notificationsPlugin.cancel(reminder.reminderId.hashCode);
    }
  }

  /// Schedule a daily repeating notification at the reminder's set time.
  Future<void> _scheduleNotification(String id, ReminderModel reminder) async {
    if (!reminder.isActive) return;
    if (!_initialized) await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );

    // If the time has already passed today, schedule for tomorrow instead.
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'melo_reminders',
      'Melo Reminders',
      channelDescription: 'Medicine and activity reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id.hashCode,
      reminder.title,
      'Reminder time!',
      scheduledTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }
}
