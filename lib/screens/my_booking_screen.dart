import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// เพิ่ม: service แจ้งเตือนในเครื่อง & API ตั้งค่าที่เซิร์ฟเวอร์ (ถ้ามี)
import '/service/local_notification_service.dart';
import '/service/notification_api.dart'; // ถ้าไฟล์ชื่อนี้ตามที่ทักทำไว้

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  List<dynamic> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // init แจ้งเตือน (เงียบๆ)
    LocalNotificationService.instance.init();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse(
        'https://demoapi-production-9077.up.railway.app/api/bookings/my-bookings');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) ?? [];
        setState(() {
          bookings = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        throw Exception('Failed to fetch bookings: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Error: $e");
    }
  }

  // === ตั้งค่าแจ้งเตือนฝั่งเซิร์ฟเวอร์ (optional) + ตั้งแจ้งเตือนในเครื่อง ===
  Future<void> _openReminderDialog({
    required int bookingId,
    required DateTime startLocal,
    required String titleForNoti,
    required String bodyForNoti,
  }) async {
    final controller = TextEditingController(text: '30'); // default 30 นาที
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ตั้งเตือนล่วงหน้า'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'นาที (เช่น 30)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, (value == null || value <= 0) ? null : value);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (minutes == null) return;

    // (ทางเลือก) อัปเดตการตั้งค่าไปเซิร์ฟเวอร์ด้วย
    try {
      await NotificationApi.updateUserNotiSetting(bookingId.toString(), minutes);
    } catch (_) {}

    // ตั้งแจ้งเตือนในเครื่อง
    await LocalNotificationService.instance.scheduleBookingReminder(
      id: bookingId,
      startTimeLocal: startLocal,
      minutesBefore: minutes,
      title: titleForNoti,
      body: bodyForNoti,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ตั้งเตือนล่วงหน้า $minutes นาทีเรียบร้อย')),
    );
  }

  String _formatTime(String iso) {
    final dateTime = DateTime.parse(iso).toLocal();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "การจองของฉัน",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ..._groupBookingsByDate().entries.map((dateEntry) {
                  final date = dateEntry.key;
                  final bookingsByTime = dateEntry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...bookingsByTime.entries.map((timeEntry) {
                        final timeRange = timeEntry.key;
                        final courts = timeEntry.value; // list<Map>
                        final totalPrice =
                            courts.fold<double>(0, (sum, c) => sum + (c['pricePerHour'] ?? 0));
                        final status = courts.first['status'];

                        // เพิ่ม: ใช้ข้อมูลตัวแรกของกลุ่มเป็นตัวแทน (มี bookingId & startLocal)
                        final bookingId = courts.first['id'] as int;
                        final startLocal = courts.first['startLocal'] as DateTime;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$timeRange : ${courts.map((c) => c['court']['name']).join(', ')}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "฿${totalPrice.toStringAsFixed(2)}",
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == "PENDING"
                                            ? Colors.orange[100]
                                            : Colors.green[100],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status == "PENDING" ? "รอชำระเงิน" : "จองสำเร็จ",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),

                                // 🔔 ปุ่มที่ "เพิ่ม" เข้ามา (UI เดิมคงไว้ 100%)
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.alarm),
                                    label: const Text('ตั้งเตือน'),
                                    onPressed: () {
                                      final title = 'เตือนการจองสนามแบด';
                                      final body = 'รอบ $timeRange กำลังจะเริ่ม';
                                      _openReminderDialog(
                                        bookingId: bookingId,
                                        startLocal: startLocal,
                                        titleForNoti: title,
                                        bodyForNoti: body,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ],
            ),
          );
  }

  /// จัดกลุ่ม bookings: แยกตามวันก่อน แล้วตามเวลา
  /// (เพิ่มเก็บ id และ startLocal ไว้ในกลุ่มด้วย เพื่อใช้ตั้งเตือน)
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupBookingsByDate() {
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

    for (var booking in bookings) {
      final date = booking['startTime'].substring(0, 10);
      final startLocal = DateTime.parse(booking['startTime']).toLocal();
      final endLocal = DateTime.parse(booking['endTime']).toLocal();
      final start = "${startLocal.hour.toString().padLeft(2, '0')}:${startLocal.minute.toString().padLeft(2, '0')}";
      final end = "${endLocal.hour.toString().padLeft(2, '0')}:${endLocal.minute.toString().padLeft(2, '0')}";
      final timeRange = "$start - $end";

      grouped.putIfAbsent(date, () => {});
      grouped[date]!.putIfAbsent(timeRange, () => []);

      grouped[date]![timeRange]!.add({
        'id': booking['id'], // <-- จำเป็นสำหรับ notification id
        'startLocal': startLocal, // <-- เอาไว้คำนวณเวลาเตือน
        'court': booking['court'],
        'pricePerHour': booking['court']['pricePerHour'] ?? 0,
        'status': booking['status'],
      });
    }

    return grouped;
  }
}
