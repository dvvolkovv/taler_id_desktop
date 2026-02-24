import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:dio/dio.dart';
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
  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  MediaStream? _localStream;
  bool _muted = false;
  bool _speakerOn = false;
  bool _aiSpeaking = false;
  String? _errorMessage;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _audioChannel = MethodChannel('taler_id/audio');

  // Function call buffering
  String? _pendingCallId;
  String? _pendingCallName;
  final StringBuffer _pendingArgs = StringBuffer();

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
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    _dc?.close();
    _dc = null;
    await _localStream?.dispose();
    _localStream = null;
    await _pc?.close();
    _pc = null;
  }

  Future<void> _connect() async {
    setState(() {
      _state = _CallState.connecting;
      _errorMessage = null;
    });
    try {
      // 1. Get ephemeral token from backend (API key stays on server)
      final client = sl<DioClient>();
      final res = await client.post(
        '/voice/session',
        data: {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final sessionToken = res['clientSecret'] as String;

      // 2. Create WebRTC peer connection
      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      });

      // 3. Capture microphone
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      for (final track in _localStream!.getAudioTracks()) {
        _pc!.addTrack(track, _localStream!);
      }

      // 4. Create data channel for OpenAI events
      _dc = await _pc!.createDataChannel(
        'oai-events',
        RTCDataChannelInit()..ordered = true,
      );
      _dc!.onMessage = _onDataChannelMessage;
      _dc!.onDataChannelState = (state) {
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          _onDataChannelOpen();
        }
      };

      // Detect AI speaking via remote audio track
      _pc!.onTrack = (event) {
        if (event.track.kind == 'audio') {
          event.track.onEnded = () {
            if (mounted) setState(() => _aiSpeaking = false);
          };
        }
      };

      // 5. Create SDP offer
      final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
      await _pc!.setLocalDescription(offer);

      // 6. Exchange SDP with OpenAI (direct WebRTC)
      final dio = Dio();
      final sdpResponse = await dio.post(
        'https://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17',
        data: offer.sdp,
        options: Options(
          headers: {
            'Authorization': 'Bearer $sessionToken',
            'Content-Type': 'application/sdp',
          },
          responseType: ResponseType.plain,
        ),
      );

      final answer = RTCSessionDescription(
        sdpResponse.data as String,
        'answer',
      );
      await _pc!.setRemoteDescription(answer);

      await _setSpeaker(true);
      setState(() => _state = _CallState.connected);
    } catch (e) {
      await _cleanup();
      setState(() {
        _state = _CallState.error;
        _errorMessage = e.toString();
      });
    }
  }

  void _onDataChannelOpen() {
    _sendEvent({
      'type': 'session.update',
      'session': {
        'tools': [
          {
            'type': 'function',
            'name': 'get_profile',
            'description':
                'Get current user profile: firstName, lastName, email, username, phone',
            'parameters': {'type': 'object', 'properties': {}},
          },
          {
            'type': 'function',
            'name': 'update_profile',
            'description': 'Update user profile fields (firstName, lastName, phone)',
            'parameters': {
              'type': 'object',
              'properties': {
                'firstName': {'type': 'string'},
                'lastName': {'type': 'string'},
                'phone': {'type': 'string'},
              },
            },
          },
        ],
        'tool_choice': 'auto',
      },
    });
  }

  void _sendEvent(Map<String, dynamic> event) {
    final msg = RTCDataChannelMessage(jsonEncode(event));
    _dc?.send(msg);
  }

  void _onDataChannelMessage(RTCDataChannelMessage msg) {
    try {
      final event = jsonDecode(msg.text) as Map<String, dynamic>;
      final type = event['type'] as String? ?? '';

      if (type == 'response.audio.delta') {
        if (!_aiSpeaking && mounted) setState(() => _aiSpeaking = true);
      } else if (type == 'response.audio.done' || type == 'response.done') {
        if (_aiSpeaking && mounted) setState(() => _aiSpeaking = false);
      } else if (type == 'response.function_call_arguments.delta') {
        _pendingCallId ??= event['call_id'] as String?;
        _pendingCallName ??= event['name'] as String?;
        _pendingArgs.write(event['delta'] as String? ?? '');
      } else if (type == 'response.function_call_arguments.done') {
        final callId = event['call_id'] as String? ?? _pendingCallId ?? '';
        final name = event['name'] as String? ?? _pendingCallName ?? '';
        final args = event['arguments'] as String? ?? _pendingArgs.toString();
        _pendingCallId = null;
        _pendingCallName = null;
        _pendingArgs.clear();
        _handleFunctionCall(callId, name, args);
      }
    } catch (_) {}
  }

  Future<void> _handleFunctionCall(
      String callId, String name, String argsJson) async {
    final client = sl<DioClient>();
    String output;
    try {
      if (name == 'get_profile') {
        final data =
            await client.get('/profile', fromJson: (d) => d);
        output = jsonEncode(data);
      } else if (name == 'update_profile') {
        final args = jsonDecode(argsJson) as Map<String, dynamic>;
        final data = await client.patch(
          '/profile',
          data: args,
          fromJson: (d) => d,
        );
        output = jsonEncode(data);
      } else {
        output = jsonEncode({'error': 'unknown function $name'});
      }
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }
    _sendEvent({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': output,
      },
    });
    _sendEvent({'type': 'response.create'});
  }

  Future<void> _toggleMute() async {
    final tracks = _localStream?.getAudioTracks() ?? [];
    for (final track in tracks) {
      track.enabled = _muted;
    }
    setState(() => _muted = !_muted);
  }

  Future<void> _setSpeaker(bool on) async {
    try {
      await _audioChannel.invokeMethod('setSpeaker', on);
    } catch (_) {}
    setState(() => _speakerOn = on);
  }

  Future<void> _toggleSpeaker() => _setSpeaker(!_speakerOn);

  Future<void> _endCall() async {
    await _cleanup();
    await _setSpeaker(false);
    if (mounted) {
      setState(() {
        _state = _CallState.idle;
        _muted = false;
        _aiSpeaking = false;
      });
    }
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
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            final scale =
                speaking ? 1.0 + (_pulseAnim.value - 1.0) * 0.8 : 1.0;
            return Transform.scale(scale: scale, child: child);
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallButton(
                icon: _speakerOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: _speakerOn ? 'Динамик вкл' : 'Динамик',
                color: _speakerOn
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.card,
                iconColor:
                    _speakerOn ? AppColors.primary : AppColors.textSecondary,
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
                color: _muted
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.card,
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
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
