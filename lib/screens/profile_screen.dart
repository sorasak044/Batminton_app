import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = '';
  String _phone = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();  // เรียกใช้ฟังก์ชันเพื่อโหลดข้อมูลผู้ใช้
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');  // อ่าน token จาก SharedPreferences

    if (token == null || token.isEmpty) {
      _logout(context);  // หากไม่มี token ให้ทำการล็อกเอาท์
      return;
    }

    final response = await http.get(
      Uri.parse('https://demoapi-production-9077.up.railway.app/api/auth/whoami'),
      headers: {
        'Authorization': 'Bearer $token',  // ส่ง token ไปใน header
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _fullName = data['name'] ?? '';  // เก็บชื่อ
        _phone = data['phone'] ?? '';  // เก็บเบอร์โทร
        _isLoading = false;
      });
    } else {
      print('❌ ดึงข้อมูลไม่สำเร็จ: ${response.body}');
      setState(() => _isLoading = false);  // ถ้าเกิดข้อผิดพลาดจะเปลี่ยนการโหลดข้อมูล
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // เคลียร์ข้อมูลทั้งหมดจาก SharedPreferences

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),  // ไปที่หน้า Login
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())  // ถ้ายังโหลดข้อมูลไม่เสร็จจะแสดง Progress Indicator
        : SingleChildScrollView(
            child: Column(
              children: [
                // ✅ ส่วนหัวโปรไฟล์
                Container(
                  color: Colors.green[300],
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Text(
                        'BADMINTON CLUB',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fullName,  // แสดงชื่อที่ได้จาก API
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        _phone,  // แสดงเบอร์โทรที่ได้จาก API
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // 🏸 Member rank
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Member Rank",
                                  style: TextStyle(fontSize: 14)),
                              const Text("Bronze",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text("Member Point"),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: 0.3,
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // TODO: ไปหน้าแลกของขวัญ
                          },
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: AssetImage("assets/images/gift.jpg"),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 📄 เมนู
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.person, "ข้อมูลส่วนตัว", () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const EditProfileScreen()));
                      }),
                      _buildMenuItem(Icons.star, "ประวัติพอยต์", () {}),
                      _buildMenuItem(Icons.card_giftcard, "คูปองของฉัน", () {}),
                      _buildMenuItem(Icons.lock, "เปลี่ยนรหัสผ่าน", () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgetPasswordScreen()));
                      }),
                      _buildMenuItem(Icons.delete_forever,
                          "ลบบัญชีผู้ใช้งานของฉัน", () {}),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🚪 Logout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[300],
                      ),
                      child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.white),),
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
