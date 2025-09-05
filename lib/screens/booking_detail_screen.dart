import 'package:flutter/material.dart';
import '/service/notification_api.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _controller = TextEditingController();

  Future<void> _saveSetting() async {
    if (_controller.text.isEmpty) return;
    final minutes = int.tryParse(_controller.text) ?? 0;

    await NotificationApi.updateUserNotiSetting(widget.bookingId, minutes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("ตั้งค่าแจ้งเตือนล่วงหน้า $minutes นาทีสำเร็จ")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("รายละเอียดการจอง")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "ตั้งเวลาแจ้งเตือน (นาที)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveSetting,
              child: const Text("บันทึกการแจ้งเตือน"),
            ),
          ],
        ),
      ),
    );
  }
}
