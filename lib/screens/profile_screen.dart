import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // 👉 import หน้า LoginScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = '';
  String _lastName = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('firstName') ?? '';
      _lastName = prefs.getString('lastName') ?? '';
      _phone = prefs.getString('phone') ?? '';
    });
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // ลบ token หรือ session ที่เก็บไว้

    // กลับไปหน้า Login และล้าง Navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_firstName $_lastName',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  _phone,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // 🏸 Member rank
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        const Text("Member Rank", style: TextStyle(fontSize: 14)),
                        const Text("Bronze", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          image: AssetImage("assets/images/gift.png"),
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
                _buildMenuItem(Icons.person, "ข้อมูลส่วนตัว", () {}),
                _buildMenuItem(Icons.star, "ประวัติพอยต์", () {}),
                _buildMenuItem(Icons.card_giftcard, "คูปองของฉัน", () {}),
                _buildMenuItem(Icons.lock, "เปลี่ยนรหัสผ่าน", () {}),
                _buildMenuItem(Icons.delete_forever, "ลบบัญชีผู้ใช้งานของฉัน", () {}),
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
                child: const Text("ออกจากระบบ"),
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
