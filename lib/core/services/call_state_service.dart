import 'dart:async';
import 'package:livekit_client/livekit_client.dart' as lk;

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

}
