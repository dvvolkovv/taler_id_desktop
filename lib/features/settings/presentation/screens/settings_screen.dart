import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/utils/constants.dart';
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
  final _storage = sl<SecureStorageService>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometricEnabled = await _storage.isBiometricEnabled;
    final localAuth = LocalAuthentication();
    final canCheck = await localAuth.canCheckBiometrics;
    final available = canCheck && (await localAuth.getAvailableBiometrics()).isNotEmpty;
    setState(() {
      _biometricEnabled = biometricEnabled;
      _biometricAvailable = available;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Verify biometrics before enabling
      final localAuth = LocalAuthentication();
      final ok = await localAuth.authenticate(
        localizedReason: 'Подтвердите биометрию для включения быстрого входа',
      );
      if (!ok) return;
    }
    await _storage.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Настройки')),
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
            _sectionHeader('Безопасность'),
            AppCard(
              child: Column(
                children: [
                  if (_biometricAvailable)
                    _switchTile(
                      icon: Icons.fingerprint,
                      iconColor: AppColors.primary,
                      title: 'Биометрия',
                      subtitle: 'Быстрый вход по Face ID или отпечатку',
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  if (_biometricAvailable) const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.lock_outlined,
                    iconColor: AppColors.secondary,
                    title: 'Изменить пароль',
                    onTap: () => _showChangePasswordSheet(context),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.security_outlined,
                    iconColor: AppColors.secondary,
                    title: 'Двухфакторная аутентификация',
                    onTap: () {/* TODO: 2FA setup */},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notifications section
            _sectionHeader('Уведомления'),
            AppCard(
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.warning,
                    title: 'Push о KYC-статусе',
                    subtitle: 'Результат верификации',
                    value: true,
                    onChanged: (v) {},
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _switchTile(
                    icon: Icons.login_outlined,
                    iconColor: AppColors.warning,
                    title: 'Push о входах',
                    subtitle: 'При входе с нового устройства',
                    value: true,
                    onChanged: (v) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Account section
            _sectionHeader('Аккаунт'),
            AppCard(
              child: Column(
                children: [
                  _navTile(
                    icon: Icons.language_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'Язык',
                    trailing: 'Русский',
                    onTap: () => _showLanguagePicker(context),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.download_outlined,
                    iconColor: AppColors.textSecondary,
                    title: 'Экспорт данных (GDPR)',
                    onTap: () {/* TODO */},
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _navTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: AppColors.error,
                    title: 'Удалить аккаунт',
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
                label: const Text('Выйти', style: TextStyle(color: AppColors.error, fontSize: 16)),
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
                'Taler ID v1.0.0',
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Выйти из аккаунта?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Вы будете выведены из Taler ID на этом устройстве.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: const Text('Выйти', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
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
            const Text('Изменить пароль',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(controller: oldCtrl, obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Текущий пароль')),
            const SizedBox(height: 12),
            TextField(controller: newCtrl, obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Новый пароль')),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Подтвердить новый пароль')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {/* TODO: change password API */},
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Язык интерфейса',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('🇷🇺', style: TextStyle(fontSize: 24)),
              title: const Text('Русский', style: TextStyle(color: AppColors.textPrimary)),
              trailing: const Icon(Icons.check, color: AppColors.primary),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Удалить аккаунт?', style: TextStyle(color: AppColors.error)),
        content: const Text(
          'Все ваши данные будут удалены (GDPR). Это действие необратимо.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {/* TODO: delete account API */},
            child: const Text('Удалить', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
