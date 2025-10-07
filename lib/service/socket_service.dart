// lib/service/socket_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '/service/local_notification_service.dart';

class SocketService with WidgetsBindingObserver {
  IO.Socket? _socket;
  String? _jwtToken;

  /// Singleton pattern
  static final SocketService instance = SocketService._internal();
  SocketService._internal();

  IO.Socket? get socket => _socket;

  /// Init service พร้อม observe lifecycle
  void init(String jwtToken) {
    _jwtToken = jwtToken;
    WidgetsBinding.instance.addObserver(this);
    connect();
  }

  /// เริ่มเชื่อมต่อ Socket.io
  void connect() {
    if (_jwtToken == null) {
      debugPrint("⚠️ No JWT token, cannot connect socket");
      return;
    }

    // ป้องกัน connect ซ้ำ
    if (_socket != null && _socket!.connected) {
      debugPrint('⚠️ Socket already connected');
      return;
    }

    const backendUrl = 'https://demoapi-production-9077.up.railway.app';

    _socket = IO.io(
      backendUrl,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': _jwtToken},
      },
    );

    _socket!.connect();

    // Connection handlers
    _socket!.onConnect((_) => debugPrint('🔌 Socket connected: ${_socket!.id}'));
    _socket!.onDisconnect((_) => debugPrint('❌ Socket disconnected'));
    _socket!.onError((err) => debugPrint('⚠️ Socket error: $err'));
    _socket!.onConnectError((err) => debugPrint('🚨 Socket connection error: $err'));

    // -------------------------
    // Event listeners
    // -------------------------

    // Booking reminder
    _socket!.on('booking-reminder', (data) async {
      debugPrint('📩 Booking Reminder: $data');
      await _showLocalNotification(
        data,
        title: 'เตือนการจองสนาม',
        body: 'คุณมีการจองสนาม ${data['courtName'] ?? ''} เริ่มเวลา ${data['startTime'] ?? ''}',
      );
    });

    // Payment approved
    _socket!.on('payment-approved', (data) async {
      debugPrint('✅ Payment Approved: $data');
      await _showLocalNotification(
        data,
        title: 'ชำระเงินอนุมัติ',
        body: 'การจองสนาม ${data['courtName'] ?? ''} เริ่มเวลา ${data['startTime'] ?? ''}',
      );
    });

    // Payment rejected
    _socket!.on('payment-reject', (data) async {
      debugPrint('❌ Payment Reject: $data');
      await _showLocalNotification(
        data,
        title: 'ชำระเงินปฏิเสธ',
        body: 'การจองสนาม ${data['courtName'] ?? ''} ถูกปฏิเสธ',
      );
    });
  }

  /// ปิดการเชื่อมต่อ socket
  void disconnect() {
    if (_socket != null) {
      debugPrint('🛑 Disconnecting socket...');
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
    }
  }

  /// Lifecycle handler
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("📱 AppLifecycle changed: $state");
    if (state == AppLifecycleState.resumed) {
      // กลับมาแอป → reconnect
      connect();
    } else if (state == AppLifecycleState.paused) {
      // พับจอ → disconnect ชั่วคราว
      disconnect();
    }
  }

  /// แสดง Local Notification
  Future<void> _showLocalNotification(
    Map data, {
    required String title,
    required String body,
  }) async {
    await LocalNotificationService.instance.showNotification(
      id: (data['bookingId'] ?? DateTime.now().millisecondsSinceEpoch).hashCode,
      title: title,
      body: body,
      payload: json.encode(data),
    );
  }
}