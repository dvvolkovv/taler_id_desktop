import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../api/dio_client.dart';
import '../di/service_locator.dart';
import '../../features/messenger/data/datasources/messenger_remote_datasource.dart';

class CallStateService {
  static final instance = CallStateService._();
  CallStateService._();

  lk.Room? room;
  String? roomName;
  String? conversationId;

  final _stateCtrl = StreamController<bool>.broadcast();
  Stream<bool> get stateStream => _stateCtrl.stream;

  bool get isInCall =>
      room != null &&
      room!.connectionState != lk.ConnectionState.disconnected;

  void setRoom(lk.Room r, String name, String? convId) {
    room = r;
    roomName = name;
    conversationId = convId;
    _stateCtrl.add(true);
  }

  void endCall() {
    room?.disconnect();
    room = null;
    roomName = null;
    conversationId = null;
    _stateCtrl.add(false);
  }

  void notifyEnded() {
    room = null;
    roomName = null;
    conversationId = null;
    _stateCtrl.add(false);
  }

  /// Connect to LiveKit in background (e.g. when accepting a call from lock screen).
  /// Safe to call from multiple listeners — guards against double-connect via [isInCall].
  static Future<void> connectInBackground(String roomName, String? convId) async {
    if (instance.isInCall) return;
    try {
      final client = sl<DioClient>();
      final res = await client.post<Map<String, dynamic>>(
        '/voice/rooms/$roomName/join',
        data: {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );

      final token = res['token'] as String;
      final resolvedRoom = (res['roomName'] as String?) ?? roomName;

      final room = lk.Room();
      await room.connect(
        'wss://id.taler.tirol/livekit/',
        token,
        roomOptions: const lk.RoomOptions(
          defaultAudioPublishOptions: lk.AudioPublishOptions(
            audioBitrate: 32000,
          ),
        ),
      );

      instance.setRoom(room, resolvedRoom, convId);

      // Notify other devices that this device answered
      if (convId != null && convId.isNotEmpty) {
        try {
          sl<MessengerRemoteDataSource>().sendCallAnswered(convId, resolvedRoom);
        } catch (_) {}
      }

      // Enable microphone
      try {
        await room.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}

      debugPrint('[CallStateService] Background connect OK: $resolvedRoom');
    } catch (e) {
      debugPrint('[CallStateService] Background connect failed: $e');
    }
  }
}
