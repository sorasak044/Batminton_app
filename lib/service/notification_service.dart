import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; 
import 'dart:io' show Platform; 
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart'; // ใช้ Local Noti

class NotificationService {
  NotificationService._(); // Singleton Pattern
  static final instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static const String _baseUrl = 'https://demoapi-production-9077.up.railway.app';
  
  // 💡 ฟังก์ชันที่ใช้ในการระบุ Platform
  static String getPlatform() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'unknown'; 
  }

  // 💡 ฟังก์ชันสำหรับดึง FCM token
  Future<String?> getFCMToken() async {
    final token = await _fcm.getToken();
    debugPrint(">>>>>> 🌟 FCM_TOKEN: $token 🌟 <<<<<<"); 
    return token;
  }

  /// 1. Initialize FCM Listeners and Permissions
  Future<void> initPushNotification() async {
    // ขอ permission (Android 13+ ต้องมี)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("🔔 Notification permission: ${settings.authorizationStatus}");

    // 2. ฟัง token refresh
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint("🔄 Token refreshed: $newToken");
      
      // 💡 เมื่อ FCM Token ถูก Refresh, ต้องทำการลงทะเบียนใหม่ด้วย JWT Token เดิม
      final prefs = await SharedPreferences.getInstance();
      final userToken = prefs.getString('auth_token');

      if (userToken != null) {
          debugPrint("Attempting to re-register refreshed token with existing JWT.");
          await registerToken(userToken); // เรียกฟังก์ชันลงทะเบียนด้วย JWT
      } else {
          debugPrint("Cannot re-register token: JWT not found in SharedPreferences.");
      }
    });
    
    // 3. ฟังข้อความเมื่อ foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground: ${message.notification?.title}");
      
      // 💡 ใช้ Local Notification Service เพื่อแสดง Pop-up ใน Foreground
      if (message.notification != null) {
          // ต้องแน่ใจว่า LocalNotificationService.showNotification 
          // รองรับ id, title, body และ payload (Best Practice)
          LocalNotificationService.instance.showNotification(
              id: message.hashCode,
              title: message.notification!.title ?? "แจ้งเตือน",
              body: message.notification!.body ?? "มีข้อความใหม่",
              payload: json.encode(message.data), // ส่ง data ไปใน payload
          );
      }
    });

    // 4. ฟังตอนกด noti เปิดแอป
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🔔 User tapped notification: ${message.data}");
      // TODO: Global Key Navigation Logic
      // navigatorKey.currentState?.pushNamed('/booking_detail', arguments: message.data['booking_id']);
    });
  }

  // --- Logic สำหรับส่ง Token ที่ต้องใช้ JWT (ใช้ใน Auth Flow) ---
  
  /// Register token ไป backend (ใช้ JWT Token สำหรับ Authorization)
  /// userToken คือ JWT Token (Auth Token) ที่ได้จากการ Login
  Future<void> registerToken(String userToken) async {
    final fcmToken = await getFCMToken(); 
    if (fcmToken == null) {
      debugPrint("⚠️ FCM Token is null. Skipping registration.");
      return;
    }
    
    final platform = getPlatform();
    const url = "$_baseUrl/api/device-token/register";

    debugPrint("📡 Registering FCM token to $url");

    try {
      final res = await http.post(
        Uri.parse(url), 
        headers: {
          "Authorization": "Bearer $userToken", // JWT Token
          "Content-Type": "application/json", 
        },
        body: json.encode({
          "token": fcmToken, // FCM Token
          "platform": platform,
        }),
      );
      debugPrint("✅ Register Response: ${res.body}");
    } catch (e) {
      debugPrint("❌ FCM Registration Failed: $e");
    }
  }

  /// Unregister token ตอน logout
  /// userToken คือ JWT Token (Auth Token) ที่ได้จากการ Login
  Future<void> unregisterToken(String userToken) async {
    final fcmToken = await getFCMToken();
    if (fcmToken == null) return;
    
    final platform = getPlatform();
    const url = "$_baseUrl/api/device-token/unregister";

    debugPrint("🛑 Unregistering FCM token from $url");
    
    try {
      final res = await http.post(
        Uri.parse(url), 
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
}
