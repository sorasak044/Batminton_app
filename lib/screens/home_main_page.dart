import 'package:flutter/material.dart';
import 'booking_screen.dart';

class HomeMainPage extends StatelessWidget {
  const HomeMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingScreen()),
            );
          },
          child: Center(
            child: Image.asset(
              'assets/images/booking.jpg',
              width: MediaQuery.of(context).size.width * 0.9,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
