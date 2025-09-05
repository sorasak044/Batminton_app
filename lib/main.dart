import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

// import service ที่เราสร้าง
import 'service/user_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ต้องเรียกก่อน await
  await initializeDateFormatting('th_TH', null); // โหลด locale ภาษาไทย

  // 🔔 init socket สำหรับ user
  final notificationService = UserNotificationService();
  await notificationService.initSocket();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.promptTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
