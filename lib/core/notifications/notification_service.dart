import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/dio_client.dart';
import '../di/service_locator.dart';

// Background message handler (top-level function required by FCM)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static String? _currentToken;

  static Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get token
    _currentToken = await _fcm.getToken();
    if (_currentToken != null) {
      await _saveTokenToBackend(_currentToken!);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await _saveTokenToBackend(token);
    });
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      final client = sl<DioClient>();
      await client.put('/profile', data: {'fcmToken': token});
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Set up foreground notification tap handlers
  /// Call this after GoRouter is initialized
  static void setupForegroundHandlers({required Function(RemoteMessage) onTap}) {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      // In production: show local notification using flutter_local_notifications
    });

    // App opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen(onTap);
  }

  /// Check if app was opened from a notification (terminated state)
  static Future<RemoteMessage?> getInitialMessage() =>
      _fcm.getInitialMessage();

  static String? get token => _currentToken;
}

/// Map notification data to deep link route
String? notificationToRoute(RemoteMessage message) {
  final data = message.data;
  final type = data['type'] as String?;

  switch (type) {
    case 'kyc_status':
      return '/dashboard/kyc';
    case 'kyb_status':
      return '/dashboard/organization';
    case 'new_session':
      return '/dashboard/sessions';
    case 'invite':
      final token = data['token'] as String?;
      return token != null ? '/invite?token=$token' : null;
    default:
      return null;
  }
}
