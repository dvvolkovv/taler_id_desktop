import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/conversation_entity.dart';
import 'chat_room_screen.dart';

/// Two-panel messenger layout for desktop (like Telegram Desktop).
/// Left panel: conversations list. Right panel: selected chat room.
class MessengerDesktopLayout extends StatefulWidget {
  /// If a conversationId is passed from the route, open it immediately.
  final String? initialConversationId;
  const MessengerDesktopLayout({super.key, this.initialConversationId});

  @override
  State<MessengerDesktopLayout> createState() => _MessengerDesktopLayoutState();
}

class _MessengerDesktopLayoutState extends State<MessengerDesktopLayout> {
  String? _selectedConversationId;
  String? _myUsername;

  @override
  void initState() {
    super.initState();
    _selectedConversationId = widget.initialConversationId;
    _loadConversationsIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUsername());
  }

  @override
  void didUpdateWidget(MessengerDesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialConversationId != null &&
        widget.initialConversationId != _selectedConversationId) {
      setState(() => _selectedConversationId = widget.initialConversationId);
    }
  }

  Future<void> _loadConversationsIfNeeded() async {
    final bloc = context.read<MessengerBloc>();
    if (bloc.state.conversations.isEmpty && !bloc.state.isLoading) {
      if (bloc.state.isConnected) {
        bloc.add(LoadConversations());
      }
    }
  }

  Future<void> _checkUsername() async {
    if (!mounted) return;
    final cache = sl<CacheService>();
    Map<String, dynamic>? profile;
    try {
      final client = sl<DioClient>();
      profile = await client.get(
        '/profile',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (profile != null) await cache.saveProfile(profile);
    } catch (_) {
      profile = cache.getProfile();
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
            backgroundColor: AppColors.of(context).card,
            title: Text('Задайте никнейм',
                style: TextStyle(color: AppColors.of(context).textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Никнейм обязателен для использования мессенджера.',
                    style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    hintText: 'username',
                    prefixText: '@',
                    prefixStyle: TextStyle(color: AppColors.of(context).primary),
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.of(context).primary),
                    ),
                  ),
                  onChanged: (_) {
                    if (errorText != null) setDialogState(() => errorText = null);
                  },
                ),
                const SizedBox(height: 8),
                Text('3–30 символов: буквы, цифры, _',
                    style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 11)),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.of(context).primary,
                    foregroundColor: Colors.black),
                onPressed: () async {
                  final value = ctrl.text.trim();
                  if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(value)) {
                    setDialogState(() => errorText = '3–30 символов: буквы, цифры, _');
                    return;
                  }
                  try {
                    final client = sl<DioClient>();
                    await client.patch('/profile/username', data: {'username': value}, fromJson: (d) => d);
                    final cache = sl<CacheService>();
                    final cur = cache.getProfile() ?? {};
                    await cache.saveProfile({...cur, 'username': value});
                    if (mounted) setState(() => _myUsername = value);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on Exception catch (e) {
                    final msg = e.toString();
                    setDialogState(() => errorText = msg.contains('409') ? 'Никнейм уже занят' : 'Ошибка');
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

  void _selectConversation(String id) {
    setState(() => _selectedConversationId = id);
    context.read<MessengerBloc>().add(MarkConversationRead(id));
  }

  void _showContactRequests(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Запросы на общение',
                  style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: BlocBuilder<MessengerBloc, MessengerState>(
                builder: (context, state) {
                  if (state.contactRequests.isEmpty) {
                    return Center(child: Text('Нет новых запросов',
                        style: TextStyle(color: AppColors.of(context).textSecondary)));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    itemCount: state.contactRequests.length,
                    itemBuilder: (context, i) {
                      final req = state.contactRequests[i];
                      final name = req['senderName'] as String? ?? '';
                      final username = req['senderUsername'] as String?;
                      final avatar = req['senderAvatar'] as String?;
                      final id = req['id'] as String;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.of(context).primary,
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                              : null,
                        ),
                        title: Text(name.isNotEmpty ? name : (username != null ? '@$username' : ''),
                            style: TextStyle(color: AppColors.of(context).textPrimary, fontWeight: FontWeight.w600)),
                        subtitle: username != null
                            ? Text('@$username', style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.close_rounded, color: AppColors.of(context).error),
                              onPressed: () => context.read<MessengerBloc>().add(RejectContactRequest(id)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_rounded, color: Colors.green),
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.read<MessengerBloc>().add(AcceptContactRequest(id));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.15),
                child: Icon(Icons.person_add_rounded, color: AppColors.of(context).primary),
              ),
              title: Text(l10n.newChat, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/dashboard/messenger/search');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.15),
                child: Icon(Icons.group_add_rounded, color: AppColors.of(context).primary),
              ),
              title: Text(l10n.newGroup, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/dashboard/messenger/create-group');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          // Left panel — conversations list
          SizedBox(
            width: 340,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  decoration: BoxDecoration(
                    color: colors.background,
                    border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.tabMessenger,
                                style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                            if (_myUsername != null)
                              Text('@$_myUsername',
                                  style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                          ],
                        ),
                      ),
                      // Contact requests
                      BlocBuilder<MessengerBloc, MessengerState>(
                        buildWhen: (p, c) => p.contactRequests.length != c.contactRequests.length,
                        builder: (context, state) {
                          final count = state.contactRequests.length;
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.person_add_alt_1_rounded),
                                iconSize: 20,
                                onPressed: () => _showContactRequests(context),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: 4, top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(color: colors.error, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text('$count',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_search_rounded),
                        iconSize: 20,
                        onPressed: () => context.push('/dashboard/messenger/search'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        iconSize: 20,
                        onPressed: () => _showNewChatSheet(context),
                      ),
                    ],
                  ),
                ),
                // Conversations list
                Expanded(
                  child: BlocBuilder<MessengerBloc, MessengerState>(
                    builder: (context, state) {
                      if (state.isLoading && state.conversations.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.conversations.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 48, color: colors.textSecondary),
                                const SizedBox(height: 12),
                                Text('Нет диалогов', style: TextStyle(color: colors.textSecondary, fontSize: 15)),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: state.conversations.length,
                        separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
                        itemBuilder: (context, index) {
                          final conv = state.conversations[index];
                          final isSelected = conv.id == _selectedConversationId;
                          return _DesktopConversationTile(
                            conversation: conv,
                            isSelected: isSelected,
                            onTap: () => _selectConversation(conv.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Divider
          VerticalDivider(width: 1, color: colors.border),
          // Right panel — chat room or placeholder
          Expanded(
            child: _selectedConversationId != null
                ? ChatRoomScreen(
                    key: ValueKey(_selectedConversationId),
                    conversationId: _selectedConversationId!,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_rounded, size: 64, color: colors.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Выберите диалог',
                            style: TextStyle(color: colors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DesktopConversationTile extends StatelessWidget {
  final ConversationEntity conversation;
  final bool isSelected;
  final VoidCallback onTap;
  const _DesktopConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isGroup = conversation.type == 'GROUP';
    final displayName = isGroup
        ? (conversation.name ?? 'Группа')
        : (conversation.otherUserName ?? 'Пользователь');
    final lastMsg = conversation.lastMessageContent;
    final lastAt = conversation.lastMessageAt;
    final timeStr = lastAt != null ? DateFormat('HH:mm').format(lastAt.toLocal()) : '';

    String? subtitleText;
    if (lastMsg != null) {
      if (conversation.lastMessageIsSystem) {
        subtitleText = _formatSystemMessage(context, lastMsg);
      } else if (isGroup && conversation.lastMessageSenderName != null) {
        subtitleText = '${conversation.lastMessageSenderName}: $lastMsg';
      } else {
        subtitleText = lastMsg;
      }
    }

    final avatar = isGroup ? conversation.avatarUrl : conversation.otherUserAvatar;

    return Material(
      color: isSelected ? colors.primary.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isGroup
                    ? colors.primary.withValues(alpha: 0.7)
                    : colors.primary,
                child: avatar != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatar,
                          width: 44, height: 44, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _avatarContent(colors, displayName, isGroup),
                        ),
                      )
                    : _avatarContent(colors, displayName, isGroup),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(displayName,
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(timeStr, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                        ],
                        if (conversation.isMuted) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.volume_off, size: 12, color: colors.textSecondary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitleText ?? (isGroup
                                ? AppLocalizations.of(context)!.participantsCount(conversation.participantCount)
                                : ''),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: conversation.isMuted ? colors.textSecondary : colors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${conversation.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarContent(AppColorsExtension colors, String name, bool isGroup) {
    if (isGroup) return const Icon(Icons.group_rounded, color: Colors.black, size: 20);
    return Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold));
  }

  String _formatSystemMessage(BuildContext context, String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final action = data['action'] as String?;
      final actor = data['actor'] as String? ?? '';
      final target = data['target'] as String? ?? '';
      final role = data['role'] as String? ?? '';
      final l10n = AppLocalizations.of(context)!;
      switch (action) {
        case 'group_created': return l10n.groupCreated;
        case 'member_added': return l10n.memberJoined(target);
        case 'member_left': return l10n.memberLeftGroup(actor);
        case 'member_removed': return l10n.memberWasRemoved(target);
        case 'role_changed': return l10n.roleChangedTo(target, role);
        default: return content;
      }
    } catch (_) {
      return content;
    }
  }
}
