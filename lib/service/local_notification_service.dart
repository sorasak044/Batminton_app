// service/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class LocalNotificationService {
  LocalNotificationService._internal(); // Singleton
  static final LocalNotificationService instance = LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// 💡 ฟังก์ชันจัดการเมื่อผู้ใช้กด Notification (ใช้สำหรับ Local/Foreground)
  static void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Local Notification Tapped! Payload: $payload');
      // TODO: Implement navigation logic here if needed
    }
  }

  Future<void> init() async {
    // 1. ตั้งค่าสำหรับแต่ละ Platform
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS/macOS: ขอ permission ให้แสดง alert, badge, sound
    const DarwinInitializationSettings initializationSettingsDarwin = 
        DarwinInitializationSettings(
          requestAlertPermission: true, 
          requestBadgePermission: true, 
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    // 2. Initialize plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotificationResponse,
    );
    
    // 3. ตั้งค่า Timezone สำหรับ Scheduled Notifications (ถ้ามี)
    tz.initializeTimeZones(); 
  }

  /// 💡 ฟังก์ชันที่ใช้แสดง Notification ในสถานะ Foreground / Background
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_reminder_ch', // ✅ ต้องตรง backend
      'Booking Reminder',
      channelDescription: 'Notifications about booking updates.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = 
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
