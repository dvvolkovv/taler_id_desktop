import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../api/dio_client.dart';
import '../di/service_locator.dart';

class CallStateService {
  static final instance = CallStateService._();
  CallStateService._();

  lk.Room? room;
  String? roomName;
  String? conversationId;
  bool _bgConnecting = false;

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
    _bgConnecting = false;
    _stateCtrl.add(false);
  }

  void notifyEnded() {
    room = null;
    roomName = null;
    conversationId = null;
    _bgConnecting = false;
    _stateCtrl.add(false);
  }

  /// Connect to a LiveKit room in the background after CallKit accept.
  /// This establishes the audio connection immediately so the caller sees
  /// the callee join the room — even while CallKit's native UI is still showing.
  /// VoiceCallScreen will detect the existing room in initState and resume it.
  Future<bool> connectInBackground(String rName, String? convId) async {
    if (isInCall) return true;
    if (_bgConnecting) return false;
    _bgConnecting = true;
    try {
      final client = sl<DioClient>();
      final res = await client.post<Map<String, dynamic>>(
        '/voice/rooms/$rName/join',
        data: {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final token = res['token'] as String;
      final r = lk.Room();
      await r.connect(
        'wss://id.taler.tirol/livekit/',
        token,
        roomOptions: const lk.RoomOptions(
          defaultAudioPublishOptions: lk.AudioPublishOptions(audioBitrate: 32000),
        ),
      );
      setRoom(r, rName, convId);
      // Enable microphone — CallKit's audio session is active so this should work
      try {
        await r.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}
      debugPrint('[CallState] connectInBackground OK, room=$rName');
      _bgConnecting = false;
      return true;
    } catch (e) {
      debugPrint('[CallState] connectInBackground failed: $e');
      _bgConnecting = false;
      return false;
    }
  }
}
