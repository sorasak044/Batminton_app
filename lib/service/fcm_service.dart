// service/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform; 
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart'; // 💡 ใช้ Local Noti เพื่อแสดงใน Foreground

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _baseUrl = 'https://demoapi-production-9077.up.railway.app';
  
  /// ขอ token ปัจจุบัน
  static Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint(">>>>>> 🌟 FCM_TOKEN: $token 🌟 <<<<<<"); 
    return token;
  }

  /// ฟังก์ชันที่ใช้ในการระบุ Platform
  static String getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown'; 
  }

  /// Register token ไป backend ที่ Endpoint ใหม่
  static Future<void> registerToken(String userToken) async {
    final fcmToken = await getToken(); 
    if (fcmToken == null) {
      debugPrint("⚠️ FCM Token is null. Skipping registration.");
      return;
    }
    
    final platform = getPlatform();

    debugPrint("📡 Registering FCM token to $_baseUrl/api/device-token/register");

    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/device-token/register"), 
        headers: {
          "Authorization": "Bearer $userToken", 
          "Content-Type": "application/json", 
        },
        body: json.encode({
          "token": fcmToken,
          "platform": platform,
        }),
      );
      debugPrint("✅ Register Response: ${res.body}");
    } catch (e) {
      debugPrint("❌ FCM Registration Failed: $e");
    }
  }

  /// Unregister ตอน logout
  static Future<void> unregisterToken(String userToken) async {
    final fcmToken = await getToken();
    if (fcmToken == null) return;
    
    final platform = getPlatform();

    debugPrint("🛑 Unregistering FCM token from $_baseUrl/api/device-token/unregister");
    
    try {
      final res = await http.post(
        Uri.parse("$_baseUrl/api/device-token/unregister"), 
        headers: {
          "Authorization": "Bearer $userToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "token": fcmToken,
          "platform": platform,
        }),
      );
      debugPrint("🛑 Unregister Response: ${res.body}");
    } catch (e) {
      debugPrint("❌ FCM Unregistration Failed: $e");
    }
  }

  /// 💡 ฟัง notification (รวม Foreground Listener)
  static void listenMessages() {
  // Foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("🔔 Foreground: ${message.notification?.title}");
    if (message.notification != null) {
      LocalNotificationService.instance.showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'แจ้งเตือน',
        body: message.notification!.body ?? 'มีข้อความใหม่',
        payload: json.encode(message.data),
      );
    }
  });

  // Background / App Tapped
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("📲 Opened App from Notification: ${message.data}");
    // Navigator logic (ถ้ามี)
    // navigatorKey.currentState?.pushNamed('/booking_detail', arguments: message.data['booking_id']);
  });
}

}