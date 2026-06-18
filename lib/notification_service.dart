import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'api_config.dart';
import 'auth_session_service.dart';
import 'firebase_options.dart';
import 'transaction_detail_screen.dart';
import 'room_chat_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase may already be initialized in some app states.
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timeLabel;
  final String category;
  final String initials;
  final bool isRead;
  final bool highlight;
  final bool isPinned;
  final String? type;
  final String? transactionId;
  final String? imageUrl;
  final String? chatPartnerId;
  final String? chatPartnerName;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.category,
    required this.initials,
    required this.isRead,
    required this.highlight,
    this.isPinned = false,
    this.type,
    this.transactionId,
    this.imageUrl,
    this.chatPartnerId,
    this.chatPartnerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timeLabel': timeLabel,
      'category': category,
      'initials': initials,
      'isRead': isRead,
      'highlight': highlight,
      'isPinned': isPinned,
      'type': type,
      'transactionId': transactionId,
      'imageUrl': imageUrl,
      'chatPartnerId': chatPartnerId,
      'chatPartnerName': chatPartnerName,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timeLabel: json['timeLabel'] ?? 'Baru saja',
      category: json['category'] ?? 'Info',
      initials: json['initials'] ?? 'NA',
      isRead: json['isRead'] ?? false,
      highlight: json['highlight'] ?? true,
      isPinned: json['isPinned'] ?? false,
      type: json['type'],
      transactionId: json['transactionId'],
      imageUrl: json['imageUrl'],
      chatPartnerId: json['chatPartnerId'],
      chatPartnerName: json['chatPartnerName'],
    );
  }

  factory AppNotification.fromApi(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().trim();
    final rawBody = (json['body'] ?? '').toString().trim();
    final type = (json['type'] ?? '').toString().trim();
    final createdAt = _readTimestamp(json['createdAt']);
    final isRead = json['isRead'] == true;

    // Parse item card JSON in body if present
    final parsed = _parseItemCardBody(rawBody);
    final body = parsed['body'] as String;
    final parsedImageUrl = parsed['imageUrl'] as String?;

    // Prefer imageUrl from parsed body, then from the notification doc itself
    final rawImageUrl = (json['imageUrl'] ?? '').toString().trim();
    final imageUrl = parsedImageUrl ?? (rawImageUrl.isEmpty ? null : rawImageUrl);

    return AppNotification(
      id: (json['id'] ?? '').toString(),
      title: title.isEmpty ? 'Notifikasi baru' : title,
      message: body.isEmpty ? 'Ada pembaruan baru untuk akunmu.' : body,
      timeLabel: _formatRelativeTime(createdAt),
      category: _categoryFromType(type),
      initials: _buildInitials(title.isEmpty ? type : title),
      isRead: isRead,
      highlight: !isRead,
      type: type.isEmpty ? null : type,
      transactionId: (json['transactionId'] ?? '').toString().trim().isEmpty
          ? null
          : (json['transactionId'] ?? '').toString().trim(),
      imageUrl: imageUrl,
      chatPartnerId: (json['chatPartnerId'] ?? '').toString().trim().isEmpty
          ? null
          : (json['chatPartnerId'] ?? '').toString().trim(),
      chatPartnerName: (json['chatPartnerName'] ?? '').toString().trim().isEmpty
          ? null
          : (json['chatPartnerName'] ?? '').toString().trim(),
    );
  }

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    final title = message.notification?.title?.trim().isNotEmpty == true
        ? message.notification!.title!.trim()
        : (message.data['title'] ?? 'Notifikasi baru').toString();
    final rawBody = message.notification?.body?.trim().isNotEmpty == true
        ? message.notification!.body!.trim()
        : (message.data['body'] ?? 'Ada pembaruan baru untuk akunmu.').toString();
    final type = (message.data['type'] ?? '').toString().trim();

    // Parse item card JSON in body if present
    final parsed = _parseItemCardBody(rawBody);
    final body = parsed['body'] as String;
    final parsedImageUrl = parsed['imageUrl'] as String?;

    final rawImageUrl = (message.data['imageUrl'] ?? '').toString().trim();
    final imageUrl = parsedImageUrl ?? (rawImageUrl.isEmpty ? null : rawImageUrl);

    return AppNotification(
      id: message.messageId ?? 'foreground-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: body,
      timeLabel: 'Baru saja',
      category: _categoryFromType(type),
      initials: _buildInitials(title),
      isRead: false,
      highlight: true,
      type: type.isEmpty ? null : type,
      transactionId: (message.data['transactionId'] ?? '').toString().trim().isEmpty
          ? null
          : (message.data['transactionId'] ?? '').toString().trim(),
      imageUrl: imageUrl,
      chatPartnerId: (message.data['chatPartnerId'] ?? '').toString().trim().isEmpty
          ? null
          : (message.data['chatPartnerId'] ?? '').toString().trim(),
      chatPartnerName: (message.data['chatPartnerName'] ?? '').toString().trim().isEmpty
          ? null
          : (message.data['chatPartnerName'] ?? '').toString().trim(),
    );
  }

  static DateTime? _readTimestamp(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }
    if (value is Map<String, dynamic>) {
      final rawSeconds = value['_seconds'] ?? value['seconds'];
      if (rawSeconds is int) {
        final rawNanos = value['_nanoseconds'] ?? value['nanoseconds'];
        final nanos = rawNanos is int ? rawNanos : 0;
        return DateTime.fromMillisecondsSinceEpoch(
          (rawSeconds * 1000) + (nanos ~/ 1000000),
          isUtc: true,
        ).toLocal();
      }
    }
    return null;
  }

  static String _categoryFromType(String type) {
    switch (type.toLowerCase()) {
      case 'chat':
        return 'Pesan';
      case 'request':
        return 'Sewa';
      case 'approved':
        return 'Status';
      case 'reminder':
      case 'overdue':
        return 'Pengingat';
      case 'payment':
        return 'Pembayaran';
      case 'dispute':
        return 'Sengketa';
      default:
        return 'Info';
    }
  }

  static String _buildInitials(String seed) {
    final parts = seed
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim().substring(0, 1).toUpperCase())
        .toList();
    if (parts.isEmpty) {
      return 'NA';
    }
    return parts.join();
  }

  static String _formatRelativeTime(DateTime? timestamp) {
    if (timestamp == null) {
      return 'Baru saja';
    }

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    }
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Detects if [body] is a JSON item card string (e.g. {"id":"...","name":"...","image":"..."})
  /// and returns a map with parsed 'body' text and optional 'imageUrl'.
  static Map<String, dynamic> _parseItemCardBody(String body) {
    if (body.startsWith('{') && body.contains('"name"')) {
      try {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        final name = decoded['name']?.toString() ?? 'Barang';
        final image = decoded['image']?.toString();
        return {
          'body': '\u{1F4E6} $name',
          'imageUrl': (image != null && image.isNotEmpty) ? image : null,
        };
      } catch (_) {
        // Not valid JSON, return as-is
      }
    }
    return {'body': body, 'imageUrl': null};
  }
}

