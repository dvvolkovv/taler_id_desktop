import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/api/dio_client.dart';

const _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
const _model = 'gpt-4o-realtime-preview-2024-12-17';

const _instructions =
    'You are Taler ID assistant. You help users manage their digital identity. '
    'You can read and update their profile, check KYC status, and list organizations. '
    'Answer concisely in the language the user speaks. '
    'When the user mentions personal data (name, phone, country, etc.), use update_profile to save it. '
    'Always confirm what you saved after updating.';

const List<Map<String, dynamic>> _tools = [
  {
    'type': 'function',
    'name': 'get_profile',
    'description':
        'Get current user profile: name, email, phone, country, date of birth',
    'parameters': {'type': 'object', 'properties': {}},
  },
  {
    'type': 'function',
    'name': 'update_profile',
    'description':
        'Update user profile fields. Only include fields that the user explicitly mentioned.',
    'parameters': {
      'type': 'object',
      'properties': {
        'firstName': {'type': 'string', 'description': 'First name'},
        'lastName': {'type': 'string', 'description': 'Last name'},
        'phone': {
          'type': 'string',
          'description': 'Phone number in international format'
        },
        'country': {
          'type': 'string',
          'description': 'Country ISO code (e.g. AT, DE, RU)'
        },
        'dateOfBirth': {
          'type': 'string',
          'description': 'Date of birth in ISO format YYYY-MM-DD'
        },
        'language': {
          'type': 'string',
          'enum': ['en', 'ru', 'de'],
          'description': 'Preferred language'
        },
      },
    },
  },
  {
    'type': 'function',
    'name': 'get_kyc_status',
    'description':
        'Get KYC verification status: UNVERIFIED, PENDING, VERIFIED, or REJECTED',
    'parameters': {'type': 'object', 'properties': {}},
  },
  {
    'type': 'function',
    'name': 'get_organizations',
    'description':
        'List all organizations the user belongs to, with roles',
    'parameters': {'type': 'object', 'properties': {}},
  },
];

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  RTCDataChannel? _dc;

  bool _active = false;
  bool _connecting = false;
  bool _isSpeaking = false;
  String? _errorText;
  String _transcript = '';

  final List<Map<String, String>> _messages = [];

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _disconnect();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── toggle ──────────────────────────────────────────────────────────
  Future<void> _toggle() async {
    if (_active || _connecting) {
      _disconnect();
    } else {
      await _connect();
    }
  }

  // ── connect ─────────────────────────────────────────────────────────
  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _errorText = null;
      _transcript = '';
      _messages.clear();
    });

    try {
      // 1. Get ephemeral token with tools & transcription
      final dio = Dio();
      final sessionRes = await dio.post(
        'https://api.openai.com/v1/realtime/sessions',
        options: Options(headers: {
          'Authorization': 'Bearer $_openAiApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': _model,
          'voice': 'alloy',
          'instructions': _instructions,
          'tools': _tools,
          'input_audio_transcription': {'model': 'whisper-1'},
        },
      );
      final ephemeralKey =
          sessionRes.data['client_secret']?['value'] as String? ?? '';
      if (ephemeralKey.isEmpty) throw Exception('No ephemeral key');

      // 2. Create PeerConnection
      _pc = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      });

      // 3. Remote audio → play through device speaker
      _pc!.onTrack = (event) {
        // nothing extra needed – audio plays automatically
      };

      // 4. Capture microphone
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localStream!.getAudioTracks()) {
        await _pc!.addTrack(track, _localStream!);
      }

      // 5. Data channel for events
      _dc = await _pc!.createDataChannel(
        'oai-events',
        RTCDataChannelInit()..ordered = true,
      );
      _dc!.onMessage = _onDataChannelMessage;

      // 6. Create SDP offer
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);

      // 7. Send offer to OpenAI, receive answer
      final sdpRes = await dio.post(
        'https://api.openai.com/v1/realtime?model=$_model',
        options: Options(headers: {
          'Authorization': 'Bearer $ephemeralKey',
          'Content-Type': 'application/sdp',
        }),
        data: offer.sdp,
      );

      final answer = RTCSessionDescription(sdpRes.data as String, 'answer');
      await _pc!.setRemoteDescription(answer);

      WakelockPlus.enable();
      setState(() {
        _active = true;
        _connecting = false;
      });
    } catch (e) {
      debugPrint('Assistant connect error: $e');
      _disconnect();
      setState(() {
        _errorText = e.toString().length > 120
            ? '${e.toString().substring(0, 120)}…'
            : e.toString();
      });
    }
  }

  // ── data channel events ─────────────────────────────────────────────
  void _onDataChannelMessage(RTCDataChannelMessage msg) {
    try {
      final data = jsonDecode(msg.text) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      if (type == 'response.audio.delta') {
        _setSpeaking(true);
      } else if (type == 'response.audio.done' ||
          type == 'response.done') {
        _setSpeaking(false);
      } else if (type == 'response.audio_transcript.delta') {
        final delta = data['delta'] as String? ?? '';
        setState(() => _transcript += delta);
      } else if (type == 'response.audio_transcript.done') {
        final text = data['transcript'] as String? ?? _transcript;
        if (text.isNotEmpty) {
          _messages.add({'role': 'assistant', 'text': text});
        }
      } else if (type == 'input_audio_buffer.speech_started') {
        setState(() => _transcript = '');
      } else if (type ==
          'conversation.item.input_audio_transcription.completed') {
        final text = data['transcript'] as String? ?? '';
        if (text.isNotEmpty) {
          _messages.add({'role': 'user', 'text': text});
        }
      } else if (type == 'response.function_call_arguments.done') {
        final name = data['name'] as String;
        final callId = data['call_id'] as String;
        final args =
            jsonDecode(data['arguments'] as String) as Map<String, dynamic>;
        _handleFunctionCall(name, callId, args);
      }
    } catch (_) {}
  }

  // ── function calling ────────────────────────────────────────────────
  Future<void> _handleFunctionCall(
      String name, String callId, Map<String, dynamic> args) async {
    final client = sl<DioClient>();
    String output;

    try {
      switch (name) {
        case 'get_profile':
          final data = await client.get('/profile', fromJson: (d) => d);
          output = jsonEncode(data);
          break;
        case 'update_profile':
          final data =
              await client.put('/profile', data: args, fromJson: (d) => d);
          output = jsonEncode(data);
          break;
        case 'get_kyc_status':
          final data = await client.get('/kyc/status', fromJson: (d) => d);
          output = jsonEncode(data);
          break;
        case 'get_organizations':
          final data = await client.get('/tenant', fromJson: (d) => d);
          output = jsonEncode(data);
          break;
        default:
          output = jsonEncode({'error': 'Unknown function: $name'});
      }
    } catch (e) {
      output = jsonEncode({'error': e.toString()});
    }

    _dc?.send(RTCDataChannelMessage(jsonEncode({
      'type': 'conversation.item.create',
      'item': {
        'type': 'function_call_output',
        'call_id': callId,
        'output': output,
      }
    })));
    _dc?.send(
        RTCDataChannelMessage(jsonEncode({'type': 'response.create'})));
  }

  void _setSpeaking(bool val) {
    if (_isSpeaking == val) return;
    _isSpeaking = val;
    if (val) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.animateTo(0.0,
          duration: const Duration(milliseconds: 200));
    }
    if (mounted) setState(() {});
  }

  // ── disconnect ──────────────────────────────────────────────────────
  void _disconnect() {
    if (_messages.isNotEmpty) {
      _sendTranscript();
    }
    WakelockPlus.disable();
    _dc?.close();
    _dc = null;
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _pc?.close();
    _pc?.dispose();
    _pc = null;
    _setSpeaking(false);
    if (mounted) {
      setState(() {
        _active = false;
        _connecting = false;
      });
    }
  }

  Future<void> _sendTranscript() async {
    try {
      final client = sl<DioClient>();
      await client.post(
        '/assistant/transcripts',
        data: {'messages': List<Map<String, String>>.from(_messages)},
        fromJson: (d) => d,
      );
    } catch (e) {
      debugPrint('Failed to save transcript: $e');
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.tabAssistant)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsating button
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isSpeaking ? _pulseAnim.value : 1.0,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _connecting ? null : _toggle,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _active
                        ? AppColors.primary
                        : AppColors.card,
                    boxShadow: [
                      if (_active)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                    ],
                  ),
                  child: Center(
                    child: _connecting
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: AppColors.textPrimary,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            _active ? Icons.stop_rounded : Icons.mic_rounded,
                            size: 64,
                            color: _active
                                ? Colors.black
                                : AppColors.textPrimary,
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Status text
            Text(
              _connecting
                  ? l10n.assistantConnecting
                  : _active
                      ? (_isSpeaking ? l10n.assistantSpeaking : l10n.assistantListening)
                      : l10n.assistantTapToStart,
              style: TextStyle(
                color: _active ? AppColors.primary : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Transcript
            if (_transcript.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    _transcript,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],

            // Error
            if (_errorText != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
