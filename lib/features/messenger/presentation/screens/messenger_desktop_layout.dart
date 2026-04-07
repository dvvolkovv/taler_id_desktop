import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/conversation_entity.dart';
import 'chat_room_screen.dart';
import 'topics_list_screen.dart';

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

  // Topics mode — when viewing a group with topics enabled
  String? _topicsGroupId;
  String? _topicsGroupName;
  List<Map<String, dynamic>> _topics = [];
  bool _topicsLoading = false;
  String? _selectedTopicId;

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

  // ─── Topics mode ───

  void _enterTopicsMode(String groupId, String groupName) {
    setState(() {
      _topicsGroupId = groupId;
      _topicsGroupName = groupName;
      _selectedTopicId = null;
      _selectedConversationId = null;
      _topicsLoading = true;
    });
    _loadTopics(groupId);
  }

  void _exitTopicsMode() {
    setState(() {
      _topicsGroupId = null;
      _topicsGroupName = null;
      _topics = [];
      _selectedTopicId = null;
    });
  }

  Future<void> _loadTopics(String groupId) async {
    try {
      final client = sl<DioClient>();
      final data = await client.get<List<dynamic>>(
        '/messenger/conversations/$groupId/topics',
        fromJson: (d) => d as List<dynamic>,
      );
      final topics = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (topics.isEmpty) {
        final created = await client.post<Map<String, dynamic>>(
          '/messenger/conversations/$groupId/topics',
          data: {'title': 'Общая', 'icon': '💬'},
          fromJson: (d) => Map<String, dynamic>.from(d as Map),
        );
        if (mounted) setState(() { _topics = [created]; _topicsLoading = false; });
      } else {
        if (mounted) setState(() { _topics = topics; _topicsLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _topicsLoading = false);
    }
  }

  void _showCreateTopicDialog(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final titleCtrl = TextEditingController();
    String selectedIcon = '💬';
    final icons = ['💬', '📢', '🔧', '🎮', '📚', '🎵', '🎨', '💡', '🔥', '⭐', '📋', '🏗️'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.card,
          title: Text(l10n.messengerTopicNew, style: TextStyle(color: colors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.messengerTopicNameHint,
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.messengerTopicIcon, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((icon) => GestureDetector(
                  onTap: () => setDialogState(() => selectedIcon = icon),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: selectedIcon == icon ? colors.primary.withValues(alpha: 0.2) : colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: selectedIcon == icon ? Border.all(color: colors.primary, width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.black),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final client = sl<DioClient>();
                  final created = await client.post<Map<String, dynamic>>(
                    '/messenger/conversations/${_topicsGroupId!}/topics',
                    data: {'title': title, 'icon': selectedIcon},
                    fromJson: (d) => Map<String, dynamic>.from(d as Map),
                  );
                  if (mounted) setState(() => _topics.add(created));
                } catch (_) {}
              },
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateChannel(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final colors = AppColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(l10n.messengerNewChannel, style: TextStyle(color: colors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.messengerChannelName,
                labelStyle: TextStyle(color: colors.textSecondary),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.messengerChannelDescription,
                labelStyle: TextStyle(color: colors.textSecondary),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel, style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.black),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await sl<DioClient>().post(
                  '/messenger/channels',
                  data: {'name': name, 'description': descCtrl.text.trim()},
                  fromJson: (d) => d,
                );
                if (mounted) context.read<MessengerBloc>().add(LoadConversations());
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.messengerChannelCreateError), backgroundColor: colors.error),
                  );
                }
              }
            },
            child: Text(l10n.create),
          ),
        ],
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
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.15),
                child: Icon(Icons.campaign_rounded, color: AppColors.of(context).primary),
              ),
              title: Text(l10n.messengerNewChannel, style: TextStyle(color: AppColors.of(context).textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _showCreateChannel(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Left panel: conversations list ───
  Widget _buildConversationsPanel(AppColorsExtension colors, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(4, 12, 8, 8),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: colors.textSecondary,
                tooltip: 'Назад',
                onPressed: () => context.go(RouteConstants.assistant),
              ),
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
                    onTap: () {
                      if (conv.topicsEnabled && conv.type == 'GROUP') {
                        _enterTopicsMode(conv.id, conv.name ?? l10n.messengerGroupDefault);
                      } else {
                        _selectConversation(conv.id);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Left panel: topics list (Telegram-style) ───
  Widget _buildTopicsPanel(AppColorsExtension colors, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(4, 12, 8, 8),
          decoration: BoxDecoration(
            color: colors.background,
            border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: colors.textSecondary,
                tooltip: 'Назад к диалогам',
                onPressed: _exitTopicsMode,
              ),
              Expanded(
                child: Text(
                  _topicsGroupName ?? '',
                  style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 22),
                color: colors.textSecondary,
                tooltip: l10n.messengerTopicNew,
                onPressed: () => _showCreateTopicDialog(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: _topicsLoading
              ? const Center(child: CircularProgressIndicator())
              : _topics.isEmpty
                  ? Center(
                      child: Text('Нет тем', style: TextStyle(color: colors.textSecondary)),
                    )
                  : ListView.separated(
                      itemCount: _topics.length,
                      separatorBuilder: (_, __) => Divider(color: colors.border, height: 1),
                      itemBuilder: (context, index) {
                        final t = _topics[index];
                        final id = t['id'] as String;
                        final title = t['title'] as String? ?? '';
                        final icon = t['icon'] as String? ?? '💬';
                        final lastMsg = t['lastMessageContent'] as String?;
                        final lastAt = t['lastMessageAt'] != null
                            ? DateTime.tryParse(t['lastMessageAt'] as String)
                            : null;
                        final isSelected = id == _selectedTopicId;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: colors.primary.withValues(alpha: 0.10),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(icon, style: const TextStyle(fontSize: 20)),
                          ),
                          title: Text(title,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              )),
                          subtitle: lastMsg != null
                              ? Text(lastMsg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: colors.textSecondary, fontSize: 13))
                              : null,
                          trailing: lastAt != null
                              ? Text(
                                  DateFormat.Hm().format(lastAt.toLocal()),
                                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedTopicId = id;
                              _selectedConversationId = _topicsGroupId;
                            });
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ─── Right panel ───
  Widget _buildRightPanel(AppColorsExtension colors, AppLocalizations l10n) {
    final convId = _selectedConversationId;
    if (convId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_rounded, size: 64, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Выберите диалог',
                style: TextStyle(color: colors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }
    // Key includes topicId so ChatRoomScreen rebuilds when switching topics
    final key = _selectedTopicId != null
        ? ValueKey('$convId-$_selectedTopicId')
        : ValueKey(convId);
    return ChatRoomScreen(
      key: key,
      conversationId: convId,
      topicId: _selectedTopicId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return BlocListener<MessengerBloc, MessengerState>(
      listenWhen: (prev, curr) =>
          !prev.isConnected && curr.isConnected,
      listener: (context, state) {
        // Bloc just connected — conversations are auto-loaded by the bloc,
        // but trigger explicitly in case the LoadConversations in initState
        // was skipped due to race condition.
        if (state.conversations.isEmpty) {
          context.read<MessengerBloc>().add(LoadConversations());
        }
      },
      child: Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          // Left panel — conversations or topics list
          SizedBox(
            width: 340,
            child: _topicsGroupId != null
                ? _buildTopicsPanel(colors, l10n)
                : _buildConversationsPanel(colors, l10n),
          ),
          // Divider
          VerticalDivider(width: 1, color: colors.border),
          // Right panel — chat room or placeholder
          Expanded(
            child: _buildRightPanel(colors, l10n),
          ),
        ],
      ),
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
