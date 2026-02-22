import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';

class DashboardScreen extends StatelessWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  static const _tabs = [
    RouteConstants.profile,
    RouteConstants.kyc,
    RouteConstants.organization,
    RouteConstants.settings,
  ];

  int _currentIndex(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final currentIndex = _currentIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      floatingActionButton: FloatingActionButton(
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
              icon: const Icon(Icons.person_outlined),
              activeIcon: const Icon(Icons.person),
              label: l10n.tabProfile,
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
          ],
        ),
      ),
    );
  }
}
