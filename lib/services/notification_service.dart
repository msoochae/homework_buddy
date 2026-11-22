import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../core/constants.dart';
import '../data/models/homework.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(AppConstants.defaultTimezone));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'homework_buddy_main',
          '숙제버디 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleReminders(List<Homework> homeworks) async {
    for (var i = AppConstants.reminderBaseId; i < AppConstants.reminderBaseId + 100; i++) {
      await _plugin.cancel(i);
    }

    final Map<String, List<Homework>> byDue = {};
    final now = DateTime.now();
    final in14days = now.add(const Duration(days: 14));

    for (final hw in homeworks) {
      if (hw.dueDate == null) continue;
      if (hw.status == 'done' || hw.status == 'none') continue;
      final due = DateTime.parse(hw.dueDate!);
      if (due.isAfter(in14days)) continue;
      byDue.putIfAbsent(hw.dueDate!, () => []).add(hw);
    }

    var id = AppConstants.reminderBaseId;
    for (final entry in byDue.entries) {
      final due = DateTime.parse(entry.key);
      final list = entry.value;

      final d1 = DateTime(due.year, due.month, due.day - 1, 19, 0);
      if (d1.isAfter(now)) {
        await _scheduleReminder(id++, '내일까지 해야 할 숙제 ${list.length}개', list, d1);
      }

      final d0 = DateTime(due.year, due.month, due.day, 8, 0);
      if (d0.isAfter(now)) {
        await _scheduleReminder(id++, '오늘까지 해야 할 숙제 ${list.length}개', list, d0);
      }
    }
  }

  static Future<void> _scheduleReminder(
      int id, String title, List<Homework> list, DateTime when) async {
    final top3 = list.take(3).map((h) => '[${_catName(h.category)}] ${h.title}').join(', ');
    final extra = list.length > 3 ? ' 외 ${list.length - 3}개' : '';

    await _plugin.zonedSchedule(
      id, title, '$top3$extra',
      tz.TZDateTime.from(when, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'homework_buddy_reminder',
          '숙제 리마인더',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static String _catName(String c) {
    switch (c) {
      case 'school': return '학교';
      case 'english': return '영어';
      case 'math': return '수학';
      case 'essay': return '논술';
      default: return '그외';
    }
  }
}
