import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../auth_session_service.dart';

class GpsTrackingService {
  static final GpsTrackingService _instance = GpsTrackingService._internal();
  factory GpsTrackingService() => _instance;
  GpsTrackingService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AuthSessionService _authService = const AuthSessionService();
  
  Timer? _pollingTimer;
  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _localNotifications.initialize(initializationSettings);
    
    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        _checkAndWarnDisabledGps();
      }
    });

    _startPolling();
    _isInitialized = true;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      try {
        final transactions = await _transactionRepo.fetchTransactions();
        
        // Cek jika ada transaksi overdue
        for (var tx in transactions) {
          if (tx.isOverdue && tx.renterId == user.uid) {
            await _sendLocationUpdate(tx.id);
          }
        }
      } catch (e) {
        debugPrint('Error polling GPS: $e');
      }
    });
  }

  Future<void> _checkAndWarnDisabledGps() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final transactions = await _transactionRepo.fetchTransactions();
      bool hasOngoing = transactions.any((tx) => 
        (tx.status.toLowerCase() == 'ongoing' || tx.isOverdue) && tx.renterId == user.uid
      );
      
      if (hasOngoing) {
        _showGpsWarningNotification();
      }
    } catch (e) {
      debugPrint('Error checking ongoing transactions: $e');
    }
  }

  Future<void> _showGpsWarningNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gps_warning_channel',
      'GPS Peringatan',
      channelDescription: 'Peringatan ketika GPS dimatikan saat sewa berjalan',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Colors.red,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _localNotifications.show(
      0,
      'Peringatan: GPS Tidak Aktif!',
      'Anda sedang dalam masa sewa. Mohon aktifkan GPS atau Anda berisiko dibanned.',
      platformChannelSpecifics,
    );
  }

  Future<void> _sendLocationUpdate(String transactionId) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // Tidak bisa kirim lokasi

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return;
        }
      } else if (permission == LocationPermission.deniedForever) {
        return;
      }

      // ignore: deprecated_member_use
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 1. Kirim ke RTDB
      final DatabaseReference ref = FirebaseDatabase.instance.ref('gps_live/$transactionId');
      await ref.set({
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'renterName': FirebaseAuth.instance.currentUser?.displayName ?? 'Penyewa',
      });

      // 2. Kirim ke Backend API
      final token = await _authService.getValidIdToken();
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/gps/log'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'transactionId': transactionId,
            'lat': position.latitude,
            'lng': position.longitude,
            'intervalMinutes': 0.5,
          }),
        );
      }
    } catch (e) {
      debugPrint('Error sending location update: $e');
    }
  }

  void stop() {
    _pollingTimer?.cancel();
    _serviceStatusStream?.cancel();
    _isInitialized = false;
  }
}
