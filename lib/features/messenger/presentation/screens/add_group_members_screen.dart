import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/messenger_bloc.dart';
import '../bloc/messenger_event.dart';
import '../bloc/messenger_state.dart';
import '../../domain/entities/user_search_entity.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String conversationId;
  const AddGroupMembersScreen({super.key, required this.conversationId});

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final _searchCtrl = TextEditingController();
  final _selectedIds = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_selectedIds.isEmpty) return;
    context.read<MessengerBloc>().add(AddGroupMembers(
      conversationId: widget.conversationId,
      userIds: _selectedIds.toList(),
    ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(l10n.addMembers),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: _add,
              child: Text(l10n.addMembers,
                  style: TextStyle(color: AppColors.of(context).primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: BlocBuilder<MessengerBloc, MessengerState>(
        builder: (context, state) {
          // Get existing member IDs to filter them out
          final existingIds = (state.groupMembers[widget.conversationId] ?? [])
              .map((m) => m.userId)
              .toSet();
          final results = state.searchResults
              .where((u) => !existingIds.contains(u.id))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    hintStyle: TextStyle(color: AppColors.of(context).textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.of(context).textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.of(context).primary),
                    ),
                  ),
                  onChanged: (q) {
                    if (q.length >= 2) {
                      context.read<MessengerBloc>().add(SearchUsers(q));
                    }
                  },
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.selectedCount(_selectedIds.length),
                      style: TextStyle(color: AppColors.of(context).primary, fontWeight: FontWeight.bold)),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final user = results[index];
                    final isSelected = _selectedIds.contains(user.id);
                    final name = [user.firstName, user.lastName]
                        .where((s) => s != null && s.isNotEmpty).join(' ');
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.of(context).primary,
                        child: user.avatarUrl != null
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: user.avatarUrl!,
                                  width: 40, height: 40, fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                      ),
                      title: Text(name.isNotEmpty ? name : (user.username ?? ''),
                          style: TextStyle(color: AppColors.of(context).textPrimary)),
                      subtitle: user.username != null
                          ? Text('@${user.username}',
                              style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 13))
                          : null,
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(user.id);
                            } else {
                              _selectedIds.add(user.id);
                            }
                          });
                        },
                        activeColor: AppColors.of(context).primary,
                        checkColor: Colors.black,
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(user.id);
                          } else {
                            _selectedIds.add(user.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