class NotificationService extends ChangeNotifier {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  FirebaseMessaging? _messaging;
  final AuthSessionService _authSessionService = const AuthSessionService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<AppNotification> _notifications = const [];
  bool _isChatAreaActive = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((item) => !item.isRead).length;
  bool get isChatAreaActive => _isChatAreaActive;

  Future<void> setChatAreaActive(bool active) async {
    if (_isChatAreaActive == active) return;
    _isChatAreaActive = active;
    _messaging ??= Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null;
    await _messaging?.setForegroundNotificationPresentationOptions(
      alert: !active,
      badge: !active,
      sound: !active,
    );
    notifyListeners();
  }

  void handleNotificationTap(AppNotification item) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint("handleNotificationTap skipped: navigatorKey context is null");
      return;
    }

    // Direct navigation for chat
    if (item.chatPartnerId != null && item.chatPartnerId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomChatScreen(
            partnerId: item.chatPartnerId!,
            partnerName: item.chatPartnerName ?? 'Pengguna',
          ),
        ),
      );
      return;
    }

    // Direct navigation for transaction detail
    if (item.transactionId != null && item.transactionId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionDetailScreen(transactionId: item.transactionId!),
        ),
      );
      return;
    }

    // Fallback for chat via title
    if (item.title.startsWith('Pesan baru dari ')) {
      final nameToQuery = item.title.replaceFirst('Pesan baru dari ', '').trim();
      if (nameToQuery.isNotEmpty) {
        _resolveChatPartnerAndNavigate(context, nameToQuery);
      }
      return;
    }
  }

  Future<void> _resolveChatPartnerAndNavigate(BuildContext context, String nameToQuery) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF012D1D),
        ),
      ),
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: nameToQuery)
          .limit(1)
          .get();

      if (!context.mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final partnerId = userDoc.id;
        final partnerAvatarUrl = userDoc.data()['profilePhotoUrl'] as String?;

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomChatScreen(
              partnerId: partnerId,
              partnerName: nameToQuery,
              partnerAvatarUrl: partnerAvatarUrl,
            ),
          ),
        );
        return;
      }
    } catch (e) {
      if (!context.mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog on error
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buka menu Chat untuk melihat pesan ini'),
        backgroundColor: Color(0xFF012D1D),
      ),
    );
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (Firebase.apps.isEmpty) {
      return;
    }

    _messaging ??= FirebaseMessaging.instance;
    final messaging = _messaging;
    if (messaging == null) {
      return;
    }

    _initialized = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payloadStr = response.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          try {
            final Map<String, dynamic> data = jsonDecode(payloadStr);
            final notification = AppNotification.fromJson(data);
            handleNotificationTap(notification);
          } catch (e) {
            debugPrint("Error handling local notification tap: $e");
          }
        }
      },
    );

    // Set default presentation options for foreground notifications
    await messaging.setForegroundNotificationPresentationOptions(
      alert: !_isChatAreaActive,
      badge: !_isChatAreaActive,
      sound: !_isChatAreaActive,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final incoming = AppNotification.fromRemoteMessage(message);
      _notifications = [
        incoming,
        ..._notifications.where((item) => item.id != incoming.id),
      ];
      notifyListeners();
      fetchNotifications(silent: true);
      
      if (!_isChatAreaActive || incoming.type != 'chat') {
        _showForegroundNotification(incoming);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      fetchNotifications(silent: true);
      final notification = AppNotification.fromRemoteMessage(message);
      handleNotificationTap(notification);
    });

    messaging.onTokenRefresh.listen((token) {
      syncFcmToken(tokenOverride: token);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      fetchNotifications(silent: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notification = AppNotification.fromRemoteMessage(initialMessage);
        handleNotificationTap(notification);
      });
    }

    // Sync FCM token on startup if already logged in
    syncFcmToken();
  }

  Future<void> syncAfterLogin() async {
    await _ensurePermissionRequested();
    await syncFcmToken();
    await fetchNotifications();
  }

  Future<void> _showForegroundNotification(AppNotification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: jsonEncode(notification.toJson()),
    );
  }

  Future<void> syncFcmToken({String? tokenOverride}) async {
    _messaging ??= Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null;
    final messaging = _messaging;
    if (messaging == null) {
      return;
    }

    final authToken = await _authSessionService.getValidIdToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    final fcmToken = tokenOverride ?? await messaging.getToken();
    if (fcmToken == null || fcmToken.trim().isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': fcmToken.trim()}),
      );
    } catch (_) {
      // Token sync can retry on next app open or token refresh.
    }
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    final authToken = await _authSessionService.getValidIdToken();
    if (authToken == null || authToken.isEmpty) {
      _notifications = const [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final rawList = (body['data'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _notifications = rawList.map(AppNotification.fromApi).toList();
        _errorMessage = null;
      } else {
        _errorMessage =
            body['error']?['message']?.toString() ?? 'Gagal memuat notifikasi.';
      }
    } catch (_) {
      _errorMessage = 'Gagal memuat notifikasi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    if (id.isEmpty) {
      return;
    }

    final authToken = await _authSessionService.getValidIdToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    final previous = _notifications;
    _notifications = previous
        .map(
          (item) => item.id == id
              ? AppNotification(
                  id: item.id,
                  title: item.title,
                  message: item.message,
                  timeLabel: item.timeLabel,
                  category: item.category,
                  initials: item.initials,
                  isRead: true,
                  highlight: false,
                  isPinned: item.isPinned,
                  type: item.type,
                  transactionId: item.transactionId,
                  imageUrl: item.imageUrl,
                  chatPartnerId: item.chatPartnerId,
                  chatPartnerName: item.chatPartnerName,
                )
              : item,
        )
        .toList();
    notifyListeners();

    try {
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
    } catch (_) {
      _notifications = previous;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final authToken = await _authSessionService.getValidIdToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    final previous = _notifications;
    _notifications = previous
        .map(
          (item) => AppNotification(
            id: item.id,
            title: item.title,
            message: item.message,
            timeLabel: item.timeLabel,
            category: item.category,
            initials: item.initials,
            isRead: true,
            highlight: false,
            isPinned: item.isPinned,
            type: item.type,
            transactionId: item.transactionId,
            imageUrl: item.imageUrl,
            chatPartnerId: item.chatPartnerId,
            chatPartnerName: item.chatPartnerName,
          ),
        )
        .toList();
    notifyListeners();

    try {
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
    } catch (_) {
      _notifications = previous;
      notifyListeners();
    }
  }

  Future<void> _ensurePermissionRequested() async {
    _messaging ??= Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null;
    final messaging = _messaging;
    if (messaging == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested =
        prefs.getBool('fcm_permission_requested') ?? false;
    if (alreadyRequested) {
      return;
    }

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {
      // Keep the app usable if permission prompt cannot be shown.
    } finally {
      await prefs.setBool('fcm_permission_requested', true);
    }
  }
}
