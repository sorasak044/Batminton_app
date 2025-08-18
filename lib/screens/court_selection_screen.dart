import 'package:flutter/material.dart';
import 'booking_summary_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourtSelectionScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String startTime;
  final String endTime;

  const CourtSelectionScreen({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<CourtSelectionScreen> createState() => _CourtSelectionScreenState();
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  List<Map<String, dynamic>> courts = [];
  Map<String, List<Map<String, dynamic>>> courtsByTimeRange =
      {}; // เก็บคอร์ทตามช่วงเวลา
  Map<String, Set<String>> selectedCourtsByTime = {}; // เก็บคอร์ทที่เลือก
  bool isLoading = true;

  // ฟังก์ชันตรวจสอบว่าคอร์ทนั้นถูกเลือกหรือไม่
  bool isSelected(String timeRange, String courtName) {
    return selectedCourtsByTime[timeRange]?.contains(courtName) ?? false;
  }

  // ฟังก์ชันสำหรับการสลับการเลือกคอร์ท
  void toggleSelection(String timeRange, String courtName) {
    setState(() {
      selectedCourtsByTime.putIfAbsent(timeRange, () => {});
      if (selectedCourtsByTime[timeRange]!.contains(courtName)) {
        selectedCourtsByTime[timeRange]!.remove(courtName);
        if (selectedCourtsByTime[timeRange]!.isEmpty) {
          selectedCourtsByTime.remove(timeRange);
        }
      } else {
        selectedCourtsByTime[timeRange]!.add(courtName);
      }
    });
  }

  // ฟังก์ชันคำนวณจำนวนคอร์ทที่เลือก
  int get totalCourts {
    final allCourts = <String>{};
    selectedCourtsByTime.values.forEach((set) => allCourts.addAll(set));
    return allCourts.length;
  }

  // ฟังก์ชันคำนวณราคาทั้งหมด โดยใช้ราคาจาก API
  double get totalPrice {
    double total = 0;
    selectedCourtsByTime.forEach((timeRange, courts) {
      courts.forEach((courtName) {
        // ค้นหาราคา per hour จาก courtsByTimeRange
        for (var court in courtsByTimeRange[timeRange]!) {
          if (court['name'] == courtName) {
            // ตรวจสอบว่า pricePerHour เป็น null หรือไม่
            final pricePerHour =
                court['pricePerHour'] ?? 0; // ใช้ค่าเริ่มต้นเป็น 0 ถ้าไม่พบราคา
            total += pricePerHour;
          }
        }
      });
    });
    return total;
  }

  @override
  void initState() {
    super.initState();
    fetchCourts();
  }

  // ฟังก์ชันดึงข้อมูลคอร์ทจาก API
  Future<void> fetchCourts() async {
    final dateStr =
        "${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}";
    final startTimeStr = widget.startTime; // ค่าที่ส่งจาก UI เช่น "08:00"
    final endTimeStr = widget.endTime; // ค่าที่ส่งจาก UI เช่น "23:00"

    final uri = Uri.parse(
      'https://demoapi-production-9077.up.railway.app/api/courts/available?date=$dateStr&startTime=$startTimeStr&endTime=$endTimeStr',
    ); // ส่งค่า startTime และ endTime

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final courtsData = decoded['courts'] as List;

        Map<String, List<Map<String, dynamic>>> groupedCourts = {};

        // ดึงข้อมูลราคาจาก API
       for (var court in courtsData) {
  final name = court['name'];
  final courtId = court['id']; // ดึง id มาเลย
  final slots = court['slots'] as List;

  final pricePerHour = await _getPricePerHour(courtId);

  for (var slot in slots) {
    final slotStart = slot['startTime'];
    final slotEnd = slot['endTime'];
    final timeRange = "$slotStart - $slotEnd";

    groupedCourts.putIfAbsent(timeRange, () => []);
    groupedCourts[timeRange]!.add({
      "id": courtId,  // เพิ่ม id ตรงนี้
      "name": name,
      "available": slot['status'] == 'AVAILABLE',
      "pricePerHour": pricePerHour,
    });
  }
}


        setState(() {
          courtsByTimeRange = groupedCourts;
          isLoading = false;
        });
      } else {
        throw Exception("โหลดข้อมูลไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // ฟังก์ชันดึงราคาจาก API /api/courts/:courtId
  Future<int> _getPricePerHour(int courtId) async {
    final uri = Uri.parse(
      'https://demoapi-production-9077.up.railway.app/api/courts/$courtId',
    ); // ใช้ courtId
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final pricePerHour = decoded['pricePerHour'];
      return pricePerHour ?? 0; // ถ้าไม่ได้ค่ากลับให้ใช้ 0
    } else {
      throw Exception("ไม่สามารถดึงข้อมูลราคาได้");
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        "${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year + 543}";

    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกคอร์ด $formattedDate'),
        backgroundColor: Colors.green[700],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ช่วงเวลาที่เลือก
                    Text(
                      "ช่วงเวลา: ${widget.startTime} - ${widget.endTime}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // แสดงคอร์ททั้งหมด
                    Expanded(
                      child: ListView(
                        children:
                            courtsByTimeRange.entries.map((entry) {
                              final timeRange = entry.key;
                              final courtList = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    timeRange,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GridView.count(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children:
                                        courtList.map((court) {
                                          final name = court["name"];
                                          final available = court["available"];
                                          final selected = isSelected(
                                            timeRange,
                                            name,
                                          );

                                          return GestureDetector(
                                            onTap:
                                                available
                                                    ? () => toggleSelection(
                                                      timeRange,
                                                      name,
                                                    )
                                                    : null,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    selected
                                                        ? Colors.green[200]
                                                        : Colors.grey[100],
                                                border: Border.all(
                                                  color:
                                                      available
                                                          ? Colors.green
                                                          : Colors.red,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.circle,
                                                        size: 12,
                                                        color:
                                                            available
                                                                ? Colors.green
                                                                : Colors.red,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        available
                                                            ? "ว่าง"
                                                            : "ไม่ว่าง",
                                                        style: TextStyle(
                                                          color:
                                                              available
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                    // แสดงจำนวนคอร์ทที่เลือกและราคาที่ต้องชำระ
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sports_tennis),
                              const SizedBox(width: 4),
                              Text("$totalCourts คอร์ด"),
                            ],
                          ),
                          Text("รวม ${totalPrice.toStringAsFixed(2)} บาท"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ปุ่ม "ต่อไป"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            totalCourts > 0
                                ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => BookingSummaryScreen(
                                            selectedDate: widget.selectedDate,
                                            selectedCourtsByTime:
                                                selectedCourtsByTime,
                                            totalPrice:
                                                totalPrice, // ส่ง totalPrice ที่คำนวณแล้ว
                                            courtsByTimeRange:
                                                courtsByTimeRange, // ส่ง courtsByTimeRange
                                            bookingId: 0,
                                          ),
                                    ),
                                  );
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[600],
                        ),
                        child: const Text(
                          "ต่อไป",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
