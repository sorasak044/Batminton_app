import 'package:flutter/material.dart';
import 'promptPay_payment_screen.dart';

class BookingSummaryScreen extends StatelessWidget {
  final DateTime selectedDate;
  final Map<String, Set<String>> selectedCourtsByTime;
  final double totalPrice;
  final Map<String, List<Map<String, dynamic>>> courtsByTimeRange; // ✅ เพิ่มตรงนี้
  final int? bookingId; 

  const BookingSummaryScreen({
    super.key,
    required this.selectedDate,
    required this.selectedCourtsByTime,
    required this.totalPrice,
    required this.courtsByTimeRange, // ✅ เพิ่มตรงนี้
    this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    final totalHours = selectedCourtsByTime.keys.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("สรุปรายการจอง"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
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
                  // วันที่ + สถานะ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedDate.day} ${_thaiMonth(selectedDate.month)} ${selectedDate.year + 543}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow[600],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "รอดำเนินการ",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // แสดงรายการจอง
                  ...selectedCourtsByTime.entries.expand((entry) {
                    final time = entry.key;
                    return entry.value.map((court) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(court, style: const TextStyle(fontSize: 16)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(time, style: const TextStyle(fontSize: 14)),
                                const Text("1 ชั่วโมง", style: TextStyle(fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                            Text(
                              "${_getCourtPrice(time, court).toStringAsFixed(2)}",
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

            // รวมเวลาและราคา
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("รวมเวลา", style: TextStyle(fontSize: 16)),
                Text("$totalHours ชั่วโมง", style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("รวมค่าบริการ", style: TextStyle(fontSize: 16)),
                Text(totalPrice.toStringAsFixed(2), style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Spacer(),

            // ปุ่ม PromptPay
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PromptPayPaymentScreen(totalAmount: totalPrice,  bookingId:bookingId ?? 0,),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code, color: Colors.white),
                label: const Text("ชำระเงินผ่าน PromptPay", style: TextStyle(color: Colors.white)),
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

  // ฟังก์ชันแปลงเวลา
  String _getEndTime(String startTime) {
    final hour = int.tryParse(startTime.split(":")[0]) ?? 0;
    final nextHour = hour + 1;
    return "${nextHour.toString().padLeft(2, '0')}:00";
  }

  // ฟังก์ชันคำนวณราคา
double _getCourtPrice(String time, String courtName) {
  if (courtsByTimeRange[time] != null) {
    final match = courtsByTimeRange[time]!
        .where((court) => court['name'] == courtName)
        .toList();
    if (match.isNotEmpty) {
      return (match.first['pricePerHour'] ?? 0).toDouble();
    }
  }
  return 0;
}


  // ฟังก์ชันแปลงเดือนเป็นไทย
  String _thaiMonth(int month) {
    const months = [
      "",
      "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.",
      "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค.",
    ];
    return months[month];
  }
}
