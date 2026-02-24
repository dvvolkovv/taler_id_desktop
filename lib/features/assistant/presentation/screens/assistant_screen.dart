import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/dio_client.dart';

enum _CallState { idle, connecting, connected, error }

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with SingleTickerProviderStateMixin {
  _CallState _state = _CallState.idle;
  lk.Room? _room;
  bool _muted = false;
  bool _speakerOn = false;
  String? _errorMessage;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _audioChannel = MethodChannel('taler_id/audio');

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _room?.removeListener(_onRoomChanged);
    _room?.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _state = _CallState.connecting;
      _errorMessage = null;
    });
    try {
      final client = sl<DioClient>();
      final res = await client.post(
        '/voice/rooms',
        data: {'withAi': true},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final token = res['token'] as String;
      _room = lk.Room();
      _room!.addListener(_onRoomChanged);
      await _room!.connect(
        'wss://livekit.taler.tirol',
        token,
        roomOptions: const lk.RoomOptions(
          defaultAudioPublishOptions: lk.AudioPublishOptions(audioBitrate: 32000),
        ),
      );
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      // Enable speaker by default for assistant
      await _setSpeaker(true);
      setState(() => _state = _CallState.connected);
    } catch (e) {
      setState(() {
        _state = _CallState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _onRoomChanged() {
    if (!mounted) return;
    if (_room?.connectionState == lk.ConnectionState.disconnected) {
      _endCall();
    } else {
      setState(() {});
    }
  }

  Future<void> _toggleMute() async {
    final newMuted = !_muted;
    await _room?.localParticipant?.setMicrophoneEnabled(!newMuted);
    setState(() => _muted = newMuted);
  }

  Future<void> _setSpeaker(bool on) async {
    try {
      await _audioChannel.invokeMethod('setSpeaker', on);
      setState(() => _speakerOn = on);
    } catch (_) {
      setState(() => _speakerOn = on);
    }
  }

  Future<void> _toggleSpeaker() => _setSpeaker(!_speakerOn);

  Future<void> _endCall() async {
    _room?.removeListener(_onRoomChanged);
    await _room?.disconnect();
    _room = null;
    await _setSpeaker(false);
    if (mounted) {
      setState(() {
        _state = _CallState.idle;
        _muted = false;
      });
    }
  }

  bool get _aiSpeaking {
    final room = _room;
    if (room == null) return false;
    return room.remoteParticipants.values.any((p) =>
        p.identity == 'ai-assistant' &&
        p.audioTrackPublications.any((t) => !t.muted));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.tabAssistant)),
      body: switch (_state) {
        _CallState.idle => _buildIdle(),
        _CallState.connecting => _buildConnecting(),
        _CallState.connected => _buildConnected(),
        _CallState.error => _buildError(),
      },
    );
  }

  Widget _buildIdle() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _connect,
            child: ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic_rounded,
                    size: 64, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Нажмите для разговора с AI',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ассистент отвечает голосом в реальном времени',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildConnecting() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24),
          Text('Подключение к ассистенту...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildConnected() {
    final speaking = _aiSpeaking;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // AI Avatar with speaking animation
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            final scale = speaking
                ? 1.0 + (_pulseAnim.value - 1.0) * 0.8
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(
                color: speaking ? AppColors.primary : AppColors.border,
                width: speaking ? 2 : 1,
              ),
              boxShadow: speaking
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      )
                    ]
                  : null,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                size: 52, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          speaking ? 'AI говорит...' : 'AI слушает',
          style: TextStyle(
            color: speaking ? AppColors.primary : AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        // Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallButton(
                icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                label: _speakerOn ? 'Динамик вкл' : 'Динамик',
                color: _speakerOn ? AppColors.primary.withValues(alpha: 0.2) : AppColors.card,
                iconColor: _speakerOn ? AppColors.primary : AppColors.textSecondary,
                onTap: _toggleSpeaker,
              ),
              _CallButton(
                icon: Icons.call_end_rounded,
                label: 'Завершить',
                color: AppColors.error,
                iconColor: Colors.white,
                onTap: _endCall,
                size: 72,
              ),
              _CallButton(
                icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: _muted ? 'Включить' : 'Микрофон',
                color: _muted ? AppColors.error.withValues(alpha: 0.2) : AppColors.card,
                iconColor: _muted ? AppColors.error : AppColors.textSecondary,
                onTap: _toggleMute,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Ошибка подключения',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: size * 0.45),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
