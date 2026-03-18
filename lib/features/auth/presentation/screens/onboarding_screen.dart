import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/utils/platform_utils.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _notificationsRequested = false;
  bool _microphoneRequested = false;

  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    try {
      final storage = sl<SecureStorageService>();
      await storage.setOnboardingSeen();
    } catch (_) {}
    if (mounted) context.go(RouteConstants.login);
  }

  Future<void> _requestNotifications() async {
    if (isMobilePlatform) {
      await NotificationService.requestPermission();
    }
    setState(() => _notificationsRequested = true);
  }

  Future<void> _requestMicrophone() async {
    if (isMobilePlatform) {
      await Permission.microphone.request();
    }
    setState(() => _microphoneRequested = true);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);

    final pages = [
      _OnboardingPage(
        icon: Icons.shield_outlined,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
        colors: colors,
      ),
      _OnboardingPage(
        icon: Icons.lock_outline,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        colors: colors,
      ),
      _OnboardingPage(
        icon: Icons.notifications_active_outlined,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
        colors: colors,
      ),
      _OnboardingPage(
        icon: Icons.mic_rounded,
        title: l10n.onboardingTitle4,
        description: l10n.onboardingDesc4,
        colors: colors,
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l10n.onboardingSkip,
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),

            // Dots indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? colors.primary : colors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _buildBottomButtons(l10n, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(AppLocalizations l10n, AppColorsExtension colors) {
    // Pages 0-1: simple Next button
    if (_currentPage < 2) {
      return _buildNextButton(l10n, colors);
    }

    // Page 2: Notifications
    if (_currentPage == 2) {
      return _buildPermissionPage(
        requested: _notificationsRequested,
        onRequest: _requestNotifications,
        icon: Icons.notifications_active,
        enableLabel: l10n.onboardingEnableNotifications,
        afterLabel: l10n.onboardingNext,
        onAfter: _nextPage,
        colors: colors,
      );
    }

    // Page 3: Microphone (last page)
    return _buildPermissionPage(
      requested: _microphoneRequested,
      onRequest: _requestMicrophone,
      icon: Icons.mic_rounded,
      enableLabel: l10n.onboardingEnableMicrophone,
      afterLabel: l10n.onboardingStart,
      onAfter: _finish,
      colors: colors,
    );
  }

  Widget _buildNextButton(AppLocalizations l10n, AppColorsExtension colors) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _nextPage,
        child: Text(l10n.onboardingNext),
      ),
    );
  }

  Widget _buildPermissionPage({
    required bool requested,
    required VoidCallback onRequest,
    required IconData icon,
    required String enableLabel,
    required String afterLabel,
    required VoidCallback onAfter,
    required AppColorsExtension colors,
  }) {
    if (!requested) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onRequest,
              icon: Icon(icon, color: Colors.white),
              label: Text(enableLabel),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: onAfter,
              child: Text(afterLabel),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onAfter,
        child: Text(afterLabel),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final AppColorsExtension colors;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: colors.primary, size: 48),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
