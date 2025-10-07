import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '/service/notification_api.dart';

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
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse(
      'https://demoapi-production-9077.up.railway.app/api/bookings/my-bookings',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bookings = (data is List) ? data : [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  /// ฟังก์ชันเปิด Dialog ตั้งเวลาแจ้งเตือน
  Future<void> _openReminderDialog({
    required int bookingId,
  }) async {
    final controller = TextEditingController(text: '30');
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              Navigator.pop(
                ctx,
                (value == null || value < 5) ? null : value, // backend ต้อง >= 5 นาที
              );
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (minutes == null) return;

    try {
      final result = await NotificationApi.updateUserNotiSetting(
        bookingId.toString(),
        minutes,
      );

      if (!mounted) return;

      if (result != null && result['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถอัปเดตการแจ้งเตือนได้')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  String _fmt(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
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
                  final totalPrice = courts.fold<double>(
                    0,
                    (sum, c) =>
                        sum + ((c['pricePerHour'] as num?)?.toDouble() ?? 0.0),
                  );
                  final status = courts.first['status'] as String? ?? 'PENDING';
                  final bookingId = courts.first['id'] as int;

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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  status == "PENDING"
                                      ? "รอชำระเงิน"
                                      : "จองสำเร็จ",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              icon: const Icon(Icons.alarm),
                              label: const Text('ตั้งเตือน'),
                              onPressed: () {
                                _openReminderDialog(
                                  bookingId: bookingId,
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

  /// แยกกลุ่มตามวัน -> เวลา และแนบข้อมูลที่ต้องใช้เตือน
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupBookingsByDate() {
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

    for (var booking in bookings) {
      final startIso = booking['startTime'] as String;
      final endIso = booking['endTime'] as String;

      final startLocal = DateTime.parse(startIso).toLocal();
      final endLocal = DateTime.parse(endIso).toLocal();

      final date = startIso.substring(0, 10);
      final start = _fmt(startLocal);
      final end = _fmt(endLocal);
      final timeRange = "$start - $end";

      grouped.putIfAbsent(date, () => {});
      grouped[date]!.putIfAbsent(timeRange, () => []);

      grouped[date]![timeRange]!.add({
        'id': booking['id'] as int,
        'startLocal': startLocal,
        'court': booking['court'],
        'pricePerHour': booking['court']?['pricePerHour'] ?? 0,
        'status': booking['status'],
      });
    }

    return grouped;
  }
}
