import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class AttendanceNotificationService {
  static const _channelId = 'attendance_reminders';
  static const _channelName = 'Attendance Reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    await _requestAndroidPermissions();
    await _scheduleWeekdayReminders();
  }

  Future<void> _requestAndroidPermissions() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  Future<void> _scheduleWeekdayReminders() async {
    await _plugin.cancelAll();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            'Daily reminder to mark attendance Monday–Friday at 11:00',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    for (var day = DateTime.monday; day <= DateTime.friday; day++) {
      await _plugin.zonedSchedule(
        id: day, // 1–5, one slot per weekday
        title: 'Attendance Reminder',
        body: 'Time to mark your attendance!',
        scheduledDate: _next11amOn(day),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Returns the next occurrence of 11:00 local time on [weekday] (Mon = 1).
  tz.TZDateTime _next11amOn(int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      11, // 11:00 AM — matches the attendance window (11:00–13:00)
    );
    while (candidate.weekday != weekday || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
