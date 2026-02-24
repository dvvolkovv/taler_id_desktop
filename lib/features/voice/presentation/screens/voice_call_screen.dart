import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/api/dio_client.dart';

class VoiceCallScreen extends StatefulWidget {
  final String? roomName; // null = create new room with AI
  const VoiceCallScreen({super.key, this.roomName});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  lk.Room? _room;
  bool _connecting = true;
  bool _muted = false;
  bool _speakerOn = false;
  String? _error;
  bool _navigatedAway = false;
  final List<lk.RemoteParticipant> _participants = [];

  static const _audioChannel = MethodChannel('taler_id/audio');

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
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
      _room = lk.Room();

      _room!.addListener(_onRoomChanged);

      await _room!.connect(
        'wss://id.taler.tirol/livekit',
        token,
        roomOptions: const lk.RoomOptions(
          defaultAudioPublishOptions: lk.AudioPublishOptions(
            audioBitrate: 32000,
          ),
        ),
      );

      // Initial participants
      setState(() {
        _participants.addAll(_room!.remoteParticipants.values);
      });

      await _room!.localParticipant?.setMicrophoneEnabled(true);

      setState(() => _connecting = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _connecting = false;
      });
    }
  }

  void _onRoomChanged() {
    if (!mounted) return;
    final room = _room;
    if (room == null) return;

    // Sync participants list from room state
    setState(() {
      _participants
        ..clear()
        ..addAll(room.remoteParticipants.values);
    });

    // Handle disconnection
    if (room.connectionState == lk.ConnectionState.disconnected) {
      _navigateBack();
    }
  }

  void _navigateBack() {
    if (_navigatedAway || !mounted) return;
    _navigatedAway = true;
    context.pop();
  }

  Future<void> _toggleMute() async {
    final newMuted = !_muted;
    await _room?.localParticipant?.setMicrophoneEnabled(!newMuted);
    setState(() => _muted = newMuted);
  }

  Future<void> _toggleSpeaker() async {
    final on = !_speakerOn;
    try {
      await _audioChannel.invokeMethod('setSpeaker', on);
    } catch (_) {}
    setState(() => _speakerOn = on);
  }

  Future<void> _hangUp() async {
    await _room?.disconnect();
    _navigateBack();
  }

  @override
  void dispose() {
    _room?.removeListener(_onRoomChanged);
    _room?.disconnect();
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
      ),
      body: _connecting
          ? const Center(
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
            )
          : _error != null
              ? Center(
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
                )
              : Column(
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
                                      isAI ? 'AI Ассистент' : p.identity,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: Icon(
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
                            icon: _speakerOn
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            label: _speakerOn ? 'Динамик' : 'Динамик',
                            color: _speakerOn ? AppColors.primary.withValues(alpha: 0.2) : AppColors.card,
                            onTap: _toggleSpeaker,
                          ),
                        ],
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
