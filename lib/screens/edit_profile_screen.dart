import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ฟังก์ชันโหลดข้อมูลผู้ใช้จาก SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    String firstName = prefs.getString('firstName') ?? '';
    String lastName = prefs.getString('lastName') ?? '';

    if (firstName.isEmpty || lastName.isEmpty) {
      final fullName = prefs.getString('userName') ?? 'สมชาย ใจดี';
      final nameParts = fullName.split(' ');
      firstName = nameParts.isNotEmpty ? nameParts[0] : 'สมชาย';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'ใจดี';
    }

    final phone = prefs.getString('userPhone') ?? '0891234567';

    setState(() {
      _firstNameController.text = firstName;
      _lastNameController.text = lastName;
      _phoneController.text = phone;
    });
  }

  // ฟังก์ชันบันทึกข้อมูลผู้ใช้และส่งไปยัง API
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone = _phoneController.text.trim();

      // ตรวจสอบว่าข้อมูลครบถ้วน
      if (firstName.isEmpty || lastName.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
        );
        return;
      }

      final token = prefs.getString(
        'auth_token',
      ); // Token ที่บันทึกใน SharedPreferences
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบ Token กรุณาล็อกอินใหม่')),
        );
        return;
      }

      try {
        // ส่งข้อมูลไปยัง API
        final response = await http.put(
          Uri.parse(
            'https://demoapi-production-9077.up.railway.app/api/auth/update-profile',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // ส่ง token สำหรับการยืนยันตัวตน
          },
          body: jsonEncode({
            'firstName': firstName,
            'lastName': lastName,
            'phone': phone,
          }),
        );

        print("Response status: ${response.statusCode}");
        print("Response body: ${response.body}");

        if (response.statusCode == 200) {
          // API success response
          final data = json.decode(response.body);
          // บันทึกข้อมูลโปรไฟล์ใหม่ใน SharedPreferences
          await prefs.setString('firstName', firstName);
          await prefs.setString('lastName', lastName);
          await prefs.setString('userPhone', phone);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
          Navigator.pop(context, true);
        } else {
          // API failed response
          throw Exception('ไม่สามารถบันทึกข้อมูลได้');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขข้อมูลส่วนตัว"),
        backgroundColor: Colors.green[300],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: "ชื่อจริง",
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: "นามสกุล",
                        icon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: "เบอร์โทร",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[300],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, // ไม่มีกรอบ
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'กรุณากรอก $label';
        }
        return null;
      },
    );
  }
}
