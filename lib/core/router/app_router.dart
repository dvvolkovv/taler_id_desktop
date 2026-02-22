import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/two_fa_screen.dart';
import '../../features/auth/presentation/screens/pin_setup_screen.dart';
import '../../features/auth/presentation/screens/pin_entry_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/tenant/presentation/screens/organization_list_screen.dart';
import '../../features/tenant/presentation/screens/organization_detail_screen.dart';
import '../../features/tenant/presentation/screens/invite_screen.dart';
import '../../features/sessions/presentation/screens/sessions_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../storage/secure_storage_service.dart';
import '../di/service_locator.dart';
import '../utils/constants.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: RouteConstants.splash,
  redirect: _globalRedirect,
  routes: [
    GoRoute(
      path: RouteConstants.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteConstants.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteConstants.register,
      builder: (_, __) => const RegisterScreen(),
    ),
    GoRoute(
      path: RouteConstants.twoFA,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return TwoFAScreen(
          email: extra?['email'] as String? ?? '',
          tempToken: extra?['tempToken'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: RouteConstants.pinSetup,
      builder: (_, __) => const PinSetupScreen(),
    ),
    GoRoute(
      path: RouteConstants.pinEntry,
      builder: (_, __) => const PinEntryScreen(),
    ),
    // Deep link: invite
    GoRoute(
      path: RouteConstants.invite,
      builder: (_, state) {
        final token = state.uri.queryParameters['token'] ?? '';
        return InviteScreen(token: token);
      },
    ),
    // Chat (full-screen, outside ShellRoute)
    GoRoute(
      path: RouteConstants.chat,
      builder: (_, __) => const ChatScreen(),
    ),
    // Dashboard shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => DashboardScreen(child: child),
      routes: [
        GoRoute(
          path: RouteConstants.profile,
          builder: (_, __) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, __) => const EditProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: RouteConstants.kyc,
          builder: (_, __) => const KycScreen(),
        ),
        GoRoute(
          path: RouteConstants.organization,
          builder: (_, __) => const OrganizationListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => OrganizationDetailScreen(
                tenantId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: RouteConstants.sessions,
          builder: (_, __) => const SessionsScreen(),
        ),
        GoRoute(
          path: RouteConstants.settings,
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

Future<String?> _globalRedirect(BuildContext context, GoRouterState state) async {
  // Allow all auth routes and splash without token check
  final publicRoutes = [
    RouteConstants.login,
    RouteConstants.register,
    RouteConstants.twoFA,
    RouteConstants.splash,
    RouteConstants.pinEntry,
    RouteConstants.pinSetup,
  ];
  if (publicRoutes.any((r) => state.matchedLocation.startsWith(r))) return null;

  // Check token for protected routes
  final storage = sl<SecureStorageService>();
  final hasToken = await storage.hasRefreshToken;
  if (!hasToken) return RouteConstants.login;

  return null;
}
