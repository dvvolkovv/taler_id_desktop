import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../messenger/presentation/bloc/messenger_bloc.dart';
import '../../messenger/presentation/bloc/messenger_event.dart';
import '../../messenger/presentation/bloc/messenger_state.dart';

class DashboardScreen extends StatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _tabs = [
    RouteConstants.assistant,
    RouteConstants.kyc,
    RouteConstants.organization,
    RouteConstants.settings,
    RouteConstants.messenger,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectMessenger());
  }

  Future<void> _connectMessenger() async {
    if (!mounted) return;
    final bloc = context.read<MessengerBloc>();
    if (bloc.state.isConnected) return;
    try {
      final storage = sl<SecureStorageService>();
      final token = await storage.getAccessToken();
      final userId = await storage.getUserId();
      if (token != null && mounted) {
        bloc.add(ConnectMessenger(token, userId: userId));
      }
    } catch (_) {}
  }

  int _currentIndex(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  void _showIncomingCall(BuildContext context, Map<String, dynamic> data) {
    final fromName = data['fromUserName'] as String? ?? 'Пользователь';
    final roomName = data['roomName'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isDismissible: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Входящий звонок от $fromName',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<MessengerBloc>()
                        .add(DismissCallInvite());
                    Navigator.pop(context);
                    context.push('/dashboard/voice?room=$roomName');
                  },
                  icon: const Icon(Icons.call, color: Colors.white),
                  label: const Text('Принять'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<MessengerBloc>()
                        .add(DismissCallInvite());
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.call_end, color: Colors.white),
                  label: const Text('Отклонить'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (context.mounted) {
        context.read<MessengerBloc>().add(DismissCallInvite());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final currentIndex = _currentIndex(location);

    return BlocListener<MessengerBloc, MessengerState>(
      listenWhen: (prev, curr) =>
          curr.pendingCallInvite != null &&
          prev.pendingCallInvite != curr.pendingCallInvite,
      listener: (context, state) {
        if (state.pendingCallInvite != null) {
          _showIncomingCall(context, state.pendingCallInvite!);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: widget.child,
        floatingActionButton: location.startsWith(RouteConstants.messenger)
            ? null
            : FloatingActionButton(
                onPressed: () => context.push(RouteConstants.chat),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.smart_toy_outlined, color: Colors.black),
              ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (i) => context.go(_tabs[i]),
            backgroundColor: Colors.transparent,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.headset_mic_outlined),
                activeIcon: const Icon(Icons.headset_mic),
                label: l10n.tabAssistant,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.verified_user_outlined),
                activeIcon: const Icon(Icons.verified_user),
                label: l10n.tabKyc,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.business_outlined),
                activeIcon: const Icon(Icons.business),
                label: l10n.tabOrganization,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: l10n.tabSettings,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                activeIcon: const Icon(Icons.chat_bubble_rounded),
                label: l10n.tabMessenger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
