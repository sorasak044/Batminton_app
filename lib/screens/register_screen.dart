import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
                // โลโก้
                Image.asset(
                  'assets/images/shuttle.png', // 👈 แก้ path ให้ตรงกับของคุณ
                  width: 150,
                ),
                const SizedBox(height: 20),

                // ชื่อแอป
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

                // ช่องกรอกข้อมูล
                _buildTextField(hint: 'ชื่อ - นามสกุล'),
                const SizedBox(height: 15),
                _buildTextField(hint: 'เบอร์โทรศัพท์'),
                const SizedBox(height: 15),
                _buildTextField(hint: 'อีเมล'),
                const SizedBox(height: 15),
                _buildTextField(hint: 'รหัสผ่าน', obscure: true),
                const SizedBox(height: 15),
                _buildTextField(hint: 'ยืนยันรหัสผ่าน', obscure: true),

                const SizedBox(height: 30),

                // ปุ่มสมัครสมาชิก
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
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

                // ลิงก์กลับไปล็อกอิน
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 👈 ย้อนกลับไปหน้า Login
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

  Widget _buildTextField({required String hint, bool obscure = false}) {
    return TextField(
      obscureText: obscure,
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
      ),
    );
  }
}
