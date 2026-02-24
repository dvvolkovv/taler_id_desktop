import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/api/dio_client.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/message_entity.dart';
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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _scrollCtrl = ScrollController();
    context.read<MessengerBloc>().add(OpenConversation(widget.conversationId));
  }

  Future<void> _startCall() async {
    // Show bottom sheet to choose call type
    final withAi = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
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
        data: {'withAi': withAi},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      final roomName = res['roomName'] as String;
      sl<MessengerRemoteDataSource>()
          .sendCallInvite(widget.conversationId, roomName);
      if (mounted) context.push('/dashboard/voice?room=$roomName');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка звонка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _sendMessage() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    context
        .read<MessengerBloc>()
        .add(SendMessage(widget.conversationId, text));
    _ctrl.clear();
    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: BlocBuilder<MessengerBloc, MessengerState>(
          buildWhen: (prev, curr) => prev.conversations != curr.conversations,
          builder: (context, state) {
            final conv = state.conversations
                .where((c) => c.id == widget.conversationId)
                .firstOrNull;
            final name = conv?.otherUserName;
            return Text(name != null && name.isNotEmpty ? name : 'Диалог');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined),
            onPressed: _startCall,
            tooltip: 'Позвонить',
          ),
        ],
      ),
      body: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          final messages =
              state.messages[widget.conversationId] ?? [];
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Начните переписку',
                          style:
                              TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _MessageBubble(
                            message: msg,
                            isMe: _isMyMessage(msg, state),
                          );
                        },
                      ),
              ),
              _InputBar(controller: _ctrl, onSend: _sendMessage),
            ],
          );
        },
      ),
    );
  }

  bool _isMyMessage(MessageEntity msg, MessengerState state) {
    final uid = state.currentUserId;
    if (uid == null) return msg.id.startsWith('temp_');
    return msg.senderId == uid;
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName!,
                  style: TextStyle(
                    color: isMe ? Colors.black87 : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.black : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
          const Text(
            'Параметры звонка',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _withAi,
              onChanged: (v) => setState(() => _withAi = v),
              activeColor: AppColors.primary,
              title: const Text(
                'Подключить AI ассистента',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _withAi
                    ? 'AI будет участвовать в разговоре'
                    : 'Обычный звонок без AI',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              secondary: Icon(
                Icons.smart_toy_outlined,
                color: _withAi ? AppColors.primary : AppColors.textSecondary,
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
                backgroundColor: AppColors.primary,
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

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Сообщение...',
                hintStyle:
                    TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
            ),
          ),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
