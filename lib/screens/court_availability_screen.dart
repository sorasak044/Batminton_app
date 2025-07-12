import 'package:flutter/material.dart';
import 'package:badminton_booking_app/screens/booking_summary_screen.dart';


class CourtSelectionScreen extends StatefulWidget {
  final DateTime selectedDate;

  const CourtSelectionScreen({super.key, required this.selectedDate});

  @override
  State<CourtSelectionScreen> createState() => _CourtSelectionScreenState();
}

class _CourtSelectionScreenState extends State<CourtSelectionScreen> {
  final int pricePerHour = 110;
  final timeSlots = List.generate(16, (i) => '${(8 + i).toString().padLeft(2, '0')}:00');
  final courts = List.generate(6, (i) => {
    "name": "Court ${i + 1}",
    "available": i != 2 && i != 4,
  });

  /// เก็บการเลือก: Map<เวลา, Set<คอร์ด>>
  Map<String, Set<String>> selectedCourtsByTime = {};

  bool isSelected(String time, String courtName) {
    return selectedCourtsByTime[time]?.contains(courtName) ?? false;
  }

  void toggleSelection(String time, String courtName) {
    setState(() {
      selectedCourtsByTime.putIfAbsent(time, () => {});
      if (selectedCourtsByTime[time]!.contains(courtName)) {
        selectedCourtsByTime[time]!.remove(courtName);
        if (selectedCourtsByTime[time]!.isEmpty) {
          selectedCourtsByTime.remove(time);
        }
      } else {
        selectedCourtsByTime[time]!.add(courtName);
      }
    });
  }

  int get totalHours => selectedCourtsByTime.keys.length;
  int get totalCourts => selectedCourtsByTime.values.fold(0, (sum, courts) => sum + courts.length);
  double get totalPrice => totalHours * totalCourts * pricePerHour.toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกคอร์ทและเวลา'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Text(
                '${widget.selectedDate.day} ${_thaiMonth(widget.selectedDate.month)} ${widget.selectedDate.year + 543}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  final time = timeSlots[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("เวลา $time", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        children: courts.map((court) {
                          final name = court["name"] as String;
                          final available = court["available"] as bool;
                          final selected = isSelected(time, name);
                          return GestureDetector(
                            onTap: available
                                ? () => toggleSelection(time, name)
                                : null,
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
                                      Text(available ? "ว่าง" : "ไม่ว่าง", style: TextStyle(color: available ? Colors.green : Colors.red)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
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
                  Row(children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 4),
                    Text("$totalHours ชั่วโมง"),
                  ]),
                  Row(children: [
                    const Icon(Icons.sports_tennis),
                    const SizedBox(width: 4),
                    Text("$totalCourts คอร์ด"),
                  ]),
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
              pricePerHour: pricePerHour,
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

  String _thaiMonth(int month) {
    const months = ["", "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.",
      "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."];
    return months[month];
  }
}
