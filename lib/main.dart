// main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';
import '/service/local_notification_service.dart';
import '/service/fcm_service.dart';
import '/service/socket_service.dart'; // ✅ ใช้ SocketService แทน UserNotificationService
import 'dart:convert'; // ต้อง import

// 💡 Global Key สำหรับ navigator (สำคัญมาก)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background FCM handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // แสดง Local Notification ใน background / terminated
  if (message.notification != null) {
    await LocalNotificationService.instance.showNotification(
      id: message.hashCode,
      title: message.notification!.title ?? 'แจ้งเตือน',
      body: message.notification!.body ?? 'มีข้อความใหม่',
      payload: (message.data.isNotEmpty) ? jsonEncode(message.data) : null,
    );
  }
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Init Intl & Firebase
  await initializeDateFormatting('th_TH', null);
  await Firebase.initializeApp();

  // 2️⃣ Background FCM handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3️⃣ Init Local Notification (ต้องก่อน FCM listener)
  await LocalNotificationService.instance.init();

  // 4️⃣ เริ่มฟัง FCM ข้อความ foreground / tapped
  FcmService.listenMessages();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 💡 กำหนด navigatorKey ให้ MaterialApp
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}
