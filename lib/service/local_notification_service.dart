import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._internal();
  static final LocalNotificationService instance =
      LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(initSettings);

    // ✅ ขอ permission Android 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestPermission();

    // ✅ ขอ permission iOS
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// ตั้งแจ้งเตือนก่อนเวลาใช้งานสนาม (minutesBefore)
  Future<void> scheduleBookingReminder({
    required int id,
    required DateTime startTimeLocal,
    required int minutesBefore,
    required String title,
    required String body,
  }) async {
    final scheduled = startTimeLocal.subtract(Duration(minutes: minutesBefore));

    if (scheduled.isBefore(DateTime.now())) {
      print("⚠️ เวลาที่เลือกผ่านมาแล้ว ไม่ตั้งแจ้งเตือน");
      return;
    }

    await _notificationsPlugin.zonedSchedule(
  id,
  title,
  body,
  tz.TZDateTime.from(scheduled, tz.local),
  const NotificationDetails(
    android: AndroidNotificationDetails(
      'reminder_channel',
      'การแจ้งเตือน',
      channelDescription: 'แจ้งเตือนการใช้งานสนาม',
      importance: Importance.max,
      priority: Priority.high,
    ),
  ),
  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  payload: 'booking_$id',
);

  }
}
