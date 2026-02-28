import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../messenger/data/datasources/messenger_remote_datasource.dart';
import '../../../messenger/domain/entities/user_search_entity.dart';

class VoiceCallScreen extends StatefulWidget {
  final String? roomName; // null = create new room with AI
  final String? conversationId; // for sending call_ended when hanging up
  final bool isIncoming; // opened from FCM push notification
  const VoiceCallScreen({
    super.key,
    this.roomName,
    this.conversationId,
    this.isIncoming = false,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  lk.Room? _room;
  bool _connecting = true;
  bool _muted = false;
  String _audioOutputType = 'earpiece'; // earpiece, speaker, bluetooth, headphones
  bool _reconnecting = false;
  final AudioPlayer _ringPlayer = AudioPlayer();

  static const _outputIcons = <String, IconData>{
    'earpiece': Icons.phone_in_talk_rounded,
    'speaker': Icons.volume_up_rounded,
    'bluetooth': Icons.bluetooth_audio_rounded,
    'headphones': Icons.headphones_rounded,
  };

  static const _outputLabels = <String, String>{
    'earpiece': 'Телефон',
    'speaker': 'Динамик',
    'bluetooth': 'Bluetooth',
    'headphones': 'Наушники',
  };
  String? _error;
  bool _navigatedAway = false;
  String? _roomName; // actual room name (resolved after connect)
  final List<lk.RemoteParticipant> _participants = [];
  lk.EventsListener<lk.RoomEvent>? _eventsListener;

  static const _audioChannel = MethodChannel('taler_id/audio');

  @override
  void initState() {
    super.initState();
    // Listen for audio interruptions from native (parallel call from phone/other app)
    _audioChannel.setMethodCallHandler(_onNativeAudioEvent);
    final cs = CallStateService.instance;
    // Resume existing room if already connected
    if (cs.isInCall && cs.room != null) {
      _room = cs.room;
      _roomName = cs.roomName;
      _connecting = false;
      _participants.addAll(_room!.remoteParticipants.values);
      _room!.addListener(_onRoomChanged);
      _subscribeRoomEvents();
    } else {
      _connect();
    }
  }

  Future<dynamic> _onNativeAudioEvent(MethodCall call) async {
    if (call.method == 'audioInterrupted') {
      _playInterruptionBeeps();
    }
    return null;
  }

  Future<void> _playInterruptionBeeps() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      try {
        await _ringPlayer.play(AssetSource('audio/ringback.wav'), volume: 0.7);
        await Future.delayed(const Duration(milliseconds: 180));
        await _ringPlayer.stop();
        if (i < 2) await Future.delayed(const Duration(milliseconds: 350));
      } catch (_) {}
    }
  }

