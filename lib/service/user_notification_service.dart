import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class UserNotificationService {
  IO.Socket? socket;

  Future<void> initSocket() async {
    // ป้องกันการเปิดซ้ำ (ถ้ามี socket เดิม)
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
          .setReconnectionDelay(2000) // ✅ หน่วงก่อน reconnect 2 วิ
          .setReconnectionAttempts(5) // ✅ ลอง reconnect สูงสุด 5 ครั้ง
          .setExtraHeaders({'Authorization': 'Bearer $token'})
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
    socket!.on("payment-approved", (data) {
      print("✅ Payment Approved: $data");
      // TODO: Show Snackbar / Local Notification
    });

    socket!.on("payment-reject", (data) {
      print("❌ Payment Rejected: $data");
      // TODO: Show Snackbar / Local Notification
    });
  }

  void dispose() {
    if (socket != null) {
      print("🛑 Disposing socket...");
      socket!.disconnect();
      socket!.destroy();
      socket = null;
    }
  }
}
