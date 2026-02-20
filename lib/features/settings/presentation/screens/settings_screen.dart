import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
import '../../../../main.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _pinEnabled = false;
  String _currentLang = 'ru';
  final _storage = sl<SecureStorageService>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometricEnabled = await _storage.isBiometricEnabled;
    final pinEnabled = await _storage.isPinEnabled;
    final savedLang = await _storage.getLanguage() ?? 'ru';
    final localAuth = LocalAuthentication();
    final canCheck = await localAuth.canCheckBiometrics;
    final available = canCheck && (await localAuth.getAvailableBiometrics()).isNotEmpty;
    setState(() {
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = available;
      _pinEnabled = pinEnabled;
      _currentLang = savedLang;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final localAuth = LocalAuthentication();
      final ok = await localAuth.authenticate(
        localizedReason: l10n.biometricsConfirm,
      );
      if (!ok) return;
    }
    await _storage.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      await context.push(RouteConstants.pinSetup);
      final pinEnabled = await _storage.isPinEnabled;
      setState(() => _pinEnabled = pinEnabled);
    } else {
      await _storage.clearPin();
      setState(() => _pinEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.settings)),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            context.go(RouteConstants.login);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Security section
            _sectionHeader(l10n.security),
            AppCard(
              child: Column(
                children: [
                  if (_biometricAvailable)
                    _switchTile(
                      icon: Icons.fingerprint,
                      iconColor: AppColors.primary,
                      title: l10n.biometrics,
                      subtitle: l10n.biometricsDesc,
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  if (_biometricAvailable) const Divider(color: AppColors.border, height: 1),
                  _switchTile(
                    icon: Icons.pin_outlined,
                    iconColor: AppColors.primary,
                    title: l10n.pinCode,
                    subtitle: l10n.pinCodeDesc,
                    value: _pinEnabled,
                    onChanged: _togglePin,
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.lock_outlined,
                    iconColor: AppColors.secondary,
                    title: l10n.changePassword,
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.security_outlined,
                    iconColor: AppColors.secondary,
                    title: l10n.twoFactorAuth,
                    onTap: () {/* TODO: 2FA setup */},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notifications section
            _sectionHeader(l10n.notifications),
            AppCard(
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.warning,
                    title: l10n.pushKycStatus,
                    subtitle: l10n.pushKycStatusDesc,
                    value: true,
                    onChanged: (v) {},
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _switchTile(
                    icon: Icons.login_outlined,
                    iconColor: AppColors.warning,
                    title: l10n.pushLogins,
                    subtitle: l10n.pushLoginsDesc,
                    value: true,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account section
            _sectionHeader(l10n.account),
            AppCard(
              child: Column(
                children: [
                  _navTile(
                    icon: Icons.language_outlined,
                    iconColor: AppColors.textSecondary,
                    title: l10n.language,
                    trailing: _currentLang == 'ru' ? l10n.languageRussian : l10n.languageEnglish,
                    onTap: () => _showLanguagePicker(context),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.download_outlined,
                    iconColor: AppColors.textSecondary,
                    title: l10n.exportData,
                    onTap: () {/* TODO */},
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: AppColors.error,
                    title: l10n.deleteAccount,
                    onTap: () => _showDeleteAccountDialog(context),
                    textColor: AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: Text(l10n.logout, style: const TextStyle(color: AppColors.error, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _confirmLogout(context),
              ),
            ),

            const SizedBox(height: 16),
            // Version info
            Center(
              child: Text(
                l10n.version('1.0.0'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12,
                fontWeight: FontWeight.w500, letterSpacing: 0.5)),
      );

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      );

  Widget _navTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailing,
    required VoidCallback onTap,
    Color? textColor,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(color: textColor ?? AppColors.textPrimary, fontSize: 14)),
              ),
              if (trailing != null)
                Text(trailing, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 4),
              if (trailing != null || textColor == null)
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      );

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(l10n.logoutConfirm, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.logoutDesc,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Text(l10n.logout, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.changePassword,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(controller: oldCtrl, obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(labelText: l10n.currentPassword)),
            const SizedBox(height: 12),
            TextField(controller: newCtrl, obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(labelText: l10n.newPassword)),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(labelText: l10n.confirmNewPassword)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {/* TODO: change password API */},
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.languageSelect,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('\u{1f1f7}\u{1f1fa}', style: TextStyle(fontSize: 24)),
              title: Text(l10n.languageRussian, style: const TextStyle(color: AppColors.textPrimary)),
              trailing: _currentLang == 'ru' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => _selectLanguage('ru'),
            ),
            ListTile(
              leading: const Text('\u{1f1ec}\u{1f1e7}', style: TextStyle(fontSize: 24)),
              title: Text(l10n.languageEnglish, style: const TextStyle(color: AppColors.textPrimary)),
              trailing: _currentLang == 'en' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () => _selectLanguage('en'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(String lang) async {
    Navigator.pop(context);
    await _storage.saveLanguage(lang);
    TalerIdApp.setLocale(context, Locale(lang));
    setState(() => _currentLang = lang);
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(l10n.deleteAccountConfirm, style: const TextStyle(color: AppColors.error)),
        content: Text(
          l10n.deleteAccountDesc,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {/* TODO: delete account API */},
            child: Text(l10n.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
