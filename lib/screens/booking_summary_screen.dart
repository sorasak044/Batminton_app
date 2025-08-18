import 'package:flutter/material.dart';
import 'promptPay_payment_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookingSummaryScreen extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, Set<String>> selectedCourtsByTime;
  final double totalPrice;
  final Map<String, List<Map<String, dynamic>>> courtsByTimeRange;
  final int? bookingId;

  const BookingSummaryScreen({
    super.key,
    required this.selectedDate,
    required this.selectedCourtsByTime,
    required this.totalPrice,
    required this.courtsByTimeRange,
    this.bookingId,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool isLoading = false;
  // เนื่องจากจองหลายคอร์ท อาจได้ bookingId หลายตัว จึงใช้ List<int>
  List<int> bookingIds = [];
   int? get bookingId => bookingIds.isNotEmpty ? bookingIds.first : null;

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      bookingIds.add(widget.bookingId!);
    }
  }

  Future<void> createBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) {
        throw Exception('ไม่พบ Token กรุณาเข้าสู่ระบบใหม่');
      }

      bookingIds.clear(); // เคลียร์ก่อนเริ่มจองใหม่

      for (var entry in widget.selectedCourtsByTime.entries) {
        final timeRange = entry.key;
        final courts = entry.value;

        // แยกเวลาจองเป็น start และ end
        final times = timeRange.split(' - ');
        final startTime = times[0];
        final endTime = times.length > 1 ? times[1] : _getEndTime(startTime);

        
        print('Courts for timeRange $timeRange: ${widget.courtsByTimeRange[timeRange]}');


        for (var courtName in courts) {
          final courtList = widget.courtsByTimeRange[timeRange] ?? [];
          final courtInfo = courtList.firstWhere(
            (c) => c['name'] == courtName,
            orElse: () => {},
          );
          

          if (courtInfo.isEmpty) {
            print('ไม่พบข้อมูลคอร์ทชื่อ "$courtName" ในช่วงเวลา $timeRange');
            continue;
          }

          final courtId = courtInfo['id'];
          if (courtId == null) {
            print(
              "Error: courtId เป็น null สำหรับคอร์ท $courtName ในช่วงเวลา $timeRange",
            );
            continue; // ข้ามคอร์ทนี้
          }

          final bookingDate =
              "${widget.selectedDate.year.toString().padLeft(4, '0')}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}";

          final requestBody = {
            "courtId": courtId,
            "date": bookingDate,
            "startTime": startTime,
            "endTime": endTime,
          };
          print('POST /api/bookings with body: $requestBody');

          final response = await http.post(
            Uri.parse(
              'https://demoapi-production-9077.up.railway.app/api/bookings',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          );

          print('Response status: ${response.statusCode}');
          print('Response body: ${response.body}');

          if (response.statusCode == 201) {
            final data = jsonDecode(response.body);
            bookingIds.add(data['booking']['id']);
          } else {
            final error = jsonDecode(response.body);
            throw Exception(error['message'] ?? 'สร้าง Booking ไม่สำเร็จ');
          }
        }
      }

      setState(() {
        isLoading = false;
      });

      if (bookingIds.isNotEmpty) {
        // สมมติส่ง bookingId ตัวแรกไปหน้าชำระเงิน
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => PromptPayPaymentScreen(
      totalAmount: widget.totalPrice,
      bookingId: bookingIds.first, // ต้องไม่เป็น 0 หรือ null
    ),
  ),
);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // คำนวณจำนวนชั่วโมงรวม = จำนวน courts ทั้งหมด (ไม่ใช่แค่ keys)
    int totalCourts = 0;
    widget.selectedCourtsByTime.values.forEach((setCourts) {
      totalCourts += setCourts.length;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("สรุปรายการจอง"),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.selectedDate.day} ${_thaiMonth(widget.selectedDate.month)} ${widget.selectedDate.year + 543}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.yellow[600],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "รอดำเนินการ",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...widget.selectedCourtsByTime.entries.expand((entry) {
                          final time = entry.key;
                          return entry.value.map((court) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    court,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        time,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const Text(
                                        "1 ชั่วโมง",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _getCourtPrice(time, court)
                                        .toStringAsFixed(2),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("รวมเวลา", style: TextStyle(fontSize: 16)),
                      Text(
                        "$totalCourts ชั่วโมง",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("รวมค่าบริการ", style: TextStyle(fontSize: 16)),
                      Text(
                        widget.totalPrice.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: createBookings,
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      label: const Text(
                        "ชำระเงินผ่าน PromptPay",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double _getCourtPrice(String time, String courtName) {
    if (widget.courtsByTimeRange[time] != null) {
      final match = widget.courtsByTimeRange[time]!
          .where((court) => court['name'] == courtName)
          .toList();
      if (match.isNotEmpty) {
        return (match.first['pricePerHour'] ?? 0).toDouble();
      }
    }
    return 0;
  }

  String _thaiMonth(int month) {
    const months = [
      "",
      "ม.ค.",
      "ก.พ.",
      "มี.ค.",
      "เม.ย.",
      "พ.ค.",
      "มิ.ย.",
      "ก.ค.",
      "ส.ค.",
      "ก.ย.",
      "ต.ค.",
      "พ.ย.",
      "ธ.ค.",
    ];
    return months[month];
  }

  String _getEndTime(String startTime) {
    final hour = int.tryParse(startTime.split(":")[0]) ?? 0;
    final nextHour = hour + 1;
    return "${nextHour.toString().padLeft(2, '0')}:00";
  }
}
