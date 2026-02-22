import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/constants.dart';
import '../bloc/tenant_bloc.dart';
import '../bloc/tenant_event.dart';
import '../bloc/tenant_state.dart';

class InviteScreen extends StatefulWidget {
  final String token;
  const InviteScreen({super.key, required this.token});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<TenantBloc, TenantState>(
        listener: (context, state) {
          if (state is TenantsLoaded && _accepted) {
            context.go(RouteConstants.organization);
          } else if (state is TenantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_outline, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.acceptInvitationTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.acceptInvitationDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 40),
                LoadingButton(
                  text: l10n.acceptInvitation,
                  loading: state is TenantLoading,
                  onPressed: () {
                    _accepted = true;
                    context.read<TenantBloc>().add(TenantInviteAccepted(widget.token));
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(RouteConstants.assistant),
                  child: Text(l10n.reject, style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
