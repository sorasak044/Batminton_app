import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationApi {
  static const String baseUrl =
      "https://demoapi-production-9077.up.railway.app/api";

  static Future<Map<String, dynamic>?> updateUserNotiSetting(
      String bookingId, int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception("⚠️ No auth token found");
      }

      final url = Uri.parse("$baseUrl/notification/noti-setting/$bookingId");

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "notiBeforeUse": minutes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Update Noti Success: $data");
        return data;
      } else {
        print("⚠️ Update Noti Failed: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("🚨 Error update noti setting: $e");
      return null;
    }
  }
}
