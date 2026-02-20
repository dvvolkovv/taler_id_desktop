import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/widgets.dart';
import '../../../../core/utils/constants.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  Color _kycColor(KycStatus status) {
    switch (status) {
      case KycStatus.verified: return AppColors.primary;
      case KycStatus.pending: return AppColors.warning;
      case KycStatus.rejected: return AppColors.error;
      case KycStatus.unverified: return AppColors.textSecondary;
    }
  }

  String _kycLabel(KycStatus status) {
    switch (status) {
      case KycStatus.verified: return 'Верифицирован';
      case KycStatus.pending: return 'На проверке';
      case KycStatus.rejected: return 'Отклонён';
      case KycStatus.unverified: return 'Не верифицирован';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => context.push(RouteConstants.profileEdit),
          ),
        ],
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return _buildSkeleton();
          }

          final user = state is ProfileLoaded
              ? state.user
              : state is ProfileUpdating
                  ? state.user
                  : state is ProfileError
                      ? state.user
                      : null;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    state is ProfileError ? state.message : 'Ошибка загрузки',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileBloc>().add(ProfileLoadRequested()),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => context.read<ProfileBloc>().add(ProfileLoadRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar + name
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          _initials(user),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName(user),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            StatusBadge(
                              label: _kycLabel(user.kycStatus),
                              color: _kycColor(user.kycStatus),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Personal info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Личные данные', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      _infoRow(Icons.phone_outlined, 'Телефон', user.phone ?? 'Не указан'),
                      const Divider(color: AppColors.border, height: 1),
                      _infoRow(Icons.flag_outlined, 'Страна', user.country ?? 'Не указана'),
                      const Divider(color: AppColors.border, height: 1),
                      _infoRow(Icons.cake_outlined, 'Дата рождения', user.dateOfBirth ?? 'Не указана'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Documents
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Документы', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: () => _showAddDocument(context),
                            child: const Text('+ Добавить', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (user.documents == null || user.documents!.isEmpty)
                        const Text('Нет загруженных документов', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                      else
                        ...user.documents!.map((doc) => _documentRow(context, doc)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _initials(UserEntity user) {
    final first = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final last = user.lastName?.isNotEmpty == true ? user.lastName![0] : '';
    return (first + last).toUpperCase().isEmpty ? user.email[0].toUpperCase() : (first + last).toUpperCase();
  }

  String _fullName(UserEntity user) {
    final parts = [user.firstName, user.lastName].where((s) => s != null && s.isNotEmpty).toList();
    return parts.isEmpty ? user.email : parts.join(' ');
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      );

  Widget _documentRow(BuildContext context, doc) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppColors.secondary, size: 18),
            const SizedBox(width: 12),
            Text(
              _docTypeName(doc.type),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outlined, color: AppColors.error, size: 18),
              onPressed: () => context.read<ProfileBloc>().add(ProfileDocumentDelete(doc.id)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  String _docTypeName(dynamic type) {
    switch (type.toString()) {
      case 'DocumentType.passport': return 'Паспорт';
      case 'DocumentType.drivingLicense': return 'Водительское удостоверение';
      case 'DocumentType.diploma': return 'Диплом / Сертификат';
      default: return 'Документ';
    }
  }

  void _showAddDocument(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Тип документа', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _docTypeButton(context, 'Паспорт / ID', DocumentType.passport),
            _docTypeButton(context, 'Водительское удостоверение', DocumentType.drivingLicense),
            _docTypeButton(context, 'Диплом / Сертификат', DocumentType.diploma),
          ],
        ),
      ),
    );
  }

  Widget _docTypeButton(BuildContext context, String label, DocumentType type) => ListTile(
        leading: const Icon(Icons.description_outlined, color: AppColors.primary),
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        onTap: () {
          Navigator.pop(context);
          // TODO: pick file with image_picker and dispatch ProfileDocumentUpload
        },
      );

  Widget _buildSkeleton() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              child: Row(
                children: [
                  const SkeletonBox(width: 64, height: 64),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    SkeletonBox(width: 140, height: 18),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 14),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppCard(child: SkeletonBox(width: double.infinity, height: 120)),
          ],
        ),
      );
}
