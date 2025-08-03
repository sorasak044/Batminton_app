import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _token; // โชว์ token (ใช้ใน dev เท่านั้น)

  Future<void> _submit() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมล')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://demoapi-production-9077.up.railway.app/api/auth/forget-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text}),
      );

      final resData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _token = resData['token']; // ใน dev อาจใช้แสดงให้กรอกเอง
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งคำขอสำเร็จ กรุณาตรวจสอบอีเมลของคุณ')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? 'เกิดข้อผิดพลาด')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ลืมรหัสผ่าน")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("ป้อนอีเมลของคุณเพื่อรับลิงก์เปลี่ยนรหัสผ่าน", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'อีเมล',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ส่งคำขอ"),
            ),
            if (_token != null) ...[
              const SizedBox(height: 24),
              const Text("Token ที่ได้รับ:", style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_token ?? '', style: const TextStyle(color: Colors.blue)),
            ],
          ],
        ),
      ),
    );
  }
}
