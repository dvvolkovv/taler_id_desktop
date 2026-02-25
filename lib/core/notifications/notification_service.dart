import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import '../api/dio_client.dart';
import '../di/service_locator.dart';
import '../../firebase_options.dart';

bool get _isIosSimulator =>
    !kIsWeb &&
    Platform.isIOS &&
    (Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
        Platform.environment['SIMULATOR_UDID'] != null);

/// Extract UUID part from roomName like "call-550e8400-e29b-41d4-a716-446655440000"
/// CallKit requires a valid RFC4122 UUID string as id.
String _toCallkitId(String roomName) {
  // If roomName already looks like a UUID, use it directly
  final uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  if (uuidRegex.hasMatch(roomName)) return roomName;
  // Strip prefix "call-" and take remaining UUID part
  final stripped = roomName.replaceFirst(RegExp(r'^call-'), '');
  if (uuidRegex.hasMatch(stripped)) return stripped;
  // Fallback: derive UUID from hash (must be a valid UUID)
  final hash = roomName.hashCode.abs();
  return '00000000-0000-4000-8000-${hash.toRadixString(16).padLeft(12, '0').substring(0, 12)}';
}

/// Shows native OS-level incoming call screen (Android full-screen / iOS CallKit).
/// Skipped on iOS Simulator where CallKit is not supported.
Future<void> showCallkitIncoming({
  required String roomName,
  required String fromName,
  required String convId,
}) async {
  if (_isIosSimulator) return;
  await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
    id: _toCallkitId(roomName),
    nameCaller: fromName,
    appName: 'Taler ID',
    type: 0,
    textAccept: 'Принять',
    textDecline: 'Отклонить',
    duration: 30000,
    extra: <String, dynamic>{'roomName': roomName, 'conversationId': convId},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0A0A0A',
      actionColor: '#FFD700',
      textColor: '#FFFFFF',
      incomingCallNotificationChannelName: 'Входящий звонок',
      missedCallNotificationChannelName: 'Пропущенный звонок',
      isShowCallID: false,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      supportsVideo: false,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: false,
      supportsHolding: false,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  ));
}

// Background message handler (top-level function required by FCM)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['type'] == 'call_invite') {
    await showCallkitIncoming(
      roomName: message.data['roomName'] ?? '',
      fromName: message.data['fromName'] ?? 'Входящий звонок',
      convId: message.data['conversationId'] ?? '',
    );
  }
}

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static String? _currentToken;

  // Pending voice call route to handle CallKit accept across all app states
  static String? _pendingCallRoute;
  static void setPendingCallRoute(String route) => _pendingCallRoute = route;
  static String? consumePendingCallRoute() {
    final route = _pendingCallRoute;
    _pendingCallRoute = null;
    return route;
  }

  static Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
    // Foreground FCM messages — show callkit for incoming calls
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'call_invite') {
        showCallkitIncoming(
          roomName: message.data['roomName'] ?? '',
          fromName: message.data['fromName'] ?? 'Входящий звонок',
          convId: message.data['conversationId'] ?? '',
        );
      }
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
    case 'call_invite':
      final roomName = data['roomName'] as String?;
      final convId = data['conversationId'] as String?;
      if (roomName != null && convId != null) {
        return '/dashboard/voice?room=$roomName&convId=$convId&incoming=1';
      }
      return null;
    default:
      return null;
  }
}
