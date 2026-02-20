import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final storage = sl<SecureStorageService>();
    final hasToken = await storage.hasRefreshToken;

    if (!hasToken) {
      if (mounted) context.go(RouteConstants.login);
      return;
    }

    final biometricEnabled = await storage.isBiometricEnabled;
    if (biometricEnabled) {
      await _tryBiometric(storage);
    } else {
      // Silent token refresh and go to profile
      if (mounted) context.go(RouteConstants.profile);
    }
  }

  Future<void> _tryBiometric(SecureStorageService storage) async {
    final localAuth = LocalAuthentication();
    try {
      final canAuth = await localAuth.canCheckBiometrics;
      if (!canAuth) {
        if (mounted) context.go(RouteConstants.profile);
        return;
      }
      final didAuth = await localAuth.authenticate(
        localizedReason: 'Войдите в Taler ID',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (mounted) {
        context.go(didAuth ? RouteConstants.profile : RouteConstants.login);
      }
    } catch (_) {
      if (mounted) context.go(RouteConstants.login);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_user, color: Colors.black, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Taler ID',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Единая идентификация экосистемы',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
