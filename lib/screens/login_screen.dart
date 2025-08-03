import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  // ฟังก์ชันสำหรับการตรวจสอบว่า Token ถูกบันทึกไว้หรือไม่
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกอีเมลและรหัสผ่าน")),
      );
      return;
    }

    final url = Uri.parse(
      'https://demoapi-production-9077.up.railway.app/api/auth/login',
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token); // บันทึก token ไว้

        // เรียก API whoami เพื่อตรวจสอบตัวตนของผู้ใช้
        final whoamiUrl = Uri.parse(
          'https://demoapi-production-9077.up.railway.app/api/auth/whoami',
        );
        final whoamiRes = await http.get(
          whoamiUrl,
          headers: {"Authorization": "Bearer $token"}, // ส่ง token ใน header
        );

        if (whoamiRes.statusCode == 200) {
          final userData = json.decode(whoamiRes.body);
          final fullName = userData['name']?.trim() ?? 'สมชาย ใจดี';
          final nameParts = fullName.split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          // บันทึกข้อมูลผู้ใช้ลงใน SharedPreferences
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('userName', fullName); 
          await prefs.setString('userEmail', userData['email'] ?? '');
          await prefs.setString('userPhone', userData['phone'] ?? '');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เข้าสู่ระบบสำเร็จ! ยินดีต้อนรับคุณ $firstName'),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${error['message']}')),
        );
      }
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // ตรวจสอบ token ที่บันทึกไว้ใน SharedPreferences หากมีให้ทำการล็อกอินเข้าอัตโนมัติ
    _getToken().then((token) {
      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('assets/images/shuttle.png', height: 120),
                const SizedBox(height: 16),
                const Text(
                  "สนามแบดมินตัน",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'อีเมล',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'รหัสผ่าน',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "ลืมรหัสผ่าน?",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "ลงชื่อเข้าใช้",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "สมัครสมาชิก",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Image.asset('assets/images/googleicon.png', height: 24),
                  label: const Text(
                    "เข้าสู่ระบบด้วย Google",
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
