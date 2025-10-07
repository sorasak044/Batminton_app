import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '/service/user_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:badminton_booking_app/service/fcm_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const ProfileScreen({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = '';
  String _phone = '';
  int _point = 0;
  bool _isLoading = true;

  final _userNotificationService = UserNotificationService();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      _logout(context);
      return;
    }

    final response = await http.get(
      Uri.parse('https://demoapi-production-9077.up.railway.app/api/auth/whoami'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _fullName = data['name'] ?? '';
        _phone = data['phone'] ?? '';
        _point = data['point'] ?? 0;
        _isLoading = false;
      });
      prefs.setString('firstName', _fullName.split(' ').first);
      widget.onProfileUpdated?.call();
    } else {
      print('❌ ดึงข้อมูลไม่สำเร็จ: ${response.body}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      // ✅ unregister FCM ก่อน logout
      await _userNotificationService.unregisterFcmToken(token);
    }

    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: Colors.green[300],
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Text(
                        'BADMINTON CLUB',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(_fullName, style: const TextStyle(fontSize: 16)),
                      Text(_phone, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [const SizedBox(width: 12)]),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.person, "ข้อมูลส่วนตัว", () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        );

                        if (result == true) {
                          await _fetchUserInfo();
                          widget.onProfileUpdated?.call();
                        }
                      }),
                      _buildMenuItem(Icons.lock, "เปลี่ยนรหัสผ่าน", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgetPasswordScreen()),
                        );
                      }),
                      _buildMenuItem(Icons.delete_forever, "ลบบัญชีผู้ใช้งานของฉัน", () {}),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                      ),
                      child: const Text(
                        "ออกจากระบบ",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
