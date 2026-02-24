import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/api/dio_client.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/conversation_entity.dart';

// BlocProvider is provided by ShellRoute in app_router.dart
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _loadConversationsIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUsername());
  }

  Future<void> _loadConversationsIfNeeded() async {
    final bloc = context.read<MessengerBloc>();
    // DashboardScreen already connects WebSocket; just reload conversations if needed
    if (bloc.state.conversations.isEmpty && !bloc.state.isLoading) {
      if (bloc.state.isConnected) {
        bloc.add(LoadConversations());
      }
      // If not connected yet, DashboardScreen will trigger ConnectMessenger
      // which calls LoadConversations after connecting
    }
  }

  Future<void> _checkUsername() async {
    if (!mounted) return;
    // Check cache first, then API
    final cache = sl<CacheService>();
    Map<String, dynamic>? profile = cache.getProfile();
    if (profile == null) {
      try {
        final client = sl<DioClient>();
        profile = await client.get(
          '/profile',
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        if (profile != null) await cache.saveProfile(profile);
      } catch (_) {
        return;
      }
    }
    if (!mounted) return;
    final username = profile?['username'] as String?;
    if (username != null && username.trim().isNotEmpty) {
      setState(() => _myUsername = username.trim());
    } else {
      _showUsernameDialog();
    }
  }

  void _showUsernameDialog() {
    final ctrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text(
              'Задайте никнейм',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Никнейм обязателен для использования мессенджера. Другие пользователи смогут найти вас по нему.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'username',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixText: '@',
                    prefixStyle: const TextStyle(color: AppColors.primary),
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  inputFormatters: [],
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  '3–30 символов: буквы, цифры, _',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black),
                onPressed: () async {
                  final value = ctrl.text.trim();
                  final regex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
                  if (!regex.hasMatch(value)) {
                    setDialogState(() =>
                        errorText = '3–30 символов: буквы, цифры, _');
                    return;
                  }
                  try {
                    final client = sl<DioClient>();
                    await client.patch(
                      '/profile/username',
                      data: {'username': value},
                      fromJson: (d) => d,
                    );
                    // Update cache to prevent dialog on next visit
                    final cache = sl<CacheService>();
                    final currentProfile = cache.getProfile() ?? {};
                    await cache.saveProfile({...currentProfile, 'username': value});
                    if (mounted) setState(() => _myUsername = value);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on Exception catch (e) {
                    final msg = e.toString();
                    setDialogState(() => errorText =
                        msg.contains('409') ? 'Никнейм уже занят' : 'Ошибка сохранения');
                  }
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _ConversationsView(myUsername: _myUsername);
}

class _ConversationsView extends StatelessWidget {
  final String? myUsername;
  const _ConversationsView({this.myUsername});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Сообщения'),
            if (myUsername != null && myUsername!.isNotEmpty)
              Text(
                '@$myUsername',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            onPressed: () => context.push('/dashboard/messenger/search'),
            tooltip: 'Найти пользователя',
          ),
        ],
      ),
      body: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          if (state.isLoading && state.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Нет диалогов',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Найдите пользователя чтобы начать переписку',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<MessengerBloc>().add(LoadConversations()),
            child: ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final conv = state.conversations[index];
                return _ConversationTile(conversation: conv);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/dashboard/messenger/search'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.black),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final displayName = conversation.otherUserName ?? 'Пользователь';
    final lastMsg = conversation.lastMessageContent;
    final lastAt = conversation.lastMessageAt;
    final timeStr = lastAt != null
        ? DateFormat('HH:mm').format(lastAt.toLocal())
        : '';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        displayName,
        style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: lastMsg != null
          ? Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            )
          : null,
      trailing: timeStr.isNotEmpty
          ? Text(
              timeStr,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            )
          : null,
      onTap: () =>
          context.push('/dashboard/messenger/${conversation.id}'),
    );
  }
}
