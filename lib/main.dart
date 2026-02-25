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
import 'core/storage/secure_storage_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';
import 'features/kyc/presentation/bloc/kyc_bloc.dart';
import 'features/tenant/presentation/bloc/tenant_bloc.dart';
import 'features/sessions/presentation/bloc/sessions_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase (mobile only)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      // Initialize FCM
      await NotificationService.init();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  // Init web token storage (Hive-based, avoids flutter_secure_storage hang)
  await SecureStorageService.initWeb();

  // Setup DI
  await setupDependencies();

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
    _setupCallkitListener();
  }

  /// Navigate to VoiceCallScreen when user accepts a call from the OS notification
  void _setupCallkitListener() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      if (event.event == Event.actionCallAccept) {
        final extra = event.body['extra'] as Map?;
        final roomName = extra?['roomName'] as String?;
        final convId = extra?['conversationId'] as String?;
        if (roomName != null && roomName.isNotEmpty) {
          appRouter.go(
            '/dashboard/voice?room=$roomName&convId=${convId ?? ''}&incoming=1',
          );
        }
      }
    });
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
