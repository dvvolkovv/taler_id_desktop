import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'core/di/service_locator.dart';
import 'core/notifications/notification_service.dart';
import 'core/services/call_state_service.dart';
import 'firebase_options.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/kyc/presentation/bloc/kyc_bloc.dart';
import 'features/tenant/presentation/bloc/tenant_bloc.dart';
import 'features/sessions/presentation/bloc/sessions_bloc.dart';

/// Set up CallKit event listener as early as possible (before runApp) so that
/// accept events are not missed when the app is launched from a killed state.
void _setupCallkitListener() {
  if (kIsWeb) return;
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
    if (event?.event != Event.actionCallAccept) return;
    final extra = event!.body['extra'] as Map?;
    final roomName = extra?['roomName'] as String?;
    final convId = extra?['conversationId'] as String?;
    if (roomName == null || roomName.isEmpty) return;
    final route =
        '/dashboard/voice?room=$roomName&convId=${convId ?? ''}&incoming=1';
    // Store for dashboard to pick up (handles killed-app race condition)
    NotificationService.setPendingCallRoute(route);
    // Only navigate immediately if the app is already in the foreground.
    // If the screen is locked / app is backgrounded, DO NOT navigate here —
    // VoiceCallScreen would mount in background and _connect() would run before
    // CallKit activates the audio session (which only happens after Face ID unlock).
    // DashboardScreen.didChangeAppLifecycleState(resumed) handles navigation
    // via _pendingCallRoute once the phone is unlocked.
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == AppLifecycleState.resumed) {
      try {
        appRouter.go(route);
      } catch (_) {}
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up CallKit listener early — before runApp — to catch accept events
  // that arrive while the app is cold-starting.
  _setupCallkitListener();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init web token storage (Hive-based, avoids flutter_secure_storage hang)
  await SecureStorageService.initWeb();

  // Setup DI first — must happen before NotificationService.init() so that
  // DioClient is registered when we try to save FCM/VoIP tokens.
  await setupDependencies();

  // Initialize Firebase (mobile only) — after DI so DioClient is available
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Initialize FCM
      await NotificationService.init();
      // Handle FCM notification taps (app in background or foreground)
      NotificationService.setupForegroundHandlers(onTap: (msg) {
        final route = notificationToRoute(msg);
        if (route != null) {
          try {
            appRouter.go(route);
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  // Load saved language
  final storage = sl<SecureStorageService>();
  final savedLang = await storage.getLanguage();

  runApp(TalerIdApp(initialLocale: savedLang));
}

class TalerIdApp extends StatefulWidget {
  final String? initialLocale;
  const TalerIdApp({super.key, this.initialLocale});

  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_TalerIdAppState>();
    state?._setLocale(locale);
  }

  @override
  State<TalerIdApp> createState() => _TalerIdAppState();
}

class _TalerIdAppState extends State<TalerIdApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocale != null) {
      _locale = Locale(widget.initialLocale!);
    }
  }

  void _setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<ProfileBloc>()),
        BlocProvider(create: (_) => sl<KycBloc>()),
        BlocProvider(create: (_) => sl<TenantBloc>()),
        BlocProvider(create: (_) => sl<SessionsBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Taler ID',
        theme: AppTheme.dark,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru'),
          Locale('en'),
        ],
      ),
    );
  }
}
