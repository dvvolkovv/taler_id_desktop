import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../bloc/kyc_bloc.dart';
import '../bloc/kyc_event.dart';
import '../bloc/kyc_state.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  @override
  void initState() {
    super.initState();
    context.read<KycBloc>().add(KycStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Верификация KYC')),
      body: BlocConsumer<KycBloc, KycState>(
        listener: (context, state) {
          if (state is KycSdkReady) {
            // Launch Sumsub SDK
            _launchSumsub(context, state.sdkToken);
          } else if (state is KycError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          if (state is KycLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is KycSdkDone) {
            return _buildWaiting();
          }

          if (state is KycStatusLoaded) {
            return _buildStatus(context, state);
          }

          if (state is KycError) {
            return _buildError(context, state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatus(BuildContext context, KycStatusLoaded state) {
    final statusConfig = _getStatusConfig(state.status);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => context.read<KycBloc>().add(KycStatusRequested()),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 32),
          // Status icon
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: statusConfig.color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: statusConfig.color.withOpacity(0.4), width: 2),
              ),
              child: Icon(statusConfig.icon, color: statusConfig.color, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: StatusBadge(label: statusConfig.label, color: statusConfig.color),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              statusConfig.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ),
          if (state.verifiedAt != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Верифицирован: ${_formatDate(state.verifiedAt!)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
          if (state.rejectionReason != null) ...[
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outlined, color: AppColors.warning, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.rejectionReason!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
          if (state.status == 'UNVERIFIED' || state.status == 'REJECTED') ...[
            LoadingButton(
              text: state.status == 'REJECTED' ? 'Пройти повторно' : 'Пройти верификацию',
              loading: false,
              onPressed: () => context.read<KycBloc>().add(KycStartRequested()),
            ),
          ],
          const SizedBox(height: 16),
          // Info card
          AppCard(
            child: Column(
              children: [
                _infoRow(Icons.security_outlined, 'Ваши данные защищены AES-256 шифрованием'),
                const Divider(color: AppColors.border, height: 1),
                _infoRow(Icons.schedule_outlined, 'Верификация занимает 1-2 рабочих дня'),
                const Divider(color: AppColors.border, height: 1),
                _infoRow(Icons.notifications_outlined, 'Вы получите push-уведомление о результате'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaiting() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Документы отправлены на проверку',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Обычно проверка занимает 1-2 рабочих дня. Вы получите push-уведомление о результате.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(BuildContext context, String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<KycBloc>().add(KycStatusRequested()),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          ],
        ),
      );

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'VERIFIED':
        return _StatusConfig(
          icon: Icons.verified_outlined,
          color: AppColors.primary,
          label: 'Верифицирован',
          description: 'Ваша личность подтверждена. У вас есть полный доступ ко всем функциям экосистемы Taler.',
        );
      case 'PENDING':
        return _StatusConfig(
          icon: Icons.hourglass_empty_outlined,
          color: AppColors.warning,
          label: 'На проверке',
          description: 'Ваши документы проходят верификацию. Обычно это занимает 1-2 рабочих дня.',
        );
      case 'REJECTED':
        return _StatusConfig(
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          label: 'Отклонено',
          description: 'Верификация не пройдена. Ознакомьтесь с причиной и отправьте документы повторно.',
        );
      default:
        return _StatusConfig(
          icon: Icons.person_outlined,
          color: AppColors.textSecondary,
          label: 'Не верифицирован',
          description: 'Пройдите верификацию для получения полного доступа к финансовым функциям экосистемы Taler.',
        );
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  void _launchSumsub(BuildContext context, String sdkToken) {
    // sumsub_flutter SDK launch
    // In production: SNSMobileSDK.init(sdkToken, locale: 'ru').launch()
    // For now, show dialog since SDK requires native setup
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Верификация', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Sumsub SDK будет запущен здесь. Требуется настройка нативного плагина.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<KycBloc>().add(KycSdkCompleted());
            },
            child: const Text('Симулировать завершение', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String label;
  final String description;
  const _StatusConfig({required this.icon, required this.color, required this.label, required this.description});
}
