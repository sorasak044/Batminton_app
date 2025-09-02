import 'package:badminton_booking_app/screens/my_booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:badminton_booking_app/screens/home_main_page.dart';
import 'package:badminton_booking_app/screens/profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

Future<void> loadUserName() async {
  final prefs = await SharedPreferences.getInstance();
  final firstName = prefs.getString('firstName') ?? '';
  setState(() {
    _userName = "$firstName ".trim();
  });
}

  @override
  Widget build(BuildContext context) {
    // สร้าง pages ภายใน build() เพื่อให้ loadUserName ส่งไปใน ProfileScreen ได้
    final List<Widget> pages = [
      const HomeMainPage(),
      const MyBookingsScreen(),
      ProfileScreen(onProfileUpdated: loadUserName),
    ];

    final List<String> titles = ["สนามแบดมินตัน", "การจองของฉัน", "โปรไฟล์"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userName.isNotEmpty
              ? 'สวัสดีคุณ $_userName !'
              : titles[_currentIndex],
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'การจองของฉัน',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}
