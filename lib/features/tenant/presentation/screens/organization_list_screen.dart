import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/tenant_entity.dart';
import '../bloc/tenant_bloc.dart';
import '../bloc/tenant_event.dart';
import '../bloc/tenant_state.dart';

class OrganizationListScreen extends StatefulWidget {
  const OrganizationListScreen({super.key});

  @override
  State<OrganizationListScreen> createState() => _OrganizationListScreenState();
}

class _OrganizationListScreenState extends State<OrganizationListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TenantBloc>().add(TenantsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Организации'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is TenantLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is TenantsLoaded) {
            if (state.tenants.isEmpty) {
              return _buildEmpty(context);
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => context.read<TenantBloc>().add(TenantsLoadRequested()),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.tenants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildCard(context, state.tenants[i]),
              ),
            );
          }

          return _buildEmpty(context);
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, TenantEntity tenant) {
    final kybColor = _kybColor(tenant.kybStatus);
    final kybLabel = _kybLabel(tenant.kybStatus);
    final roleLabel = _roleLabel(tenant.myRole);

    return GestureDetector(
      onTap: () => context.push(
        RouteConstants.organizationDetail.replaceFirst(':id', tenant.id),
      ),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.business_outlined, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      StatusBadge(label: kybLabel, color: kybColor),
                      const SizedBox(width: 8),
                      if (roleLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(roleLabel,
                              style: const TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.w500)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_outlined, color: AppColors.textSecondary, size: 64),
            const SizedBox(height: 16),
            const Text('Нет организаций', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Создайте организацию или примите приглашение',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Создать организацию'),
            ),
          ],
        ),
      );

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Новая организация',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Название *'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    context.read<TenantBloc>().add(TenantCreateSubmitted({
                      'name': nameCtrl.text.trim(),
                      if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                    }));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Создать'),
              ),
            ),
          ],
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
      case KybStatus.verified: return 'KYB ✓';
      case KybStatus.pending: return 'KYB...';
      case KybStatus.rejected: return 'KYB ✗';
      default: return 'Без KYB';
    }
  }

  String? _roleLabel(TenantRole? role) {
    switch (role) {
      case TenantRole.owner: return 'Owner';
      case TenantRole.admin: return 'Admin';
      case TenantRole.operator: return 'Operator';
      case TenantRole.viewer: return 'Viewer';
      default: return null;
    }
  }
}
