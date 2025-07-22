import 'package:flutter/material.dart';
import 'booking_summary_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourtSelectionScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String startTime;
  final String endTime;
  final int pricePerHour;

  const CourtSelectionScreen({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    this.pricePerHour = 110,
  });

  @override
  State<CourtSelectionScreen> createState() => _CourtSelectionScreenState();
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  List<Map<String, dynamic>> courts = [];
  Map<String, Set<String>> selectedCourtsByTime = {};
  bool isLoading = true;

  String get currentTimeSlot => widget.startTime;

  bool isSelected(String courtName) {
    return selectedCourtsByTime[currentTimeSlot]?.contains(courtName) ?? false;
  }

  void toggleSelection(String courtName) {
    setState(() {
      selectedCourtsByTime.putIfAbsent(currentTimeSlot, () => {});
      if (selectedCourtsByTime[currentTimeSlot]!.contains(courtName)) {
        selectedCourtsByTime[currentTimeSlot]!.remove(courtName);
        if (selectedCourtsByTime[currentTimeSlot]!.isEmpty) {
          selectedCourtsByTime.remove(currentTimeSlot);
        }
      } else {
        selectedCourtsByTime[currentTimeSlot]!.add(courtName);
      }
    });
  }

  int get totalCourts => selectedCourtsByTime.values.fold(0, (sum, courts) => sum + courts.length);
  double get totalPrice => totalCourts * widget.pricePerHour.toDouble();

  @override
  void initState() {
    super.initState();
    fetchCourts();
  }

  Future<void> fetchCourts() async {
    final dateStr = "${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse('http://10.0.2.2:3000/api/courts/available?date=$dateStr&startTime=${widget.startTime}&endTime=${widget.endTime}');

    
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          courts = (data as List).map((item) {
            return {
              "name": item["name"],
              "available": item["available"] ?? true,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception("โหลดข้อมูลไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      print("Error fetching courts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = "${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year + 543}";
    
    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกคอร์ด $formattedDate'),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "ช่วงเวลา: ${widget.startTime} - ${widget.endTime}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: courts.map((court) {
                        final name = court["name"] as String;
                        final available = court["available"] as bool;
                        final selected = isSelected(name);

                        return GestureDetector(
                          onTap: available ? () => toggleSelection(name) : null,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selected ? Colors.green[200] : Colors.grey[100],
                              border: Border.all(
                                color: available ? Colors.green : Colors.red,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 16)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.circle, size: 12, color: available ? Colors.green : Colors.red),
                                    const SizedBox(width: 6),
                                    Text(
                                      available ? "ว่าง" : "ไม่ว่าง",
                                      style: TextStyle(color: available ? Colors.green : Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: totalCourts > 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingSummaryScreen(
                                    selectedDate: widget.selectedDate,
                                    selectedCourtsByTime: selectedCourtsByTime,
                                    pricePerHour: widget.pricePerHour,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: const Text("ต่อไป"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
