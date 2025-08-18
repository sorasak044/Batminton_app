import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.parse('https://demoapi-production-9077.up.railway.app/api/bookings/my-bookings');

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
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to fetch bookings: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("❌ Error: $e");
    }
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
                        final courts = timeEntry.value;
                        final totalPrice =
                            courts.fold<double>(0, (sum, c) => sum + (c['pricePerHour'] ?? 0));
                        final status = courts.first['status'];

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
                                        status == "PENDING"
                                            ? "รอชำระเงิน"
                                            : "จองสำเร็จ",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
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
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupBookingsByDate() {
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

    for (var booking in bookings) {
      final date = booking['startTime'].substring(0, 10);
      final start = _formatTime(booking['startTime']);
      final end = _formatTime(booking['endTime']);
      final timeRange = "$start - $end";

      if (!grouped.containsKey(date)) {
        grouped[date] = {};
      }

      if (!grouped[date]!.containsKey(timeRange)) {
        grouped[date]![timeRange] = [];
      }

      grouped[date]![timeRange]!.add({
        'court': booking['court'],
        'pricePerHour': booking['court']['pricePerHour'] ?? 0,
        'status': booking['status'],
      });
    }

    return grouped;
  }
}
