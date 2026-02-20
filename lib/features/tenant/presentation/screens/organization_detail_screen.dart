import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../domain/entities/tenant_entity.dart';
import '../bloc/tenant_bloc.dart';
import '../bloc/tenant_event.dart';
import '../bloc/tenant_state.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final String tenantId;
  const OrganizationDetailScreen({super.key, required this.tenantId});

  @override
  State<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TenantBloc>().add(TenantDetailRequested(widget.tenantId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Организация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppColors.primary),
            onPressed: () => _showInviteSheet(context),
          ),
        ],
      ),
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.primary),
            );
          } else if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is TenantLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is TenantDetailLoaded) {
            final t = state.tenant;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.business_outlined, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                StatusBadge(label: _kybLabel(t.kybStatus), color: _kybColor(t.kybStatus)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (t.description != null && t.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(t.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contact info
                if (t.website != null || t.email != null || t.phone != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Контакты', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        if (t.website != null) _contactRow(Icons.language_outlined, t.website!),
                        if (t.email != null) _contactRow(Icons.email_outlined, t.email!),
                        if (t.phone != null) _contactRow(Icons.phone_outlined, t.phone!),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Members
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Участники (${t.members.length})',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: () => _showInviteSheet(context),
                            child: const Text('+ Пригласить', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...t.members.map((m) => _memberRow(m)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // KYB action
                if (t.kybStatus == KybStatus.none || t.kybStatus == KybStatus.rejected)
                  ElevatedButton.icon(
                    onPressed: () {/* Start KYB */},
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('Пройти KYB-верификацию'),
                  ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 16),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      );

  Widget _memberRow(TenantMemberEntity member) {
    final roleColors = {
      TenantRole.owner: AppColors.primary,
      TenantRole.admin: AppColors.secondary,
      TenantRole.operator: AppColors.warning,
      TenantRole.viewer: AppColors.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.border,
            child: Text(
              member.email[0].toUpperCase(),
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [member.firstName, member.lastName].where((s) => s != null && s.isNotEmpty).join(' ').isEmpty
                      ? member.email
                      : [member.firstName, member.lastName].where((s) => s != null && s.isNotEmpty).join(' '),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
                Text(member.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColors[member.role]!.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              member.role.name,
              style: TextStyle(color: roleColors[member.role], fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    TenantRole selectedRole = TenantRole.viewer;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Пригласить участника',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TenantRole>(
                value: selectedRole,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Роль'),
                items: TenantRole.values.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(r.name, style: const TextStyle(color: AppColors.textPrimary)),
                )).toList(),
                onChanged: (v) => setModalState(() => selectedRole = v ?? TenantRole.viewer),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (emailCtrl.text.contains('@')) {
                      context.read<TenantBloc>().add(TenantMemberInvited(
                        tenantId: widget.tenantId,
                        email: emailCtrl.text.trim(),
                        role: selectedRole,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Отправить приглашение'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _kybColor(KybStatus status) {
    switch (status) {
      case KybStatus.verified: return AppColors.primary;
      case KybStatus.pending: return AppColors.warning;
      case KybStatus.rejected: return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _kybLabel(KybStatus status) {
    switch (status) {
      case KybStatus.verified: return 'Верифицирована';
      case KybStatus.pending: return 'На проверке';
      case KybStatus.rejected: return 'Отклонено';
      default: return 'Не верифицирована';
    }
  }
}
