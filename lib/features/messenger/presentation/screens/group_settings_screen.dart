import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/group_member_entity.dart';

class GroupSettingsScreen extends StatefulWidget {
  final String conversationId;
  const GroupSettingsScreen({super.key, required this.conversationId});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MessengerBloc>().add(LoadGroupMembers(widget.conversationId));
  }

  static const _roleColors = {
    'OWNER': Colors.amber,
    'ADMIN': Colors.blue,
    'MEMBER': Colors.grey,
  };

  String _roleLabel(String role, AppLocalizations l10n) {
    switch (role) {
      case 'OWNER': return l10n.groupRoleOwner;
      case 'ADMIN': return l10n.groupRoleAdmin;
      case 'MEMBER': return l10n.groupRoleMember;
      default: return role;
    }
  }

  void _showChangeRoleSheet(GroupMemberEntity member, String myRole) {
    final l10n = AppLocalizations.of(context)!;
    final canAssignAdmin = myRole == 'OWNER';
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
            Text(l10n.changeRole,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (canAssignAdmin && member.role != 'ADMIN')
              ListTile(
                leading: Icon(Icons.shield_rounded, color: _roleColors['ADMIN']),
                title: Text(l10n.groupRoleAdmin, style: TextStyle(color: AppColors.of(context).textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MessengerBloc>().add(ChangeGroupRole(
                    conversationId: widget.conversationId,
                    userId: member.userId,
                    role: 'ADMIN',
                  ));
                },
              ),
            if (member.role != 'MEMBER')
              ListTile(
                leading: Icon(Icons.person_rounded, color: _roleColors['MEMBER']),
                title: Text(l10n.groupRoleMember, style: TextStyle(color: AppColors.of(context).textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<MessengerBloc>().add(ChangeGroupRole(
                    conversationId: widget.conversationId,
                    userId: member.userId,
                    role: 'MEMBER',
                  ));
                },
              ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.person_remove_rounded, color: AppColors.of(context).error),
              title: Text(l10n.removeMember,
                  style: TextStyle(color: AppColors.of(context).error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemoveMember(member);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(GroupMemberEntity member) {
    final l10n = AppLocalizations.of(context)!;
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.removeMember, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.removeMemberConfirm(name.isNotEmpty ? name : (member.username ?? '')),
            style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(RemoveGroupMember(
                conversationId: widget.conversationId,
                userId: member.userId,
              ));
            },
            child: Text(l10n.delete, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.leaveGroup, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.leaveGroupConfirm, style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(LeaveGroup(widget.conversationId));
              context.go('/dashboard/messenger');
            },
            child: Text(l10n.leaveGroup, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(l10n.deleteGroup, style: TextStyle(color: AppColors.of(context).textPrimary)),
        content: Text(l10n.deleteGroupConfirm, style: TextStyle(color: AppColors.of(context).textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MessengerBloc>().add(DeleteGroup(widget.conversationId));
              context.go('/dashboard/messenger');
            },
            child: Text(l10n.deleteGroup, style: TextStyle(color: AppColors.of(context).error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(title: Text(l10n.groupInfo)),
      body: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          final conv = state.conversations
              .where((c) => c.id == widget.conversationId)
              .firstOrNull;
          final members = state.groupMembers[widget.conversationId] ?? [];
          final myRole = conv?.myRole ?? 'MEMBER';
          final canManage = myRole == 'OWNER' || myRole == 'ADMIN';

          return ListView(
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.3),
                      child: conv?.avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: conv!.avatarUrl!,
                                width: 72, height: 72, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(Icons.group_rounded, size: 36, color: AppColors.of(context).primary),
                              ),
                            )
                          : Icon(Icons.group_rounded, size: 36, color: AppColors.of(context).primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(conv?.name ?? '',
                              style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(l10n.participantsCount(members.length),
                              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Members header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(l10n.groupMembers(members.length),
                        style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (canManage)
                      TextButton.icon(
                        onPressed: () => context.push('/dashboard/messenger/${widget.conversationId}/add-members'),
                        icon: Icon(Icons.person_add_rounded, size: 18, color: AppColors.of(context).primary),
                        label: Text(l10n.addMembers,
                            style: TextStyle(color: AppColors.of(context).primary, fontSize: 13)),
                      ),
                  ],
                ),
              ),
              // Member list
              ...members.map((m) => _buildMemberTile(m, myRole, state.currentUserId, l10n)),
              const Divider(height: 32),
              // Leave group
              ListTile(
                leading: Icon(Icons.exit_to_app_rounded, color: AppColors.of(context).error),
                title: Text(l10n.leaveGroup, style: TextStyle(color: AppColors.of(context).error)),
                onTap: _confirmLeaveGroup,
              ),
              // Delete group (OWNER only)
              if (myRole == 'OWNER')
                ListTile(
                  leading: Icon(Icons.delete_forever_rounded, color: AppColors.of(context).error),
                  title: Text(l10n.deleteGroup, style: TextStyle(color: AppColors.of(context).error)),
                  onTap: _confirmDeleteGroup,
                ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(GroupMemberEntity member, String myRole, String? myUserId, AppLocalizations l10n) {
    final name = [member.firstName, member.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    final displayName = name.isNotEmpty ? name : (member.username ?? member.userId);
    final isMe = member.userId == myUserId;
    final canManage = (myRole == 'OWNER' || myRole == 'ADMIN') && !isMe && member.role != 'OWNER';
    final roleColor = _roleColors[member.role] ?? Colors.grey;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.of(context).primary,
        child: member.avatarUrl != null
            ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: member.avatarUrl!,
                  width: 40, height: 40, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Text(displayName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              )
            : Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(displayName,
                style: TextStyle(color: AppColors.of(context).textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _roleLabel(member.role, l10n),
              style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      subtitle: member.username != null
          ? Text('@${member.username}',
              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13))
          : null,
      trailing: canManage
          ? IconButton(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.of(context).textSecondary),
              onPressed: () => _showChangeRoleSheet(member, myRole),
            )
          : null,
      onTap: !isMe ? () => context.push('/dashboard/user/${member.userId}') : null,
    );
  }
}
