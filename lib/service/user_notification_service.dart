import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '/service/fcm_service.dart'; 
import '/service/local_notification_service.dart'; // ✅ import Local Notification

class UserNotificationService {
  IO.Socket? socket;

  /// ✅ เริ่มเชื่อมต่อ Socket.io
  Future<void> initSocket() async {
    // ถ้า socket เชื่อมต่อแล้ว ให้ skip
    if (socket != null && socket!.connected) {
      print("⚠️ Socket already connected, skip init.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    socket = IO.io(
      'https://demoapi-production-9077.up.railway.app',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(5)
          .setQuery({'token': token})
          .build(),
    );

    socket!.connect();

    // Event listeners
    socket!.onConnect((_) => print("🔌 Connected to Socket (User)"));
    socket!.onDisconnect((_) => print("❌ Disconnected from Socket"));
    socket!.onError((err) => print("⚠️ Socket Error: $err"));
    socket!.onReconnect((_) => print("🔄 Reconnected to socket"));
    socket!.onReconnectError((err) => print("🚨 Reconnect error: $err"));

    // Events เฉพาะระบบ
    socket!.on("payment-approved", (data) async {
      print("✅ Payment Approved: $data");

      // แสดง Local Notification
      await LocalNotificationService.instance.showNotification(
        id: (data['bookingId'] ?? DateTime.now().millisecondsSinceEpoch).hashCode,
        title: 'ชำระเงินอนุมัติ',
        body: 'การจอง ${data['courtName'] ?? ''} เริ่มเวลา ${data['startTime'] ?? ''}',
        payload: json.encode(data),
      );
    });

    socket!.on("payment-reject", (data) async {
      print("❌ Payment Rejected: $data");

      // แสดง Local Notification
      await LocalNotificationService.instance.showNotification(
        id: (data['bookingId'] ?? DateTime.now().millisecondsSinceEpoch).hashCode,
        title: 'ชำระเงินปฏิเสธ',
        body: 'การจอง ${data['courtName'] ?? ''} ถูกปฏิเสธ',
        payload: json.encode(data),
      );
    });
  }

  /// ✅ Register FCM token โดยเรียกใช้ FcmService
  Future<void> registerFcmToken(String authToken) async {
    await FcmService.registerToken(authToken); 
  }

  /// ✅ Unregister FCM token โดยเรียกใช้ FcmService
  Future<void> unregisterFcmToken(String authToken) async {
    await FcmService.unregisterToken(authToken);
  }

  /// ✅ ปิดการเชื่อมต่อ socket
  void dispose() {
    if (socket != null) {
      print("🛑 Disposing socket...");
      socket!.disconnect();
      socket!.destroy();
      socket = null;
    }
  }
}
