import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationApi {
  static Future<void> updateUserNotiSetting(String bookingId, int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final url = Uri.parse(
      "https://demoapi-production-9077.up.railway.app/api/notification/noti-setting/$bookingId",
    );

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: json.encode([
        {"notiBeforeUse": minutes}
      ]),
    );

    if (response.statusCode == 200) {
      print("✅ ตั้งค่าแจ้งเตือนสำเร็จ");
    } else {
      print("❌ Error: ${response.body}");
    }
  }
}
