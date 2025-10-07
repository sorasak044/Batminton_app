import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ✅ เก็บข้อความ error ของแต่ละ field
  String? firstNameError;
  String? lastNameError;
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;

   bool _validateInputs() {
    setState(() {
      firstNameError = firstNameController.text.isEmpty ? "กรุณากรอกชื่อ" : null;
      lastNameError = lastNameController.text.isEmpty ? "กรุณากรอกนามสกุล" : null;

      // ✅ เช็คเบอร์โทร 10 หลัก
      if (phoneController.text.isEmpty) {
        phoneError = "กรุณากรอกเบอร์โทรศัพท์";
      } else if (!RegExp(r'^\d{10}$').hasMatch(phoneController.text)) {
        phoneError = "กรุณากรอกเบอร์โทร 10 หลัก";
      } else {
        phoneError = null;
      }

      // ✅ เช็คอีเมล
      if (emailController.text.isEmpty) {
        emailError = "กรุณากรอกอีเมล";
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(emailController.text)) {
        emailError = "อีเมลไม่ถูกต้อง";
      } else {
        emailError = null;
      }

      // ✅ เช็ครหัสผ่าน
      if (passwordController.text.isEmpty) {
        passwordError = "กรุณากรอกรหัสผ่าน";
      } else if (passwordController.text.length < 4) {
        passwordError = "รหัสผ่านต้องมีอย่างน้อย 4 ตัว";
      } else {
        passwordError = null;
      }

      // ✅ ยืนยันรหัสผ่าน
      if (confirmPasswordController.text.isEmpty) {
        confirmPasswordError = "กรุณายืนยันรหัสผ่าน";
      } else if (confirmPasswordController.text != passwordController.text) {
        confirmPasswordError = "รหัสผ่านไม่ตรงกัน";
      } else {
        confirmPasswordError = null;
      }
    });

    // คืนค่า false ถ้ามี error
    return firstNameError == null &&
        lastNameError == null &&
        emailError == null &&
        phoneError == null &&
        passwordError == null &&
        confirmPasswordError == null;
  }

 Future<void> _registerUser() async {
  if (!_validateInputs()) return;

  final url = Uri.parse(
    'https://demoapi-production-9077.up.railway.app/api/auth/register',
  );

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

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print("✅ Register Success: $responseData");

      final prefs = await SharedPreferences.getInstance();

      // ✅ เก็บ token ถ้ามี
      if (responseData['token'] != null) {
        await prefs.setString('token', responseData['token']);
      }

      // ✅ เก็บข้อมูล user
      if (responseData['user'] != null) {
        await prefs.setString('firstName', responseData['user']['firstName'] ?? '');
        await prefs.setString('lastName', responseData['user']['lastName'] ?? '');
        await prefs.setString('email', responseData['user']['email'] ?? '');
        await prefs.setString('phone', responseData['user']['phone'] ?? '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
      );

      // ✅ ไปหน้า Home ทันที
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      print("❌ Error Response: ${response.body}");
      final error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${error['message']}')),
      );
    }
  } catch (e) {
    print("❌ Exception: $e");
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
                Image.asset('assets/images/shuttle.png', width: 150),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),

                _buildTextField(controller: firstNameController, hint: 'ชื่อ'),
                if (firstNameError != null)
                  _buildErrorText(firstNameError!),
                const SizedBox(height: 15),

                _buildTextField(controller: lastNameController, hint: 'นามสกุล'),
                if (lastNameError != null)
                  _buildErrorText(lastNameError!),
                const SizedBox(height: 15),

                _buildTextField(controller: phoneController, hint: 'เบอร์โทรศัพท์', keyboardType: TextInputType.number),
                if (phoneError != null)
                  _buildErrorText(phoneError!),
                const SizedBox(height: 15),

                _buildTextField(controller: emailController, hint: 'อีเมล', keyboardType: TextInputType.emailAddress),
                if (emailError != null)
                  _buildErrorText(emailError!),
                const SizedBox(height: 15),

                _buildTextField(controller: passwordController, hint: 'รหัสผ่าน', obscure: true, isPasswordField: true),
                if (passwordError != null)
                  _buildErrorText(passwordError!),
                const SizedBox(height: 15),

                _buildTextField(controller: confirmPasswordController, hint: 'ยืนยันรหัสผ่าน', obscure: true, isConfirmPasswordField: true),
                if (confirmPasswordError != null)
                  _buildErrorText(confirmPasswordError!),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _registerUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'สมัครสมาชิก',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 15),

// ✨ ข้อความ "มีบัญชีอยู่แล้ว"
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text("มีบัญชีอยู่แล้ว?"),
    TextButton(
      onPressed: () {
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const LoginScreen()),
); // ไปหน้า login
      },
      child: Text("เข้าสู่ระบบ"),
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

  // ✅ ใช้ TextField เดิม
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

  // ✅ Widget แสดง error ใต้ TextField
  Widget _buildErrorText(String error) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          error,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }
}
