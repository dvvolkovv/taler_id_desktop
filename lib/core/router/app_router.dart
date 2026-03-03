import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/messenger/presentation/bloc/messenger_bloc.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/two_fa_screen.dart';
import '../../features/auth/presentation/screens/pin_setup_screen.dart';
import '../../features/auth/presentation/screens/pin_entry_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/assistant/presentation/screens/assistant_screen.dart';

import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/tenant/presentation/screens/organization_list_screen.dart';
import '../../features/tenant/presentation/screens/organization_detail_screen.dart';
import '../../features/tenant/presentation/screens/invite_screen.dart';
import '../../features/sessions/presentation/screens/sessions_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/messenger/presentation/screens/conversations_screen.dart';
import '../../features/messenger/presentation/screens/chat_room_screen.dart';
import '../../features/messenger/presentation/screens/user_search_screen.dart';
import '../../features/messenger/presentation/screens/user_profile_screen.dart';
import '../../features/voice/presentation/screens/voice_call_screen.dart';
import '../../features/call_history/presentation/screens/call_history_screen.dart';
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
      path: RouteConstants.onboarding,
      builder: (_, __) => const OnboardingScreen(),
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
    // Voice call (full-screen, outside ShellRoute)
    GoRoute(
      path: RouteConstants.voice,
      builder: (_, state) {
        final roomName = state.uri.queryParameters['room'];
        final conversationId = state.uri.queryParameters['convId'];
        final incoming = state.uri.queryParameters['incoming'] == '1';
        return VoiceCallScreen(
          roomName: roomName,
          conversationId: conversationId,
          isIncoming: incoming,
        );
      },
    ),
    // Dashboard shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => BlocProvider.value(
        value: sl<MessengerBloc>(),
        child: DashboardScreen(child: child),
      ),
      routes: [
        GoRoute(
          path: RouteConstants.assistant,
          builder: (_, __) => const AssistantScreen(),
        ),
        GoRoute(
          path: RouteConstants.profile,
          builder: (_, __) => const ProfileScreen(),
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
          path: RouteConstants.callHistory,
          builder: (_, __) => const CallHistoryScreen(),
        ),
        GoRoute(
          path: RouteConstants.sessions,
          builder: (_, __) => const SessionsScreen(),
        ),
        GoRoute(
          path: RouteConstants.settings,
          builder: (_, __) => const SettingsScreen(),
        ),
        // User profile
        GoRoute(
          path: '/dashboard/user/:userId',
          builder: (_, state) => UserProfileScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
        // Messenger
        GoRoute(
          path: RouteConstants.messenger,
          builder: (_, __) => const ConversationsScreen(),
          routes: [
            GoRoute(
              path: 'search',
              builder: (_, __) => const UserSearchScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => ChatRoomScreen(
                conversationId: state.pathParameters['id']!,
              ),
            ),
          ],
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
    RouteConstants.onboarding,
  ];
  if (publicRoutes.any((r) => state.matchedLocation.startsWith(r))) return null;

  // Check token for protected routes
  final storage = sl<SecureStorageService>();
  final hasToken = await storage.hasRefreshToken;
  if (!hasToken) return RouteConstants.login;

  return null;
}
