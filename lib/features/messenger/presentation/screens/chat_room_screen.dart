import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/services/call_state_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../data/datasources/messenger_remote_datasource.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  const ChatRoomScreen({super.key, required this.conversationId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final TextEditingController _ctrl;
  late final ScrollController _scrollCtrl;
  final _recorder = AudioRecorder();
  final _speech = SpeechToText();
  bool _speechInitialized = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _recordingPath;
  double _prevKeyboardHeight = 0;
  MessageEntity? _replyTo;
  String? _replyToSenderName;
  MessageEntity? _editingMessage;
  bool _socketDisconnected = false;
  StreamSubscription? _disconnectSub;
  StreamSubscription? _reconnectSub;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _scrollCtrl = ScrollController();
    context.read<MessengerBloc>().add(OpenConversation(widget.conversationId));
    // Mark messages as read when opening conversation
    context.read<MessengerBloc>().add(MarkConversationRead(widget.conversationId));
    // Listen for socket connectivity changes
    final ds = sl<MessengerRemoteDataSource>();
    _disconnectSub = ds.disconnectStream.listen((_) {
      if (mounted) setState(() => _socketDisconnected = true);
    });
    _reconnectSub = ds.reconnectStream.listen((_) {
      if (mounted) setState(() => _socketDisconnected = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kh = MediaQuery.of(context).viewInsets.bottom;
    if (kh > _prevKeyboardHeight) {
      // With reverse:true, bottom of chat is offset 0
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollCtrl.hasClients && _scrollCtrl.offset > 0) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    _prevKeyboardHeight = kh;
  }

  void _setReply(MessageEntity msg, String? senderName) {
    setState(() {
      _replyTo = msg;
      _replyToSenderName = senderName;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
      _replyToSenderName = null;
    });
  }

  void _startEditing(MessageEntity message) {
    setState(() {
      _editingMessage = message;
      _replyTo = null;
      _replyToSenderName = null;
    });
    _ctrl.text = message.content;
    _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
  }

  void _cancelEditing() {
    setState(() => _editingMessage = null);
    _ctrl.clear();
  }

  void _handleMenuAction(String action, bool isMuted) {
    if (action == 'mute') {
      if (isMuted) {
        context.read<MessengerBloc>().add(UnmuteConversation(widget.conversationId));
      } else {
        _showMuteDurationSheet();
      }
    }
  }

  void _showMuteDurationSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.muteNotifications,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary)),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor1Hour, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 60));
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor8Hours, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 480));
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteFor2Days, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId, durationMinutes: 2880));
              },
            ),
            ListTile(
              leading: Icon(Icons.volume_off, color: AppColors.of(context).textPrimary),
              title: Text(l10n.muteForever, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<MessengerBloc>().add(
                    MuteConversation(conversationId: widget.conversationId));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _joinActiveCall(String roomName) async {
    if (CallStateService.instance.isInCall) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Уже идёт звонок'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }
    if (mounted) context.push('/dashboard/voice?room=$roomName&convId=${widget.conversationId}');
  }

  Future<void> _startCall() async {
    // Guard: only one call at a time
    if (CallStateService.instance.isInCall) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Уже идёт звонок'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
      return;
    }

    // Show bottom sheet to choose call type
    final withAi = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CallOptionsSheet(),
    );
    if (withAi == null || !mounted) return;

    try {
      final client = sl<DioClient>();
      final res = await client.post(
        '/voice/rooms',
        data: {'withAi': withAi, 'conversationId': widget.conversationId},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      // Generate E2EE key for human-to-human calls (not AI)
      final String? e2eeKey = withAi ? null : base64Url.encode(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)),
      );
      sl<MessengerRemoteDataSource>()
          .sendCallInvite(widget.conversationId, roomName, e2eeKey: e2eeKey);
      final _conv = context.read<MessengerBloc>().state.conversations
          .where((c) => c.id == widget.conversationId)
          .firstOrNull;
      final calleeName = _conv?.type == 'GROUP' ? _conv?.name : _conv?.otherUserName;
      final calleeParam = calleeName != null && calleeName.isNotEmpty
          ? '&callee=${Uri.encodeComponent(calleeName)}'
          : '';
      final e2eeParam = e2eeKey != null ? '&e2ee=${Uri.encodeComponent(e2eeKey)}' : '';
      if (mounted) context.push('/dashboard/voice?room=$roomName&convId=${widget.conversationId}$calleeParam$e2eeParam');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка звонка: $e'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _sendFile() async {
    // Allow any file type
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null || !mounted) return;
    final file = result.files.single;

    // Optional caption
    final captionCtrl = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text('Подпись к файлу', style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: TextField(
          controller: captionCtrl,
          style: TextStyle(color: AppColors.of(context).textPrimary),
          decoration: InputDecoration(
            hintText: 'Необязательно...',
            hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Без подписи'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, captionCtrl.text.trim()),
            child: Text('Отправить', style: TextStyle(color: AppColors.of(context).primary)),
          ),
        ],
      ),
    );
    captionCtrl.dispose();
    if (caption == null || !mounted) return;

    try {
      final client = sl<DioClient>();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path!, filename: file.name),
      });
      final res = await client.post(
        '/messenger/files',
        data: formData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (!mounted) return;
      String msgContent = caption.isNotEmpty ? caption : file.name;
      if (_replyTo != null) {
        final quoted = _replyTo!.fileUrl != null
            ? (_replyTo!.fileName ?? '📎 Файл')
            : _replyTo!.content;
        final q = quoted.length > 60 ? '${quoted.substring(0, 60)}...' : quoted;
        final who = _replyToSenderName != null ? '$_replyToSenderName: ' : '';
        msgContent = '↩ $who«$q»\n$msgContent';
      }
      context.read<MessengerBloc>().add(SendMessage(
        widget.conversationId,
        msgContent,
        fileUrl: res['fileUrl'] as String,
        fileName: res['fileName'] as String,
        fileSize: res['fileSize'] as int?,
        fileType: res['fileType'] as String,
      ));
      _cancelReply();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки файла: $e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (_editingMessage != null) {
      final msg = _editingMessage!;
      context.read<MessengerBloc>().add(EditMessage(
        conversationId: msg.conversationId,
        messageId: msg.id,
        newContent: text,
      ));
      _ctrl.clear();
      _cancelEditing();
      return;
    }
    String content = text;
    if (_replyTo != null) {
      final quoted = _replyTo!.fileUrl != null
          ? (_replyTo!.fileName ?? '📎 Файл')
          : _replyTo!.content;
      final q = quoted.length > 60 ? '${quoted.substring(0, 60)}...' : quoted;
      final who = _replyToSenderName != null ? '$_replyToSenderName: ' : '';
      content = '↩ $who«$q»\n$text';
    }
    context.read<MessengerBloc>().add(SendMessage(widget.conversationId, content));
    _ctrl.clear();
    _cancelReply();
    // With reverse:true, new messages appear at offset 0
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients && _scrollCtrl.offset > 0) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission || !mounted) return;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() { _isRecording = true; _recordingPath = path; });
  }

  Future<void> _stopRecordingAndSend() async {
    final path = await _recorder.stop();
    setState(() { _isRecording = false; });
    if (path == null || !mounted) return;
    try {
      final client = sl<DioClient>();
      final file = File(path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'voice.m4a'),
      });
      final res = await client.post(
        '/messenger/files',
        data: formData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (!mounted) return;
      context.read<MessengerBloc>().add(SendMessage(
        widget.conversationId,
        '🎤 Голосовое сообщение',
        fileUrl: res['fileUrl'] as String,
        fileName: res['fileName'] as String,
        fileSize: res['fileSize'] as int?,
        fileType: 'audio',
      ));
      file.deleteSync();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  Future<void> _startTranscription() async {
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize();
    }
    if (!_speechInitialized || !mounted) return;
    setState(() => _isTranscribing = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          final words = result.recognizedWords;
          final current = _ctrl.text;
          final newText = current.isEmpty ? words : '$current $words';
          _ctrl.text = newText;
          _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
        }
      },
    );
  }

  Future<void> _stopAndTranscribe() async {
    await _speech.stop();
    if (mounted) setState(() => _isTranscribing = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _speech.cancel();
    _disconnectSub?.cancel();
    _reconnectSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: BlocBuilder<MessengerBloc, MessengerState>(
          buildWhen: (prev, curr) => prev.conversations != curr.conversations,
          builder: (context, state) {
            final conv = state.conversations
                .where((c) => c.id == widget.conversationId)
                .firstOrNull;
            final isGroup = conv?.type == 'GROUP';
            final name = isGroup ? (conv?.name ?? 'Группа') : conv?.otherUserName;
            final avatarUrl = isGroup ? conv?.avatarUrl : conv?.otherUserAvatar;
            final otherUserId = conv?.otherUserId;
            return GestureDetector(
              onTap: isGroup
                  ? () => context.push('/dashboard/messenger/${widget.conversationId}/settings')
                  : otherUserId != null
                      ? () => context.push('/dashboard/user/$otherUserId')
                      : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.of(context).primary.withValues(alpha: isGroup ? 0.4 : 0.2),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              width: 36, height: 36, fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => isGroup
                                  ? Icon(Icons.group_rounded, color: AppColors.of(context).primary, size: 18)
                                  : Text(
                                      name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: TextStyle(color: AppColors.of(context).primary, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          )
                        : isGroup
                            ? Icon(Icons.group_rounded, color: AppColors.of(context).primary, size: 18)
                            : Text(
                                name != null && name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(color: AppColors.of(context).primary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name != null && name.isNotEmpty ? name : 'Диалог',
                            overflow: TextOverflow.ellipsis),
                        if (isGroup && conv != null)
                          Text(
                            AppLocalizations.of(context)!.participantsCount(conv.participantCount),
                            style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, fontWeight: FontWeight.normal),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: _startCall,
            tooltip: 'Позвонить',
          ),
          BlocBuilder<MessengerBloc, MessengerState>(
            buildWhen: (prev, curr) => prev.conversations != curr.conversations,
            builder: (context, state) {
              final conv = state.conversations
                  .where((c) => c.id == widget.conversationId)
                  .firstOrNull;
              final isMuted = conv?.isMuted ?? false;
              return PopupMenuButton<String>(
                icon: Icon(
                  isMuted ? Icons.volume_off : Icons.more_vert,
                  color: isMuted ? AppColors.of(context).textSecondary : null,
                ),
                onSelected: (value) => _handleMenuAction(value, isMuted),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'mute',
                    child: Row(
                      children: [
                        Icon(
                          isMuted ? Icons.volume_up : Icons.volume_off,
                          size: 20,
                          color: AppColors.of(context).textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(isMuted
                            ? AppLocalizations.of(context)!.unmuteNotifications
                            : AppLocalizations.of(context)!.muteNotifications),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<MessengerBloc, MessengerState>(
        listenWhen: (prev, curr) {
          final prevCount = prev.messages[widget.conversationId]?.length ?? 0;
          final currCount = curr.messages[widget.conversationId]?.length ?? 0;
          return currCount > prevCount;
        },
        listener: (context, state) {
          // With reverse:true the list starts at bottom — only scroll if user scrolled up
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollCtrl.hasClients) return;
            if (_scrollCtrl.offset > 0) {
              _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        },
        child: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          final messages = state.messages[widget.conversationId] ?? [];
          final conv = state.conversations
              .where((c) => c.id == widget.conversationId)
              .firstOrNull;
          final isGroup = conv?.type == 'GROUP';
          final otherUserName = conv?.otherUserName;
          final activeRoomName = state.activeGroupCalls[widget.conversationId];
          return Column(
            children: [
              // Connectivity warning banner — shown at TOP when socket disconnected
              if (_socketDisconnected)
                _ConnectivityBanner(),
              // Active call banner for group conversations
              if (isGroup && activeRoomName != null)
                _ActiveCallBanner(
                  onJoin: () => _joinActiveCall(activeRoomName),
                ),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'Начните переписку',
                          style:
                              TextStyle(color: AppColors.of(context).textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[messages.length - 1 - index];
                          final isMe = _isMyMessage(msg, state);
                          final sName = isMe ? null : (msg.senderName ?? otherUserName);
                          return _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            isGroup: isGroup,
                            senderName: sName,
                            onReply: msg.isSystem ? null : () => _setReply(msg, isMe ? 'Вы' : sName),
                            onEdit: (isMe && !msg.isSystem && msg.fileUrl == null) ? () => _startEditing(msg) : null,
                          );
                        },
                      ),
              ),
              if (_editingMessage != null)
                _EditPreviewBar(
                  message: _editingMessage!,
                  onCancel: _cancelEditing,
                ),
              if (_replyTo != null)
                _ReplyPreviewBar(
                  message: _replyTo!,
                  senderName: _replyToSenderName,
                  onCancel: _cancelReply,
                ),
              _InputBar(
                controller: _ctrl,
                onSend: _sendMessage,
                onAttach: _sendFile,
                isRecording: _isRecording,
                onRecordStart: _startRecording,
                onRecordStop: _stopRecordingAndSend,
                isTranscribing: _isTranscribing,
                onTranscribeStart: _startTranscription,
                onTranscribeStop: _stopAndTranscribe,
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  bool _isMyMessage(MessageEntity msg, MessengerState state) {
    final uid = state.currentUserId;
    if (uid == null) return msg.id.startsWith('temp_');
    return msg.senderId == uid;
  }
}

class _ConnectivityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFB71C1C),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.connectionUnstable,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCallBanner extends StatelessWidget {
  final VoidCallback onJoin;
  const _ActiveCallBanner({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.callInProgress,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: onJoin,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(AppLocalizations.of(context)!.joinCall, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final MessageEntity message;
  final bool isMe;
  final String? senderName;
  final bool isGroup;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.senderName,
    this.isGroup = false,
    this.onReply,
    this.onEdit,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  double _dragOffset = 0;
  bool _replyTriggered = false;
  static const _replyThreshold = 56.0;
  static const _maxDrag = 72.0;

  @override
  Widget build(BuildContext context) {
    if (widget.message.isSystem) {
      return _buildSystemMessage(context);
    }

    return GestureDetector(
      onLongPress: () => _showMessageActions(context),
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx > 0 || _dragOffset > 0) {
          final newOffset = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
          if (newOffset >= _replyThreshold && !_replyTriggered) {
            _replyTriggered = true;
            HapticFeedback.mediumImpact();
          }
          setState(() => _dragOffset = newOffset);
        }
      },
      onHorizontalDragEnd: (_) {
        if (_replyTriggered && widget.onReply != null) {
          widget.onReply!();
        }
        setState(() {
          _dragOffset = 0;
          _replyTriggered = false;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragOffset = 0;
          _replyTriggered = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_dragOffset > 4)
            Positioned(
              left: 4,
              top: 0,
              bottom: 8,
              child: Center(
                child: Icon(
                  Icons.reply_rounded,
                  color: AppColors.of(context).primary.withValues(
                      alpha: (_dragOffset / _replyThreshold).clamp(0.0, 1.0)),
                  size: 22,
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(_dragOffset * 0.65, 0),
            child: Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isMe && widget.senderName != null && widget.senderName!.isNotEmpty && (widget.isGroup || widget.senderName != null))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.senderName!,
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (widget.message.fileUrl != null && widget.message.fileType == 'image')
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.message.fileUrl!,
                    width: 220,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(Icons.broken_image, color: AppColors.of(context).textSecondary),
                  ),
                ),
              )
            else if (widget.message.fileUrl != null && widget.message.fileType == 'audio')
              _AudioMessagePlayer(fileUrl: widget.message.fileUrl!, isMe: widget.isMe)
            else if (widget.message.fileUrl != null && widget.message.fileType == 'document')
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(widget.message.fileUrl!);
                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file_rounded, color: AppColors.of(context).primary, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.message.fileName ?? widget.message.content,
                        style: TextStyle(
                          color: AppColors.of(context).primary,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              _LinkifiedText(
                text: widget.message.content,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 14,
                ),
                linkStyle: TextStyle(
                  color: AppColors.of(context).primary,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.message.isEdited) ...[
                  Text(
                    'Отредактировано',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  DateFormat('HH:mm').format(widget.message.sentAt.toLocal()),
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (widget.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    widget.message.isRead
                        ? Icons.done_all_rounded
                        : widget.message.isDelivered
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                    size: 14,
                    color: widget.message.isRead
                        ? AppColors.of(context).primary
                        : AppColors.of(context).textSecondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
          ),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.onReply != null)
              ListTile(
                leading: Icon(Icons.reply_rounded, color: colors.primary),
                title: Text('Ответить', style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReply!();
                },
              ),
            if (widget.isMe && widget.message.fileUrl == null && widget.message.content.isNotEmpty && widget.onEdit != null)
              ListTile(
                leading: Icon(Icons.edit_rounded, color: colors.primary),
                title: Text('Редактировать', style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onEdit!();
                },
              ),
            if (widget.message.fileUrl == null && widget.message.content.isNotEmpty)
              ListTile(
                leading: Icon(Icons.copy_rounded, color: colors.textSecondary),
                title: Text('Копировать', style: TextStyle(color: colors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: widget.message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Скопировано'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.forward_rounded, color: colors.textSecondary),
              title: Text('Переслать', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showForwardPicker(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
              title: Text('Удалить', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    final bloc = context.read<MessengerBloc>();
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Удалить сообщение',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Удалить у меня', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                bloc.add(DeleteMessage(
                  conversationId: widget.message.conversationId,
                  messageId: widget.message.id,
                  forEveryone: false,
                ));
              },
            ),
            if (widget.isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text('Удалить у всех', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  bloc.add(DeleteMessage(
                    conversationId: widget.message.conversationId,
                    messageId: widget.message.id,
                    forEveryone: true,
                  ));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showForwardPicker(BuildContext context) {
    final bloc = context.read<MessengerBloc>();
    final conversations = bloc.state.conversations;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ForwardPickerSheet(
        conversations: conversations,
        onSelected: (targetConversationId) {
          bloc.add(ForwardMessage(
            message: widget.message,
            targetConversationId: targetConversationId,
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сообщение переслано'), duration: Duration(seconds: 2)),
          );
        },
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    String text;
    try {
      final data = jsonDecode(widget.message.content) as Map<String, dynamic>;
      final action = data['action'] as String?;
      final actor = data['actor'] as String? ?? '';
      final target = data['target'] as String? ?? '';
      final role = data['role'] as String? ?? '';
      final l10n = AppLocalizations.of(context)!;
      switch (action) {
        case 'group_created': text = l10n.groupCreated; break;
        case 'member_added': text = l10n.memberJoined(target); break;
        case 'member_left': text = l10n.memberLeftGroup(actor); break;
        case 'member_removed': text = l10n.memberWasRemoved(target); break;
        case 'role_changed': text = l10n.roleChangedTo(target, role); break;
        default: text = widget.message.content;
      }
    } catch (_) {
      text = widget.message.content;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.of(context).card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

final _urlRegex = RegExp(
  r'https?://[^\s<>\"\)]+',
  caseSensitive: false,
);

class _LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextStyle linkStyle;
  const _LinkifiedText({
    required this.text,
    required this.style,
    required this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final matches = _urlRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      return SelectionArea(child: Text(text, style: style));
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final m in matches) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start), style: style));
      }
      final url = m.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: linkStyle,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            final uri = Uri.tryParse(url);
            if (uri == null) return;
            // Open room links inside the app instead of the browser
            if (uri.host == Uri.parse(AppConfig.baseUrl).host && uri.path.startsWith('/room/')) {
              final code = uri.pathSegments.last;
              if (code.isNotEmpty) {
                GoRouter.of(context).go('/dashboard/voice?publicCode=$code');
                return;
              }
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
          },
      ));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: style));
    }
    return SelectionArea(child: Text.rich(TextSpan(children: spans)));
  }
}

class _CallOptionsSheet extends StatefulWidget {
  const _CallOptionsSheet();

  @override
  State<_CallOptionsSheet> createState() => _CallOptionsSheetState();
}

class _CallOptionsSheetState extends State<_CallOptionsSheet> {
  bool _withAi = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Параметры звонка',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _withAi,
              onChanged: (v) => setState(() => _withAi = v),
              activeColor: AppColors.of(context).primary,
              title: Text(
                'Подключить AI ассистента',
                style: TextStyle(color: AppColors.of(context).textPrimary),
              ),
              subtitle: Text(
                _withAi
                    ? 'AI будет участвовать в разговоре'
                    : 'Обычный звонок без AI',
                style: TextStyle(
                    color: AppColors.of(context).textSecondary, fontSize: 12),
              ),
              secondary: Icon(
                Icons.smart_toy_outlined,
                color: _withAi ? AppColors.of(context).primary : AppColors.of(context).textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _withAi),
              icon: const Icon(Icons.call_rounded, color: Colors.black),
              label: const Text(
                'Позвонить',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForwardPickerSheet extends StatefulWidget {
  final List<ConversationEntity> conversations;
  final void Function(String conversationId) onSelected;

  const _ForwardPickerSheet({
    required this.conversations,
    required this.onSelected,
  });

  @override
  State<_ForwardPickerSheet> createState() => _ForwardPickerSheetState();
}

class _ForwardPickerSheetState extends State<_ForwardPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final filtered = widget.conversations.where((c) {
      final name = c.name ?? c.otherUserName ?? '';
      return name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Переслать в...',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Поиск...',
                hintStyle: TextStyle(color: colors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final conv = filtered[i];
                final name = conv.name ?? conv.otherUserName ?? 'Чат';
                final avatarUrl = conv.type == 'DIRECT' ? conv.otherUserAvatar : conv.avatarUrl;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primary.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(name, style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelected(conv.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool isRecording;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;
  final bool isTranscribing;
  final VoidCallback onTranscribeStart;
  final VoidCallback onTranscribeStop;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.isRecording,
    required this.onRecordStart,
    required this.onRecordStop,
    required this.isTranscribing,
    required this.onTranscribeStart,
    required this.onTranscribeStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        border: Border(
          top: BorderSide(color: AppColors.of(context).border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isRecording ? null : onAttach,
            icon: Icon(Icons.attach_file_rounded, color: AppColors.of(context).textSecondary),
          ),
          Expanded(
            child: isRecording
                ? Row(
                    children: [
                      Icon(Icons.circle, color: AppColors.of(context).error, size: 12),
                      SizedBox(width: 8),
                      Text('Запись...', style: TextStyle(color: AppColors.of(context).error, fontSize: 14)),
                    ],
                  )
                : isTranscribing
                ? Row(
                    children: [
                      Icon(Icons.circle, color: Colors.orange, size: 12),
                      SizedBox(width: 8),
                      Text('Говорите...', style: TextStyle(color: Colors.orange, fontSize: 14)),
                    ],
                  )
                : TextField(
                    controller: controller,
                    style: TextStyle(color: AppColors.of(context).textPrimary),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => onSend(),
                    textInputAction: TextInputAction.send,
                  ),
          ),
          IconButton(
            onPressed: () => FocusScope.of(context).unfocus(),
            icon: Icon(Icons.keyboard_hide_rounded, color: AppColors.of(context).textSecondary),
            tooltip: 'Скрыть клавиатуру',
          ),
          // Transcribe button: hold to dictate → text
          if (!isRecording)
            GestureDetector(
              onLongPressStart: (_) => onTranscribeStart(),
              onLongPressEnd: (_) => onTranscribeStop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isTranscribing ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded,
                  color: isTranscribing ? Colors.orange : AppColors.of(context).textSecondary,
                ),
              ),
            ),
          // Voice button: hold to record voice message
          if (!isTranscribing)
            GestureDetector(
              onLongPressStart: (_) => onRecordStart(),
              onLongPressEnd: (_) => onRecordStop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: isRecording ? AppColors.of(context).error : AppColors.of(context).textSecondary,
                ),
              ),
            ),
          if (!isRecording && !isTranscribing)
            IconButton(
              onPressed: onSend,
              icon: Icon(Icons.send_rounded, color: AppColors.of(context).primary),
            ),
        ],
      ),
    );
  }
}

class _ReplyPreviewBar extends StatelessWidget {
  final MessageEntity message;
  final String? senderName;
  final VoidCallback onCancel;
  const _ReplyPreviewBar({required this.message, this.senderName, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final preview = message.fileUrl != null
        ? '📎 ${message.fileName ?? 'Файл'}'
        : message.content;
    final previewText = preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName ?? '',
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _EditPreviewBar extends StatelessWidget {
  final MessageEntity message;
  final VoidCallback onCancel;
  const _EditPreviewBar({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final preview = message.content;
    final previewText = preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          top: BorderSide(color: colors.border),
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_rounded, color: colors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Редактирование',
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _AudioMessagePlayer extends StatefulWidget {
  final String fileUrl;
  final bool isMe;
  const _AudioMessagePlayer({required this.fileUrl, required this.isMe});

  @override
  State<_AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<_AudioMessagePlayer> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play(UrlSource(widget.fileUrl));
      setState(() => _playing = true);
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
            color: AppColors.of(context).primary,
            size: 32,
          ),
          const SizedBox(width: 8),
          Text(
            'Голосовое сообщение',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
