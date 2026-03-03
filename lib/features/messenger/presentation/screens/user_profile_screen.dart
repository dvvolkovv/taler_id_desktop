import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = sl<DioClient>();
      final data = await client.get(
        '/profile/${widget.userId}',
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
      if (mounted) setState(() { _profile = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openChat() async {
    final bloc = context.read<MessengerBloc>();
    bloc.add(StartConversationWith(widget.userId));
    // Wait for new conversation ID
    final state = await bloc.stream.firstWhere(
      (s) => s.newConversationId != null || (!s.isLoading && s.error != null),
    );
    if (!mounted) return;
    final convId = state.newConversationId;
    if (convId != null) {
      bloc.add(ClearNewConversation());
      context.push('/dashboard/messenger/$convId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _profile?['firstName'] as String? ?? '';
    final lastName = _profile?['lastName'] as String? ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final username = _profile?['username'] as String?;
    final avatarUrl = _profile?['avatarUrl'] as String?;
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(fullName.isNotEmpty ? fullName : 'Профиль'),
        backgroundColor: AppColors.of(context).surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.of(context).error, size: 48),
                      const SizedBox(height: 16),
                      Text('Ошибка загрузки профиля',
                          style: TextStyle(color: AppColors.of(context).textPrimary)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.2),
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Text(
                                    initials,
                                    style: TextStyle(
                                        color: AppColors.of(context).primary,
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : Text(
                                initials,
                                style: TextStyle(
                                    color: AppColors.of(context).primary,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 20),
                      if (fullName.isNotEmpty)
                        Text(
                          fullName,
                          style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      if (username != null && username.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '@$username',
                          style: TextStyle(
                              color: AppColors.of(context).textSecondary, fontSize: 15),
                        ),
                      ],
                      const SizedBox(height: 32),
                      BlocListener<MessengerBloc, MessengerState>(
                        listenWhen: (p, c) =>
                            p.newConversationId != c.newConversationId &&
                            c.newConversationId != null,
                        listener: (context, state) {
                          final convId = state.newConversationId;
                          if (convId != null) {
                            context.read<MessengerBloc>().add(ClearNewConversation());
                            context.push('/dashboard/messenger/$convId');
                          }
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openChat,
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                color: Colors.black),
                            label: const Text('Написать сообщение',
                                style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.of(context).primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
