import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController(); // ช่องกรอกเบอร์โทรศัพท์
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ฟังก์ชันเช็คว่ากรอกครบไหม
  bool _validateInputs() {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
      );
      return false;
    }
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')),
      );
      return false;
    }
    return true;
  }

  Future<void> _registerUser() async {
    if (!_validateInputs()) return; // เช็คก่อน ถ้าไม่ครบจะไม่ไปต่อ

    final url = Uri.parse(
      'https://demoapi-production-9077.up.railway.app/api/auth/register',
    ); // API URL ของคุณ

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "firstName": firstNameController.text,
          "lastName": lastNameController.text,
          "email": emailController.text,
          "phone": phoneController.text,
          "password": passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // บันทึกข้อมูลผู้ใช้ลง SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('firstName', responseData['user']['firstName']);
        await prefs.setString('lastName', responseData['user']['lastName']);
        await prefs.setString('phone', responseData['user']['phone'] ?? '');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: ${error['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/shuttle.png',
                  width: 150,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // แยกชื่อ และ นามสกุล ออกจากกัน
                _buildTextField(controller: firstNameController, hint: 'ชื่อ'),
                const SizedBox(height: 15),
                _buildTextField(controller: lastNameController, hint: 'นามสกุล'),
                const SizedBox(height: 15),

                _buildTextField(
                  controller: phoneController,
                  hint: 'เบอร์โทรศัพท์',
                  keyboardType: TextInputType.number, // แป้นพิมพ์ตัวเลขเท่านั้น
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: emailController,
                  hint: 'อีเมล',
                  keyboardType: TextInputType.emailAddress, // แป้นพิมพ์มี @
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: passwordController,
                  hint: 'รหัสผ่าน',
                  obscure: true,
                  isPasswordField: true,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: confirmPasswordController,
                  hint: 'ยืนยันรหัสผ่าน',
                  obscure: true,
                  isConfirmPasswordField: true,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'สมัครสมาชิก',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'มีบัญชีอยู่แล้ว? ลงชื่อเข้าใช้',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool isPasswordField = false,
    bool isConfirmPasswordField = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPasswordField
          ? _obscurePassword
          : isConfirmPasswordField
              ? _obscureConfirmPassword
              : false,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade300,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: (isPasswordField || isConfirmPasswordField)
            ? IconButton(
                icon: Icon(
                  (isPasswordField && _obscurePassword) ||
                          (isConfirmPasswordField && _obscureConfirmPassword)
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    if (isPasswordField) {
                      _obscurePassword = !_obscurePassword;
                    } else if (isConfirmPasswordField) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }
                  });
                },
              )
            : null,
      ),
    );
  }
}
