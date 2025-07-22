import 'package:flutter/material.dart';
import 'court_selection_screen.dart';

class TimeSelectionScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String courtName;

  const TimeSelectionScreen({
    super.key,
    required this.selectedDate,
    required this.courtName
    
  });

  @override
  State<TimeSelectionScreen> createState() => _TimeSelectionScreenState();
}

class _TimeSelectionScreenState extends State<TimeSelectionScreen> {
  String? selectedTime;

  List<String> availableTimes = List.generate(16, (index) {
    final hour = 8 + index;
    return '${hour.toString().padLeft(2, '0')}:00';
  });

  String addOneHour(String time) {
    final hour = int.parse(time.split(':')[0]);
    final nextHour = hour + 1;
    return '${nextHour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เลือกเวลา - ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year + 543}'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text('เลือกเวลาเริ่มต้น:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: availableTimes.length,
                itemBuilder: (context, index) {
                  final time = availableTimes[index];
                  final isSelected = selectedTime == time;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedTime = time;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? Colors.green : Colors.grey[200],
                          foregroundColor:
                              isSelected ? Colors.white : Colors.black,
                          minimumSize: const Size(200, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(time),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedTime == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourtSelectionScreen(
                              selectedDate: widget.selectedDate,
                              startTime: selectedTime!,
                              endTime: addOneHour(selectedTime!),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "ยืนยัน",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