  Future<void> _connect() async {
    // Play ringback tone for outgoing calls to user (not incoming, not AI assistant)
    if (!widget.isIncoming && widget.roomName != null) {
      try {
        await _ringPlayer.setReleaseMode(ReleaseMode.loop);
        await _ringPlayer.play(AssetSource('audio/ringback.wav'), volume: 0.6);
      } catch (_) {}
    }
    try {
      final client = sl<DioClient>();
      final Map<String, dynamic> res;

      if (widget.roomName == null) {
        res = await client.post(
          '/voice/rooms',
          data: {},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
      } else {
        res = await client.post(
          '/voice/rooms/${widget.roomName}/join',
          data: {},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
      }

      final token = res['token'] as String;
      _roomName = (res['roomName'] as String?) ?? widget.roomName;
      _room = lk.Room();

      _room!.addListener(_onRoomChanged);
      _subscribeRoomEvents();

      await _room!.connect(
        'wss://id.taler.tirol/livekit/',
        token,
        roomOptions: const lk.RoomOptions(
          defaultAudioPublishOptions: lk.AudioPublishOptions(
            audioBitrate: 32000,
          ),
        ),
      );

      // Register in global state so call persists across navigation
      CallStateService.instance.setRoom(
        _room!,
        _roomName!,
        widget.conversationId,
      );

      // Notify other devices: this device answered the call (dismiss CallKit on others)
      if (widget.isIncoming && widget.conversationId != null) {
        try {
          sl<MessengerRemoteDataSource>().sendCallAnswered(widget.conversationId!, _roomName!);
        } catch (_) {}
      }

      // Initial participants
      setState(() {
        _participants.addAll(_room!.remoteParticipants.values);
      });

      // Enable microphone; may fail on iOS simulator — don't treat as fatal
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {}

      // Request audio focus on Android
      try {
        await _audioChannel.invokeMethod('requestAudioFocus');
      } catch (_) {}

      // Stop ringback — room is connected (callee may already be present)
      await _ringPlayer.stop();

      setState(() => _connecting = false);
      WakelockPlus.enable();

      // Force earpiece mode — LiveKit may default to speakerphone on Android
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        await _audioChannel.invokeMethod('setAudioOutput', 'earpiece');
      } catch (_) {}
    } catch (e) {
      setState(() {
        _error = e.toString();
        _connecting = false;
      });
    }
  }

  void _subscribeRoomEvents() {
    final room = _room;
    if (room == null) return;
    _eventsListener = room.createListener();
    _eventsListener!
      ..on<lk.RoomReconnectingEvent>((_) {
        if (mounted) setState(() => _reconnecting = true);
      })
      ..on<lk.RoomReconnectedEvent>((_) {
        if (mounted) setState(() => _reconnecting = false);
      })
      ..on<lk.ParticipantConnectedEvent>((_) async {
        // Stop ringback when someone answers the call
        await _ringPlayer.stop();
      });
  }

  void _onRoomChanged() {
    if (!mounted) return;
    final room = _room;
    if (room == null) return;

    // Handle disconnection (navigate before setState)
    if (room.connectionState == lk.ConnectionState.disconnected) {
      CallStateService.instance.notifyEnded();
      _navigateBack();
      return;
    }

    // Sync participants list from room state
    if (mounted) {
      setState(() {
        _participants
          ..clear()
          ..addAll(room.remoteParticipants.values);
      });
    }
  }

  void _navigateBack() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteConstants.assistant);
    }
  }

  Future<void> _toggleMute() async {
    final newMuted = !_muted;
    await _room?.localParticipant?.setMicrophoneEnabled(!newMuted);
    setState(() => _muted = newMuted);
  }

  Future<void> _showAudioOutputPicker() async {
    List<Map<String, String>> outputs = [
      {'id': 'earpiece', 'name': 'Телефон', 'type': 'earpiece'},
      {'id': 'speaker', 'name': 'Динамик', 'type': 'speaker'},
    ];
    try {
      final raw = await _audioChannel.invokeMethod<List>('getAudioOutputs');
      if (raw != null) {
        outputs = raw.map((e) => Map<String, String>.from(e as Map)).toList();
      }
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Аудиовыход',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...outputs.map((o) {
              final type = o['type'] ?? o['id'] ?? '';
              final name = o['name'] ?? type;
              final icon = _outputIcons[type] ?? Icons.volume_up_rounded;
              final isSelected = _audioOutputType == type;
              return ListTile(
                leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                title: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _setAudioOutput(type);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _setAudioOutput(String type) async {
    try {
      await _audioChannel.invokeMethod('setAudioOutput', type);
      setState(() => _audioOutputType = type);
    } catch (_) {}
  }

  Future<void> _hangUp() async {
    // Notify the other party that the call ended
    final convId = widget.conversationId ?? CallStateService.instance.conversationId;
    final rName = _roomName ?? CallStateService.instance.roomName;
    if (convId != null && rName != null) {
      try {
        sl<MessengerRemoteDataSource>().sendCallEnded(convId, rName);
      } catch (_) {}
    }
    // Release audio focus on Android
    try {
      await _audioChannel.invokeMethod('abandonAudioFocus');
    } catch (_) {}
    CallStateService.instance.endCall();
    _navigateBack();
  }

  Future<void> _addParticipant() async {
    final convId = widget.conversationId ?? CallStateService.instance.conversationId;
    final rName = _roomName ?? CallStateService.instance.roomName;
    if (rName == null) return;

    // Show user search bottom sheet
    final selected = await showModalBottomSheet<UserSearchEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UserSearchSheet(),
    );
    if (selected == null || !mounted) return;

    try {
      final client = sl<DioClient>();
      // Join the room (this creates a new token for the invitee)
      await client.post(
        '/voice/rooms/$rName/join',
        data: {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      // Send call invite to selected user via messenger
      if (convId != null) {
        sl<MessengerRemoteDataSource>().sendCallInvite(convId, rName, inviteeId: selected.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Приглашение отправлено ${selected.username != null ? "@${selected.username}" : selected.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioChannel.setMethodCallHandler(null);
    WakelockPlus.disable();
    _eventsListener?.dispose();
    _room?.removeListener(_onRoomChanged);
    _ringPlayer.dispose();
    // Do NOT disconnect room — call continues in background via CallStateService
    super.dispose();
  }

  bool _participantHasMic(lk.RemoteParticipant p) {
    return p.audioTrackPublications.isNotEmpty &&
        p.audioTrackPublications
            .any((pub) => pub.muted == false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Голосовой звонок'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _hangUp,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: _addParticipant,
            tooltip: 'Добавить участника',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_reconnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Переподключение...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_connecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Подключение...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ошибка подключения',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _hangUp,
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        // Status
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.card,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Звонок активен',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Participants list
        Expanded(
          child: _participants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ожидание участников...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _participants.length,
                  itemBuilder: (_, i) {
                    final p = _participants[i];
                    final isAI = p.identity == 'ai-assistant';
                    final hasMic = _participantHasMic(p);
                    final displayName = isAI
                        ? 'AI Ассистент'
                        : (p.name?.isNotEmpty == true ? p.name! : p.identity);
                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAI
                              ? AppColors.primary
                              : AppColors.surface,
                          child: Icon(
                            isAI
                                ? Icons.smart_toy_rounded
                                : Icons.person_rounded,
                            color: isAI
                                ? Colors.black
                                : AppColors.textPrimary,
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: isAI
                            ? const Icon(
                                Icons.graphic_eq_rounded,
                                color: AppColors.primary,
                              )
                            : Icon(
                                hasMic
                                    ? Icons.mic_rounded
                                    : Icons.mic_off_rounded,
                                color: hasMic
                                    ? Colors.green
                                    : AppColors.textSecondary,
                              ),
                      ),
                    );
                  },
                ),
        ),
        // Self participant indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: AppColors.card,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.black,
                ),
              ),
              title: const Text(
                'Вы',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                _muted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                color: _muted ? AppColors.error : Colors.green,
              ),
            ),
          ),
        ),
        // Controls
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlButton(
                icon: _muted
                    ? Icons.mic_off_rounded
                    : Icons.mic_rounded,
                label: _muted ? 'Включить' : 'Выкл. микр.',
                color: _muted ? AppColors.error : AppColors.card,
                onTap: _toggleMute,
              ),
              _ControlButton(
                icon: Icons.call_end_rounded,
                label: 'Завершить',
                color: AppColors.error,
                onTap: _hangUp,
                large: true,
              ),
              _ControlButton(
                icon: _outputIcons[_audioOutputType] ?? Icons.volume_up_rounded,
                label: _outputLabels[_audioOutputType] ?? 'Аудио',
                color: _audioOutputType != 'earpiece'
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.card,
                onTap: _showAudioOutputPicker,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserSearchSheet extends StatefulWidget {
  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final _ctrl = TextEditingController();
  List<UserSearchEntity> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await sl<MessengerRemoteDataSource>().searchUsers(q.trim());
      if (mounted) setState(() => _results = results);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Добавить участника',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Поиск по никнейму...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: _search,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final u = _results[i];
                      final name = [u.firstName, u.lastName].where((s) => s != null && s.isNotEmpty).join(' ');
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.surface,
                          child: Icon(Icons.person_rounded, color: AppColors.textPrimary),
                        ),
                        title: Text(name.isNotEmpty ? name : u.email, style: const TextStyle(color: AppColors.textPrimary)),
                        subtitle: u.username != null ? Text('@${u.username}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)) : null,
                        onTap: () => Navigator.pop(context, u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: large ? 72 : 56,
            height: large ? 72 : 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: large ? 32 : 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
