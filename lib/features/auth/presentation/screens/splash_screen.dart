import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/di/service_locator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _videoController = VideoPlayerController.asset('assets/video.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoReady = true);
          _videoController.play();
          _animController.forward();
        }
      });

    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final storage = sl<SecureStorageService>();
    final hasToken = await storage.hasRefreshToken;

    if (!hasToken) {
      final onboardingSeen = await storage.isOnboardingSeen;
      if (mounted) {
        context.go(onboardingSeen ? RouteConstants.login : RouteConstants.onboarding);
      }
      return;
    }

    final pinEnabled = await storage.isPinEnabled;
    final biometricEnabled = await storage.isBiometricEnabled;

    if (biometricEnabled) {
      final success = await _tryBiometric();
      if (success) {
        if (mounted) context.go(RouteConstants.assistant);
        return;
      }
      if (pinEnabled) {
        if (mounted) context.go(RouteConstants.pinEntry);
        return;
      }
      if (mounted) context.go(RouteConstants.login);
    } else if (pinEnabled) {
      if (mounted) context.go(RouteConstants.pinEntry);
    } else {
      if (mounted) context.go(RouteConstants.assistant);
    }
  }

  Future<bool> _tryBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      final canAuth = await localAuth.canCheckBiometrics;
      if (!canAuth) return false;
      return await localAuth.authenticate(
        localizedReason: 'Войдите в Taler ID',
        options: const AuthenticationOptions(biometricOnly: false),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _videoReady
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          ),
                        )
                      : Image.asset('app_icon_1024.png', width: 80, height: 80),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Taler ID',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appSubtitle,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
