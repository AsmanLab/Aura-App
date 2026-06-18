import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class AttendanceNotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: android,
      iOS: iOS,
    );

    await _notifications.initialize(settings: initializationSettings);

    await _scheduleWeeklyNotifications();
  }

  Future<void> _scheduleWeeklyNotifications() async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance Reminders',
      channelDescription: 'Daily reminders to mark attendance',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    for (var day = DateTime.monday; day <= DateTime.friday; day++) {
      await _notifications.zonedSchedule(
        id: day,
        title: 'Трекер посещаемости',
        body: 'Пора отметиться о прибытии!',
        scheduledDate: _nextInstanceOf11am(day),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exact,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOf11am(int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      11,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> showInstantNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_channel',
      'Attendance',
      channelDescription: 'Attendance notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
