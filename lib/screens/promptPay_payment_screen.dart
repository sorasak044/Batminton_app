import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PromptPayPaymentScreen extends StatefulWidget {
  final double totalAmount;
   final int bookingId;

  const PromptPayPaymentScreen({super.key, required this.totalAmount , required this.bookingId,});

  @override
  State<PromptPayPaymentScreen> createState() => _PromptPayPaymentScreenState();
}

class _PromptPayPaymentScreenState extends State<PromptPayPaymentScreen> {
  late Timer _timer;
  Duration _remainingTime = const Duration(minutes: 10);
  File? _slipImage;
  String? _qrBase64;
  bool _loadingQR = true;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _generatePromptPayQR();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _slipImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _generatePromptPayQR() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');  // ดึง Token จาก SharedPreferences

  if (token == null || token.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่')),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse("https://demoapi-production-9077.up.railway.app/api/payment/generate-qr"),  // แก้ URL ให้ตรงกับของจริง
      headers: {
        "Authorization": "Bearer $token",  // ส่ง Token ไปใน header
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "phoneNumber": "0812345678",  // เบอร์โทรที่ใช้ในการรับชำระ
        "amount": widget.totalAmount.toStringAsFixed(2),  // ยอดเงินที่ต้องการชำระ
      }),
    );

    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final qrBase64 = data['qrImage'].split(',').last;  // ดึงเฉพาะข้อมูล QR Image จาก Base64

      setState(() {
        _qrBase64 = qrBase64;  // ตั้งค่าฐานข้อมูลของ QR ที่ได้รับ
        _loadingQR = false;  // ตั้งให้การโหลด QR เสร็จสมบูรณ์
      });
    } else {
      throw Exception("QR generation failed: ${response.body}");  // หากเกิดข้อผิดพลาดในการสร้าง QR
    }
  } catch (e) {
    debugPrint("Error: $e");
    setState(() {
      _loadingQR = false;  // เปลี่ยนสถานะให้การโหลด QR เสร็จสิ้น
    });
  }
}



Future<void> uploadSlip() async {
  if (_slipImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('กรุณาเลือกสลิปก่อน')),
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null || token.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่')),
    );
    return;
  }

  final uri = Uri.parse('https://demoapi-production-9077.up.railway.app/api/bookings/upload-slip/${widget.bookingId}');
  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('slip', _slipImage!.path));

  final response = await request.send();

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('อัปโหลดสลิปสำเร็จ')),
    );
    Navigator.pop(context); // หรือไปหน้า success
  } else {
    final body = await response.stream.bytesToString();
    debugPrint('Upload failed: $body');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('อัปโหลดล้มเหลว: ${response.statusCode}')),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    final minutes = _remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text("ข้อมูลการชำระเงิน"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("ยอดชำระทั้งหมด", style: TextStyle(fontSize: 16)),
                Text("${widget.totalAmount.toStringAsFixed(2)} THB", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("กรุณาชำระภายใน", style: TextStyle(fontSize: 16)),
                Text("$minutes:$seconds", style: const TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("THAI QR PAYMENT", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _loadingQR
                      ? const CircularProgressIndicator()
                      : _qrBase64 != null
                          ? Image.memory(
                              base64Decode(_qrBase64!),
                              height: 200,
                              width: 200,
                            )
                          : const Text("ไม่สามารถสร้าง QR ได้"),
                  const SizedBox(height: 12),
                  const Text("สแกน QR หรือโอนเข้าบัญชี", style: TextStyle(fontSize: 14)),
                  const Text("ชื่อบัญชี: สมศักดิ์ ยอดรัก", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text("บัญชี: xxx-x-x2583-x", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("ทุกธนาคาร | รับชำระผ่านพร้อมเพย์"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _slipImage == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 40),
                            SizedBox(height: 4),
                            Text("กดเพื่อแนบสลิป", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_slipImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
  onPressed: uploadSlip,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    padding: const EdgeInsets.symmetric(vertical: 14),
  ),
  child: const Text("อัปโหลดสลิป", style: TextStyle(color: Colors.white)),
),

                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("ยกเลิก", style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
